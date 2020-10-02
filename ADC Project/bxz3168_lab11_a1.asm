;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;LEDS
LED0		.equ	0x01
LED1		.equ	0x10
LED2		.equ	0x20
LED3		.equ	0x40
LED4		.equ	0x80
LED5		.equ	0xE8
LED6		.equ	0xD8
LED7		.equ	0xB8
LED8		.equ	0x78
SWdelay		.equ 	0x6
LED			.equ 	0xAF
;-------------------------------------------------------------------------------
;variables
;-------------------------------------------------------------------------------
	.data
	.bss	meas_base, 10
	.bss 	meas_latest, 10
	.bss	sensor_status, 1
	.bss	converted_samp, 20
	.bss 	TA_SW_FLAG, 1
	.bss 	converted_Log, 20
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.
           	.global functions
			.global setup
			.global waitForCenter
			.global waitForUpDown
			.global waitForLeftRight
			.global getSamples
			.global convertSamples
			.global displaySamples
			.global UART_samples
;-------------------------------------------------------------------------------
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
setup:
			bis.b	#0xff, &P1DIR	; set up P1 as outputs
			bic.b	#0xff, &P1OUT	; P1 outputs 0
			bis.b 	#6h,&P1SEL 		; P1.2/P1.1 = USART0 TXD/RXD
			bis.b 	#6h,&P1SEL2 	; P1.2/P1.1 = USART0 TXD/RXD
			call 	#meas_base_val

;---------------------------------------------------------------------------------
;functions
;--------------------------------------------------------------------------------
waitForCenter:
			clr   &P1OUT
			mov.b #LED0, P1OUT
			call  #LEDdelay
			call  #meas_latest_val	; stores 5 meas_latest values
			call  #det_sensor		; detects which sensor is touched
			cmp.b #0x20,sensor_status	; center LED/ middle sense
			jne	  waitForCenter
			clr   sensor_status
endcenter	mov	  #0, P1OUT
			ret

waitForUpDown:
			clr   R10
			clr   &P1OUT
			mov.b #0x68, P1OUT			; turns on LEDs 5&8 to prompt top/bottom
			call  #meas_latest_val
			call  #det_sensor
			cmp   #0x10, sensor_status	; see if top sense is pressed
			jeq   topsense
			cmp   #0x4, sensor_status	; see if bottom sense is pressed
			jeq   botsense
			jmp   waitForUpDown
topsense	mov   #0, P1OUT
			mov   #1, R10				; stores 1 for 0.2 sample rate
			clr	  sensor_status
			jmp   endtest
botsense	mov   #0, P1OUT
			mov   #2, R10				; stores 2 for 0.5 sample rate
			clr   sensor_status
			jmp   endtest
endtest		nop
			ret

waitForLeftRight:
			clr   R11
			clr	  &P1OUT
			mov.b #0x60, P1OUT
			call  #LEDdelay
			mov.b #0, P1OUT
			call  #LEDdelay
			mov.b #0x98, P1OUT
			call  #LEDdelay
			mov.b #0, P1OUT

			call  #meas_latest_val
			call  #det_sensor
			cmp   #0x2, sensor_status
			jeq   leftsense
			cmp   #0x8, sensor_status
			jeq   rightsense
			jmp   waitForLeftRight
leftsense 	clr &P1OUT
			mov #1, R11		; Log scale
			ret
rightsense  clr &P1OUT
			mov #2, R11		; Linear scale
			ret

convertSamples:
			cmp #1, R11		; see if linear or log conversion
			jeq convertLog	;
			clr R13			; index counter for samples
			clr R12			; Linear shift counter -> 7x
			clr  R9  		; used to keep track of how many times shifted -> Log
			clr R14			;
			mov #0x8, R14	;

convertLinear
			cmp #0x28, R13
			jeq finishLin
		 	rra UART_samples(R13)						; shift UART_Sample right, R13 used for index of samples
		 	add #2, R13
		 	inc R12										; increment linear shift counter
		 	cmp #0x7, R12								; see if shifted 7x
		 	jeq Linear									; jump to Linear if shifted 7x
		 	jmp convertLinear
