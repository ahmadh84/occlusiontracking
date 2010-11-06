/*KMEANSK Performs K-means clustering given a list of feature vectors and k
 *  Note that the first argument (feature vectors) should be given as a 
 *  double
 * 
 *  The argument k indicates the number of clusters you want the data to be
 *  divided into. data_vecs (N*R) is the set of R dimensional feature 
 *  vectors for N data points. Each row in data_vecs gives the R 
 *  dimensional vector for a single data point. Each column in data_vecs 
 *  refers to values for a particular feature vector for all the N data 
 *  points. The output data_idxs is a N*1 vector of integers telling which 
 *  cluster number a particular data point belongs to. It also outputs 
 *  centroids which is a k*R matrix, where each rows gives the vector for 
 *  the cluster center. If we want to segment a color image i into 5 
 *  clusters using spacial and color information, we can use this function 
 *  as follows:
 *
 *	Extra parameters are provided in the same way as 'kmeans' in Matlab's
 *	stat's toolbox:
 *
 *	@args:
 *		'MaxIter' - Give the maximum number of iterations kmeans should run.
 *					The default value is 1000.
 *		'start' - Method used to choose the initial cluster centroid 
 *					positions. 'sample' would select k observations from X 
 *					at random (default). 'uniform' selects k points linearly
 *					interpolated in the range over each dimension of X.
 *
 *  Example:
 *      r = i(:,:,1);
 *      g = i(:,:,2);
 *      b = i(:,:,3);
 *      [cx rx] = meshgrid(1:size(i,1), 1:size(i,2));
 *      data_vecs = [r(:) g(:) b(:) rx(:) cx(:)];
 *      [ data_idxs centroids ] = kmeansK( data_vecs, k );
 *      d = reshape(data_idxs, size(i,1), size(i,2));
 *      imagesc(d);
 *
 *
 *  @author: Ahmad Humayun
 *  @email: ahmad.humyn@gmail.com
 *  @date: June 2010
 *	@updated: October 2010
 */

#include <string.h>
#include <limits>
#include <math.h>

using namespace std;

#include "mexutils.h"
#include <matrix.h>
#include <mex.h>


/* Initializes the centroids of the k clusters - called once */
void initCentroids(const double* const data_vecs, const int k, double* const centroids, const int features_dim, const int n_data, const unsigned int INIT_CENTROIDS)
{
	if(INIT_CENTROIDS == 0)
	{
		// call randsample to get random integers without replacement
		mxArray *rhs_randsample[2], *lhs_randsample[1];
		rhs_randsample[0] = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
		unsigned long *rhs_rs = (unsigned long*)mxGetPr(rhs_randsample[0]);
		rhs_rs[0] = n_data;
		rhs_randsample[1] = mxCreateNumericMatrix(1, 1, mxUINT32_CLASS, mxREAL);
		rhs_rs = (unsigned long*)mxGetPr(rhs_randsample[1]);
		rhs_rs[0] = k;
		mexCallMATLAB(1,lhs_randsample, 2,rhs_randsample, "randsample");
		double *lhs_rs = (double*)mxGetPr(lhs_randsample[0]);

		// iterate over output of randsample and set centroids to those data_vecs rows
		for(int i=0; i < k; i++)
		{
			for(int j=0; j < features_dim; j++)
				matElemRef(centroids, i, j, k) = matElemRef(data_vecs, ((unsigned long)lhs_rs[i])-1, j, n_data);
		}

		// destroy the arrays used to call randsample
		mxDestroyArray(rhs_randsample[0]);
		mxDestroyArray(rhs_randsample[1]);
		mxDestroyArray(lhs_randsample[0]);
	}
	else
	{
		// Set initial centroids
		// 1. find the max min in each feature
		double temp;
		for(int i=0; i < features_dim; i++)
		{       
			// init - set first and last centroids as the first value
			matElemRef(centroids, 0, i, k) = matElemRef(data_vecs, 0, i, n_data);
			matElemRef(centroids, k-1, i, k) = matElemRef(data_vecs, 0, i, n_data);
	        
			for(int j=1; j < n_data; j++)
			{
				temp = matElemRef(data_vecs, j, i, n_data);
	            
				// check if its the min
				if(temp < matElemRef(centroids, 0, i, k))
					matElemRef(centroids, 0, i, k) = temp;
	            
				// check if its the max
				if(temp > matElemRef(centroids, k-1, i, k))
					matElemRef(centroids, k-1, i, k) = temp;
			}
		}
	    
		// 2. Linearly interpolate from min to max to create the initial centroids
		for(int i=0; i < features_dim; i++)
		{   
			// find the gap btw max and min
			double per_gap = (matElemRef(centroids, k-1, i, k) - matElemRef(centroids, 0, i, k)) / (k-1);

			for(int j = 1; j < k-1; j++)
				matElemRef(centroids, j, i, k) = matElemRef(centroids, 0, i, k) + (per_gap * j);
		}
	}
}


