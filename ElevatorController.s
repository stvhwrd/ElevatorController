@ CSC230 --  Elevator simulation program

@ Template Author:  Dr. Micaela Serra 
@ Modified by: Stevie Howard 

@===== STAGE 0
@  	Sets initial outputs and screen
@	Enters IDLE state and updates simulated time every second

@	Polls for left black button to exit simulation
        .equ    SWI_EXIT, 		0x11		@terminate program

@ swi codes for using the Embest board
        .equ    SWI_SETSEG8, 		0x200	@display on 8 Segment
        .equ    SWI_SETLED, 		0x201	@LEDs on/off
        .equ    SWI_CheckBlack, 	0x202	@check press Black button
        .equ    SWI_CheckBlue, 		0x203	@check press Blue button
        .equ    SWI_DRAW_STRING, 	0x204	@display a string on LCD
        .equ    SWI_DRAW_INT, 		0x205	@display an int on LCD  
        .equ    SWI_CLEAR_DISPLAY, 	0x206	@clear LCD
        .equ    SWI_DRAW_CHAR, 		0x207	@display a char on LCD
        .equ    SWI_CLEAR_LINE, 	0x208	@clear a line on LCD
        .equ 	SEG_A,		0x80		@ patterns for 8 segment display
		.equ 	SEG_B,		0x40
		.equ 	SEG_C,		0x20
		.equ 	SEG_D,		0x08
		.equ 	SEG_E,		0x04
		.equ 	SEG_F,		0x02
		.equ 	SEG_G,		0x01
		.equ 	SEG_P,		0x10                
        .equ    LEFT_LED, 	0x02	@patterns for LED lights
        .equ    RIGHT_LED, 	0x01
        .equ    BOTH_LED, 	0x03
        .equ    NO_LED, 	0x00

@ bit patterns for black buttons
        .equ    LEFT_BLACK_BUTTON, 	0x02	
        .equ    RIGHT_BLACK_BUTTON, 0x01

@ bit patterns for blue keys
        .equ    C1, 		1<<0	@ =1
        .equ    C2, 		1<<1	@ =2
        .equ    C3, 		1<<2	@ =4
        .equ    C4, 		1<<3	@ =8
        .equ    F1UP, 		1<<4	@ =16
        .equ    F2UP, 		1<<5	@ =32
        .equ    F3UP, 		1<<6	@ =64
        .equ    F2DW, 		1<<9	@ = 512
        .equ    F3DW, 		1<<10	@ = 1024
        .equ    F4DW, 		1<<11	@ = 2056

@ timing related
		.equ    SWI_GetTicks, 		0x6d	@get current time 
		.equ    EmbestTimerMask, 	0x7fff	@ 15 bit mask for Embest timer
											@(2^15) -1 = 32,767        										
        .equ	OneSecond,			1000	@ Time intervals
        .equ	HalfSecond,			500
        .equ	WaitFloors,			4		@ seconds moving between floors
        .equ	WaitDoors,			4		@ seconds opening doors	

@ Values used for initialization
		.equ	NumTextLines,		5
		.equ	EndSimulation,		-2
		.equ	EmergencyStop,		-1
		.equ	RequestsDone,		0
		.equ	TopFloor,			4
		.equ	BottomFloor,		1


       .text           
       .global _start


@======================================================================================================@
@======================================================================================================@
@======================================================================================================@
@===== The entry point of the program =================================@


_start:						@go to initial idle state at floor 1
	ldr		r3,=FloorNum	@draw initial screen
	bl		Initdraw		@Initdraw(R3:&floor)
	ldr		r4,=SimulTime
	mov		r0,#0			@no requests

MainControl:				@ go to Idling until some event
	ldr		r7,[r3]			@r7 = current floor			
	bl		Idling			@R0<--Idling(R3:&floor;R4:&simulation time)	
							@ when back here, some event happened: check which one
							@ It cannot be emergency, that is taken care of directly

	cmp		r0,#EndSimulation		@was it end of program?
	beq		NormalExit

SwitchOnBlue:					@ check which blue button
	ldr		r7,[r3]				@ r7 = current floor	
	cmp		r0,#C1				@ check if button pushed was C1
	beq		CF1UP
	cmp		r0,#C2				@ check if button pushed was C2
	beq		CF2UPDW
	cmp		r0,#C3				@ check if button pushed was C3
	beq		CF3UPDW
	cmp		r0,#C4				@ check if button pushed was C4
	beq		CF4DW
	cmp		r0,#F1UP			@ check if button pushed was F1UP
	beq		CF1UP
	cmp		r0,#F2UP			@ check if button pushed was F2UP
	beq		CF2UPDW
	cmp		r0,#F3UP			@ check if button pushed was F3UP
	beq		CF3UPDW
	cmp		r0,#F2DW			@ check if button pushed was F2DW
	beq		CF2UPDW
	cmp		r0,#F3DW			@ check if button pushed was F3DW
	beq		CF3UPDW
	cmp		r0,#F4DW			@ check if button pushed was F4DW
	beq		CF4DW		
	bal		MainControl			@ if any other button, ignore

