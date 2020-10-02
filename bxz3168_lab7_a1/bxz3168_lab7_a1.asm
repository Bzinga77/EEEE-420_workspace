;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
; Toggles the center LED when center "key" on the capacitive touch sensor
; is "pressed"
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
SWdelay		.equ	0x000F	; delay value used by the SW timer
;-------------------------------------------------------------------------------
; Allocate 2 bytes for the baseline measurement
;-------------------------------------------------------------------------------
			.data
			.bss	meas_base, 2			;
;-------------------------------------------------------------------------------
; Allocate another 2 bytes for the latest measurement
;-------------------------------------------------------------------------------
			.bss	meas_latest, 2				;
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
            .global RESET					;
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
; Main loop from here
;-------------------------------------------------------------------------------
; Setting up P1.0 to drive center LED
;-------------------------------------------------------------------------------
			bis.b	#0xff, &P1DIR	; set up P1 as outputs
			bic.b	#0xff, &P1OUT	; P1 outputs 0
;-------------------------------------------------------------------------------
; Setting up P2.5 to pin oscillation mode
;-------------------------------------------------------------------------------
			bic.b #BIT5,&P2DIR 		; P2.5 input
			bic.b #BIT5,&P2SEL 		;
			bis.b #BIT5,&P2SEL2		;
;-------------------------------------------------------------------------------
; The oscillation from P2.5 is driving INCLK input of TA0
; No division of this clock source
;-------------------------------------------------------------------------------
		 	mov #TASSEL_3, &TA0CTL 	;
;-------------------------------------------------------------------------------
; Setting up to capture the value of TAR on either rising or falling edges
; using SW based trigger
;-------------------------------------------------------------------------------
			mov #CM_3 + CCIS_2 + CAP, &TA0CCTL1 	;
;-------------------------------------------------------------------------------
; Get the baseline reading
;-------------------------------------------------------------------------------
; Clear TAR and start TA0 in continuous mode; use BIS and not MOV
; so that you don't cancel previous settings
;-------------------------------------------------------------------------------
			bis #MC_2 + TACLR, &TA0CTL 	;
;-------------------------------------------------------------------------------
; Call the SW delay routine, which here it is used to provide the accumulation
; period;
;-------------------------------------------------------------------------------
			call #SWtimer			;
;-------------------------------------------------------------------------------
; Now, after the accumulation period has passed, generate a SW based
; capture trigger by toggleing CCIS0
;-------------------------------------------------------------------------------
			xor	#CCIS0, &TA0CCTL1	;
;-------------------------------------------------------------------------------
; Save the baseline captured value in meas_base
;-------------------------------------------------------------------------------
			mov	TA0CCR1, meas_base	; note the use of the SYMBOLIC AM
			bic #MC1+MC0, &TA0CTL 	; Stop TA
			sub #5, meas_base		; Adjust the baseline
;-------------------------------------------------------------------------------
; From here on check again and again the status of the sensor
; If it was "pressed", i.e. meas_latest =/= meas_base, toggle the central LED
;-------------------------------------------------------------------------------
CheckAgain	bis #TACLR, &TA0CTL 	; Clear TAR
			bis #MC_2, &TA0CTL 		; Continuous Mode
			call #SWtimer			;
			xor #CCIS0, &TA0CCTL1	;
			mov TA0CCR1, meas_latest; Puts TACCR1 into meas_latest
			bic #MC1+MC0, &TA0CTL 	; Stop TA
			cmp	meas_base, meas_latest; see if button is pressed
			jl	NoKey			;
			jmp CheckAgain		;
NoKey
			cmp #0x0460, meas_latest;
			jge	CheckAgain			;
Toggle
			xor #1, P1OUT			;
			jmp CheckAgain			;
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
