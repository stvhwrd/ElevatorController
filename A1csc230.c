/* File: A1csc230.c */
/* Stevie Howard V00158441 */
/* CSC 230 - Assignment 1 */
/*Read 2 dimensional matrices and their sizes until
	end of file. Compute the transpose. Test if a matrix
	is symmetrical, skew-symmetrical or orthogonal */

#include <stdio.h>
#define MAXSIZE 10		/*max number for rows and columns */

FILE *fpin;		/*pointer to input file*/

/**************************************************/

/*****THIS IS THE INITIAL FRAMEWORK DOING ONLY THE I/O IN MAIN ******/



/*==== Function RdRowSize: read the row size of a matrix from a file */
/*Input parameters:
FILE *fp		pointer to input file
int *Nrows		pointer to row size to be returned
Output parameter:
1 if okay, -1 if end of file found*/

int RdRowSize(FILE *fp, int *Nrows){
	int temp;

	fscanf(fp,"%d", &temp);

	*Nrows=temp;
	
	if(*Nrows<1){
		return -1;
	}
	return 1;	
}
	
	
/*==== Function RdColumnSize: reads the column size of a matrix from a file */
/*Input parameters:
FILE *fp 		pointer to input file
int *Ncolumns		pointer to column size to be returned
Output parameter:
1 if okay, -1 if end of file found*/
int RdColumnSize(FILE *fp, int *Ncolumns){
	int temp;
	
	fscanf(fp,"%d",&temp);
	
	*Ncolumns=temp;
			
	if(*Ncolumns<1){
		return -1;
	}
	return 1;	
}	

/*==== Procedure RdMatrix: read the elements of a matrix from a file */
/*Input parameters:
FILE *fp			pointer to input file
int Mat[MAXSIZE][MAXSIZE]	2D array for matrix
int R,int C			number of rows and columns
Output parameters:
None */

void RdMatrix(FILE *fp,int Mat[MAXSIZE][MAXSIZE],int R,int C) {
	int temp, i, j;
	
	for (i=0;i<R;i++) {		/*read matrix*/
		
		for (j=0;j<C;j++) {
			
			fscanf(fpin,"%d",&temp);
			
			Mat[i][j]=temp;
		}
	}
}



/*===== Procedure PrMat: print a 2-D matrix of integers row by row*/
/*Input parameters:
int Mat[MAXSIZE][MAXSIZE]	the matrix to be printed
int R, int C			number of rows and columns
Output parameter: None*/

void PrMat (int Mat[MAXSIZE][MAXSIZE],int R,int C) {
	int i, j;

	for (i=0;i<R;i++){

		fprintf(stdout,"     ");

		for (j=0;j<C;j++){

			fprintf(stdout,"%5d  ",Mat[i][j]);
		}
		fprintf(stdout,"\n");
	}
	fprintf(stdout,"\n");
}



/*===== Procedure Transpose: construct the transpose of a matrix*/
/*Input parameters:
int Mat[MAXSIZE][MAXSIZE]	the original matrix
int Transp[MAXSIZE][MAXSIZE] 	the transpose to be built
int RM,int CM			original number of rows and columns
int *RT,int *CT			transpose number of rows and columns
Output parameter: None*/

/*Given a matrix Mat and its dimensions in RM and CM,
construct its transpose in Transp with dimensions RT and CT as in:
copy rows 0,1,...,CM-1 of Mat to cols 0,1,...,RT-1 of Transp */

void Transpose (int Mat[MAXSIZE][MAXSIZE], int Transp[MAXSIZE][MAXSIZE], int RM, int CM, int *RT, int *CT) {
	int i,j;

	*RT=CM;

	*CT=RM;

	for(i=0;i<RM;i++){

		for(j=0;j<CM;j++){

			Transp[j][i] = Mat[i][j];
		}
	}
}



/*===== Function Symm: check for symmetric matrix*/
/*Input parameters:
int Mat[MAXSIZE][MAXSIZE]	the matrix
int Transp[MAXSIZE][MAXSIZE] 	its transpose
int Size			dimensions
Output parameter:
 0 for yes or -1 for no 

Given a square matrix, check if it is symmetric
by comparing if Mat = Transp*/

int Symm (int Mat[MAXSIZE][MAXSIZE], int Transp[MAXSIZE][MAXSIZE],int Size) {
	int i,j;

	for(i=0;i<Size;i++){

		for(j=0;j<Size;j++){

			if(Transp[i][j] != Mat[i][j]){

				return -1;
			}
		}
	}
	return 0;
}



