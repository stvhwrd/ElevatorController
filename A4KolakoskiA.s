@ PART 3: The second implementation using ARM
@ Implement your program using ARM, in a file called “A4KolakoskiA.s”, tested using ARMSim#, 
@ for any number of MAXRUNS from 10 to 100 simply by reassembling it with different initial values. 
@ Submit the program with a pre-encoded value of MAXRUNS=50. Important to note at this point is that
@ in the next deliverable you will substitute the ARM function AppendKseq with the C function. 
@ Thus, before you code the ARM one, make sure that the parameter passing in registers follow 
@ the C expectations of the compiler, other- wise you may find yourself rewriting code later on!
@ Read PART 4 before doing this part.


@ ARM Parameter Passing Conventions
@ The Gnu C compiler gcc can translate a function into code which conforms to the ARM procedure call standard
@ (or APCS for short), when given the appropriate command‐line options.

@ The APCS rules are as follows:
@ • The first four arguments are passed in R0, R1, R2 and R3 respectively. (If there are fewer 
@	arguments then only the first few of these registers are used.) Thus: parameter 1 always
@	goes in R0, parameter 2 always goes in R1, parameter 3 always goes in R2, parameter 4 always goes in R3.
@ • Any additional arguments are pushed onto the stack.
@ • The return value always goes in R0.
@ • The function is free to destroy the contents of R0–R3 and R12 (used as “scratch”). That is, the
@ called function can use these registers for computations and does not restore their original values
@ when the function exits.
@ • The function must preserve the contents of all other registers (excluding PC of course).

@ Thus the version of the gcc cross‐compiler from Code Sourcery implements the calling conventions and 
@ treats R0‐R3 and R12 as “caller‐save” registers, implying that it is the caller function responsibility
@ to save them in the stack before the BL instruction and restore them after return.


	@ ====================================================================
@ CSc 230  Assignment#4
@ Kolakoski sequence
@ ====================================================================

@ ====================================================================
@ Local Constants
@ ====================================================================
	.equ	MAXRUNS,		50			@ maximum number of runs of AppendKseq
	.equ	SWI_Exit,      	0x11			@ normal program exit
	.equ	SWI_PrintInt,  	0x6b			@ print an integer
	.equ	SWI_PrintChar,	0x0				@ print a character
	.equ	SWI_PrStr, 		0x69			@ print a string
	.equ	Stdout,        	1				@ output mode 

	
@ ====================================================================
@ Exported Symbols
@ ====================================================================
	.global	_start
	@.global	Print

@ ====================================================================
@ Imported Symbols
@ ====================================================================
	@.extern	Compute

@ ====================================================================
	.text
@ ====================================================================

@ ====================================================================
@ main()
@ ====================================================================
_start:
@ initialization 
	ldr		r0,=Kseq			@ r0 = &Kseq[0]
	mov		r1,#3				@ r1 = startindex
	ldr		r2,=ones			@ r2 = &ones
	mov		r9,#1
	str		r9,[r2]				@ ones == 1
