function display(this)
%DISPLAY   Displays parameters of HS optical flow algorithm
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

  
  disp(sprintf('Image sequence (size):          %s', ...
               mat2str(size(this.images))));
  disp(sprintf('Spatial term weighting:         %s', ...
               mat2str(this.lambda)));
  disp(sprintf('Linear solver:                  %s', ...
               this.solver));
  disp(sprintf('# of pyramid levels:            %d', ...
               this.pyramid_levels));
  disp(sprintf('Spacing of pyramid levels:      %d', ...
               this.pyramid_spacing));
  disp(sprintf('Max. # of iterations:           %d', ...
               this.max_iters));
  disp(sprintf('Limit flow updates              %d', ...
               this.limit_update)); 