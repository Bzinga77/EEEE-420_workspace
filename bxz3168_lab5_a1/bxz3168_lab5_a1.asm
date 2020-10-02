;*******************************************************************************
;	MSP430 Assembler Code Template for use with TI Code Composer Studio
;   dxp_Lab5_a1_CAPTOUCH1.asm
;	Displays a clockwise circle
;	dbp 0301_365_20053
;   Built with CCE for MSP430 Version: 1.00
;	Updated for version 4.x.x by Dorin Patru April 2011
;	Re-coded completely for CCS v5.4, Launch Pad and Capacitive Booster Pack
;		by Dorin Patru October 2013
;*******************************************************************************

;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------

;		.data			; presume .data begins at 0x0200
SPEED:	.word	0xFFFF	; display half speed
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
                                            ; Main loop here
;-------------------------------------------------------------------------------
			clr		r10				; delay counter
			clr		r11				; LED select
			clr 	r7
			bic.b	#0xff,&P1DIR	; set up P1 as input
			bis.b	#0xf8,&P1DIR	; set up P1[7:3] as outputs
;-------------------------------------------------------------------------------
;	LEDs 4-1 not elegant display
;-------------------------------------------------------------------------------
; Loop of LEDs 8-5
;---------------------------------------------------------------------------------
LED8to5prep:bic.w	#0xf8,&P1OUT	; turn out all LEDs
			bis.w	#0xf8,&P1OUT	; prepare to display LEDs 5-8
			mov.w	#0x100, r11		; prepare r11 for the loop
			clr 	r7				; clears counter for Loop
LED8to5:	rra.w	r11				; Rotate R11 right
			add.b 	#0x1,r7			; add 1 to counter
			cmp		#0x5,r7			; compare to see if counter equals 5
			jeq		LED1to4prep		; If counter=5 then jump to LED1to4prep Loop
			bic.w	r11, &P1OUT		; turn on LEDs 5-8
			call	#DELAY			; wait around
			bis.w 	#0x00FF,&P1OUT	; Set P7 to P0 to 1.
			jmp		LED8to5			; jump to display the next LED
;--------------------------------------------------------------------------------
LED1to4prep:bic.b	#0xf8,&P1OUT	; prepare to display LEDs 1-4
			mov.b	#0x8, r11		; prepare r11 for the loop
			clr 	r7				; clears counter for loop
LED1to4:	rla.w	r11				; Rotate R11 left
			add.b 	#0x1,r7			; add 1 to counter
			cmp		#0x5,r7			; compare to see if counter=5
			jeq		LED8to5prep		; If counter=5 then jump to LED8to5prep
			bis.w	r11,&P1OUT		; turn on LEDs 1-4
			call	#DELAY			;
			AND 	#0x0000,&P1OUT	; Set P7 to P0 to 0.
			jmp		LED1to4			; jump to display the next LED
;-------------------------------------------------------------------------------
;	Delay Subroutine
;-------------------------------------------------------------------------------
DELAY:		mov.w	&SPEED,R10
MORE_DELAY:	dec.w   R10             ; Decrement R10
            jnz     MORE_DELAY   	; Delay over?
           	ret				    	; return
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
