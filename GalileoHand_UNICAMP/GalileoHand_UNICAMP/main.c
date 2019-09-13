/* Universidad Galileo
 * Turing Research Lab
 * Julio E. Fajardo
 * Galileo Bionic Hand
 * CMSIS-DSP Application
 * Embedded Prostheses Controller
 * May-09-2017
 * main.c
 */

#define ARM_MATH_CM4

#include "MK20D7.h"                     					// Device header
#include "arm_math.h"                   					// ARM::CMSIS:DSP
#include <stdlib.h>
#include <stdio.h>
#include <jansson.h>
#include "drivers.h"
#include "finger.h"

#define DEACTIVATED 0
#define ACTIVATED   1

uint8_t n = 0;
uint8_t data_ready = 0;
char rx_string[64] = "";
//char rx_string[64] = "{\"st\":2,\"o\":\"notebook\",\"g\":11}";
char debug[128] = "";
uint8_t app_st = 0;

uint8_t myo_data = 0;
uint8_t myo_state = 0;
uint8_t myo_count = 0;
uint8_t myo_grasps[6] = {POWER,POINT,HOOK,KEY,PINCH,TRIPOD};

int16_t encoding = 0;

typedef struct electrode{
  q15_t mean;
  q15_t threshold;
  q15_t buffer[ESIZE];
  q15_t rectified[ESIZE];
  } electrodes;

electrodes E1 = {0,500};
electrodes E2 = {0,500};

uint8_t muscle_state = DEACTIVATED;

fingers thumb_rot = {WAITC,6,0,500,0,80};
fingers thumb_f =   {WAITC,5,0,200,0,100};
fingers index_f =   {WAITC,4,0,200,0,100};
fingers middle_f =  {WAITC,3,0,200,0,100};
fingers ring_f =    {WAITC,2,0,200,0,100};
fingers little_f =  {WAITC,1,0,200,0,100};

typedef struct seq{
	uint8_t action;
	uint16_t time;
} sequence;

/*															
const uint8_t actions[7][6] = { OPEN,  OPEN,  OPEN,   OPEN, OPEN,  OPEN,    // Open
	                              CLOSE, CLOSE, CLOSE, CLOSE, CLOSE, CLOSE,   // Power Grip
                                CLOSE, CLOSE, CLOSE, CLOSE, CLOSE, OPEN,    // Point
                                OPEN,  OPEN,  OPEN,  CLOSE, CLOSE, CLOSE,   // Pinch
                                CLOSE, CLOSE, CLOSE, CLOSE, OPEN,  OPEN,    // Hook
                                CLOSE, CLOSE, CLOSE, CLOSE, CLOSE, OPEN,    // Lateral
                                CLOSE, CLOSE, OPEN,   OPEN, CLOSE, CLOSE,   // Peace
	                              CLOSE, CLOSE, OPEN,  CLOSE, CLOSE, CLOSE 
                              };
*/

