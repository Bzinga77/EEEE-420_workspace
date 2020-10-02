#include <msp430.h> 

int SWdelay=0x0003;
int meas_base[5];
int meas_latest[5];
int sensor_status=0;
int R5=0;
int R6=0;
int i=0;
void meas_base_val(void);
void meas_latest_val(void);
void det_sensor(void);
void display(void);
void meas_setup(void);
void SWtimer(void);

int main(void)
{
	WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
	
	P1DIR |= 0xFF;
	P1OUT &= ~0xFF;
    meas_base_val();

	while(1){
	meas_latest_val();
	det_sensor();
	display();
	}
}

	void meas_base_val(void){
        R5=0x02;
        R6=0x00;
	    for(i=0;i<5;i++){
	    meas_setup();
	    TA0CTL |= (MC_2 + TACLR);
	    SWtimer();
	    TA0CCTL1 = TA0CCTL1^CCIS0;
	    meas_base[R6]= TA0CCR1;
	    TA0CTL &= ~(MC1+MC0);
	    meas_base[R6]=meas_base[R6]-3;
        P2SEL2 &= ~R5;
        R5=R5<<1;
        R6=R6+1;
	    }
	}

	void meas_latest_val(void){
	    R5=0x02;
	    R6=0x00;
	    for(i=0;i<5;i++){
	    meas_setup();
	    TA0CTL |= (MC_2 + TACLR);
	    SWtimer();
        TA0CCTL1 = TA0CCTL1^CCIS0;
        meas_latest[R6]=TA0CCR1;
        TA0CTL &= ~(MC1+MC0);
        P2SEL2 &= ~R5;
        R5=R5<<1;
        R6=R6+1;
	    }
	}

	void det_sensor(void){
	    sensor_status=0;
        R5=0x02;
        R6=0x00;
	    for(i=0;i<5;i++){
	        if(meas_latest[R6]>meas_base[R6]){
	            R5=R5<<1;
	            R6=R6+1;
	        }
	        else
	        {
	        sensor_status |= R5;
	        }
	    }
	}

	void display(void){
	    if(sensor_status==0x0002){
	        P1OUT=0x10;
	    }
	    else if(sensor_status==0x0004){
	        P1OUT=0x80;
	    }
	    else if(sensor_status==0x0008){
	        P1OUT=0x78;
	    }
	    else if(sensor_status==0x010){
	        P1OUT=0xE8;
	    }
	    else if(sensor_status==0x20){
	        P1OUT=0x1;
	    }
	    else{
	    P1OUT=0;
	    return;
	    }
	}

	void meas_setup(void){
	    P2DIR &= ~R5;
	    P2SEL &= ~R5;
	    P2SEL2 |= R5;
	    TA0CTL=TASSEL_3;
	    TA0CCTL1=(CM_3 + CCIS_2 + CAP);
	}

	void SWtimer(void){
	    unsigned int j;
	     j = SWdelay;
	     j--;
	         while(j>0){
	             j--;
	             j--;
	}
}