CF1UP:
	cmp		r7,#1				@ is elevator already on floor 1?
	beq		EndSwitchOnBlue		@ yes - then no action required
	bgt		MoveDown			@ no - then car needs to move down: MoveDown

CF2UPDW:
	cmp		r7,#2				@ is elevator already on floor 2?
	beq		EndSwitchOnBlue		@ yes - then no action required
	bgt		MoveDown			@ current floor < calling floor, so car needs to move down
	blt		MoveUp				@ current floor > calling floor, so car needs to move up

CF3UPDW:
	cmp		r7,#3				@ is elevator already on floor 3?
	beq		EndSwitchOnBlue		@ yes - then no action required
	bgt		MoveDown			@ current floor < calling floor, so car needs to move down
	blt		MoveUp				@ current floor > calling floor, so car needs to move up

CF4DW:
	cmp		r7,#4				@ is elevator already on floor 4?
	beq		EndSwitchOnBlue		@ yes - then no action required
	blt		MoveUp				@ current floor > calling floor, so car needs to move up

EndSwitchOnBlue:
	bal		MainControl			@ return to an idle

MoveUp:							@ MoveUp(r7=current floor)
	bl		MovingUp			@ MovingUp(R3= &floor; R4= &simulation time)
	cmp		r0,#EndSimulation	@ was stop button pushed?
	beq		NormalExit			@ yes - end simulation normally
	bl		CheckSignalsLower	@ CheckSignalsLower(r3: &floor)
	cmp		r0,#1				@ check the result of CheckSignalsLower
	beq		MoveDown			@ If the result is a 1 the car must go down, MoveDown(r7=current floor)
	bal		MainControl			@ otherwise return to idling

MoveDown:						@ MoveDown(r7=current floor)
	bl		MovingDown			@ MovingDown(R3= &floor; R4= &simulation time)
	cmp		r0,#EndSimulation	@ check for stop button pushed
	beq		NormalExit			@ end simulation normally
	bl		CheckSignalsHigher	@ CheckSignalsHigher(r3: &floor)
	cmp		r0,#1				@ check the result of CheckSignalsHigher
	beq		MoveUp				@ If the result is a 1 the car must go up, MoveUp(r7=current floor)
	bal		MainControl			@ otherwise return to idling

NormalExit:
	bl		ExitClear			@ clear all, come back and exit	
	bal		EndElevator

EndElevator:
	swi		SWI_EXIT			@ program main exit


	
@======================================================================@
@======================================================================@	
@ === Idling (R3:&floor;R4:&simulation time)-->R0 =====================@
@   Inputs:	R3 = & floor; R4 = & simulation time	
@   Output:  R0 = #EndSimulation, 
@				 = #EmergencyStop
@				 = number >0 for blue button pattern
@   Description:
@ 		Poll buttons continuosly
@		Every 1 second, update simulation time on screen

Idling:
	stmfd	sp!,{r1-r10,lr}
	mov		r5,#0					@ Display Idle State on all outputs
	BL		UpdateDirectionScreen	@ UpdateDirectionScreen(R5:direction)
	mov		r5,#1					@ point (stopped)
	BL		UpdateFloor				@ UpdateFloor(R3:&floor;R5:stopped)
	mov		r0, #NO_LED				@ LEDs off
	swi		SWI_SETLED				
	ldr     r7, =EmbestTimerMask	@ mask for 15 bit timer
	ldr		r10,=OneSecond			@ interval to update time

PollMainEv:							
	swi     SWI_GetTicks			@ get time T0
	and		r0,r0,r7				@ T0 in 15 bits
	ldr     r1, =Time0
	str     r0, [r1]				@ save T1 in Time0

RepeatTillTimeEv:
	swi     SWI_CheckBlack
	cmp     r0, #LEFT_BLACK_BUTTON	@ end of simulation
	beq     ShutEv
	cmp     r0, #RIGHT_BLACK_BUTTON	@ emergency manual shutdown
	beq     EmButtonEv
	swi		SWI_CheckBlue			@ car or floor button
	cmp		r0,#0				
	bne		BlueButtonEv			@ pressed blue buttons
									@ else here no events detected, keep checking time passing
	swi     SWI_GetTicks			@ get time T1
	and		r0,r0,r7				@ T1 in 15 bits
	mov		r2,r0					@ r2 is T1
	ldr     r3, =Time0
	ldr     r1, [r3]				@ r1 is T0
	cmp		r2,r1					@ is T1>T0?
	bge		SimpleTimeEv
	sub		r9,r7,r1				@ elapsed TIME= 32,676 - T0
	add		r9,r9,r2				@    + T1
	bal		CheckIntervalEv

SimpleTimeEv:
	sub		r9,r2,r1				@ elapsed TIME = T1-T0

