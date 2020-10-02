//******************************************************************************
//  Lab4_ArrayFill.c
//
//  Description; Initialize and fill a 16 element array
//
//  Assembly version by:
//  D. Phillips, 365_20053; RIT ; 25Mar06 ; Built with CCE for MSP430 V.1.00
//  Updated for CCS v4 by Dorin Patru 03/20/11
//
//  C version by: Dorin Patru for the EE365 MSP430 Kit - March 2011
//  C version updated by: Dorin Patru for the LaunchPad Kit - September 2013
//******************************************************************************

#include "msp430g2553.h"

int main(void)
{
  WDTCTL = WDTPW + WDTHOLD;     // Stop watchdog timer
//------------------------------------------------------------------------------
//char type is one byte; int type is two bytes; volatile to prevent optimization
//------------------------------------------------------------------------------

    volatile unsigned int i=0, j=0, sum=0;  // sum is the sum of the indices
    volatile unsigned char ArrayFill [4][4];

//------------------------------------------------------------------------------
//  Initialize ArrayFill to 0xff
//------------------------------------------------------------------------------
    for (i=0; i<=3; i++)
    {
        for (j=0; j<=3; j++)
        {
            ArrayFill[i][j] = 0xff;
        }
    }
//------------------------------------------------------------------------------
//  Fill ArrayFill with the indices values and calculate the sum of the indices
//------------------------------------------------------------------------------
    for (i=0; i<=3; i++)
    {
        for (j=0; j<=3; j++)
        {
            ArrayFill[i][j] = 15-((4 * i) + j) ;
            sum = sum + 1;
        }
    }
    sum = sum;
}
