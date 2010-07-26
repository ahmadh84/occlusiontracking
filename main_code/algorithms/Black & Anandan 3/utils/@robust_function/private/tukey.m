function y = tukey(x, sigma, type)
%TUKEY   Tukey robust function.
%   TUKEY(X, SIGMA, TYPE) evaluates the Tukey robust function
%   with sigma SIGMA at point(s) X.  
%   TYPE selects the evaluation type:
%    - 0: function value
%    - 1: first derivative
%    - 2: second derivative
%  
%   This is a private member function of the class 'robust_function'. 
%
%   Author:  Stefan Roth, Department of Computer Science, Brown University
%   Contact: roth@cs.brown.edu
%   $Date: $
%   $Revision: $

% Copyright 2004-2006 Brown University, Providence, RI.
% 
%                         All Rights Reserved
% 
% Permission to use, copy, modify, and distribute this software and its
% documentation for any purpose other than its incorporation into a
% commercial product is hereby granted without fee, provided that the
% above copyright notice appear in all copies and that both that
% copyright notice and this permission notice appear in supporting
% documentation, and that the name of Brown University not be used in
% advertising or publicity pertaining to distribution of the software
% without specific, written prior permission.
% 
% BROWN UNIVERSITY DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
% INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR ANY
% PARTICULAR PURPOSE.  IN NO EVENT SHALL BROWN UNIVERSITY BE LIABLE FOR
% ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

  
  idx = (x > sigma);
  
  y = zeros(size(x));

  switch (type)
   case 0
    y(idx) = 1/3;
    
    tmp = x(~idx).^2 / sigma^2;
    y(~idx) = tmp - tmp.^2 + tmp.^3 / 3;
   case 1
    y(idx)  = 0;
    y(~idx) = x(~idx) .* (1 - (x(~idx).^2 / sigma^2)).^2;
   case 2
    y(idx)  = 0;
    y(~idx) = (1 - (x(~idx).^2 / sigma^2)).^2;
  end