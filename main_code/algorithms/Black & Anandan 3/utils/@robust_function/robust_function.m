function this = robust_function(varargin)
%ROBUST_FUNCTION   Construct a robust function
%   ROBUST_FUNCTION(TYPE[, PARAM]) constructs a robust function of type
%   TYPE with optional parameters PARAM.
%   The following robust function types are available:
%    - 'geman_mcclure'
%    - 'huber'
%    - 'lorentzian'
%    - 'quadratic'
%    - 'tukey'
%    - 'spline'
%    - 'mixture'
%    - 'gaussian' (like quadratic, but normalized)
%    - 'tdist' (normalized)
%    - 'tdist_unnorm' (unnormalized)
%    - 'charbonnier'
%
%   ROBUST_FUNCTION(O) constructs a robust function by copying O.
%  
%   This is a member function of the class 'robust_function'. 
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
  
  
  error(nargchk(0, 2, length(varargin)));
  
  switch (length(varargin))
   case 0
    this.type  = @quadratic;
    this.param = 1;
    this = class(this, 'robust_function');
    
   case 1
    if isa(varargin{1}, 'robust_function')
      this = other;
    else
      switch (varargin{1})
       case 'geman_mcclure'
        this.type = @geman_mcclure;
       case 'huber'
        this.type = @huber;
       case 'lorentzian'
        this.type = @lorentzian;
       case 'quadratic'
        this.type = @quadratic;
       case 'tukey'
        this.type = @tukey;
       case 'spline'
        this.type = @spline;
       case 'mixture'
        this.type = @mixture;
       case 'gaussian'
        this.type = @gaussian;
       case 'tdist'
        this.type = @tdist;
       case 'tdist_unnorm'
        this.type = @tdist_unnorm;
       case 'charbonnier'
        this.type = @charbonnier;
       otherwise
        error('Invalid robust function type.');
      end

      this.param = 1;
      this = class(this, 'robust_function');
    end

   case 2
    switch (varargin{1})
     case 'geman_mcclure'
      this.type = @geman_mcclure;
     case 'huber'
      this.type = @huber;
     case 'lorentzian'
      this.type = @lorentzian;
     case 'quadratic'
      this.type = @quadratic;
     case 'tukey'
      this.type = @tukey;
     case 'spline'
      this.type = @spline;
     case 'mixture'
      this.type = @mixture;
     case 'gaussian'
      this.type = @gaussian;
     case 'tdist'
      this.type = @tdist;
     case 'tdist_unnorm'
      this.type = @tdist_unnorm;
     case 'charbonnier'
      this.type = @charbonnier;
     otherwise
      error('Invalid robust function type.');
    end

    this.param = varargin{2};
    this = class(this, 'robust_function');
  
  end