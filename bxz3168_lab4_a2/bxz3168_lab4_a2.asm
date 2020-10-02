;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;   Lab3_ArrayFill_a2.asm
;
;   Description; Initialize and fill a 16 element array
;
;	Notes: 	The specific storage mapping between sections and the address
;			space can be found in the lnk_msp430f149.cmd file
;
;   D. Phillips, 365_20053; RIT ; 25Mar06 ; Built with CCE for MSP430 V.1.00
;
;	Updated for CCS v4 by Dorin Patru 03/20/11
;	Updated for CCS v5.4 by Dorin Patru 09/19/13
;*******************************************************************************
; Labels used as constants by the assembler
;-------------------------------------------------------------------------------
NUMROWS 	.equ	0x04
NUMCOLS 	.equ	0x04
FULL		.equ	0x10
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------
; Uninitialized volatile storage
;-------------------------------------------------------------------------------
Array:		.bss ROW0,4		; A 16 element 1-D array that can also
			.bss ROW1,4 	; be considered as a 4x4 2-D array
			.bss ROW2,4		; .bss is an assembler directive to indicate where
			.bss ROW3,4 	; to allocate uninitialized space in memory
							; The first location is at 0x200
			.bss SUM,2		; a sixteen bit storage location
;-------------------------------------------------------------------------------
; Initialized volatile storage
;-------------------------------------------------------------------------------
; Constants
;-------------------------------------------------------------------------------
Constants:	.sect ".const"	; designate which section to store these constants

Zeroes:		.byte 0x00	;
Ones:		.byte 0xff	;
Odds:		.byte 0x55	;
Evens:		.byte 0xaa	;
;-------------------------------------------------------------------------------
; Code
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
;			Main loop here
;-------------------------------------------------------------------------------
Mainloop:
			clr		r4			; row counter
			clr		r5			; column counter
			clr		r6			; array index
			clr		&SUM		; clear the accumulator location
InitLoop:
			cmp.b	#0x04, r6	; passed end of array?
			jeq		DoubleLoop	; yep, done initializing
			mov.b	&Zeroes, ROW0(r6); initialize an element of the array
			add.b	ROW0, SUM
			mov.b 	&Ones, ROW1(r6);
			add.b	ROW1, SUM
			mov.b 	&Odds, ROW2(r6);
			add.b	ROW2, SUM
			mov.b 	&Evens, ROW3(r6);
			add.b 	ROW3, SUM
			add.b 	#1, r6;
			jmp 	InitLoop

DoubleLoop:						;
			clr		r6			; clear the array index
ROWLOOP:						; outer loop, process a row at a time
			cmp.b	#NUMROWS, r4	; finished last row?
			jeq		FINI		; yep, done
COLLOOP:						; inner loop,
			cmp.b	#NUMCOLS, r5	; finished last column?
			jeq		NEXTROW		; yep, done, get the nextrow
			mov.b	r6,	ROW0(r6)	; store the array index in the array
			add		r6,	SUM		; update the summation of the array index
			add.b	#1,	r5		; move to the next element in the row
			add.b	#1,	r6		; update the array index
			jmp		COLLOOP		; try another column
NEXTROW:						;
			clr.b	r5			; clear the column counter
			add.b	#1,	r4		; update the row counter
			jmp		ROWLOOP		; try another row
FINI:							;
			jmp Mainloop		; start over
;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack
;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
; This stores away the address of where to jump to when the MCU is reset
; (Take a look at the linker command file to find the specific address
; associated with the section .reset)
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