Linear		mov UART_samples(R13), converted_samp(R13)	; move the shifted value in converted_samp array
finishLin	ret

convertLog
			cmp  #0x28, R13
			jeq  finishLog
			bic  #0xEFFF, UART_samples(R13)		; 1XXX XXXX XX -> bit mask to see if 10th bit is equal 1
			cmp  #0x200, UART_samples(R13)		; if 10th bit equal 1 jump to Log
			jeq  Log
			rla  UART_samples(R13)				; rotate left
			add  #2, R13
			inc  R9 							; add 1 to shift counter
			cmp  #0x8, R9						; compare to see if shifted 8 times
			jeq  Log							; if shifted 8 times, jump to Log
Log 		sub  R9, R14						; this gives the # of LEDs on
			mov  R14, converted_Log(R13)
			jmp  convertLog
finishLog	ret

displaySamples:
SetupTimerA eint
			clr &TACCTL0				;
			clr &TA0CTL					;
			bis #(TASSEL_2 + MC_1 + ID_3 + TACLR + TAIE), &TA0CTL 	;

SetupUART0 	clr.b 	&UCA0CTL0 		; default values - see UG
			clr.b 	&UCA0CTL1 		; default values - see UG
			bis.b	#UCSSEL1, &UCA0CTL1 ; UCLK = SMCLK ~1.1 MHz
			clr.b 	&UCA0STAT 		; default values - see UG
			mov.b 	#068h,&UCA0BR0 	; Baud Rate = ? - YOU MUST COME UP WITH THIS VALUE
			mov.b 	#000h,&UCA0BR1 	; UCBRx = ?		- FOR THE REQUIRED BAUD RATE

			cmp #1, R10
			jeq displayTwo

displayfive	mov #0xFFFF, &TA0CCR0   ;  0.5s display rate
testflag	tst.b &TA_SW_FLAG		;
			jz  testflag
			cmp #1, R11
			jeq LogDisplay
			jmp LinearDisplay
			ret

displayTwo  mov #0x6B6C, &TA0CCR0	;  0.2s display rate
testflag2	tst.b &TA_SW_FLAG
			jz  testflag2
			cmp #1, R11
			jeq LogDisplay
			jmp LinearDisplay
			ret

LinearDisplay
			clr R13
Check		clr &P1OUT
			mov converted_samp(R13), R15
			add #2, R13
			cmp #0x28, R13
			jeq Clear
			cmp #0, R15
			jeq Linear1
			cmp #1, R15
			jeq Linear2
			cmp #2, R15
			jeq Linear3
			cmp #3, R15
			jeq Linear4
			cmp #4, R15
			jeq Linear5
			cmp #5, R15
			jeq Linear6
			cmp #6, R15
			jeq Linear7
			cmp #7, R15
			jeq Linear8
			jmp Check
Clear 		clr R13
			jmp Check


Linear1		mov #LED4, P1OUT
			call #LEDdelay
			jmp Check
Linear2		mov #(LED3+LED4), P1OUT
			call #LEDdelay
			jmp Check
Linear3 	mov #(LED2+LED3+LED4), P1OUT
			call #LEDdelay
			jmp Check
Linear4		mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			jmp Check
Linear5 	mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #LED5, P1OUT
			call #LEDdelay
			jmp Check
Linear6     mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #(LED5+LED6), P1OUT
			call #LEDdelay
			jmp Check
Linear7		mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #(LED5+LED6+LED7), P1OUT
			call #LEDdelay
			jmp Check
Linear8		mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #(LED5+LED6+LED7+LED8), P1OUT
			call #LEDdelay
			jmp Check

LogDisplay
			clr r13
			inc r13
Check2		clr &P1OUT
			cmp #0, R14
			jeq Log1
			cmp #1, R14
			jeq Log2
			cmp #2, R14
			jeq Log3
			cmp #3, R14
			jeq Log4
			cmp #4, R14
			jeq Log5
			cmp #5, R14
			jeq Log6
			cmp #6, R14
			jeq Log7
			cmp #7, R14
			jeq Log8
			cmp #8, R14
			jeq Log9

