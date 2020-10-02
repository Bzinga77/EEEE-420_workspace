;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430g2553.h"       ; Include device header file
;-------------------------------------------------------------------------------
; R/W Data
;-------------------------------------------------------------------------------
				.bss ADC_SW_FLAG,1 ;
				.bss TA_SW_FLAG,1	;
DataSample:		.bss sample, 64		;
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
;
;-------------------------------------------------------------------------------
			clr.b &ADC_SW_FLAG 	; Clear ADC SW flag
			clr.b &TA_SW_FLAG	;
			clr.w r5 		; Register used to store and process the sample value
							; after its acquisition
			clr r6			;
			clr.w r8		;
;-------------------------------------------------------------------------------
; Select analog function on P1.0, i.e. pin2 of the 20PDIP package
;-------------------------------------------------------------------------------
			bis.b #0x01, &ADC10AE0	; P1.0 on pin 2 analog function enabled
;-------------------------------------------------------------------------------
; Main loop from here
;-------------------------------------------------------------------------------
Timer:
			eint						;
			clr &TACCTL0				;
			clr &TA0CTL					;
			mov #0x2AF8, &TA0CCR0		;
			bis #(TASSEL_2 + MC_1 + TACLR + TAIE), &TA0CTL 	;
FLAG_TEST
			tst.b &TA_SW_FLAG	;	check flag = 0
			jz	FLAG_TEST		;	if flag = 0, test again
			cmp #0x20, r8		;	Check if r8 = 32
			jeq end				;	jump to end if r8 = 32
			call #ACQUIRE 		;
			clr &TA_SW_FLAG		;
			jmp FLAG_TEST		;

end			nop					;

;-------------------------------------------------------------------------------

ACQUIRE:
			clr.w	&ADC10CTL0	; Clear configuration registers just in case
			clr.w	&ADC10CTL1	; some values were left on by a prior routine
;-------------------------------------------------------------------------------
; ADC10CTL0 configuration based on the CLR instruction above and the one below:
;	SREF=001, ADC10SHT=64*ADC10CLKs, ADC10SR=0, REFOUT=0, REFBURST=0, MSC=0,
;	REF2_5=0, REFON=1, ADC10ON=1, ADC10IE=1, ADC10IFG=0, ENC=0, ADC10SC=0
;-------------------------------------------------------------------------------
			bis.w #(SREF_1 + ADC10SHT_3 + REFON + ADC10ON + ADC10IE), &ADC10CTL0 ;
;-------------------------------------------------------------------------------
; ADC10CTL1 configuration based on the CLR instruction above and the ones below:
;	INCH=1010, SHS=00, ADC10DF=0, ISSH=0, ADC10DIV=/8, ADC10SSEL=00,
;	CONSEQ=00, ADC10BUSY=0
;-------------------------------------------------------------------------------
			bis.w #(INCH_0 + ADC10DIV_7), &ADC10CTL1 ; Input channel = int. temp. diode
			clrz 				; Clear Z
			clr.b &ADC_SW_FLAG 		; Clear ADC SW FLAG
			bis.w #(ENC + ADC10SC), &ADC10CTL0 ; Start a conversion
CheckFlag	tst.b &ADC_SW_FLAG 		; Check to see if ADC10_ISR was
			jz CheckFlag 		; executed
			clr.w	&ADC10CTL0	; Clear configuration registers
			clr.w	&ADC10CTL1	; Safe practice
			add.b #1, r8		;
			ret					;
;-------------------------------------------------------------------------------
; Interrupt Service Routines
;-------------------------------------------------------------------------------
ADC10_ISR:
			nop					;
			bic.w #ADC10IFG, &ADC10CTL0	;
			mov.w &ADC10MEM, r5	;
			mov.w r5, DataSample(r6);
			add.w #2, r6		;

;-------------------------------------------------------------------------------
; Set the ADC SW flag, which is continuously checked by the ACQUIRE routine
;-------------------------------------------------------------------------------
			mov.b #0x01, &ADC_SW_FLAG ;
			reti 				;
;-------------------------------------------------------------------------------
TA0_ISR:
			bic.w #TAIFG, &TA0CTL	;
			mov.b #1, &TA_SW_FLAG	;	sets TA_SW_FLAG high
			reti
;---------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack
;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"		; MSP430 RESET Vector
            .short  RESET
;-------------------------------------------------------------------------------
			.sect ".int05" 			; ADC10 Vector
isr_adc10: 	.short ADC10_ISR ;
;-------------------------------------------------------------------------------
isr_TimerA: .sect ".int08"
			.short TA0_ISR	;
.end