/* Given the k centroid, assigns each element in data_vecs to one of the 
	k segments. The function returns true whenever a certain data element is
	assigned to a different segment, giving clues on if we need another KMeans
	iteration */
bool findDataAssignment(const double* const data_vecs, unsigned long* const data_idxs, const int k, const double* const centroids, const int features_dim, const int n_data)
{
	bool not_converged = false;
	unsigned long min_idx;
	double min_dist, temp_dist;

	// iterate over all data elements
	for(int i=0; i < n_data; i++)
	{
		// initialize the min. distance and its index
		min_dist = numeric_limits<double>::max();

		// iterate over all k centroids
		for(int j=0; j < k; j++)
		{
			temp_dist = 0;
			// calculate euclidean distance
			for(int z=0; z < features_dim; z++)
				temp_dist += pow(matElemRef(data_vecs, i, z, n_data)-matElemRef(centroids, j, z, k), 2);

			if(temp_dist < min_dist)
			{
				min_dist = temp_dist;
				min_idx = j+1;
			}
		}

		// make final assignment if it changes
		if(data_idxs[i] != min_idx)
		{
			data_idxs[i] = min_idx;
			not_converged = true;
		}
	}

	return not_converged;
}


/* Given elements of data_vecs, associated to a certain segment, adjust each
	segement centroid accordingly for the next iteration */
void adjustCentroids(const double* const data_vecs, const unsigned long* const data_idxs, unsigned long* const data_count, const int k, double* const centroids, const int features_dim, const int n_data)
{
	unsigned long k_idx;

	// initialize
	memset(data_count, 0, k*sizeof(unsigned long));

	// iterate over all data elements
	for(int i=0; i < n_data; i++)
	{
		// get the data's centroid idx
		k_idx = data_idxs[i]-1;

		// increment the counter
		data_count[k_idx]++;
	}

	// Adjust only those centroids which have 1 or more data points
	for(int i=0; i < k; i++)
	{
		if(data_count[i] > 0)
		{
			for(int j=0; j < features_dim; j++)
				matElemRef(centroids, i, j, k) = 0.0;
		}
	}

	// now adjust the centroids by iterating over all elements
	for(int i=0; i < n_data; i++)
	{
		// get the data's centroid idx
		k_idx = data_idxs[i]-1;

		// iterate over all features
		for(int j=0; j < features_dim; j++)
			matElemRef(centroids, k_idx, j, k) += (double)matElemRef(data_vecs, i, j, n_data) / data_count[k_idx];
	}
}


