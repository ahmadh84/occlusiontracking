function y = mixture(x, comps, type)
%MIXTURE   Mixture of robust functions.
%   MIXTURE(X, COMPS, TYPE) evaluates a mixture of robust functions
%   with mixture components COMPS at point(s) X.  COMPS is a cell-array
%   of structures with mixture coefficients alpha and robust functions
%   fun.
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

  
  switch (type)
   case 0
    y = zeros(size(x));
    
    for i = 1:length(comps)
      y = y + comps{i}.alpha * exp(-evaluate(comps{i}.fun, x));
    end
    y = -log(y);
      
   case 1
    n = zeros(size(x));
    d = zeros(size(x));
    
    for i = 1:length(comps)
      tmp = exp(-evaluate(comps{i}.fun, x));
      n = n + comps{i}.alpha * deriv(comps{i}.fun, x) .* tmp;
      d = d + comps{i}.alpha * tmp;
    end
    y = n ./ d;
    
   case 2
    n = zeros(size(x));
    d = zeros(size(x));
    
    for i = 1:length(comps)
      tmp  = exp(-evaluate(comps{i}.fun, x));
      n = n + comps{i}.alpha * deriv(comps{i}.fun, x) .* tmp;
      d = d + comps{i}.alpha * tmp;
    end
    
    y = zeros(size(x));
    
    idx = (abs(x) >= eps);
    y(idx) = n(idx) ./ (x(idx) .* d(idx));
    if (any(~idx))
      y(~idx) = mean(mixture([-eps, eps], comps, 2));
    end
    
  end