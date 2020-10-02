;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;******************************************************************************
; MSP430G2553 Demo - USI-UART, 9600 Echo ISR, ~1 MHz SMCLK
;
; Description: Echo a received character, RX ISR used.
; USI_RX interrupt triggers TX Echo.
; Default SMCLK = DCOCLK ~= 1.05 MHz
; Baud rate divider with SMCLK @9600 = 1MHz/2400 = 114.15
; Original functionality by M. Buccini / G. Morton
; Texas Instruments Inc., May 2005
; Built with Code Composer Essentials Version: 1.0
; Adapted for DB365 by Dorin Patru 05/14/08; updated May 2011
; Upgraded for LaunchPad and CCS 5.4 by Dorin Patru December 2013
;******************************************************************************
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------
				.data
Print_Array: 	.bss	print_array, 5
;---------------------------------------------------------------------------------
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
; Setup P1.2 as TXD and P1.1 as RXD; see data sheet port schematic and UG
;-------------------------------------------------------------------------------
SetupP1 	bis.b 	#6h,&P1SEL 	; P1.2/P1.1 = USART0 TXD/RXD
			bis.b 	#6h,&P1SEL2 	; P1.2/P1.1 = USART0 TXD/RXD
;-------------------------------------------------------------------------------
; Setup USI in UART mode, minimal configuration, point to point
;-------------------------------------------------------------------------------
SetupUART0 	clr.b 	&UCA0CTL0 		; default values - see UG
			clr.b 	&UCA0CTL1 		; default values - see UG
			bis.b	#UCSSEL1, &UCA0CTL1 ; UCLK = SMCLK ~1.1 MHz
			clr.b 	&UCA0STAT 		; default values - see UG
;			bis.b 	#UCLISTEN, &UCA0STAT ; loopback - used for debugging only
;-------------------------------------------------------------------------------
; For a baud rate of 9600,the pre-scaler value is
;    = (UCAxBR0 + UCAxBR1 × 256) = 104 in decimal - integer part - see UG
;-------------------------------------------------------------------------------
			mov.b 	#068h,&UCA0BR0 	; Baud Rate = ? - YOU MUST COME UP WITH THIS VALUE
			mov.b 	#000h,&UCA0BR1 	; UCBRx = ?		- FOR THE REQUIRED BAUD RATE
;-------------------------------------------------------------------------------
; Modulation Control Register - fractional part - see UG
;-------------------------------------------------------------------------------
			mov.b 	#004h,&UCA0MCTL 	; UCBRFx = 0, UCBRSx = 1, UCOS16 = 0
;-------------------------------------------------------------------------------
; SW reset of the USI state machine
;-------------------------------------------------------------------------------
			bic.b	#UCSWRST,&UCA0CTL1 ; **Initialize USI state machine**
			bis.b 	#UCA0RXIE,&IE2 	; Enable USART0 RX interrupt
	 		bis.b 	#GIE,SR 			; General Interrupts Enabled
;-------------------------------------------------------------------------------
; After the state machine is reset, the TXD line seems to oscillate a few times
; It is therefore safer to check if the machine is in a state in which it is
; ready to transmit the next byte.  Don't remove this code!
;-------------------------------------------------------------------------------
TX2			bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		TX2 					; Jump if TX buffer not ready
			mov.b	#0x55,&UCA0TXBUF 	; TX <U> charac. eq. to #0x55 in ASCII

;-------------------------------------------------------------------------------
; Always check if the transmit buffer is empty before loading a new value in!
; We send a dummy "Hi" to make sure the interface is working.
;-------------------------------------------------------------------------------
TXH			bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		TXH 					; Jump if TX buffer not ready
			mov.b 	#0x48,&UCA0TXBUF 	; TX 'H' charac. eq. to #0x48 in ASCII
TXi			bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		TXi 					; Jump if TX buffer not ready
			mov.b 	#0x69,&UCA0TXBUF 	; TX 'i' charac. eq. to #0x69 in ASCII
TXD			bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		TXD 					; Jump if TX buffer not ready
			mov.b 	#0x0D,&UCA0TXBUF 	; TX <carriage return> charac. eq. to #0x0D in ASCII
TXA			bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		TXA 					; Jump if TX buffer not ready
			mov.b 	#0x0A,&UCA0TXBUF 	; TX <line feed> charac. eq. to #0x0A in ASCII
;-------------------------------------------------------------------------------
;load the array with lower case "print";
			clr		r11
			mov.b	#0x70, print_array(r11)	;p
			mov.b	#1,r11
			mov.b	#0x72, print_array(r11)	;R
			add.b	#1,r11
			mov.b	#0x69, print_array(r11)	;I
			add.b	#1,r11
			mov.b	#0x6e, print_array(r11)	;N
			add.b	#1,r11
			mov.b	#0x74, print_array(r11) ;T
			clr 	r11
