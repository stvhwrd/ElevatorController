/*
PART 4: The fourth implementation using both C and ARM
Finally write the last version of the Kolakoski program using a mixture of C and ARM. Use the instructions 
posted on the website to combine multiple object files and to make sure that all parameters are appropriate 
(be careful about what the compiled C code may change!). Note carefully: the goal here is that you do not 
write any new code. You should be able to insert your original C code for AppendKseq in a separate file 
called by the ARM program. We will check if any changes were made between the two versions! The trick is 
that the function should be called in ARM passing the parameters as expected by the C compiler.
Use the following template with functions and procedures as indicated.

Main: in ARM assembly, in a file A4KolakoskiAC.s.
AppendKseq: in C, in a file A4AppendKseqCsub.c.
PrintKseq: in ARM assembly, in the same file as main.
Any other function: in ARM assembly, in the same file as main.

Basically you are repeating the second implementation while substituting the C code for AppendKseq in an
external C source file, A4AppendKseqCsub.c, containing the C source code for AppendKseq, which
needs to be cross compiled to ARM code. Then ARMSim# will be able to link it in with the assembled
A4KolakoskiAC.s and the program should run as it did both in the second full ARM implementation
and the third one with multiple files.
*/

extern int AppendKseq(int Kseq[], int startindex, int *Num1)
{


	int n = 2;
	int i = 1;

	for(n=2;n<=MAXRUNS;n++){
		for(i = 1; i <= Kseq[n]; i++)		/* for i less than the value of Kseq[n] */
		{
			Kseq[startindex] = 1 + n % 2;	/* assign the value of (1 + n % 2) to the next spot in array */
			if(Kseq[startindex] == 1)	/* if the value inserted is a one, */
			{
				(*Num1)++;	/* increment 1's counter */
			}
			startindex++;	/* increment counter to next available spot in array */
		}
	}
	return startindex;	/* return the index of next position in array to be filled in */
}