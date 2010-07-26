#ifndef _MEX_TOOLS_H_
#define _MEX_TOOLS_H_

/*
  mex_tools.h - MEX utility functions

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

#include "mex.h"

#ifdef __cplusplus
extern "C"
{
#endif
  
/*
  Create a double matrix of size m x n with given complexity flag, but
  in contrast to MEX-builtin don't initialize values.
 */    
mxArray*
mxCreateDoubleMatrixNoinit(mwSize m, mwSize n, mxComplexity ComplexFlag);

  
/*
  Create a double array with ndim dimensions and sizes dims with given
  complexity flag, but in contrast to MEX-builtin don't initialize
  values.
 */    
mxArray*
mxCreateDoubleArrayNoinit(mwSize ndim, const mwSize* dims, mxComplexity ComplexFlag);

#ifdef __cplusplus
}
#endif

#endif /* _MEX_TOOLS_H_ */
