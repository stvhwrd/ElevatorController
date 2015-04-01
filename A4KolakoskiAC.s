@ PART 4: The fourth implementation using both C and ARM
@ Finally write the last version of the Kolakoski program using a mixture of C and ARM. Use the instructions 
@ posted on the website to combine multiple object files and to make sure that all parameters are appropriate 
@ (be careful about what the compiled C code may change!). Note carefully: the goal here is that you do not 
@ write any new code. You should be able to insert your original C code for AppendKseq in a separate file 
@ called by the ARM program. We will check if any changes were made between the two versions! The trick is 
@ that the function should be called in ARM passing the parameters as expected by the C compiler.
@ Use the following template with functions and procedures as indicated.
@ Main: in ARM assembly, in a file A4KolakoskiAC.s.
@ AppendKseq: in C, in a file A4AppendKseqCsub.c.
@ PrintKseq: in ARM assembly, in the same file as main.
@ Any other function: in ARM assembly, in the same file as main.
@ Basically you are repeating the second implementation while substituting the C code for AppendKseq in an
@ external C source file, A4AppendKseqCsub.c, containing the C source code for AppendKseq, which
@ needs to be cross compiled to ARM code. Then ARMSim# will be able to link it in with the assembled
@ A4KolakoskiAC.s and the program should run as it did both in the second full ARM implementation
@ and the third one with multiple files.


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
	.extern	AppendKseq

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
@	stmfd	sp!, {r0-r7,lr} 	@ "caller-save" push
	bl		AppendKseq
@	ldmfd	sp!, {r0-r7,pc} 	@ "caller-save" pop	
	bl 		PrintBlock			@ PrintBlock()
End:
	swi	SWI_Exit
	
@ ====================================================================
@ void AppendKseq(R0: int Kseq[], R1: int startindex, R2: int *Num1)
@ ====================================================================


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