CheckIntervalEv:
	cmp		r9,r10					@ is TIME < update period?
	blt		RepeatTillTimeEv
									@ enough time passed without events, need to update outputs
	str     r0, [r3]        		@ update Time0	
	BL		UpdateTime				@ UpdateTime(R4: & simul time)
	bal		PollMainEv				@ then keep polling till event

BlueButtonEv:						@ store event type in global array 
	BL		SetButtonsArray			@ SetButtonsArray(r0:blue button)
	bal		DoneIdling				 

EmButtonEv:
	mov		r0,#EmergencyStop		@ get out
	bal		EmergencyState			

ShutEv:
	mov		r0,#EndSimulation		@ ending simulation

DoneIdling:
	LDMFD	sp!,{r1-r10,pc}


		
@======================================================================@
@======================================================================@		
@ === Void SetButtonsArray(r0:blue button)=============================@
@   Inputs:	r0=blue button request	
@   Results:  none
@   Description:
@ 		Set the appropriate entry in the global array of requests
@		if it is a valid button
@

SetButtonsArray:
	STMFD	sp!,{r0-r6,lr}
	ldr		r3,=ButtonsArray	@ address of global array
	mov		r2,#1				@ flag
	ldr		r4,=0x0000FFFF		@ mask to clear upper register
	and		r0,r0,r4			@ clear upper 16 bits
	mov		r5,#1				@ find position of blue button
	mov		r6,#1				@ to translate to index in array

LP1:
	cmp		r5,r0				@ is this position?
	beq		Index				@ position found
	mov		r5,r5,lsl #1		@ else try next position
	add		r6,r6,#1
	bal		LP1

