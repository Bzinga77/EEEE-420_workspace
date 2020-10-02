;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;   MSP430G2553 Demo - Software Toggle P1.0
;
;   Description; Toggle P1.0 by xor'ing P1.0 inside of a software loop.
;   ACLK = n/a, MCLK = SMCLK = default DCO ~ 800k
;
;                MSP430x1xx
;             -----------------
;         /|\|              XIN|-
;          | |                 |
;          --|RST          XOUT|-
;            |                 |
;            |             P1.0|-->LED
;
;   M.Buccini
;   Texas Instruments, Inc
;   September 2004
;   Built with CCE for MSP430 Version: 1.00
;	Modified and enhanced for the EE365 Kit by Dorin Patru, March 2011;
;	Modified and enhanced for the LaunchPad by Dorin Patru, September 2013
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
            .global RESET 					; Define entry point
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;-------------------------------------------------------------------------------
                                            ; Main loop here
;-------------------------------------------------------------------------------
SetupP4     bis.b   #001h,&P1DIR            ; P1.0 output
			bic.w #0xFFFF,r12;
            bis.w #0x12EF,r12			;
			bic.w #0xFFFF,r13 						;
			bic.w #0xFFFF,r14 						;
			bic.w #0xFFFF,r15 						;
			bis.b #0x00EF,r13 					;
			bis.w #0x12EF,r14 					;
			bis.w #0x12EF,r15 					;
Mainloop    xor.b   #001h,&P1OUT            ; Toggle P1.0
Wait        mov.w   #050000,R15             ; Delay to R15
L1          dec.w   R15                     ; Decrement R15
            jnz     L1                      ; Delay over?
            jmp     Mainloop                ; Again
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