Log1		clr &P1OUT
			call #LEDdelay
			jmp Check2
Log2		mov #LED4, P1OUT
			call #LEDdelay
			jmp Check2
Log3		mov #(LED3+LED4), P1OUT
			call #LEDdelay
			jmp Check2
Log4	 	mov #(LED2+LED3+LED4), P1OUT
			call #LEDdelay
			jmp Check2
Log5		mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			jmp Check2
Log6	 	mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #LED5, P1OUT
			call #LEDdelay
			jmp Check2
Log7	    mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #(LED5+LED6), P1OUT
			call #LEDdelay
			jmp Check2
Log8		mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #(LED5+LED6+LED7), P1OUT
			call #LEDdelay
			jmp Check2
Log9		mov #(LED1+LED2+LED3+LED4), P1OUT
			call #LEDdelay
			mov #(LED5+LED6+LED7+LED8), P1OUT
			call #LEDdelay
			jmp Check2

TA0_ISR:
			bic.w #TAIFG, &TA0CTL	;
			mov.b #1, &TA_SW_FLAG	;	sets TA_SW_FLAG high
			reti
;------------------------------------------------------------------------------
;SubRoutines
;------------------------------------------------------------------------------
meas_setup:
			bic.b R5,&P2DIR
			bic.b R5,&P2SEL
			bis.b R5,&P2SEL2
		 	mov #TASSEL_3, &TA0CTL
			mov #CM_3 + CCIS_2 + CAP, &TA0CCTL1
			ret

meas_base_val:
			mov.b	#0x02, R5	; initialize R5 to point to P2.x
			mov.b	#0x00, R6	; initialize R6 to the base of meas_base
meas_base_again
			call #meas_setup			;
			bis #MC_2 + TACLR, &TA0CTL 	;
			call #SWtimer				;
			xor	#CCIS0, &TA0CCTL1		;
			mov	TA0CCR1, meas_base(R6)	;
			bic #MC1+MC0, &TA0CTL 		;
			sub #4, meas_base(R6)		;
			bic.b 	R5,&P2SEL2			;
			rla.b	R5					;
			add.b	#0x02, R6			;
			cmp.b	#0x40, R5			;
			jne		meas_base_again		;
			ret							;

meas_latest_val:
			mov.b	#0x02, R5	; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
meas_latest_again
			call #meas_setup	;
			bis #MC_2 + TACLR, &TA0CTL 	; Continuous, Clear TAR
			call #SWtimer			;
			xor #CCIS0, &TA0CCTL1	; Trigger SW capture
			mov TA0CCR1, meas_latest(R6)	; Save captured value in array
			bic #MC1+MC0, &TA0CTL 	; Stop timer
			bic.b 	R5,&P2SEL2		; Stop the oscillation on the latest. pin
			rla.b	R5				; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
			jne		meas_latest_again	;
			ret							;

det_sensor:
			clr.b	sensor_status	;
			mov.b	#0x02, R5		; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
CheckNextSensor
			cmp		meas_latest(R6), meas_base(R6)	;
			jl		NotThisSensor		;
			bis.b	R5, sensor_status	; Update sensor_status
NotThisSensor
			rla.b	R5			; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
			jne		CheckNextSensor	;
			ret						;

SWtimer:
			mov	#SWdelay, r8		;
Reloadr7	mov	#SWdelay, r7		;
ISr70		dec	r7					;
			jnz	ISr70				; The total SW delay count is
			dec	r8					;  = SWdelay * SWdelay
			jnz	Reloadr7			;
			ret						; Return from this subroutine

LEDdelay:
			mov	#LED, r8		;
Reloadr70	mov	#LED, r7		;
ISr700		dec	r7					;
			jnz	ISr70				; The total SW delay count is
			dec	r8					;  = SWdelay * SWdelay
			jnz	Reloadr7			;
			ret						; Return from this subroutine
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
;-------------------------------------------------------------------------------
isr_TimerA: .sect ".int08"
			.short TA0_ISR	;
.end