@ initialize first 3 elements of Kseq
	mov		r9,#0				@ r9: temp
	str		r9,[r0]				@ Kseq[0] = 0
	mov		r9,#1				@ 
	str		r9,[r0,#4]			@ Kseq[1] = 1
	mov		r9,#2				@ 
	str		r9,[r0,#8]			@ Kseq[2] = 2
@ run algorithm to fill in the array
@	stmfd	sp!, {r0-r9,lr} 	@ "caller-save" push
	bl		AppendKseq
@	ldmfd	sp!, {r0-r9,pc} 	@ "caller-save" pop	
	bl 		PrintBlock			@ PrintBlock()
End:
	swi	SWI_Exit
	
@ ====================================================================
@ void AppendKseq(R0: int Kseq[], R1: int startindex, R2: int *Num1)
@ ====================================================================
AppendKseq:
	stmfd	sp!,{r0-r9,lr} 	@ "caller-save" push
	mov		r3,#1				@ r3 = i  <-- inner loop counter init. 1
	mov		r4,#2				@ r4 = n  <-- outer loop counter init. 2
	mov		r6,r0				@ r6 = &Kseq[0]
OuterLoop:
	mov		r3,#1				@ i = 1
	cmp		r4,#MAXRUNS			@ is n <= MAXRUNS?
	bgt		EndOuter			@ no: end outer loop, finished "AppendKseq"
	add		r9,r6,r4,LSL#2
	ldr		r7,[r9]				@ r7 = value at Kseq[n]
InnerLoop:
	cmp		r3,r7				@ is i <= Kseq[n]
	bgt		EndInner			@ no: end inner loop
	add		r8,r6,r1,LSL#2		@ r8 = &Kseq[0] + startindex*4 = &Kseq[startindex]
	mov		r0,r4				@ r0 = outer loop counter (n)
	bl		OnePlusNModTwo		@ OnePlusNModTwo(R0: n), returns r0 = (1 + n % 2)
	str		r0,[r8]				@ Kseq[startindex] = (1 + n % 2)
	cmp		r0,#1				@ is Kseq[startindex] == 1?
	bne		NotOne				@ no: skip over ones++
	ldr		r9,[r2]				@ yes: r8 = increment ones counter variable...
	add		r9,r9,#1			@ ...	
	str		r9,[r2]				@ ones++
NotOne:
	add		r1,r1,#1			@ startindex++
	add		r3,r3,#1			@ i++
	bal		InnerLoop			@ continue inner loop
EndInner:
	add		r4,r4,#1			@ n++
	bal		OuterLoop			@ continue outer loop
EndOuter:
	ldr		r7,=length			@ r7 = &length
	sub		r9,r1,#1			@ r9 = startindex - 1
	str		r9,[r7]				@ length = startindex - 1
	ldr		r8,=ones			@ r8 = &ones
	ldr		r8,[r8]				@ r8 = # of ones
	sub		r9,r9,r8			@ r9 = length - ones
	ldr		r7,=twos			@ r7 = &twos
	str		r9,[r7]				@ twos = length - ones
	ldmfd	sp!,{r0-r9,pc}	@ "caller-save" pop

@ ====================================================================
@ PrintElements() 
@ prints a tab and value for each position in array, newline every 10 elements
@ ====================================================================
PrintElements:
	stmfd	sp!,{r0-r7,lr}

	ldr		r2,=length			@ 
	ldr		r2,[r2]				@ r2 = #length
								@ r3 = &Kseq[i]
	mov		r4,#1				@ r4 = loop counter, init 1
								@ r5 = temp
	mov		r6,#0				@ r6 = element print counter, counts up to 10 and asks for newline
	ldr		r7,=Kseq			@ r7 = &Kseq
	ldr		r1, =Newline		@ 
	mov		r0, #Stdout     	@ 
	swi		SWI_PrStr			@ print a new line (1)	
	ldr		r1, =Newline		@ 
	mov		r0, #Stdout     	@ 
	swi		SWI_PrStr			@ print another new line	(2)
PrintLoop:	
	cmp 	r4,r2 				@ is i <= length?
	bgt		EndPrint			@ no: finished printing
	mov		r5,r4,LSL#2 		@ r5 = i*4
	add 	r3,r7,r5			@ r3 = &Kseq[i]
	cmp		r6,#10				@ have we printed 10 elements on current line?
	blt		SameLine			@ no: keep printing on same line
	ldr		r1, =Newline		@ 
	mov		r0, #Stdout     	@ 
	swi		SWI_PrStr			@ else print a new line
	mov		r6,#0				@ reset print counter	
SameLine:
	ldr		r1, =Tab			@ 
	mov		r0, #Stdout     	@ ASCII horizontal tab character
	swi		SWI_PrStr			@ 
	ldr		r1, [r3]			@ r1 = #Kseq[i]
	mov		r0, #Stdout     	@ stdout
	swi		SWI_PrintInt		@ print element at Kseq[i]
	add 	r4,r4,#1			@ increment loop counter
	add		r6,r6,#1			@ increment element print counter
	bal 	PrintLoop			@ keep looping
EndPrint:	
	ldmfd	sp!,{r0-r7,pc}

@ ====================================================================
@ void PrintBlock()    prints the entire output to stdout
@ ====================================================================
PrintBlock:
	stmfd	sp!, {r0,r1,lr} 
	ldr	r1,=Line1			@ r1 = "\nStevie Howard	V00158441\nKolakoski program starts"
	mov	r0,#Stdout			
	swi	SWI_PrStr
	ldr	r1,=Line2a			@ r1 = "\n\nKolakoski sequence of length "
	mov	r0,#Stdout			
	swi	SWI_PrStr
	ldr r1,=length
	ldr r1,[r1]				@ r1 = number of length
	mov	r0,#Stdout
	swi	SWI_PrintInt
	ldr	r1,=Line2b			@ r1 = " with "
	mov	r0,#Stdout			
	swi	SWI_PrStr
	mov	r1,#MAXRUNS			@ r1 = number of runs
	mov	r0,#Stdout
	swi	SWI_PrintInt
	ldr	r1,=Line2c			@ r1 = " runs.\n\n"
	mov	r0,#Stdout			
	swi	SWI_PrStr
	ldr	r1,=Line3			@ r1 = "\n\nNumber of 1's in sequence: "
	mov	r0,#Stdout			
	swi	SWI_PrStr
	ldr r1,=ones
	ldr r1,[r1]				@ r1 = number of ones
	mov	r0,#Stdout
	swi	SWI_PrintInt
	ldr r1,=Line4			@ r1 = "\nNumber of 2's in sequence: "
	mov	r0,#Stdout			
	swi	SWI_PrStr
	ldr r1,=twos
	ldr r1,[r1]				@ r1 = number of twos
	mov	r0,#Stdout
	swi	SWI_PrintInt	
	bl PrintElements		@ print the array of elements, PrintElements()		
	ldr	r1,=Outro			@ r1 = "\n\nKolakoski program ends\n"
	mov	r0,#Stdout			
	swi	SWI_PrStr
	ldmfd	sp!, {r0,r1,pc}

@ ====================================================================
@ int OnePlusNModTwo(R0:dividend)      calculate 1+n%2 and return result 
@ ====================================================================
OnePlusNModTwo:
	stmfd		sp!, {r1-r4,lr}
	mov 		r1,r0 			@r1 = value of n
	mov 		r2,#2 			@r2 = 2 (divisor)
loop:
	subs 		r1,r1,r2 		@compute m - n
	bpl 		loop
setresult:
	add 		r1,r1,r2 		@r1 = remainder
	add			r0,r1,#1		@r0 = 1 + n % 2
EndNModTwo:
	ldmfd		sp!, {r1-r4,pc}	

@ ====================================================================
	.data
	.align
@ ====================================================================
	ones:	.skip	4			@ count of how many 1s in sequence
	twos:	.skip	4			@ count of how many 2s in sequence
	length:	.skip	4			@ length of produced array
	Kseq:	.skip	MAXRUNS*8	@ reserve space for a maximum array size of 2*MAXRUNS
	Newline:	.asciz	"\n"
	Tab:		.asciz	"\t" 
	Line1:		.asciz	"Stevie Howard	V00158441\nKolakoski program starts"
	Line2a:		.asciz	"\n\nKolakoski sequence of length "
	Line2b:		.asciz	" with "
	Line2c:		.asciz	" runs."
	Line3:		.asciz	"\nNumber of 1's in sequence: "
	Line4:		.asciz	"\nNumber of 2's in sequence: "
	Outro:		.asciz	"\n\nKolakoski program ends\n"

@ ====================================================================
	.end