/*===== Function SkewSymm: check for symmetric matrix*/
/*Input parameters:
int Mat[MAXSIZE][MAXSIZE]	the matrix
int Transp[MAXSIZE][MAXSIZE] 	its transpose
int Size			dimensions
Output parameter:
0 for yes or -1 for no */

/*Given a square matrix, check if it is skew-symmetric
by comparing if Mat = - Transp*/

int SkewSymm (int Mat[MAXSIZE][MAXSIZE], int Transp[MAXSIZE][MAXSIZE], int Size) {
	int i,j;

	for(i=0;i<Size;i++){

		for(j=0;j<Size;j++){

			if(Transp[-i][-j] != Mat[i][j]){

				return -1;
			}
		}
	}
	return 0;
}



/*===== Function MatMult: multiply 2 matrices*/
/*Input parameters:
int MatA[MAXSIZE][MAXSIZE]	matrix 1
int MatB[MAXSIZE][MAXSIZE]	matrix 2
int MatP[MAXSIZE][MAXSIZE]	resulting matrix
int RowA,int ColA		dimensions matrix 1
int RowB,int ColB		dimensions matrix 2
int *RowP, int *ColP		dimensions result
Output parameter:
0 if okay, or -1 if incompatible sizes*/

/* 	Multiply two matrices to produce a third, the product matrix.  Before multiplying
	it's necessary to check that inner sizes are the same, otherwise matrix multiplication
	is impossible in the stated order.  Order is important and it is assumed that the first
	matrix given in parameters is the A (and the second matrix given in parameters is the B) in A x B = C. */

int MatMult(int MatA[MAXSIZE][MAXSIZE],int MatB[MAXSIZE][MAXSIZE],int MatP[MAXSIZE][MAXSIZE],int RowA,int ColA,int RowB,int ColB,int *RowP,int *ColP) {
	
	int row,col,inner,sum;

	if(ColA==RowB){
		/*set the sizes of RowP and ColP*/
		*RowP = RowA;
		*ColP = ColB;

		for(row=0;row<RowB;row++){

			for(col=0;col<ColA;col++){

				sum = 0;

				for(inner=0; inner<ColB; inner++){
	
					sum += (MatA[row][inner]) * (MatB[inner][col]);
					
					MatP[row][col] = sum;
				}

			}
		}

		return 0;
	}
	else{
		return -1; 	/* sizes incompatible, can't be multiplied in that order*/
	}
}



/*===== Function CheckID: check a matrix for equality with identity matrix */
/*Input parameters:
int Prod[MAXSIZE][MAXSIZE]		product matrix
int Size						dimensions of square matrix
Output parameter:
1 for yes or 0 for no*/

/*Given a square matrix, check that each element is the same as identity matrix of same dimensions*/

int CheckID (int Mat[MAXSIZE][MAXSIZE], int Size){
	int i,j;
	int IDMat[MAXSIZE][MAXSIZE];
	
	for(i=0;i<Size;i++){		/*create an identity matrix of appropriate size.  An alternative approach 
								would be to create a static global identity matrix of dimensions MAXSIZE x MAXSIZE.*/
		for(j=0;j<Size;j++){

			if(i==j){				/*assign a 1 to every i'th row and i'th column place, a.k.a. pivots*/

				IDMat[i][j] = 1;
			}
			else{					/*assign a 0 to every other position such that row index is not equal to column index*/

				IDMat[i][j] = 0;
			}
		}
	}

 

	for(i=0;i<Size;i++){		/*traverse the matrix comparing the elements of the product matrix with 
								the elements of the identity matrix*/
		for(j=0;j<Size;j++){

			if(Mat[i][j]==IDMat[i][j]){				/*return true if each element in product matrix is the same as identity*/

				return 1;
			}
		}
	}
return 0;
}


/*===== Function Ortho: check for orthogonal matrix*/
/*Input parameters:
int Mat[MAXSIZE][MAXSIZE]	matrix
int Transp[MAXSIZE][MAXSIZE] 	its transpose
int Size			dimensions
Output parameter:
0 for yes or -1 for no*/

/*Given a square matrix, its dimensions in Size,
and its transpose in Transp, check if Mat is
orthogonal by comparing if Mat x Transp = Identity */

