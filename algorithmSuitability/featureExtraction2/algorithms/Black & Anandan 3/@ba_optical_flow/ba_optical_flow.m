function this = ba_optical_flow(varargin)
%
%BA_OPTICAL_FLOW   Optical flow computation with Black & Anandan method
%       Black, M. J. and Anandan, P. The robust estimation of multiple
%       motions: Parametric and piecewise-smooth flow fields,
%       CVIU, 63(1), pp. 75-104, Jan. 1996.
%       http://www.cs.brown.edu/people/black/Papers/cviu.63.1.1996.pdf
%       
%   BA_OPTICAL_FLOW([IMGS]) constructs a BA optical flow object
%   with the optional image sequence IMGS ([n x m x 2] array). 
%   BA_OPTICAL_FLOW(O) constructs BA optical flow object by copying O.
%  
%   This is a member function of the class 'ba_optical_flow'. 

%   Author: Deqing Sun, Department of Computer Science, Brown University
%   Contact: dqsun@cs.brown.edu
%   $Date: 2007-11-30 $

% Copyright 2007-2008, Brown University, Providence, RI.
%
%                         All Rights Reserved
%
% Permission to use, copy, modify, and distribute this software and its
% documentation for any purpose other than its incorporation into a
% commercial product is hereby granted without fee, provided that the
% above copyright notice appear in all copies and that both that
% copyright notice and this permission notice appear in supporting
% documentation, and that the name of the author and Brown University not be used in
% advertising or publicity pertaining to distribution of the software
% without specific, written prior permission.
%
% THE AUTHOR AND BROWN UNIVERSITY DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
% INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR ANY
% PARTICULAR PURPOSE.  IN NO EVENT SHALL THE AUTHOR OR BROWN UNIVERSITY BE LIABLE FOR
% ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.  

error(nargchk(0, 1, length(varargin)));
  
  switch (length(varargin))
    case 0
        
      this.images          = [];              
      this.lambda          = 1e-1;
      this.lambda_q        = 5e-2; %1/36;      % Quadratic formulation of the objective function
      this.solver          = 'backslash';      % 'sor', 'pcg'
      this.limit_update    = true;
      this.warping_mode    = 'backward';  
      this.display         = true;      
      this.deriv_filter    = [-1 9 -45 0 45 -9 1]/60;        % derivative used by Bruhn et al "combing "IJCV05' page218, or [-1 0 1]/2;  
      this.interpolation_method = 'bi-linear';               %'bi-cubic's
      
      this.spatial_filters = {[1 -1], [1; -1]};      
      
      for i = 1:length(this.spatial_filters);
          this.rho_spatial_u{i}   = robust_function('lorentzian', 0.1);
          this.rho_spatial_v{i}   = robust_function('lorentzian', 0.1);      
      end;
      this.rho_data        = robust_function('lorentzian', 6.3);

      this.pyramid_levels  = 4; 
      this.pyramid_spacing = 2; 
      this.max_iters       = 3;             % number of warping per pyramid level
      this.max_linear      = 1;             % maximum number of linearization performed per warping, 1 OK for HS
      
      % For Graduated Non-Convexity (GNC) optimization
      this.gnc_iters            = 3;
      this.alpha                = 1;
      this.gnc_pyramid_levels   = 2;
      this.gnc_pyramid_spacing  = 1.25;
      
      this = class(this, 'ba_optical_flow');         
      
    case 1
      if isa(varargin{1}, 'ba_optical_flow')
        this = other;        
      else    
          this = ba_optical_flow;
      end
      
    otherwise
      error('Incompatible arguments!');
      
  end