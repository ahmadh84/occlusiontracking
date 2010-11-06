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
 */

#include <string.h>
#include <limits>
#include <math.h>

using namespace std;

#include "mexutils.h"
#include <matrix.h>
#include <mex.h>


/* Initializes the centroids of the k clusters - called once */
void initCentroids(const double* const data_vecs, const int k, double* const centroids, const int features_dim, const int n_data)
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


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	const mwSize *dims;
	int features_dim, n_data, numdims, k;
	double *data_vecs, *centroids;
	unsigned long *data_idxs;
	unsigned long *data_count;
	mxArray* centroidsMxArray;
	bool not_converged = true;
    
	//mexPrintf("No. of inputs %d | No. of outputs %d\n", nrhs, nlhs);
    // check inputs
	if(nrhs != 2)
		mexErrMsgTxt("The function takes two inputs - usage: [idx c] = kmeansK(D, k)");
    
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
	initCentroids(data_vecs, k, centroids, features_dim, n_data);

	// main loop to adjust the centroids and make the data assignments
	while(not_converged)
	{
		// Assign each data item to one of the k segments
		not_converged = findDataAssignment(data_vecs, data_idxs, k, centroids, features_dim, n_data);
        
		// Adjust the segment centroids according to the new data assignments
		adjustCentroids(data_vecs, data_idxs, data_count, k, centroids, features_dim, n_data);
        
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