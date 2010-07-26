function this = hs_optical_flow(varargin)
%
%HS_OPTICAL_FLOW  Optical flow computation with Horn & Schunck method
%       B.K.P. Horn and B.G. Schunck. Determining optical flow. 
%       Artificial Intelligence, 16:185-203, Aug. 1981.
%       http://people.csail.mit.edu/bkph/papers/Optical_Flow_OPT.pdf
%       
%   HS_OPTICAL_FLOW([IMGS]) constructs a HS optical flow object
%   with the optional image sequence IMGS ([n x m x 2] array). 
%   HS_OPTICAL_FLOW(O) constructs HS optical flow object by copying O.
%  
%   This is a member function of the class 'hs_optical_flow'. 

% Authors: Deqing Sun, Department of Computer Science, Brown University
%          Stefan Roth, Department of Computer Science, TU Darmstadt
% Contact: dqsun@cs.brown.edu, sroth@cs.tu-darmstadt.de
% $Date: 2008-10-28$
% $Revision: 0 $
%
% Copyright 2007-2008, Brown University, Providence, RI. USA
% 		     TU Darmstadt, Darmstadt, Germany 
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
      this.lambda          = 200;   
      this.pyramid_levels  = 4;             
      this.pyramid_spacing = 2;           
      this.solver          = 'backslash';   %'pcg' 'sor' 
      this.max_iters       = 3;             % maximum number of warping per pyramid level
      this.max_linear      = 1;             % maximum number of linearization performed per warping, 1 OK for HS
      this.limit_update    = false;         % limit the range of flow increments at each warping step
      this.warping_mode    = 'backward';  
      this.display         = true;
     
      this.sigmaD2         = 1;             % data term
      this.sigmaS2         = 1;             % spatial term
      
      this.interpolation_method = 'bi-linear'; %'bi-cubic'
      
      this = class(this, 'hs_optical_flow');         
      
    case 1
        
      if isa(varargin{1}, 'hs_optical_flow')          
        this = varargin{1};                
      else              
        this = hs_optical_flow;        
      end
      
    otherwise
        
      error('Incompatible arguments!');
      
  end