double getTotalSumSqDistance(const double* const data_vecs, const unsigned long* const data_idxs, const int k, double* const centroids, const int features_dim, const int n_data)
{
	unsigned long k_idx;

	double squared_dist = 0.0;

	// calculate total sq distance by iterating over all elements
	for(int i=0; i < n_data; i++)
	{
		// get the data's centroid idx
		k_idx = data_idxs[i]-1;

		// iterate over all features
		for(int j=0; j < features_dim; j++)
			squared_dist += pow(matElemRef(data_vecs, i, j, n_data)-matElemRef(centroids, k_idx, j, k), 2);
	}

	return squared_dist;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mwSize *dims;
	int features_dim, n_data, numdims, k;
	double *data_vecs, *centroids;
	unsigned long *data_idxs;
	unsigned long *data_count;
	mxArray* centroidsMxArray;
	bool not_converged = true;
    unsigned int INIT_CENTROIDS = 0;
	unsigned int MAX_ITER = 1000;

	unsigned int iterations_done = 0;

	//mexPrintf("No. of inputs %d | No. of outputs %d\n", nrhs, nlhs);
    // check inputs
	if(nrhs < 2)
		mexErrMsgTxt("The function takes two inputs - usage: [idx c] = kmeansK(D, k)");
	else if(nrhs > 2)
	{
		if(nrhs % 2 == 1)
			mexErrMsgTxt("No. of extra string parameters arguments should be even");

		for(int i=2; i < nrhs; i+=2)
		{
			if(mxGetClassID(prhs[i]) == mxCHAR_CLASS)
			{
				char *input_buf, *input_buf2;
				input_buf = mxArrayToString(prhs[i]);

				if(strcmp(input_buf, "MaxIter") == 0)
				{
					if(!mexIsRealScalar(prhs[i+1]) || !mxIsDouble(prhs[i+1]))
						mexErrMsgTxt("'MaxIter' parameter should be noncomplex scalar");
					MAX_ITER = (int)(*mxGetPr(prhs[i+1]));
				}
				else if(strcmp(input_buf, "start") == 0)
				{
					if(mxGetClassID(prhs[i+1]) == mxCHAR_CLASS)
						mexErrMsgTxt("'start' parameter should be a string");
					input_buf2 = mxArrayToString(prhs[i+1]);
					if(strcmp(input_buf2, "sample") == 0)
						INIT_CENTROIDS = 0;
					else if(strcmp(input_buf2, "uniform") == 0)
						INIT_CENTROIDS = 1;
					else
						mexErrMsgTxt("'start' parameter argument can only be 'sample' or 'uniform'");
				}
				else
				{
					char temp_buffer [2000];
					sprintf(temp_buffer, "'%s' is not a valid parameter identifier", input_buf);
					mexWarnMsgTxt(temp_buffer);
				}
			}
			else
				mexErrMsgTxt("Argument preceding an extra parameter should be a string identifier - 'MaxIter', 'start'\n");
		}
	}

    numdims = mxGetNumberOfDimensions(prhs[0]);
    if(numdims != 2 || !mxIsDouble(prhs[0]) || mxIsComplex(prhs[0]) || mxIsEmpty(prhs[0]))
        mexErrMsgTxt("The first argument should be a dimension 2 non-empty real double matrix");
    
    if(!mexIsRealScalar(prhs[1]) || !mxIsDouble(prhs[1]))
        mexErrMsgTxt("k should be noncomplex scalar");
  
    // get the input values
	data_vecs = mxGetPr(prhs[0]);
	k = (int)(*mxGetPr(prhs[1]));

	if(k < 1)
		mexErrMsgTxt("k should be greater than 0");
    
	dims = mxGetDimensions(prhs[0]);
	n_data = (int)dims[0];
	features_dim = (int)dims[1];

	// array to store the centroids (made on stack)
	plhs[0] = mxCreateNumericMatrix(n_data, 1, mxUINT32_CLASS, mxREAL);
    data_idxs = (unsigned long*)mxGetPr(plhs[0]);
	centroidsMxArray = mxCreateNumericMatrix(k, features_dim, mxDOUBLE_CLASS, mxREAL);
	centroids = (double*)mxGetPr(centroidsMxArray);
	data_count = new unsigned long[k];

	// initialize centroid positions
	initCentroids(data_vecs, k, centroids, features_dim, n_data, INIT_CENTROIDS);

	// main loop to adjust the centroids and make the data assignments
	while(not_converged && iterations_done < MAX_ITER)
	{
		// Assign each data item to one of the k segments
		not_converged = findDataAssignment(data_vecs, data_idxs, k, centroids, features_dim, n_data);
        
		// Adjust the segment centroids according to the new data assignments
		adjustCentroids(data_vecs, data_idxs, data_count, k, centroids, features_dim, n_data);
 
		//mexPrintf("%f\n", getTotalSumSqDistance(data_vecs, data_idxs, k, centroids, features_dim, n_data));

		/*
		for(int i = 0; i < n_data; i++)
		{
			mexPrintf("%d\n", data_idxs[i]);
			mexPrintf("\n");
		}
		mexPrintf("\n");
		
		for(int i = 0; i < k; i++)
		{
			for(int j = 0; j < features_dim; j++)
				mexPrintf("%f\t", matElemRef(centroids, i, j, k));
			mexPrintf("\n");
		}
		mexPrintf("\n");
		*/

		// increment number of iterations
		iterations_done++;
	}

	// if did not converge in the given number of iterations
	if(not_converged && iterations_done >= MAX_ITER)
	{
		char temp_buffer [2000];
		sprintf(temp_buffer, "Failed to converge in %d iterations.", MAX_ITER);
		mexWarnMsgTxt(temp_buffer);
	}

	// if user requires the centroids
	if(nlhs > 1)
	{
		// assign to output array
		plhs[1] = centroidsMxArray;
	}
	else
	{
		// deallocate memory
		mxDestroyArray(centroidsMxArray);
	}

	// remove data_count from heap
	delete [] data_count;
}