const uint8_t actions[18][6] = { {OPEN,  OPEN,  OPEN,  OPEN,  OPEN,  OPEN},    // Relaxed Hand
	                               {OPEN,  OPEN,  OPEN,  OPEN,  OPEN,  OPEN},    // Relaxed Hand
	                               {CLOSE, CLOSE, CLOSE, OPEN,  CLOSE, CLOSE},   // Active Index Grip (trigger)
                                 {OPEN,  OPEN,  OPEN,  OPEN,  CLOSE, CLOSE},   // Column Grip (thumb -> fingers, look for proper rotation)
                                 {CLOSE, CLOSE, CLOSE, CLOSE, OPEN,  OPEN},    // Abduction Grip (rot -> CLOSE ALL, look for proper rotation)
                                 {CLOSE, CLOSE, CLOSE, OPEN,  CLOSE, CLOSE},   // Finger Point 
                                 {CLOSE, CLOSE, CLOSE, CLOSE, OPEN,  OPEN},    // Hook Grip
                                 {CLOSE, CLOSE, CLOSE, CLOSE, CLOSE, OPEN},    // Key Grip
	                               {OPEN,  OPEN,  OPEN,  OPEN,  CLOSE, OPEN},    // Mouse Grip (trigger)
																 {OPEN,  OPEN,  OPEN,  OPEN,  OPEN,  OPEN},    // Open Palm Grip
																 {OPEN,  OPEN,  OPEN,  CLOSE, CLOSE, CLOSE},	 // Pinch Grip (pinch -> power)
																 {CLOSE, CLOSE, CLOSE, CLOSE, CLOSE, CLOSE},	 // Power Grip
																 {CLOSE, CLOSE, CLOSE, CLOSE, CLOSE, CLOSE},   // Precision Close Grip (close(pink,ring,middle) -> pinch)
																 {OPEN,  OPEN,  OPEN,  CLOSE, CLOSE, CLOSE},   // Precision Open Grip
																 {OPEN,  OPEN,  CLOSE, CLOSE, CLOSE, CLOSE},   // Tripod Grip
																 {OPEN,  OPEN,  OPEN,   OPEN,  OPEN, CLOSE},   // Thumb Rot
																 {OPEN,  OPEN,  OPEN,  CLOSE,  OPEN, CLOSE},   // Prepinch
																 {OPEN,  OPEN,  CLOSE, CLOSE, OPEN,  CLOSE}    // Pretripod
															};

															
uint8_t action_st = 0;															
															
uint8_t btn = 0;                                                            // Activate / deactivate 
uint8_t cmd = 0;                                                            // LCD commands
uint32_t count = 0;															 
uint32_t ticks = 0;                                                         // 1 ms ticks
uint8_t i = 0;

//char * line = "{\"state\":1,\"event\":\"accept\",\"grasp\":2}";
json_error_t error;
json_t *root; 															
uint8_t state = 0;                                                          // Activate / deactivate 
char * event;
uint8_t grasp = 0;
uint8_t trigger = 0;															
																						
char * tokens[] = {" ", " ", " ", " "};
char * st_tok[] = {" ", " "};
char * ob_tok[] = {" ", " "};
char * gr_tok[] = {" ", " "};
char * tr_tok[] = {" ", " "};

uint8_t pflag = 0;
uint16_t pms = 0;
void Hand_Action(uint8_t hand_action);
void wait(void);
void time_start(void);
uint8_t timeout(uint16_t millis);

