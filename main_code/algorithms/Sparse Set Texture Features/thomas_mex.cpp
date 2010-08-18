#include "mex.h"
#define max(a,b) (a>b?a:b)

void mexFunction(int nlhs, mxArray* plhs [],int nrhs, mxArray* prhs[]){
	if(nrhs != 4 || nlhs != 1)
		mexErrMsgTxt("use x = thomas_mex(a,b,c,d); with a being the diagonal, b the upper diagonal and c the lower diagonal of Ax=d\n a,d should be 1 x n and b,c should be 1 x n-1\n");
	double *a = mxGetPr(prhs[0]); double *b = mxGetPr(prhs[1]); double *c = mxGetPr(prhs[2]); double *d=mxGetPr(prhs[3]);
	int n = max(mxGetN(prhs[0]), mxGetM(prhs[0]));
	if(mxGetM(prhs[0])*mxGetN(prhs[0])!=n || mxGetM(prhs[1])*mxGetN(prhs[1]) != n-1 || mxGetM(prhs[2])*mxGetN(prhs[2])!= n-1 || 
	mxGetM(prhs[3])*mxGetN(prhs[3]) != n)
			mexErrMsgTxt("use x = thomas_mex(a,b,c,d); with a being the diagonal, b the upper diagonal and c the lower diagonal of Ax=d\n a,d should be 1 x n and b,c should be 1 x n-1\n");
	plhs[0] = mxCreateDoubleMatrix(1,n,mxREAL);
	double * x = mxGetPr(plhs[0]);

    double *m = new double[n],*y = new double[n], t;
    
	m[0] = a[0];
    y[0] = d[0];
    for(int i=1; i<n; i++)
    {
        t = c[i-1]/m[i-1];
        m[i] = a[i] - t*b[i-1];
        y[i] = d[i] - t*y[i-1];
    }
    y[0] = d[0];
    x[n-1] = y[n-1]/m[n-1];
    for(int i=n-2;i>=0;i--)
        x[i] = (y[i] - b[i]*x[i+1])/m[i];
    delete[] m;
    delete[] y;
}