Index:	
	sub		r0,r6,#1			@ index=button-1
	cmp		r0,#12				@ button 12,13,14,15 9 (i.e. >12) invalid
	bge		EndSetButtonsArray
	cmp		r0,#7				@ button 7,8 invalid
	beq		EndSetButtonsArray
	cmp		r0,#8	
	beq		EndSetButtonsArray
	str		r2,[r3,r0,LSL #2]	@ array[index*4]	

EndSetButtonsArray:
	swi	SWI_CheckBlue			@ clear for buttons bounce?
	LDMFD	sp!,{r0-r6,pc}



@======================================================================@
@======================================================================@
@ === Void ClearButtonsArray(r3: &floor)===============================@
@   Inputs:	r3 = & floor	
@   Results:  none
@   Description:
@ 		Clear the entries in the global array for a given floor
@

ClearButtonsArray:
	STMFD	sp!,{r1-r4,lr}
	ldr		r1,=ButtonsArray	@ address of global array
	mov		r2,#0				@ flag
	ldr		r3,[r3]				@ floor
	sub		r3,r3,#1			@ index=floor-1
	mov		r4,#3				@ loop counter for 3 arrays

RB:	
	str		r2,[r1,r3,LSL #2]	@ array[index*4]
	add		r3,r3,#4			@ next array
	subs	r4,r4,#1			@ decrement loop counter, have we looped 3 times?
	bne		RB					@ no - keep looping
	LDMFD	sp!,{r1-r4,pc}

	

@======================================================================@
@======================================================================@
@ === WaitAndPoll (R4: & simul time;R5:waiting time)===================@
@   Inputs:	R4 = & simulation time
@			R5 = time in seconds to wait while polling	
@   Results:  R0 = #EndSimulation, 
@				 = #EmergencyStop
@				 = 0 otherwise
@	Side effects: if events captured, global arrays updated
@   Description:
@ 		Poll buttons while waiting for a length of time   
@		in seconds, and every 1 second update simulation
@		time on screen. If polling captures event, arrays
@		for signals are updated
@ 	Used when elevator is moving between floors 
@	or when doors are opening 
@

WaitAndPoll:
	stmfd	sp!,{r1-r10,lr}
	ldr     r7, =EmbestTimerMask		@mask for 15 bit timer
	ldr		r10,=OneSecond				@interval to update time
	mov 	r6,#0						@r6 is loop counter to count full seconds

WaitPollMainEv:
	swi     SWI_GetTicks				@get time T0
	and		r0,r0,r7					@T0 in 15 bits
	ldr     r1, =Time0					@R1 = T0
	str     r0, [r1]					@save T0 in Time0

WaitRepeatTillTimeEv:
	swi     SWI_CheckBlack				
	cmp     r0, #LEFT_BLACK_BUTTON		@ end of simulation
	beq     WaitShutEv
	cmp     r0, #RIGHT_BLACK_BUTTON		@ emergency manual shutdown
	beq     WaitEmButtonEv
	swi		SWI_CheckBlue				@ car or floor button
	cmp		r0,#0				
	bne		WaitBlueButtonEv			@ pressed blue buttons
										@ else no events detected, keep checking time passing
	swi     SWI_GetTicks				@get time T1
	and		r8,r0,r7					@T1 in 15 bits
	mov		r2,r8						@r2 is T1
	ldr     r3, =Time0
	ldr     r1,[r3]						@ r1 is T0
	cmp		r2,r1						@ is T1>T0?
	bge		WaitSimpletimeEv
	sub		r9,r7,r1					@ elapsed TIME= 32,676 - T0
	add		r9,r9,r2					@    + T1
	bal		WaitCheckIntervalEv

WaitSimpletimeEv:
	sub		r9,r2,r1					@ elapsed TIME = T1-T0

WaitCheckIntervalEv:
	cmp		r9,r10						@is TIME < update period?
	blt		WaitRepeatTillTimeEv
										@ enough time passed without events, need to update outputs
	str     r0, [r3]        			@ update Time0	
	BL		UpdateTime					@ UpdateTime(R4: & simul time)
	add		r6,r6,#1					@ increment loop counter
	cmp		r6,r5						@ is number of loops < 5?
	blt		WaitPollMainEv				@ then keep polling till event
	bal		EndWaitAndPoll

WaitBlueButtonEv:						@ store event type in global array 
	BL	SetButtonsArray					@ SetButtonsArray(r0:blue button)
	bal	WaitRepeatTillTimeEv

WaitEmButtonEv:
	mov	r0,#EmergencyStop				@ get out
	bal	EmergencyState

WaitShutEv:
	mov	r0,#EndSimulation				@ ending simulation

EndWaitAndPoll:
	LDMFD	sp!,{r1-r10,pc}

		

@======================================================================@
@======================================================================@
@ ===CheckSignalsHigher(r3: &floor)====================================@
@   Input:	r3 = & floor	
@   Results:  R0 = 0 (no to higher signal); 1 (yes to higher signal)
@   Description:
@ 		Check global arrays for any signals at floor>given floor

CheckSignalsHigher:
	STMFD	sp!,{r1-r10,lr}
	ldr		r1,=ButtonsArray		@ address of global array
	ldr		r0,=RequestsDone		@ no flag found (by default)
	mov		r6,#0					@ outer loop counter for each floor being checked
	ldr		r7,=TopFloor			@ R7 = number of floors
	ldr		r3,[r3]					@ floor number, used as index to check floor above current floor.
	sub		r5,r7,r3				@ R5 = loop counter for # floors to check (1st one checked automatically)

HighWrap:	
	mov		r4,#3					@ loop counter for 3 arrays

HighLoop:	
	ldr		r2,[r1,r3,LSL #2]		@ array[index*4]
	cmp		r2,#1					@ is the value at this position in array == 1?
	beq		HigherSignalExists		@ yes - then it is a signal, and it is higher.
	add		r3,r3,#4				@ else check next array
	subs	r4,r4,#1				@ have we looped 3 times? once for each array?
	bne		HighLoop				@ if not, loop again
	sub		r3,r3,#11				@ R3 = floor above the last floor checked
	add		r6,r6,#1				@ add one to outer loop counter
	cmp		r6,r5					@ has the outer loop run enough times to check all possible floors?
	blt		HighWrap				@ no - loop again checking the next higher floor.

EndCheckSignalsHigher:				@ return to calling function
	LDMFD	sp!,{r1-r10,pc}
	
HigherSignalExists:			
	mov		r0,#1					@ move the flag into R0 to indicate that a higher signal exists
	bal 	EndCheckSignalsHigher
	


@======================================================================@
@======================================================================@
@ ===CheckSignalsLower(r3: &floor)=====================================@
@   Inputs:	r3 = & floor	
@   Output:  R0 = 0 (no to lower signal); 1 (yes to lower signal)
@   Description:
@ 		Check global arrays for any signals at floor<given floor

CheckSignalsLower:
	STMFD	sp!,{r1-r10,lr}
	ldr		r1,=ButtonsArray		@ address of global array
	ldr		r0,=RequestsDone		@ no flag found (by default)
	mov		r6,#0					@ outer loop counter for each floor to be checked
	ldr		r3,[r3]					@ R3=current floor number
	sub		r5,r3,#1				@ R5 = loop counter for how many additional floors to check (will check first one automatically)
	sub		r3,r3,#2				@ index=floor-2 to access the floor below current, in array

LowWrap:	
	mov		r4,#3					@ loop counter for 3 arrays

LowLoop:	
	ldr		r2,[r1,r3,LSL #2]		@ array[index*4]
	cmp		r2,#1					@ is the value at this position in array == 1?
	beq		LowerSignalExists		@ yes - then there are lower floors signalled
	add		r3,r3,#4				@ else check next array
	subs	r4,r4,#1				@ have we looped 3 times - once for each array?
	bne		LowLoop					@ no - loop again
	sub		r3,r3,#13				@ R3 = floor below the last floor checked
	add		r6,r6,#1				@ add one to outer loop counter
	cmp		r6,r5					@ has the outer loop run enough times to check all possible floors?
	blt		LowWrap					@ no - loop again checking the next lower floor.

EndCheckSignalsLower:				@ return to calling function
	LDMFD	sp!,{r1-r10,pc}			
	
LowerSignalExists:
	mov		r0,#1					@ move the flag into R0 to indicate that a higher signal exists
	bal 	EndCheckSignalsLower



@======================================================================@
@======================================================================@
@ ===CheckFloorSignal(r3: &floor)======================================@
@   Inputs:	r3 = & floor	
@   Output:  none
@   Description:
@ 		Check global arrays for any signals at current floor

CheckFloorSignal:
	STMFD	sp!,{r1-r10,lr}
	ldr		r0,=RequestsDone		@ no flag found yet (by default)
	ldr		r1,=ButtonsArray		@ address of global array
	ldr		r3,[r3]					@ R3 = floor number
	sub		r3,r3,#1				@ index=floor-1
	mov		r4,#3					@ loop counter for 3 arrays

FloorSignal:	
	ldr		r2,[r1,r3,LSL #2]		@ array[index*4]
	cmp		r2,#1					@ check if the content at that index is a 1
	beq		FloorSignalExists		@ if there is a 1 at this index in any array, the signal is there
	add		r3,r3,#4				@ move on to next array
	subs	r4,r4,#1				@ decrement loop counter
	bne		FloorSignal				@ loop 3 times
	beq		EndCheckFloorSignal 

FloorSignalExists:
	mov		r0,#1					@ R0=1 to indicate a flag was found

EndCheckFloorSignal:
	LDMFD	sp!,{r1-r10,pc}



@======================================================================@
@======================================================================@	
@ ===MovingUp (R3= &floor; R4= &simulation time)=======================@
@   Inputs:	R3 = &floor; R4 = &simulation time
@   Output:  R0 = #EndSimulation, 
@				 = #EmergencyStop
@				 = 0 otherwise
@	Side effects: if events captured, global arrays updated
@   Description:
@ 		Move up each floor until all UP requests done

MovingUp:
	STMFD	sp!,{r1-r10,lr}
	ldr		r7,[r3]					@ R7 = current floor
	mov		r5,#1					@ R5 = 1 to indicate up direction
	BL		UpdateDirectionScreen	@ UpdateDirectionScreen(R5:direction)
	mov		r5,#0					@ no 8-segment dot (moving)
	BL		UpdateFloor				@ UpdateFloor(R3:&floor;R5:moving)
	mov		r0, #LEFT_LED			@ Left LED on
	swi		SWI_SETLED				@ LEDs updated

TopMovingUp:	
	ldr		r5,=WaitFloors			@ set delay for floor travel time
	bl		WaitAndPoll				@ check for any buttons pushed while traveling between floors
	cmp		r0,#EndSimulation		@ check for stop button pushed
	beq		EndMovingUp				@ return to Main for exit instructions
	add		r7,r7,#1				@ floor indicator incremented by one
	str		r7,[r3]					@ floor variable incremented by one
	mov		r5,#0					@ no 8-segment dot
	bl		UpdateFloor				@ UpdateFloor(R3:&floor;R5:moving)
	bl		CheckFloorSignal		@ look for a call at current floor
	cmp		r0,#1					@ check for a "yes" returned by checkfloorsignal
	bne		CheckTop				@ if no signal at current floor, go to CheckTop
	bl		OpenDoors				@ OpenDoors (R3: &floor;R4: &simul time)
	cmp		r0,#EndSimulation		@ check whether exit button was pressed
	beq		EndMovingUp				@ if yes, finished moving up.
	mov		r0, #LEFT_LED			@ Left LED on
	swi		SWI_SETLED

CheckTop:
	cmp		r7,#TopFloor			@ check whether current floor is top floor
	beq		EndMovingUp				@ yes - then we cannot go any higher
	bl		CheckSignalsHigher		@ CheckSignalsHigher(r3: &floor)
	cmp		r0,#1					@ check whether there have been calls from higher floors
	bne		EndMovingUp 
	mov		r5,#1					@ R5=1 to indicate up direction
	bl		UpdateDirectionScreen	@ UpdateDirectionScreen(R5:direction)
	bal		TopMovingUp				@ continue loop to continue moving up

EndMovingUp:
	LDMFD	sp!,{r1-r10,pc}



@======================================================================@
@======================================================================@
@ === MovingDown(R3: &floor;R4: &simul time)===========================@
@   Inputs:	R3 = & floor; R4 = & simulation time	
@   Output:  R0 = #EndSimulation, 
@				 = #EmergencyStop
@				 = 0 otherwise
@	Side effects: if events captured, global arrays updated
@   Description:
@ 		Move down each floor until all DOWN requests done

MovingDown:
	STMFD	sp!,{r1-r10,lr}
	ldr		r7,[r3]					@ R7 = current floor
	mov		r5,#-1					@ R5=-1 to indicate down direction
	BL		UpdateDirectionScreen	@ UpdateDirectionScreen(R5:direction)
	mov		r5,#0					@ 8-segment should have no dot (moving)
	BL		UpdateFloor				@ UpdateFloor(R3:&floor;R5:moving)
	mov		r0, #RIGHT_LED			@ Right LED on
	swi		SWI_SETLED

TopMovingDown:	
	ldr		r5,=WaitFloors
	bl		WaitAndPoll
	cmp		r0,#EndSimulation		@ check for stop button pushed
	beq		EndMovingDown			@ return to Main for exit instructions
	sub		r7,r7,#1				@ decrement floor counter
	str		r7,[r3]					@ floor variable decremented by one
	mov		r5,#0					@ no 8-segment dot
	bl		UpdateFloor				@ UpdateFloor(R3:&floor;R5:moving)
	bl		CheckFloorSignal		@ look for a call at current floor
	cmp		r0,#1					@ check for a "yes" returned by checkfloorsignal
	bne		CheckBottom				@ if no signal at current floor, go to CheckTop
	bl		OpenDoors				@ OpenDoors (R3: &floor;R4: &simul time)
	cmp		r0,#EndSimulation		@ check whether exit button was pressed
	beq		EndMovingDown			@ if yes, finished moving up.
	mov		r0, #RIGHT_LED			@ Left LED on
	swi		SWI_SETLED

CheckBottom:
	cmp		r7,#BottomFloor			@ check whether current floor is top floor
	beq		EndMovingDown			@ yes - cannot go any lower.
	bl		CheckSignalsLower		@ CheckSignalsLower(r3: &floor)
	cmp		r0,#1					@ check whether there has been a call from lower floors
	bne		EndMovingDown			@ no - finished moving down.
	mov		r5,#-1					@ R5=1 to indicate up direction
	bl		UpdateDirectionScreen	@ UpdateDirectionScreen(R5:direction)
	bal		TopMovingDown			@ continue loop to continue moving down

EndMovingDown:						@ return to calling function
	LDMFD	sp!,{r1-r10,pc}
	


@======================================================================@
@======================================================================@
@ === OpenDoors (R3: &floor;R4: &simul time)===========================@
@   Inputs:	R3 = & floor; R4 = & simulation time	
@   Output:  R0 = #EndSimulation, 
@				 = #EmergencyStop
@				 = 0 otherwise
@	Side effects: clears arrays at floor number
@   Description:
@ 		Set the outputs for doors open,
@		stay for X seconds while polling

OpenDoors:
	STMFD	sp!,{r1-r10,lr}
	mov		r5,#2					@ Display open doors
	BL		UpdateDirectionScreen	@UpdateDirectionScreen(R5:direction)
	mov		r5,#0					@ 8-segment should have no dot
	BL		UpdateFloor				@ UpdateFloor(R3:&floor;R5:stopped)
	mov		r0, #BOTH_LED			@ bothLEDs on
	swi		SWI_SETLED
	ldr		r5,=WaitDoors			@ Set wait time for doors
	bl		WaitAndPoll				@ WaitAndPoll(R4=&simulation time, R5=delay time)
	bl		ClearButtonsArray		@ ClearButtonsArray(r3: &floor)

EndOpenDoors:
	LDMFD	sp!,{r1-r10,pc}
	


@======================================================================@
@======================================================================@	
@===== UpdateTime(R4:& simulated time)=================================@
@   Inputs:  R4 = & simulated time
@   Output: none
@   Description:
@      Displays the updated value of the current simulation time
@		on screen and updates its variable

UpdateTime:
	stmfd	sp!, {r0-r4,lr}
	ldr		r2,[r4]			@update simulated time
	add		r2,r2,#1	 	
	str		r2,[r4]
	mov		r1, #2			@ r1 = next line number to display
	mov		r0, #20			@ r0 = column number for displayed strings
	swi		SWI_DRAW_INT

EndUpdateTime:
	ldmfd	sp!, {r0-r4,pc}



@======================================================================@
@======================================================================@
@===== UpdateFloor(R3:&floor;R5:stopped)===============================@
@   Inputs:  R3 = & floor number;R5 = 1(idle) or 0(moving)
@   Output: none
@   Description:
@      Displays the value of the current floor on the LCD screen
@		and in the 8-segment

UpdateFloor:
	stmfd	sp!, {r0-r2,lr}
	ldr		r0,[r3]				@r0=floor number
	mov		r1,r5				@ point?
	BL		Display8Segment		@ Display8Segment (Number:R0; Point:R1)
	mov		r2,r0				@r2=floor number
	mov		r0,#20				@column on screen
	mov		r1,#4				@row on screen
	swi		SWI_DRAW_INT

EndUpdateFloor:	
	ldmfd	sp!, {r0-r2,pc}


	
@======================================================================@
@======================================================================@	
@===== UpdateDirectionScreen(R5:direction)=============================@
@   Inputs:  R5 = current direction of elevator movement
@   Output: none
@   Description:
@      Displays the pattern for the elevator direction on 
@		the appropriate 5 lines on the LCD screen
@		Direction: -1 = down; 0 = stopped; 1 = up ; 2 open doors

UpdateDirectionScreen:
	stmfd	sp!, {r0-r5,lr}
	mov		r4,#0			@line counter
	cmp		r5,#0			@establish direction
	blt		DirDown
	beq		DirIdle
	cmp		r5,#1
	beq		DirUp

DirOp:		ldr	r2,=lineD1op
	bal		DrawDir

DirDown:	ldr	r2,=lineD1dw
	bal		DrawDir

DirIdle:	ldr	r2,=lineD1st
	bal		DrawDir

DirUp:		ldr	r2,=lineD1up

DrawDir:
	mov		r1, #6			@ r1 = row
	mov		r0, #0			@ r0 = column

Drl:	
	swi		SWI_DRAW_STRING
	add		r1, r1, #1		@next line number
	add		r2,r2,#8		@next string
	add		r4,r4,#1		@update line counter
	cmp		r4, #NumTextLines
	blt		Drl

EndUpdateDirectionScreen:
	ldmfd	sp!, {r0-r5,pc}
	


@======================================================================@
@======================================================================@	
@ =====Initdraw(R3:& floor)============================================@
@   Inputs:  R3 = & floor
@   Output: none
@   Description:
@      	Draws the initial state of LCD screen, LEDs
@		and 8-segment

Initdraw:
	stmfd	sp!, {r0-r5,lr}
	mov		r1, #0					@ r1 = row
	mov		r0, #0					@ r0 = column 
	ldr		r2, =lineID				@ identification
	swi		SWI_DRAW_STRING
	mov		r1, #2					@ r1 = row
	mov		r0, #10					@ r0 = column 
	ldr		r2, =lineTime			@ time XXX
	swi		SWI_DRAW_STRING
	mov		r1, #4					@ r1 = row
	mov		r0, #10					@ r0 = column
	ldr		r2, =lineFloor			@ floor number XX
	swi		SWI_DRAW_STRING	
	mov		r1, #11					@ r1 = row
	mov		r0, #1					@ r0 = column
	ldr		r2, =keysline1			@ floor number XX
	swi		SWI_DRAW_STRING
	mov		r1, #12					@ r1 =row
	mov		r0, #1					@ r0 = column
	ldr		r2, =keysline2			@ floor number XX
	swi		SWI_DRAW_STRING
	mov		r1, #13					@ r1 = row
	mov		r0, #1					@ r0 = column
	ldr		r2, =keysline3			@ floor number XX
	swi		SWI_DRAW_STRING
	mov		r5,#0					@ Draw the Idle State strings
	BL		UpdateDirectionScreen	@UpdateDirectionScreen(R5:direction)
	mov		r5,#1					@ point (stopped)
	BL		UpdateFloor				@UpdateFloor(R3:&floor;R5:stopped)
	mov		r0, #NO_LED				@LEDs off
	swi		SWI_SETLED
	mov		r0,#1					@floor 1			
	mov		r1,#1					@stopped
	BL		Display8Segment			@Display8Segment(R0:number;R1:point)

EndInitdraw:
	ldmfd	sp!, {r0-r5,pc}



@======================================================================@
@======================================================================@
@=====EmergencyState()=================================================@
@   Inputs:  none
@   Output:  none
@   Description:
@     	The function sets the  configuration for
@		the output devices in case of emergency.
@	NOTE: this function does not return to Main Control;
@		execution stays here in an infinite loop after
@		updating outputs, until program is ended manually

EmergencyState:
	swi		SWI_CLEAR_DISPLAY		@ clear standard output from LCD 
	mov		r0, #0					@ column 1 for message display
	mov		r1, #7					@ line 8 for message display
	ldr		r2, =EmergencyMessage
	swi		SWI_DRAW_STRING  		@ display emergency message on line 7

EmergencyFlashing:	
	mov		r0, #8					@ 8-segment pattern ALL on (like an 8)
	mov		r1,#0					@ 8-segment dot off
	BL		Display8Segment			@ Display8Segment(R0:number;R1:point)
	mov		r0, #BOTH_LED
	swi		SWI_SETLED				@ both LEDs on
	ldr		r10,=HalfSecond			@ set delay to half a second
	bl		Wait					@ wait for half a second with all lights on
	mov		r0, #10					@ 8-segment pattern ALL off
	BL		Display8Segment			@ Display8Segment(R0:number;R1:point)
	mov		r0, #NO_LED
	swi		SWI_SETLED				@ both LEDs off
	ldr		r10,=HalfSecond		
	bl		Wait					@ wait for half a second with lights off, Wait(Delay:r10)
	bal		EmergencyFlashing		@ loop for the rest of eternity



@======================================================================@
@======================================================================@
@===== ExitClear()=====================================================@
@   Inputs:  none
@   Output: none
@   Description:
@      Clear the board and display the last message

ExitClear:	
	stmfd	sp!, {r0-r2,lr}
	mov		r0, #10				@ 8-segment pattern off
	mov		r1,#0
	BL		Display8Segment		@ Display8Segment(R0:number;R1:point)
	mov		r0, #NO_LED			
	swi		SWI_SETLED			@ clear LEDs	
	swi		SWI_CLEAR_DISPLAY 	@ clear LCD
	mov		r0, #5				
	mov		r1, #7
	ldr		r2, =Goodbye
	swi		SWI_DRAW_STRING  	@ display goodbye message on line 8

EndExitClear:
	ldmfd	sp!, {r0-r2,pc}



@======================================================================@
@======================================================================@
@ ==== void Wait(Delay:r10) ===========================================@
@   Inputs:  R10 = delay in milliseconds
@   Output: none
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer 

Wait:
	stmfd	sp!, {r0-r2,r7-r10,lr}
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks		@get time T1
	and		r1,r0,r7			@T1 in 15 bits

WaitLoop:
	swi 	SWI_GetTicks		@get time T2
	and		r2,r0,r7			@T2 in 15 bits
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	bal		CheckIntervalW

simpletimeW:
	sub		r9,r2,r1			@ elapsed TIME = T2-T1

CheckIntervalW:
	cmp		r9,r10				@is TIME < desired interval?
	blt		WaitLoop

EndWait:
	ldmfd	sp!, {r0-r2,r7-r10,pc}	



@======================================================================@
@======================================================================@
@ *** Display8Segment (Number:R0; Point:R1) ***========================@
@   Inputs:  R0=number to display; R1=point or no point
@   Output:  none
@   Description:
@ 		Displays the number 0-9 in R0 on the 8-segment
@ 		If R1 = 1, the point is also shown

Display8Segment:
	STMFD 	sp!,{r0-r2,lr}
	ldr 	r2,=Digits
	ldr 	r0,[r2,r0,lsl#2]
	tst 	r1,#0x01 @if r1=1,
	orrne 	r0,r0,#SEG_P 			@then show P
	swi 	SWI_SETSEG8

EndDisplay8Segment:
	LDMFD 	sp!,{r0-r2,pc}



@======================================================================================================@
@======================================================================================================@
@======================================================================================================@
@======================================================================================================@	


	.data
	.align
SimulTime:	.word   0
Time0:		.skip	4
FloorNum:	.word	1

ButtonsArray:
ButtonsCar:	.word	0,0,0,0		@ 4 words for 4 car buttons
FloorUp:	.word	0,0,0,0		@ floor 1,2,3 up,4 unused 
FloorDw:	.word	0,0,0,0		@ floor 2,3,4 down, 1 unused

Digits:												@ for 8-segment display
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_G 		@0
	.word SEG_B|SEG_C 								@1
	.word SEG_A|SEG_B|SEG_F|SEG_E|SEG_D 			@2
	.word SEG_A|SEG_B|SEG_F|SEG_C|SEG_D 			@3
	.word SEG_G|SEG_F|SEG_B|SEG_C 					@4
	.word SEG_A|SEG_G|SEG_F|SEG_C|SEG_D 			@5
	.word SEG_A|SEG_G|SEG_F|SEG_E|SEG_D|SEG_C 		@6
	.word SEG_A|SEG_B|SEG_C 						@7
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G @8
	.word SEG_A|SEG_B|SEG_F|SEG_G|SEG_C 			@9
	.word 0 										@Blank 

lineID:		.asciz	"Elevator -- Stevie Howard"

lineTime:  	.asciz  "Time:            seconds"

lineFloor:	.asciz	"Floor =    "

keysline1:	.asciz	"Blue Keys:     C1,  C2,  C3,  C4"
keysline2:	.asciz	"              FU1   FU2  FU3  XX"
keysline3:	.asciz	"               XX   FD2  FD3  FD4"

	.align
lineD1up:	.asciz	"   @   "
lineD2up:	.asciz	"  @|@  "
lineD3up:	.asciz	" @ | @ "
lineD4up:	.asciz	"   |   "
lineD5up:	.asciz	"   |   "
lineD1st:	.asciz	"@@@@@@@"
lineD2st:	.asciz	"@@@@@@@"
lineD3st:	.asciz	"@@@@@@@"
lineD4st:	.asciz	"@@@@@@@"
lineD5st:	.asciz	"@@@@@@@"
lineD1dw:	.asciz	"   |   "
lineD2dw:	.asciz	"   |   "
lineD3dw:	.asciz	" @ | @ "
lineD4dw:	.asciz	"  @|@  "
lineD5dw:	.asciz	"   @   "
lineD1op:	.asciz	"@@@@@@@"
lineD2op:	.asciz	"@     @"
lineD3op:	.asciz	"@     @"
lineD4op:	.asciz	"@     @"
lineD5op:	.asciz	"@@@@@@@"


Goodbye:
	.asciz	"**** Elevator program ended. ****"
EmergencyMessage:
	.asciz	"***ELEVATOR EMERGENCY - TIME TO PANIC!**"

	.end