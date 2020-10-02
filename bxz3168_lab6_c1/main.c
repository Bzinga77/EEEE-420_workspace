#include <msp430g2553.h>

int PWMPeriod=1000 ; //~8x100ms w/ SMCLK / 8
int PWMDC1=900   ; //80% DC
int PWMDC2=100    ; //20% DC
int SWdelay=0x07ff  ; //delay value used by the SW timer
unsigned int speed = 0x07FF;
/**
 * main.c
 */
int main(void)
{
	WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
    void SWtimer(void);
    P1DIR |= BIT6; //P1.6 output
    P1SEL |= BIT6; //P1.6 peripheral function
    TACTL = TASSEL1+ID1+ID0+TACLR;
    TACCTL1 = OUTMOD1;
    TACCR0 = PWMPeriod;

	    while(1)
	    {
	     TACTL &= ~(MC1 + MC0);
	     TACCR1 = PWMDC1;
	     TACTL |= (MC1 + MC0);
	     SWtimer();

	     TACTL &= ~(MC1 + MC0);
	     TACCR1 = PWMDC2;
	     TACTL |= (MC1 + MC0);
	     SWtimer();
	     }
}

void SWtimer(void)
	 {
	 volatile unsigned int i, j;
	 j = speed;
	 j--;
	 while(j > 0)
	 { // software delay
	 i = speed;
	 i--;
	     while(i > 0)
	         { // software delay
	         i--;
	         i--;
	         }
	 j--;
	 j--;
	 }
	}
