//******************************************************************************
// dxp_Lab5_c1_CAPTOUCH1.c
//
// Re-coded completely for CCS v5.4, Launch Pad and Capacitive Booster Pack
//      by Dorin Patru October 2013
//******************************************************************************

#include <msp430g2553.h>

unsigned int speed = 0xFFFF; // NOTE: Same delay count as ASM version
                             //       Why does it operate slower?

void delay(void); // Function prototype for delay subroutine

int main(void){
    unsigned int i;

    WDTCTL = WDTPW + WDTHOLD; // Stop watchdog timer

    P1DIR &= ~0xFF; // Equivalent to BIC.B #0xFF,&P1DIR
    P1DIR |= 0xF8;  // Equivalent to BIS.B #0xF8,&P1DIR

    while(1){
        P1OUT &= ~0xF8;
        P1OUT |= 0xF8;
        for (i=7; i>3; i--)
        {
            P1OUT &= ~(1 << i); // () = 2^i
            delay();
            P1OUT |= (1 << i);
        }
        delay();
        P1OUT &= ~0xF8;
        for (i=4; i<8; i++)
        {
            P1OUT |= (1<<i);
            delay();
            P1OUT &= ~(1 << i); // () = 2^i
        }
        P1OUT |= 0xF8;
        delay();
    }
}

void delay(void){
    unsigned int j;
    j = speed;
    j--;
    while(j > 0){   // software delay
        j--;
        j--;
        }
}