/*It also calls the function:
MatMult(Mat,Transp,Prod,MR,MC,TR,TC,&PR,&PC)
to multiply the two matrices before comparing the result to I*/

int Ortho (int Mat[MAXSIZE][MAXSIZE], int Transp[MAXSIZE][MAXSIZE], int Size) {
	
	int MatProd[MAXSIZE][MAXSIZE];	/*declare and initalize product matrix*/

	MatMult(Mat, Transp, MatProd, Size, Size, Size, Size, &Size, &Size); 	/*each of the square matrices as parameters are of dimension Size x Size*/
	if(CheckID(MatProd, Size)){
		return 0;
	}
	return 1;
}



/*===============================================*/
int main() {

    int MatMain[MAXSIZE][MAXSIZE];	/*the initial matrix*/
	int RrowsM, CcolsM;				/*matrix row size and column size*/
	int nir,i=1; 				/*counters*/
	int MatTransp[MAXSIZE][MAXSIZE]; 		/*the transpose*/
	int RrowsTr,CcolsTr;			/*transpose row size and column size*/
	
	fprintf(stdout, "\nMatrix testing program starts\n\n");	/*Headers*/
	fprintf(stdout, "Stevie Howard V00158441\n\n");
	fprintf(stdout, "CSC 230 Assignment 1 Part 1\n\n");

	/*open input file - file name is hardcoded*/
	fpin = fopen("INA1.txt", "r");  /* open the file for reading */
	
	if (fpin == NULL) {
		fprintf(stdout, "Cannot open input file  - Bye\n");
		
		return(0); 					/* if problem, exit program*/
	}
	
	nir=RdRowSize(fpin, &RrowsM);	/* nir is essentially a boolean, as it returns 1 if it succesfully reads row size from file */
							
	while (nir == 1) {				/* while not end of file*/
		
		RdColumnSize(fpin, &CcolsM); 	/* read column size */
		
		RdMatrix(fpin, MatMain, RrowsM, CcolsM); /*read matrix*/
	
		fprintf(stdout, "\n\n\n****** Matrix %d******",i);	/*print the matrix and the sizes*/
		fprintf(stdout, "  \nSize = %2d x %2d\n",RrowsM,CcolsM);

		PrMat(MatMain, RrowsM, CcolsM);	/*print the matrix and the sizes*/
			
		Transpose(MatMain, MatTransp, RrowsM, CcolsM, &RrowsTr, &CcolsTr);	/*compute transpose*/

		fprintf(stdout, "Matrix %d Transpose:",i);	/*print the matrix and the sizes*/
		fprintf(stdout, "  \nSize = %2d x %2d\n",RrowsM,CcolsM);

		PrMat(MatTransp, RrowsTr, CcolsTr);	/*print transpose*/

		
		if(RrowsM==CcolsM){		/* if the matrix is square and nonempty, we can check for symmetry, skew-symmetry, orthogonality */
			
			if(!(Symm(MatMain, MatTransp, RrowsM))){	/*Symm returns a 0 on success*/
				printf("This square matrix is: \n		==>Symmetric "); /*if a 0 is returned, matrix is symmetric*/
			}
			else{
				printf("This square matrix is: \n		==>NOT symmetric "); /*if a non 0 is returned, matrix is not symmetric*/
			}

			if(!(SkewSymm(MatMain, MatTransp, RrowsM))){	/*SkewSymm returns a 0 on success*/
				printf("\n		==>Skew-symmetric ");			/*if a 0 is returned, matrix is symmetric*/
			}
			else{
				printf("\n 		==>NOT skew-symmetric ");		/*if a non 0 is returned, matrix is not symmetric*/
			}
			
			if(!Ortho(MatMain, MatTransp, RrowsM)){			/*Ortho returns 0 on success*/
				printf("\n		==>Orthogonal ");			/*if a 0 is returned, matrix is orthogonal*/
			}
			else{
				printf("\n 		==>NOT orthogonal ");		/*if a non 0 is returned, matrix is not orthogonal*/
			}
		}
		else{
			printf("This matrix is not square - no testing required.\n\n");	/*the tests do not apply to non-square matrices*/
		}

		nir=RdRowSize(fpin, &RrowsM);	/*read next row size */
		i++;
	}

	fclose(fpin);  /* close the file */
	fprintf(stdout, "\n\n\nThat's all for now - thank you, goodbye!\n"); /*end of program message*/

	return (0);
}
