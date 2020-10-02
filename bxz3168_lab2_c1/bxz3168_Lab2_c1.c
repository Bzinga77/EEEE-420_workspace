/*
 * bxz3168_Lab2_c1.c
 *
 *  Created on: Jan 21, 2020
 *      Author: bxz3168
 */

//******************************************************************************
//  MSP430x1xx Demo - Software Toggle P1.0
//
//  Description; Toggle P1.0 by xor'ing P1.0 inside of a software loop.
//  ACLK = n/a, MCLK = SMCLK = default DCO
//
//                MSP430x1xx
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |             P1.0|-->LED
//
//  A. Dannenberg
//  Texas Instruments, Inc
//  January 2006
//  Built with CCE for MSP430 Version: 3.0, 4.2
//  Modified and enhanced by D. Patru for the EE365 MSP430 Kit - March 2011
//  Modified and enhanced by D. Patru for the LaunchPad Kit - September 2013
//  Brandon Zeng
//  Currently built with CCS 5.4.
//******************************************************************************

#include "msp430g2553.h"

int main(void)
{
  WDTCTL = WDTPW + WDTHOLD;             // Stop watchdog timer
  P1DIR |= 0x01;                        // Set P1.0 to output direction

  for (;;)
  {
    volatile unsigned int i;            // volatile to prevent optimization

    P1OUT ^= 0x01;                      // Toggle P1.0 using exclusive-OR

    i = 10000;                          // SW Delay
    do i--;
    while (i != 0);
  }
}
