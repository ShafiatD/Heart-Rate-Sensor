#include <xc.inc>
global	lresult, hresult, Analysis_and_output, count_beats
extrn	LCD_Setup, LCD_Write_HR, LCD_ErrMessage ; external LCD subroutines
extrn	ADC_Setup, ADC_Read, ADC_hextodec ; external ADC subroutines
extrn	Int_Setup, Int_Start_interrupt, Int_Main ; external Interrupt subroutines
extrn	HR_Setup, HR_Look_for_beat, HR_Count_beats, HR_Calculate, HR_reset_var, HR_Next_Beat, HR_Add_Beat ; external heart rate subroutines
    
psect	udata_acs   ; reserve data space in access ram
hresult:    ds 1    ; reserve one byte for the high byte of the hextodec result
lresult:    ds 1    ; reserve one byte for the low byte of the hextodec result
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

int_hi:	org	0x0008	; high vector, no low vector
	goto	Int_Main

setup:	
	lfsr	0,0x080
	call	LCD_Setup	; setup LCD
	call	ADC_Setup	; setup ADC
	call	Int_Setup	; setup Int
	call	HR_Setup	; setup HR
	goto	start
	
	; ******* Main programme ****************************************
start:	
	call	HR_Look_for_beat	; call look for beat routine
	call	Int_Start_interrupt	; call routine to start interrupt
count_beats:
	movlw	0x0			; clear file register to be counted in
	movwf	INDF0, A
	movlw	0x01			; check if reset variable is >1
	cpfsgt	HR_reset_var, A
	goto	HR_Count_beats		; if =1 call count beat routine
	movlw	0x02			; check if reset variable is >2
	cpfsgt	HR_reset_var, A
	goto	HR_Add_Beat		; if =2 call add beat routine
	goto	HR_Next_Beat		; else if =3 call next beat routine
Analysis_and_output:
	movlw	0x01			; reset stack pointer if unbalanced
	cpfseq	STKPTR, A
	pop
	call	HR_Calculate		; call rate calculation routine
	movlw	0x28
	cpfsgt	PRODL, A		; if low byte is less than 40, show error
	goto	LCD_ErrMessage
	movlw	0xC8
	cpfslt	PRODL, A		; if low byte is more than 200 show error
	goto	LCD_ErrMessage
	movlw	0x01
	cpfslt	PRODH, A		; if high byte is more than 0 show error
	goto	LCD_ErrMessage
	movff	PRODL, lresult		; move heartrate low byte to l result register
	movff	PRODH, hresult		; move heartrate high byte to h result register
	call	ADC_hextodec		; convert heartrate from hex to decimal
	call	LCD_Write_HR		; call LCD HR write code
	goto	count_beats		; count the next beat

	end	rst