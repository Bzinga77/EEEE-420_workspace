;*******************************************************************************
; MSP-FET430P140 Demo - Generate a PWM signal with TA on TA1
; Coded for CCS v5.4 and LaunchPad by Dorin Patru - October 2013
;*******************************************************************************
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------
PWMPeriod	.equ	1000	; ~8x100ms w/ SMCLK / 8
PWMDC1		.equ	900	; 80% DC
PWMDC2		.equ	100		; 20% DC
SWdelay		.equ	0x07FF	; delay value used by the SW timer
;-------------------------------------------------------------------------------
; Program section
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
            .global RESET 					;
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
;;; setup P1.6 as TA OUT1
;-------------------------------------------------------------------------------
			bis.b #BIT6,&P1DIR 		; P1.6 output
			bis.b #BIT6,&P1SEL 		; P1.6 peripheral function
SetupTA 	mov #TASSEL1+ID1+ID0+TACLR,&TACTL 	; SMCLK, Clear TA
									; TACTL = uuuu uu11 0000 u100
			mov #OUTMOD1,&TACCTL1 	;
			mov #PWMPeriod,&TACCR0 	; ~100ms
StartPWM	bic #MC1 + MC0,&TACTL 	; Stop TA to change the value
			mov #PWMDC1,&TACCR1		; Load first PW value in TACCR1
			bis #MC1 + MC0,&TACTL 	; Start TA in up/down mode
			call #SWtimer			; Call the SW delay routine
									; 	to keep this PW for a while
			bic #MC1 + MC0,&TACTL 	; Stop TA to change the value
			mov #PWMDC2, &TACCR1	; Now switch the PW
			bis #MC1 + MC0,&TACTL 	; Start TA in up/down mode
			call #SWtimer			; Call the SW delay routine
									; 	to keep this PW for a while
			jmp	StartPWM			;
;-------------------------------------------------------------------------------
SWtimer:	mov	#SWdelay, r6		; Load delay value in r5
Reloadr5	mov	#SWdelay, r5		; Load delay value in r6
ISr50		dec	r5					; Keep this PW for some time
			jnz	ISr50				; The total SW delay count is
			dec	r6					;  = SWdelay * SWdelay
			jnz	Reloadr5			;
			ret						; Return from this subroutine
;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack
;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