;-------------------------------------------------------------------------------
; Mainloop starts here:
;-------------------------------------------------------------------------------
Mainloop 	nop
			cmp		#0x5, r11
			jeq		printloop
			jmp 	Mainloop

printloop	call	#hello_world
			clr		r11
			jmp		Mainloop
;------------------------------------------------------------------------------
; Echo back RXed character, confirm TX buffer is ready first
;------------------------------------------------------------------------------
;new line after receiving print;
;------------------------------------------------------------------------------------------------;
hello_world:	bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
				jz 		hello_world 		; Jump if TX buffer not ready
				mov.b 	#0x0A,&UCA0TXBUF 	; TX <line feed> charac. eq. to #0x0A in ASCII

hello_world2:	bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
				jz 		hello_world2 		; Jump if TX buffer not ready
				mov.b 	#0x0D,&UCA0TXBUF 	; TX <carriage return> charac. eq. to #0x0D in ASCII
;-------------------------------------------------------------------------------------------------
MyStrCpy:		clr		R13					; will count 13 characters of the string
				mov.w   #SourceStr,R14      ; Load address of source
CopyTest:
            ;wait for buffer empty
TXempty:    bit.b 	#UCA0TXIFG, &IFG2 ; USCI_A0 Transmit Interrupt?
			jz		TXempty
            mov.b   @R14+,&UCA0TXBUF          ; [2 words , 5 cycles] copy src -> dst
			inc		R13
            cmp.b   #24,R13                   ; [2 words , 4 cycles] test source
            jne     CopyTest                  ; [1 word , 2 cycles] continue if not \0
;--------------------------------------------------------------------------------------------------;
;new line after printing hello world from MSP430;
;----------------------------------------------------------------------------------------------;
NewLine1	bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		NewLine1					; Jump if TX buffer not ready
			mov.b 	#0x0A,&UCA0TXBUF 	; TX <line feed> charac. eq. to #0x0A in ASCII

NewLine2	bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		NewLine2 					; Jump if TX buffer not ready
			mov.b 	#0x0D,&UCA0TXBUF 	; TX <carriage return> charac. eq. to #0x0D in ASCII
	        ret                                ; Yes: return to caller
;---------------------------------------------------------------------------------------------------
SourceStr:                                     	; string constant, stored between 0xC000 and 0xFFFF
			.string	"hello world, from MSP430 " ; "" should cause a '\0' to be appended
;------------------------------------------------------------------------------
USART0RX_ISR:	nop						;
				mov.b 	&UCA0RXBUF,r10 	; Move received byte in r10
;-------------------------------------------------------------------------------
; For demonstration purposes, it is assumed that the remote terminal sends
; numbers which are eual to the upper case letter.  By adding the value 0x20 to
; it, the echoed number represents the same, but lower case letter.
;-------------------------------------------------------------------------------
			add.b 	#0x20, r10 				; add 0x20 to change upper -> lower case of the received byte
CheckLoop	cmp.b 	r10, print_array(r11)	; compare lower case received byte to letters of array
			jne		Loop1					; if not equal, jump to Loop1
			inc		r11						; increment array index
			jmp		Loop2					; jump to loop 2

;P -> correct! \\ index 0 -> 1;
;P -> incorrect! \\ looking for index 1(R) ;
;need to compare to index 0 to see if incorrect letter is P. If not then clear index and restart.

Loop1
			clr 	r11						; clears r11 to index 0 to check if p is pressed twice
			cmp.b 	r10, print_array(r11)	;
			jeq		Loop3					; if incorrect letter is "p" being pressed twice, go to loop3
			clr 	r11						; clear index of array back to 0
			jmp 	Loop2					;

Loop3		inc 	r11						; increment the index of array and go to loop2 to print letter
			jmp 	Loop2					;

;this loops outputs the lower case letter of the uppercase inputted letter;
Loop2		bit.b 	#UCA0TXIFG,&IFG2 	; USI TX buffer ready?
			jz 		Loop2				; Jump if TX buffer not ready
			mov.b 	r10,&UCA0TXBUF 		; TX -> RXed character
			reti 						;
;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack
;-------------------------------------------------------------------------------
;           Interrupt Vectors - see device specific header file
;-------------------------------------------------------------------------------
            .sect   ".reset"		; RESET Vector
            .short  RESET
			.sect ".int07" 			; USI - RXD Vector
isr_USART:	.short USART0RX_ISR 	; USI receive ISR
.end
