#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <cuda_runtime.h>
// #include "cutil.h"

#include "mex.h"

#define SPXL 8
#define SPXR 7
#define SPYU 8
#define SPYD 7

#define BLOCK_SIZE_Y 16   //SPYU+SPYD+1
#define BLOCK_SIZE_X 16		//SPYU+SPYD+1
#define MAX_CELL_SIZE 50

#define min(a, b) ((a) < (b) ? (a) : (b))
#define max(a, b) ((a) > (b) ? (a) : (b))

#define  MAX_LEVELS  1000

int quickSort(float *, int, int *, int *);
__global__ void NSSD(float *, float *, int , int , int *, int *, int *, int *, float *, int *, int *, float *, float *);


int quickSort(float *arr, int elements, int *arr1, int *arr2) 
{
	float  piv, piv1;
	int p1, p2;
	int beg[MAX_LEVELS], end[MAX_LEVELS], i=0, L, R ;
	beg[0]=0; end[0]=elements;

	while (i>=0) {
		L=beg[i]; R=end[i]-1;
		if (L<R) {
			piv=(arr[L]); 
			piv1=arr[L]; 
			p1=arr1[L]; 
			p2=arr2[L]; 
			if (i==MAX_LEVELS-1) 
				return 0;
			while (L<R) {
				while ((arr[R])>=piv && L<R)
					R--; 
				if (L<R) {
					arr[L]=arr[R];
					arr1[L]=arr1[R];
					arr2[L++]=arr2[R];
				}
				while ((arr[L])<=piv && L<R) 
					L++; 
				if (L<R) {
					arr[R]=arr[L]; 
					arr1[R]=arr1[L];
					arr2[R--]=arr2[L];
				}

			}
			arr[L]=piv1; 
			arr1[L]=p1; 
			arr2[L]=p2; 
			beg[i+1]=L+1; 
			end[i+1]=end[i]; 
			end[i++]=L; 
		}
		else 
			i--; 
	}
	return 1; 
}

