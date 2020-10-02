#include <msp430.h> 

int meas_base;
int meas_latest;
int SWDelay=0x00FF;


/**
 * main.c
 */
void SWtimer(void);

int main(void)
{
WDTCTL = WDTPW + WDTHOLD;	// stop watchdog timer

P1DIR |= 0xFF;
P1OUT &= ~0xFF;

P2DIR &= ~BIT5;
P2SEL &= ~BIT5;
P2SEL2 |= BIT5;

TA0CTL = TASSEL_3;
TA0CCTL1 = CM_3 + CCIS_2 + CAP;
TA0CTL |= MC_2 + TACLR;
SWtimer();

TA0CCTL1=TA0CCTL1^CCIS0;

meas_base=TA0CCR1;
TA0CTL &= ~(MC1+MC0);
meas_base = meas_base - 5;

    while(1)
        {
        TA0CTL |= TACLR;
        TA0CTL |= MC_2;
        SWtimer();
        TA0CCTL1=TA0CCTL1^CCIS0;
        meas_latest = TA0CCR1;
        TA0CTL &= ~(MC1+MC0);
        if(meas_latest < meas_base)
        {
            if(meas_latest < 0x300)
            {
                P1OUT = P1OUT^1;
            }
        }
}
}
void SWtimer(void){
    unsigned int j;
    j = SWDelay;
    j--;
        while(j>0){
            j--;
            j--;
            }
}

