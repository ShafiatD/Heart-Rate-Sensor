#include <xc.inc>

global  ADC_Setup, ADC_Read, numresulth, numresultl, ADC_hextodec

extrn	lresult, hresult
   
psect	udata_acs
byte8:		ds 1	    ;reserve a byte for the 8bit value
lbyte16:	ds 1	    ;reserve a byte for the low byte of the 16bit value
hbyte16:	ds 1	    ;reserve a byte for the high byte of the 16bit value
lbyte16_2:	ds 1	    ;reserve a byte for the low byte of the second 16bit value
hbyte16_2:	ds 1	    ;reserve a byte for the high byte of the second 16bit value
lbyte24:	ds 1	    ;reserve a byte for the low byte of the 24bit value
mbyte24:	ds 1	    ;reserve a byte for the middle byte of the 24bit value
hbyte24:	ds 1	    ;reserve a byte for the high byte of the 24bit value
lbyte32:	ds 1	    ;reserve a byte for the low byte of the 32bit value
m1byte32:	ds 1	    ;reserve a byte for the second byte of the 32bit value
m2byte32:	ds 1	    ;reserve a byte for the third byte of the 32bit value
hbyte32:	ds 1	    ;reserve a byte for the high byte of the 32bit value
numresulth:	ds 1	    ;reserve a byte for the high byte of the result of hextodec
numresultl:	ds 1	    ;reserve a byte for the high byte of the result of hextodec
ten:		ds 1	    ;reserve a byte for the multiplication value (10)

psect	adc_code, class=CODE
ADC_Setup:
	movwf	numresulth, A
	movwf	numresultl, A
	bsf	TRISA, PORTA_RA0_POSN, A  ; pin RA0==AN0 input
	bsf	ANSEL0	    ; set AN0 to analog
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	bcf	VCFG1	    ; enable ADC to accept external +voltage reference
	bsf	VCFG0
	movlw	0x0a	    ; set 'ten' variable to 10
	movwf	ten, A	    
	return

ADC_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	return

adc8x16:
	movlw	0x0		    ; clear all registers for 24bit number
	movwf	lbyte24, A
	movwf	mbyte24, A
	movwf	hbyte24, A
	movf	byte8, W, A	    ; move 8bit value to W
	mulwf	lbyte16, A	    ; multiply low byte of 16bit value by W
	movff	PRODL, lbyte24, A   ; move the low byte of the result to the low byte of the 24bit value
	movff	PRODH, mbyte24, A   ; move the high byte of the result to the mid byte of the 24bit value
	mulwf	hbyte16, A	    ; multiply high byte of 16bit value by W
	movf	PRODL, W, A	    ; move the low byte of the result to W
	addwf	mbyte24, A	    ; add W to the mid byte of the 24 bit value
	movf	PRODH, W, A	    ; move the high byte of the result to W
	addwfc	hbyte24, A	    ; add W to the high byte of the 24 bit value plus the carry bit
	return
adc16x16:
	movlw	0x0		        ; clear the 32 bit registers
	movwf	lbyte32, A
	movwf	m1byte32, A
	movwf	m2byte32, A
	movwf	hbyte32, A
	movff	lbyte16_2, byte8, A	; move the low byte of the 2nd 16bit value to the 8bit register
	call	adc8x16			; multiply the 8 bit register and the 1st 16bit value
	movff	lbyte24, lbyte32, A	; move the low byte of the result to the low byte of the 32bit value
	movff	mbyte24, m1byte32, A	; move the mid byte of the result to the m1 byte of the 32bit value
	movff	hbyte24, m2byte32, A	; move the high byte of the result to the m2 byte of the 32bit value
	movff	hbyte16_2, byte8, A	; move the high byte of the 2nd 16bit value to the 8bit register
	call	adc8x16			; multiply the 8 bit register and the 1st 16bit value
	movf	lbyte24, W, A		; move the low byte of the result to W
	addwf	m1byte32, A		; add W to the m1 byte of the 32bit value
	movf	mbyte24, W, A		; move the mid byte of the result to W
	addwfc	m2byte32, A		; add W to the m2 byte of the 32bit value plus the carry bit
	movf	hbyte24, W, A		; move the high byte of the result to W
	addwfc	hbyte32, A		; add W to the m2 byte of the 32bit value plus the carry bit
	return