__global__ void NSSD(float *Im1, float *Im2, int IMSIZEX, int IMSIZEY, int *xmin, int *xmax, int *ymin, int *ymax, float *C, int *movedE, int *movedS, float *Sp, float *SpVal)
{
	// Block index
	int bID = blockIdx.x;

	
	// Thread index
	int tx = threadIdx.x;
	int ty = threadIdx.y;
	int tid = ty*BLOCK_SIZE_X+tx;

	int tSizeX, tSizeY, tStartX, tStartY;
	int x, y;
	int saStartX, saStartY, saEndX, saEndY, saSizeX, saSizeY;


	tStartX = xmin[bID]-1;
	tStartY = ymin[bID]-1;
	tSizeX = xmax[bID] - tStartX;
	tSizeY = ymax[bID] - tStartY;
	

	saStartX = max(0, tStartX - SPXL);
	saStartY = max(0, tStartY - SPYU);
	saEndX = min(IMSIZEX-1, xmax[bID]-1 + SPXR);
	saEndY = min(IMSIZEY-1, ymax[bID]-1 + SPYD);
	saSizeX = saEndX - saStartX +1;
	saSizeY = saEndY - saStartY +1;

	__shared__ char SP[MAX_CELL_SIZE][MAX_CELL_SIZE];
	__shared__ float T[MAX_CELL_SIZE][MAX_CELL_SIZE];

	__shared__ float meanT;
	__shared__ float SumToffsetSqrd ;
	
	meanT = 0.;
	SumToffsetSqrd = 0.;

	__shared__ float temp[BLOCK_SIZE_X*BLOCK_SIZE_Y];
	__shared__ int tempi[BLOCK_SIZE_X*BLOCK_SIZE_Y];

	float meanF = 0.;
	float SumFoffsetSqrd = 0.;
	float numerator = 0.;

	__shared__ int noOfOnPixels;

	__shared__ int noOfPixelsToWriteInCellX;
	__shared__ int noOfPixelsToWriteInCellY;
	//__shared__ int noOfPixelsToWriteInSAX;
	//__shared__ int noOfPixelsToWriteInSAY;

	noOfPixelsToWriteInCellX = int((1.*tSizeX/BLOCK_SIZE_X)+1);
	noOfPixelsToWriteInCellY = int((1.*tSizeY/BLOCK_SIZE_X)+1);
	//noOfPixelsToWriteInSAX = int((1.*saSizeX/BLOCK_SIZE_X)+1);
	//noOfPixelsToWriteInSAY = int((1.*saSizeY/BLOCK_SIZE_X)+1);

	tempi[tid] = 0;
	for (x = noOfPixelsToWriteInCellX*tx ; x<min(noOfPixelsToWriteInCellX*(tx+1), tSizeX); x++ )
		for (y = noOfPixelsToWriteInCellY*ty ; y<min(noOfPixelsToWriteInCellY*(ty+1), tSizeY);  y++  )
		{
			T[x][y] = Im1[(tStartX +x)*IMSIZEY + tStartY + y];
			SP[x][y] = char(Sp[(tStartX +x)*IMSIZEY + tStartY + y]== SpVal[bID]);
			tempi[tid]+=int(SP[x][y]);
		}


    for(int stride = BLOCK_SIZE_X*BLOCK_SIZE_Y / 2; stride > 0; stride >>= 1)
	{
		__syncthreads();
        for(int iAccum = tid; iAccum < stride; iAccum += BLOCK_SIZE_X*BLOCK_SIZE_Y)
			tempi[iAccum] += tempi[stride + iAccum];
	}


	noOfOnPixels = tempi[0];
	__syncthreads();

	
	temp[tid] = 0.;
	for (x = noOfPixelsToWriteInCellX*tx ; x<min(noOfPixelsToWriteInCellX*(tx+1), tSizeX); x++ )
		for (y = noOfPixelsToWriteInCellY*ty ; y<min(noOfPixelsToWriteInCellY*(ty+1), tSizeY); y++ )
			if (SP[x][y])
				temp[tid] += T[x][y]/noOfOnPixels;


    for(int stride = BLOCK_SIZE_X*BLOCK_SIZE_Y / 2; stride > 0; stride >>= 1)
	{
		__syncthreads();
        for(int iAccum = tid; iAccum < stride; iAccum += BLOCK_SIZE_X*BLOCK_SIZE_Y)
			temp[iAccum] += temp[stride + iAccum];
	}

	meanT = temp[0];
	__syncthreads();



	temp[tid] =0.;
	for (x = noOfPixelsToWriteInCellX*tx ; x<min(noOfPixelsToWriteInCellX*(tx+1), tSizeX); x++ )
		for (y = noOfPixelsToWriteInCellY*ty ; y<min(noOfPixelsToWriteInCellY*(ty+1), tSizeY); y++ )
			if (SP[x][y])
				temp[tid] += pow(T[x][y] - meanT,2);
   
	for(int stride = BLOCK_SIZE_X*BLOCK_SIZE_Y / 2; stride > 0; stride >>= 1)
	{
		__syncthreads();
        for(int iAccum = tid; iAccum < stride; iAccum += BLOCK_SIZE_X*BLOCK_SIZE_Y)
			temp[iAccum] += temp[stride + iAccum];
	}

	SumToffsetSqrd = temp[0];
	__syncthreads();


	//for (x = noOfPixelsToWriteInSAX*tx ; x<min(noOfPixelsToWriteInSAX*(tx+1), saSizeX); x++ )
	//	for (y = noOfPixelsToWriteInSAY*ty ; y<min(noOfPixelsToWriteInSAY*(ty+1), saSizeY); y++ )	{
	//			SA[x][y] = Im2[(saStartX +x)*IMSIZEY + saStartY + y];
	//	}
	//__syncthreads();

	// Final x,y positions in search area where each threads writes an element
	int sax2 = min(tx + tSizeX -1, saSizeX-1);
	int say2 = min(ty + tSizeY -1, saSizeY-1);

	meanF =0.;
	for (x=tx; x<=sax2 ; x++)
		for (y=ty; y<=say2; y++)
			if (SP[x-tx][y-ty])
				meanF += Im2[(saStartX +x)*IMSIZEY + saStartY + y] / noOfOnPixels;


	__syncthreads();

	SumFoffsetSqrd =0.;
	for (x=tx; x<=sax2 ; x++)
		for (y=ty; y<=say2; y++)
			if (SP[x-tx][y-ty])
				SumFoffsetSqrd += pow(Im2[(saStartX +x)*IMSIZEY + saStartY + y] - meanF, 2);
	__syncthreads();


	float denom = SumToffsetSqrd + SumFoffsetSqrd;

	for (x=tx; x<=sax2 ; x++)
		for (y=ty; y<=say2; y++)
			if (SP[x-tx][y-ty])
				numerator += pow(T[x-tx][y-ty] - meanT - Im2[(saStartX +x)*IMSIZEY + saStartY + y] + meanF, 2);

	numerator = float(0.5) * numerator;
	__syncthreads();


	C[bID * BLOCK_SIZE_X * BLOCK_SIZE_Y + BLOCK_SIZE_X * ty + tx] =  -10.5 * (numerator/denom - 0.3) * (tx + tSizeX -1 < saSizeX) * (ty + tSizeY -1 < saSizeY);
	movedE[bID * BLOCK_SIZE_X * BLOCK_SIZE_Y + BLOCK_SIZE_X * ty + tx] = tx - SPXL;
	movedS[bID * BLOCK_SIZE_X * BLOCK_SIZE_Y + BLOCK_SIZE_X * ty + tx] = ty - SPYU;
}