int main(void){
	Switch_Config();
  LED_Config(); 
  ADC0_Config();
  PIT_Init(1000);
  UART0_Config();	//LCD
	UART1_Config();	//BT
  Output_Config();
  SysTick_Config(SystemCoreClock/1000);
  QD_Init(&encoding);
	
  arm_fill_q15(0, little_f.buffer, SIZE);
  arm_fill_q15(0, ring_f.buffer, SIZE);
  arm_fill_q15(0, middle_f.buffer, SIZE);
  arm_fill_q15(0, index_f.buffer, SIZE);
  arm_fill_q15(0, thumb_f.buffer, SIZE);
	
  wait();
		
  while(1){
		if(data_ready){
			//root = json_loads(rx_string,0,&error); 
	    //json_unpack(root, "{s:i, s:s, s:i}", "state", &state, "event", &event, "grasp", &grasp);
			//sprintf(debug,"%s\n",rx_string);
			//UART1_putString(debug);
			
			tokens[0] = strtok(rx_string,",");
		  tokens[1] = strtok(NULL,",");
			tokens[2] = strtok(NULL,",");
			st_tok[0] = strtok(tokens[0],":");
			st_tok[1] = strtok(NULL,":");
			app_st = (uint8_t)strtoul(&st_tok[1][0], NULL, 10);		
			switch(app_st){
				case 0:{
					muscle_state = DEACTIVATED;
					LED_Off();
				} break; 
				case 1:{
					LED_On();
				} break;
				case 2:{
					LED_Off();
					ob_tok[0] = strtok(tokens[1],":");
					ob_tok[1] = strtok(NULL,":");
					ob_tok[1] = strtok(ob_tok[1],"\"");	//object name
					gr_tok[0] = strtok(tokens[2],":");
					gr_tok[1] = strtok(NULL,":");
					grasp = (uint8_t)strtoul(&gr_tok[1][0], NULL, 10);
					UART0_send('#');
					UART0_send('*');
					UART0_send(grasp+'0');
					//sprintf(debug,"%s, %d\n",ob_tok[1],grasp);
			    //UART1_putString(debug);
				} break;
				case 3:{
					LED_On();
					muscle_state = ACTIVATED;
					//if(grasp==TRIPOD) thumb_rot.time_ms = 450;
					//else thumb_rot.time_ms = 400;
					action_st = 0;
				} break;
				case 4:{
					tr_tok[0] = strtok(tokens[1],":");
					tr_tok[1] = strtok(NULL,":");
					trigger = (-1)*(uint8_t)strtol(&gr_tok[1][0], NULL, 10);
				}
			}
			
			data_ready = 0;
		}
	
	  /*if(data_ready){
	    switch(myo_state){
			  case 0:{
					if(myo_data == '*'){
						LED_On();
						myo_state = 1;
					} 
			  } break;
				case 1:{
					switch(myo_data){
						case '1': muscle_state = ACTIVATED;
						break;
						case '2':{
							if(myo_count<5) myo_count++;
							else myo_count = 0;
						} break;
						case '3':{
							if(myo_count>0) myo_count--;
						  else myo_count = 5;	
						} break;
						case '4': muscle_state = DEACTIVATED;
					}		
					
					grasp = myo_grasps[myo_count];
					UART0_send('#');
					UART0_send('*');
					UART0_send(grasp+'0');
					
				} break;
		  }
			data_ready = 0;
		}*/
		
    if(muscle_state){
    	//LED_On();
			switch(grasp){ 
				case ACTIVE: {
					switch(action_st){
						case 0: {
							Hand_Action(THUMROT);
							time_start();
							if(timeout(1000)) action_st = 1;
						} break;
						case 1: {
							time_start();
							Hand_Action(ACTIVE);
							if(timeout(1000)) action_st = 2;
						} break;
						case 2: {
							if(trigger){
								Hand_Action(POWER);
								if(timeout(1000)) {
									action_st = 3;
									trigger = 0;
								}
							} 
						} break;
            case 3: {
							if(trigger){
								Hand_Action(ACTIVE);
							  if(timeout(1000)) {
									action_st = 2;
									trigger = 0;
								}
							}
						} 						
					}
					//Hand_Action(ACTIVE); 
				} break;
        case COLUMN: {
					switch(action_st){
						case 0: {
							Hand_Action(COLUMN);
							time_start();
							if(timeout(1000)) action_st = 1;
						} break;
						case 1: {
							Hand_Action(POWER);
						} 
					}
					//Hand_Action(COLUMN);  
				} break;
        case ABDUCT: {
					switch(action_st){
						case 0: {
							Hand_Action(ABDUCT);
							time_start();
							if(timeout(1000)) action_st = 1;
						} break;
						case 1: {
							Hand_Action(POWER);
						} 
					}
					//Hand_Action(ABDUCT); 
				} break;
        case POINT:  Hand_Action(POINT);   break;
        case HOOK:   Hand_Action(HOOK);    break;
        case KEY:  {  
					switch(action_st){
						case 0: {
							Hand_Action(HOOK);
							time_start();
							if(timeout(250)) action_st = 1;
						} break;
						case 1: {
							Hand_Action(KEY);
						} 
					}
					//Hand_Action(KEY);     
				} break;
				case MOUSE:	 Hand_Action(MOUSE);   break;
				case PINCH:	 {
					switch(action_st){
						case 0: {
							Hand_Action(PREPINCH);
							time_start();
							if(timeout(1000)) action_st = 1;
						} break;
						case 1: {
							Hand_Action(PINCH);
						} 
					}
					//Hand_Action(PINCH);
				} break;
 				case POWER:  {
					switch(action_st){
						case 0: {
							Hand_Action(THUMROT);
							time_start();
							if(timeout(1000)) action_st = 1;
						} break;
						case 1: {
							Hand_Action(POWER);
						} 
					}
					//Hand_Action(POWER);   
				} break;
				case PRECG:  Hand_Action(PRECG);   break;
				case PREOG:  Hand_Action(PREOG);   break;
				case TRIPOD: {
					switch(action_st){
						case 0: {
							Hand_Action(THUMROT);
							time_start();
							if(timeout(1000)) action_st = 1;
						} break;
						case 1: {
							Hand_Action(PRETRPOD);
							time_start();
							if(timeout(1000)) action_st = 2;
						} break;
						case 2: {
							Hand_Action(TRIPOD);
						} 
					}
					//Hand_Action(TRIPOD);  
				} break;
        default:     Hand_Action(REST);
      }
    } else { 
			//LED_Off();
			Hand_Action(REST);
		}
		
	}
}