adc8x24:
	movlw	0x0			; clear the 32bit registers except for the high byte
	movwf	lbyte32, A
	movwf	m1byte32, A
	movwf	m2byte32, A
	movff	hbyte24, hbyte32	; move the high byte of the 24bit value to the high byte of the 32bit value (this is to save the byte temporarily)
	movff	mbyte24, hbyte16, A	; move the mid byte of the 24bit value to the high byte of the 16bit value
	movff	lbyte24, lbyte16, A	; move the low byte of the 24bit value to the low byte of the 16bit value
	call	adc8x16			; multiply the 8bit value and the 16bit value
	movff	lbyte24, lbyte32, A	; move the low byte of the result to the low byte of the 32bit value
	movff	mbyte24, m1byte32, A	; move the mid byte of the result to the m1 byte of the 32bit value
	movff	hbyte24, m2byte32, A	; move the high byte of the result to the m2 byte of the 32bit value
	movf	hbyte32, W, A		; move the high byte of the 32bit value to W (the high byte of the original 24bit value)
	mulwf	byte8, A		; multiply the 8bit value by W
	movf	PRODL, W, A		; move the low byte of the result to W
	addwf	m2byte32, A		; add W to the m2 byte of the 32bit value
	movlw	0x0			; clear the high byte of the 32bit value
	movwf	hbyte32, A
	movf	PRODH, W, A		; move the high byte of the result to W
	addwfc	hbyte32, A		; add W to the high byte of the 32bit value plus the carry bit
	return
ADC_hextodec:
	movlw	0x00			;clear result registers
	movwf	numresulth, A
	movwf	numresultl, A
	movff	hresult, hbyte16, A	;move acd outputs to 16bit registers
	movff	lresult, lbyte16, A
	movlw	0x41			;move 0x418A to 2nd 16bit registers
	movwf	hbyte16_2, A
	movlw	0x8A
	movwf	lbyte16_2, A
	call	adc16x16		;perform 16bitx16bit multiplication
	movf	hbyte32, W, A		;move the highest byte to the working register
	iorwf	numresulth, A		;add highest byte to final result register
	swapf	numresulth, A		;move it to high nibble
	movff	ten, byte8		;move 0x0A to 8bit register
	movff	m2byte32, hbyte24, A	;move lowest 3 bytes from 16x16 result to 24 bit registers
	movff	m1byte32, mbyte24, A
	movff	lbyte32, lbyte24, A
	call	adc8x24			;perform 8x24 bit multiplication
	movf	hbyte32, W, A		;move highest byte to the woring register
	iorwf	numresulth, A		;add highest byte to low nibble of the final result register
	movff	m2byte32, hbyte24, A	;move lowest 3 bytes from 16x16 result to 24 bit registers
	movff	m1byte32, mbyte24, A
	movff	lbyte32, lbyte24, A
	call	adc8x24			;perform 8x24 bit multiplication
	movf	hbyte32, W, A		;move highest byte to the woring register
	iorwf	numresultl, A		;add highest byte to low nibble of the final result register
	swapf	numresultl, A		;move it to high nibble
	movff	m2byte32, hbyte24, A	;move lowest 3 bytes from 16x16 result to 24 bit registers
	movff	m1byte32, mbyte24, A
	movff	lbyte32, lbyte24, A
	call	adc8x24			;perform 8x24 bit multiplication
	movf	hbyte32, W, A		;move highest byte to the woring register
	iorwf	numresultl, A		;add highest byte to low nibble of the final result register
	return
end