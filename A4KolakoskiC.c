#include <stdio.h>
#include <string.h>

#define MAXRUNS 50
#define MAX_ARRAY MAXRUNS*2	//Maximum size of Kseq array should be MAXRUNS*2


/*
PrintKseq. void PrintKseq(int Kseq[],int index)
Description: Print the Kolakoski sequence.
Inputs: address of Kseq array, index = next position to be filled.
Output: none.
Side effects: none. However the elements of Kseq are printed in rows, possibly 10 elements per row.
Expectation: Kseq is not empty.
*/

void PrintKseq(int Kseq[], int index)
{
	int i;	/* loop counter variable */
	
	for(i = 1; i <= index; i++){	/* for every initialized element in Kseq array */
		printf("\t%d",Kseq[i]);		/* print the value of Kseq */
		if(i!=0 && i%10 == 0){		/* print a new line every 10 elements */
			printf("\n");			
		}
	}
}

/*
AppendKseq. int AppendKseq(int Kseq[],int startindex,int *Num1)
Description: Append the next elements in the Kolakoski sequence to the initial array.
Inputs: address of initial Kseq array, index = next position to be filled; Num1 = address of variable for the
number of entries equal to 1.
Output: int= next position to be filled.
Side effects: update number of entries equal to 1 in its variable Num.
Expectation: Kseq array has been initialized for the first 3 entries at least (i.e. index > 2)
 */

int AppendKseq(int Kseq[], int startindex, int *Num1)
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

int main(int argc, char *argv[])
{
	/*initialization*/
	int Kseq[MAX_ARRAY];	/* declare an array of length MAX_ARRAY, where MAX_ARRAY == MAXRUNS*2 */
	Kseq[0] = 0; Kseq[1] = 1; Kseq[2] = 2; /* intialize first three spots in array with pre-defined values */
	int ones = 1; int twos = 1; /* counter variables for the number of 1s and 2s in the sequence */
	int length = 0; int runs = MAXRUNS;	/* length of array */
	int startindex = 3;	/*index of the next spot in array to be filled*/

	
	/*main execution begins*/
	length = AppendKseq(Kseq, startindex, &ones)-1;	/*fill in array for MAXRUNS executions of Kolakoski algorithm,
													 return index of next position to be filled*/
	twos = length - ones;	/* the number of twos will be the difference of length and number of ones */
	runs = MAXRUNS;	/* pre-defined number of times to fully execute the algorithm */
	
	/* print block */
	printf("Stevie Howard  V00158441\nKolakoski Program starts");	/* print intro statement */
	printf("\n\nKolakoski sequence of length %d with %d runs.", length, runs);
	printf("\nNumber of 1's in sequence: %d\nNumber of 2's in sequence: %d\n\n", ones, twos);
	PrintKseq(Kseq, length);	/* print out array in 10-to-a-row formation */
	printf("\n\nKolakoski program ends\n");

	return 0;	/* exit program */
}