void SysTick_Handler(void) {
  little_f.buffer[ticks%SIZE] = (int16_t) ADC0_Read(2);
  ring_f.buffer[ticks%SIZE]   = (int16_t) ADC0_Read(3);
  middle_f.buffer[ticks%SIZE] = (int16_t) ADC0_Read(4);
  index_f.buffer[ticks%SIZE]  = (int16_t) ADC0_Read(5);
  thumb_f.buffer[ticks%SIZE]  = (int16_t) ADC0_Read(6);
	
  Finger_Timing(&little_f);
  Finger_Timing(&ring_f);
  Finger_Timing(&middle_f);
  Finger_Timing(&index_f);
  Finger_Timing(&thumb_f);
  Finger_Timing(&thumb_rot);
	
  ticks++; 
}

void PIT0_IRQHandler(void){
  PIT->CHANNEL[0].TFLG |= PIT_TFLG_TIF_MASK;
	if(pflag) pms++;
	QD_Process(&encoding);
}

void PORTC_IRQHandler(void){
  if(PORTC->PCR[6]&PORT_PCR_ISF_MASK){
   PORTC->PCR[6] |= (PORT_PCR_ISF_MASK);
  }
  if(PORTC->PCR[7]&PORT_PCR_ISF_MASK){
   PORTC->PCR[7] |= (PORT_PCR_ISF_MASK);
  }
}
	
void UART0_RX_TX_IRQHandler(void){
  uint8_t data ;
  (void) UART0->S1;
  data = UART0->D;
  UART0->D = data;
}

void UART1_RX_TX_IRQHandler(void){
  volatile uint8_t data ;
	if(UART1->S1 & UART_S1_RDRF_MASK){
    (void)UART1->S1;
		data = UART1->D;
		/*if((data=='1')||(data=='2')||(data=='3')||(data=='4')||(data=='*')){
			myo_data = data;
			data_ready = 1;
		} */
    data = UART1->D;
    if(data != '\n'){
      rx_string[n] = UART1->D;
      n++;	
      data_ready = 0;
    } else {
      rx_string[n] = '\0';
      n = 0;
			LED_On();			
      data_ready = 1;
    }
  }
}

void Hand_Action(uint8_t hand_action){
	Finger_Action(&little_f, actions[hand_action][0],0);
  Finger_Action(&ring_f, actions[hand_action][1],0);
  Finger_Action(&middle_f, actions[hand_action][2],0);
  Finger_Action(&index_f, actions[hand_action][3],100);
  Finger_Action(&thumb_f, actions[hand_action][4],200);
  Finger_ActionTime(&thumb_rot, actions[hand_action][5],0);
}

void wait(void){
  for(volatile int i=0;i<5000;i++){	
    for(volatile int j=0;j<2000;j++);
  }
}


void time_start(void){
	pflag = 1;
}

uint8_t timeout(uint16_t millis){
	if(pms>millis){
	  pflag = 0;
	  pms = 0;
		return 1;
	} else return 0;
}