void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
	float *Im1f, *Im2f, *Sp2f, *Im1_d, *Im2_d, *Sp2_d, *Sp2Val_d;
	double *Im1, *Im2, *Sp2, *boundsX, *boundsY, *Sp2Val;
	double noHits;    
    int i,j, pos, noPels, NC, M, N; 	
    int *xmin, *ymin, *xmax, *ymax, *xmin_d, *ymin_d, *xmax_d, *ymax_d;
    int *movedS, *movedE, *movedS_d, *movedE_d, *bestmovedS, *bestmovedE;
    float *maxScore_d, *maxScoref, *bestScores, *Sp2Valf;	    
    double *maxScoreRes, *movedSRes, *movedERes;

    //double N0, lambda;
	//int flag;
	//float *meanT, *meanTd;
	//flag = mxIsDouble(prhs[0]) ;

    /* Find the dimensions of the data */
    M = mxGetM(prhs[0]);
    N = mxGetN(prhs[0]);
    NC = mxGetM(prhs[2]);
           
    /* Retrieve the input data */
    Im1 = mxGetPr(prhs[0]);
    Im2 = mxGetPr(prhs[1]);
    
    boundsX = mxGetPr(prhs[2]);
    boundsY = mxGetPr(prhs[3]);
    
    Sp2 = mxGetPr(prhs[4]);
    Sp2Val = mxGetPr(prhs[5]);
    noHits = mxGetScalar(prhs[6]);
   
    //N0 = mxGetScalar(prhs[6]);
    //lambda = mxGetScalar(prhs[7]);

	noPels = M*N;
    
    /* Check if the input array is single or double precision */
    Im1f = (float *) mxMalloc(noPels*sizeof(float));
    for (j = 0; j < M*N; j++)
    {
        Im1f[j] = (float) Im1[j];
    }
    Im2f = (float *) mxMalloc(noPels*sizeof(float));
    for (j = 0; j < M*N; j++)
    {
        Im2f[j] = (float) Im2[j];
    }
    Sp2f = (float *) mxMalloc(noPels*sizeof(float));
    for (j = 0; j < M*N; j++)
    {
        Sp2f[j] = (float) Sp2[j];
    }
    Sp2Valf = (float *) mxMalloc(NC*sizeof(float));
	for (j = 0; j < NC; j++)
    {
        Sp2Valf[j] = (float) Sp2Val[j];
    }
    xmin = (int *) mxMalloc(NC*sizeof(int));
	for (j = 0; j < NC; j++)
    {
        xmin[j] = (int) boundsX[j];
    }
    xmax = (int *) mxMalloc(NC*sizeof(int));
	for (j = 0; j < NC; j++)
    {
        xmax[j] = (int) boundsX[NC+j];
    }
	ymin = (int *) mxMalloc(NC*sizeof(int));
	for (j = 0; j < NC; j++)
    {
        ymin[j] = (int) boundsY[j];
    }
	ymax = (int *) mxMalloc(NC*sizeof(int));
	for (j = 0; j < NC; j++)
    {
        ymax[j] = (int) boundsY[NC+j];
    }

   	maxScoref = (float *) mxMalloc(NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(float));
	movedS = (int *) mxMalloc(NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(int));
	movedE = (int *) mxMalloc(NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(int));
	//meanT = (float *) malloc( BLOCK_SIZE_X*BLOCK_SIZE_Y*sizeof(float));

	cudaError_t error ;

	error = cudaMalloc((void **) &Im1_d, noPels*sizeof(float));
	error = cudaMalloc((void **) &Im2_d, noPels*sizeof(float));
	error = cudaMalloc((void **) &Sp2_d, noPels*sizeof(float));
	error = cudaMalloc((void **) &Sp2Val_d, NC*sizeof(float));
	error = cudaMalloc((void **) &xmin_d, NC*sizeof(int));
	error = cudaMalloc((void **) &xmax_d, NC*sizeof(int));
	error = cudaMalloc((void **) &ymin_d, NC*sizeof(int));
	error = cudaMalloc((void **) &ymax_d, NC*sizeof(int));
	error = cudaMalloc((void **) &maxScore_d, NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(float));
	error = cudaMalloc((void **) &movedS_d, NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(int));
	error = cudaMalloc((void **) &movedE_d, NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(int));

    error = cudaMemcpy(Im1_d, Im1f, noPels*sizeof(float), cudaMemcpyHostToDevice);
	error = cudaMemcpy(Im2_d, Im2f, noPels*sizeof(float), cudaMemcpyHostToDevice);
	error = cudaMemcpy(xmin_d, xmin, NC*sizeof(int), cudaMemcpyHostToDevice);
	error = cudaMemcpy(xmax_d, xmax, NC*sizeof(int), cudaMemcpyHostToDevice);
	error = cudaMemcpy(ymin_d, ymin, NC*sizeof(int), cudaMemcpyHostToDevice);
	error = cudaMemcpy(ymax_d, ymax, NC*sizeof(int), cudaMemcpyHostToDevice);
    error = cudaMemcpy(Sp2_d, Sp2f, noPels*sizeof(float), cudaMemcpyHostToDevice);
    error = cudaMemcpy(Sp2Val_d, Sp2Valf, NC*sizeof(float), cudaMemcpyHostToDevice);


 	dim3 dimBlock(BLOCK_SIZE_X, BLOCK_SIZE_Y);
 	dim3 dimGrid(NC,1);
 	
	printf("%d\n",sizeof(float));
	printf("Starting GPU...\n");	
	NSSD<<<dimGrid, dimBlock>>>(Im1_d, Im2_d, N, M, xmin_d, xmax_d, ymin_d, ymax_d, maxScore_d, movedS_d, movedE_d, Sp2_d, Sp2Val_d);
	printf("GPU Completed...\n");
	cudaMemcpy(maxScoref, maxScore_d, NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(float), cudaMemcpyDeviceToHost);
	cudaMemcpy(movedS, movedS_d, NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(movedE, movedE_d, NC*(SPYU+SPYD+1)*(SPXL+SPXR+1)*sizeof(int), cudaMemcpyDeviceToHost);

	bestScores = (float *) mxMalloc(NC*noHits*sizeof(float));
	bestmovedS = (int *) mxMalloc(NC*noHits*sizeof(int));
	bestmovedE = (int *) mxMalloc(NC*noHits*sizeof(int));
	for (j = 0; j < NC*(SPYU+SPYD+1)*(SPXL+SPXR+1); j+=(SPYU+SPYD+1)*(SPXL+SPXR+1))
    {
		quickSort(&maxScoref[j],(SPYU+SPYD+1)*(SPXL+SPXR+1),&movedS[j],&movedE[j]);
		for (i = 0;i<noHits;i++)
		{
			pos = ( j/((SPYU+SPYD+1)*(SPXL+SPXR+1)) )*noHits+i;
			//sth wrong here
			bestScores[pos] = maxScoref[j+(SPYU+SPYD+1)*(SPXL+SPXR+1)-1-i];
			bestmovedS[pos] = movedS[j+(SPYU+SPYD+1)*(SPXL+SPXR+1)-1-i];
			bestmovedE[pos] = movedE[j+(SPYU+SPYD+1)*(SPXL+SPXR+1)-1-i];
		}
	}

    /* Setup the output */
    plhs[0] = mxCreateDoubleMatrix(noHits,NC,mxREAL);
    maxScoreRes  = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(noHits,NC,mxREAL);
    movedSRes  = mxGetPr(plhs[1]);
    plhs[2] = mxCreateDoubleMatrix(noHits,NC,mxREAL);
    movedERes  = mxGetPr(plhs[2]);
	for (j = 0; j < NC*noHits; j++)
    {
        maxScoreRes[j] = (double) bestScores[j];
    }
	for (j = 0; j < NC*noHits; j++)
    {
        movedSRes[j] = (double) bestmovedS[j];
    }
	for (j = 0; j < NC*noHits; j++)
    {
        movedERes[j] = (double) bestmovedE[j];
    }


	cudaFree(Im1_d);
	cudaFree(Im2_d);
	cudaFree(xmin_d);
	cudaFree(xmax_d);
	cudaFree(ymin_d);
	cudaFree(ymax_d);
	cudaFree(maxScore_d);
	cudaFree(movedS_d);
	cudaFree(movedE_d);
	cudaFree(Sp2_d);
	cudaFree(Sp2Val_d);
	
	mxFree(Im1f);
	mxFree(Im2f);
	mxFree(Sp2f);
	mxFree(Sp2Valf);
	mxFree(xmin);
	mxFree(xmax);
	mxFree(ymin);
	mxFree(ymax);
	mxFree(maxScoref);
	mxFree(movedS);
	mxFree(movedE);
	mxFree(bestScores);
	mxFree(bestmovedS);
	mxFree(bestmovedE);

		
}



