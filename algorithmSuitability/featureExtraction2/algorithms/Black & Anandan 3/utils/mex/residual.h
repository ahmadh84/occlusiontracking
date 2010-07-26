/*
  residual.h - Compute L2 residual of linear equation system

  This is part of a Matlab v7 MEX plugin.
  
  Author:  Stefan Roth, Department of Computer Science, TU Darmstadt
  Contact: sroth@cs.tu-darmstadt.de
  $Date$
  $Revision$
  
  Copyright 2004-2007 Brown University, Providence, RI.
  Copyright 2007-2008 TU Darmstadt, Darmstadt, Germany.
  
                       All Rights Reserved
  
  Permission to use, copy, modify, and distribute this software and its
  documentation for any purpose other than its incorporation into a
  commercial product is hereby granted without fee, provided that the
  above copyright notice appear in all copies and that both that
  copyright notice and this permission notice appear in supporting
  documentation, and that the name of Brown University not be used in
  advertising or publicity pertaining to distribution of the software
  without specific, written prior permission.
  
  BROWN UNIVERSITY DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
  INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR ANY
  PARTICULAR PURPOSE.  IN NO EVENT SHALL BROWN UNIVERSITY BE LIABLE FOR
  ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 
 */

#include <math.h>
#include "mex.h"

// Compute L2 residual of A'*x = b (i.e. ||A'*x - b||)
double residual(const mxArray* A, const mxArray* x, const mxArray* b)
{
  double*  APr = mxGetPr(A);
  mwIndex* AJc = mxGetJc(A);
  mwIndex* AIr = mxGetIr(A);
  double*  bPr = mxGetPr(b);
  double*  xPr = mxGetPr(x);
  
  mwSize total = 0;
  mwSize ncols = mxGetN(A);
  double res = 0.0;
  
  // Iterate over all the columns of A
  for (mwSize col = 0; col < ncols; col++)
    {
      mwIndex row_start = AJc[col];
      mwIndex row_end   = AJc[col+1];

      double col_tmp = -bPr[col];
      
      for (mwSize row_idx = row_start; row_idx < row_end; row_idx++)
	{
	  mwIndex row = AIr[row_idx];
	  col_tmp += APr[total++] * xPr[row];	  
	}

      res = res + col_tmp * col_tmp;
    }

  return sqrt(res);
}
