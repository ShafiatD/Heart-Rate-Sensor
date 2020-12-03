#include <xc.inc>

global	HR_Setup, HR_Look_for_beat, HR_Count_beats, HR_Calculate, HR_reset_var, HR_Next_Beat, HR_Add_Beat ;export functions
extrn	ADC_Read ;import from ADC

psect	udata_acs
thresholdh:		ds 1	; reserve 1 byte for threshold high byte
thresholdl:		ds 1	; reserve 1 byte for threshold low byte
addition_count:		ds 1	; reserve 1 byte for the addition counter
multiply:		ds 1	; reserve 1 byte for the multiplication variable
Clear_Reg_count:	ds 1	; reserve 1 byte for the register clear counter
HR_reset_var:		ds 1	; reserve 1 byte for the heartrate reset variable

psect	heartrate_code, class=CODE
HR_Setup:
	movlw	0x01		    ; reset HR Reset variable
	movwf	HR_reset_var, A
	movlw	0x0D		    ; set threshold values
	movwf	thresholdh, A
	movlw	0x98		    ; set threshold values
	movwf	thresholdl, A
	movlw	0x04		    ; set multiplication value to 4
	movwf	multiply, A
	movlw	0x0f		    ; set clear reg counter to 15
	movwf	Clear_Reg_count, A
	movlw	0x0
	lfsr	2, 0x080	    ; set fsr2 to the beginning of the seconds registers
Clear_Registers:
	movwf	POSTINC2, A	    ; clear all registers
	decfsz	Clear_Reg_count, A
	goto	Clear_Registers
	return			    ; return to main code

HR_Look_for_beat:
	call	ADC_Read	    ; call the ADC read function
	movf	thresholdh, W, A    ; move the high byte of the threshold to W
	cpfsgt	ADRESH, A	    ; check if the high byte from the ADC is more than threshold
	goto	lfb_lt_or_eq	    ; if it isnt skip to checking if it is equal or less than
	return			    ; if it is return to main code
lfb_lt_or_eq:
	cpfseq	ADRESH, A	    ; check if the high byte from ADC is equal to threshold
	goto	HR_Look_for_beat    ; if it isnt continue waiting for beat
	movf	thresholdl, W, A    ; if it is move the low byte of the threshold to W
	cpfsgt	ADRESL, A	    ; check if the low byte is bigger than the threshold
	goto	HR_Look_for_beat    ; if it isnt continue waiting for beat
	return			    ; if it is return to main code

HR_Count_beats:
	movlw	0x01		    ; set reset variable to 1
	movwf	HR_reset_var, A
Count_Beats:
	movf	thresholdh, W, A    ; move the high byte of the threshold to W
	call	ADC_Read	    ; call the ADC read function
	cpfsgt	ADRESH, A	    ; check if the high byte from the ADC is more than threshold
	goto	cb_lt_or_eq	    ; if it isnt skip to checking if it is equal or less than
	goto	HR_Add_Beat	    ; if it is go to Add Beat Routine
cb_lt_or_eq:
	cpfseq	ADRESH, A	    ; check if the high byte from ADC is equal to threshold
	goto	Count_Beats	    ; if it isnt continue waiting for beat
	movf	thresholdl, W, A    ; if it is move the low byte of the threshold to W
	cpfsgt	ADRESL, A	    ; check if the low byte is bigger than the threshold
	goto	Count_Beats	    ; if it isnt continue waiting for beat
HR_Add_Beat:
	movlw	0x02		    ; set reset variable to 2
	movwf	HR_reset_var, A
	incf	INDF0, A	    ; increase beat counter by 1
HR_Next_Beat:
	movlw	0x03		    ; set reset variable to 3
	movwf	HR_reset_var, A
	movf	thresholdh, W, A    ; move high byte of threshold to W
Next_Beat:
	call	ADC_Read	    ; read the value from the ACD
	cpfslt	ADRESH, A	    ; check to see if ACD value is lower than threshold
	goto	Next_Beat	    ; if not loop to check again
	goto	HR_Count_beats	    ; if it is go back to counting beats

HR_Calculate:
	movlw	0x0f		    ; set counter to 15
	movwf	addition_count, A
	lfsr	1, 0x080	    ; set fsr1 to the start of the seconds registers
	movlw	0x0		    ; clear W register
Total:
	addwf	POSTINC1,W,A	    ; total all seconds registers
	decfsz	addition_count, A
	goto	Total
	mulwf	multiply, A	    ; multiply by multiplication variable
	return

