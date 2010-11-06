/*MEXUTILS holds common functions used in MATLAB mex programming
 * 
 *  @author: Ahmad Humayun
 *  @email: ahmad.humyn@gmail.com
 *  @date: June 2010
 */

#ifndef _MEX_UTILS_H_
#define _MEX_UTILS_H_

#include "matrix.h"

/* #DEFINE(s) */
#define matElemRef(mat,r,c,rows) mat[r + c*rows]


/* MEMORY ALLOCATION */
/* Returns a pointer-to-pointer to array on heap of size rows x cols */
template <class storageType>
storageType** create2DArray(const unsigned int rows, const unsigned int cols)
{
    storageType **ptr = new storageType* [rows];
    for (unsigned int j=0; j < rows; j++)
        ptr[j] = new storageType[cols];
    return ptr;
}

/* Delete a 2D array from the heap */
template <class storageType>
void delete2DArray(storageType **ptr, const unsigned int rows)
{
    for(unsigned int j=0; j < rows; j++)
        delete [] ptr[j];
    delete [] ptr;
}


/* UTIL FUNCTIONS */
/* checks if a certain variable is a (non-complex) numeric scalar */
bool mexIsRealScalar(const mxArray* const ptr)
{
    // check if the dimension is 2
    if(mxGetNumberOfDimensions(ptr) != 2)
        return false;
    
    // check if it isn't a complex and is a 1x1 matrix
    if(!mxIsNumeric(ptr) || mxIsComplex(ptr) || (int)mxGetM(ptr) != 1 || (int)mxGetM(ptr) != 1)
        return false;
    
    return true;
}

/* checks if a certain variable could be a (color or grayscale) image */
bool mexIsImage(const mxArray* const ptr)
{
    // check if the matrix is only of certain numeric types
    if(!mxIsNumeric(ptr) && !(mxIsClass(ptr, "double") || mxIsClass(ptr, "uint8") || mxIsClass(ptr, "uint16")))
        return false;
    
    // check if array is non-complex and non-empty
    if(mxIsComplex(ptr) || mxIsEmpty(ptr))
        return false;
    
    // checks if dimension is 2 or 3
    if(mxGetNumberOfDimensions(ptr) != 2)
    {
        if(mxGetNumberOfDimensions(ptr) == 3)
        {
            // check if the depth of the 3rd dimension is only 3 (color)
            const mwSize *dims = mxGetDimensions(ptr);
            if(dims[2] != 3)
                return false;
        }
        else
            return false;
    }
    
    return true;
}

/* checks if certain variable is a vector (remember, it might not 
 * necessarily be numeric) */
bool mexIsVector(const mxArray* const ptr)
{
    if(mxGetNumberOfDimensions(ptr) != 2)
        return false;
    
    const mwSize *dims = mxGetDimensions(ptr);
    if(dims[0] > 1 && dims[1] > 1)
        return false;
    
    return true;
}


#endif