/* Universidad Galileo
 * Turing Research Lab
 * Julio E. Fajardo
 * Galileo Bionic Hand
 * CMSIS-DSP Application
 * Embedded Prostheses Controller
 * May-09-2017
 * finger.h
 */
 
#ifndef FINGER_H_
#define FINGER_H_

#include <stdint.h>
#include <stdlib.h>
#include "arm_math.h"                   // ARM::CMSIS:DSP

#define 		SIZE     50
#define 		ESIZE    25

#define			OPEN      0
#define			WAITC     1
#define			CLOSE     2
#define			WAITO     3

#define 		REST      0
#define			RELAX     1
#define			ACTIVE    2
#define			COLUMN    3
#define			ABDUCT    4
#define			POINT     5
#define			HOOK      6
#define     KEY	      7
#define			MOUSE     8
#define			PALM      9
#define			PINCH     10
#define     POWER     11
#define     PRECG     12
#define     PREOG	    13
#define     TRIPOD    14
#define     THUMROT   15
#define     PREPINCH  16
#define     PRETRPOD  17

typedef struct finger{
	uint8_t state;
	uint8_t finger_m;
	uint32_t time_ms;	
	uint32_t time_difference;
	q15_t mean;
	q15_t threshold;
	q15_t buffer[SIZE];
	} fingers;

void Finger_Close(uint8_t finger_m);
void Finger_Open(uint8_t finger_m);
void Finger_Stop(uint8_t finger_m);
void Finger_Action(fingers * finger_f, uint8_t action, int16_t time_offset);
void Finger_Timing(fingers * finger_f);
void Finger_ActionTime(fingers *finger_f, uint8_t action, int16_t time_offset);
void Finger_Rotation(fingers *finger_f, uint8_t action);

#endif /* DRIVERS_H_ */
