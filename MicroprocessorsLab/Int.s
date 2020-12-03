#include <xc.inc>
	
global	Int_Setup, Int_Start_interrupt, Int_Main
extrn	Analysis_and_output

psect udata_acs
int_count:  ds 1    ; reserve one byte for the interrupt counter
init:	    ds 1    ; reserve one byte for the initialisation variable

psect	dac_code, class=CODE
	
Int_Setup:
	clrf	TRISJ, A	; Set PORTD as all outputs
	clrf	LATJ, A		; Clear PORTD outputs
	movlw	0x0		; Clear initialisation variable
	movwf	init, A
	return			; return to main code
	
Int_Start_interrupt:
	movlw	10000111B	; Set timer0 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	movlw	0x0
	movwf	int_count, A	; clear interrupt count
	return

Int_Main:
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	bcf	TMR0IF		; clear interrupt flag
	incf	int_count, F, A	; increment interrupt count by 1
	movlw	0x01		; check if init has been initalised
	cpfseq	init, A		
	goto	Int_Check	; if it hasnt goto Int_Check
	movlw	0x0f
	cpfseq	int_count, A	; check if interrupt counter is 15
	goto	Int_Main_lt15	; if it is less than 15 goto main lt15 routine
	lfsr	0, 0x080	; else reset fsr0 to start of seconds registers
	movlw	0x0		; clear interrupt counter
	movwf	int_count, A
	bsf	GIE		; re-enable all interrupts
	pop			; clear unnecessary elements in stack
	goto	Analysis_and_output	; go back to main code
	
Int_Main_lt15:
	movf	POSTINC0, W, A	; increment fsr0
	bsf	GIE		; re-enable all interrupts
	pop			; clear unnecessary elements in stack
	goto	Analysis_and_output	; go back to main code
	
Int_Check:
	movlw	0x0f
	cpfseq	int_count, A	; check if interrupt counter is 15	
	goto	Int_return	; if not go to return routine
	movlw	0x01		; else set initialisation variable to 1
	movwf	init, A		
	lfsr	0, 0x080	; reset fsr0 to start of seconds registers
	movlw	0x0		; clear interrupt counter
	movwf	int_count, A
	bsf	GIE		; re-enable all interrupts
	pop			; clear unnecessary elements in stack
	goto	Analysis_and_output	; go back to main code
	
Int_return:
	movf	POSTINC0, W, A	; increment fsr0
	retfie	f
	end

