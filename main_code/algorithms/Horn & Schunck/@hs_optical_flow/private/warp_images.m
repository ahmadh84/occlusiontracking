function warped = warp_images(this, uv, warping_mode, no_pad)
%WARP_IMAGES   Warp image sequence
%   OUT = WARP_IMAGES(IN, UV, MODE[, NO_PAD]) warps the image sequence IN
%   with the flow field UV. If MODE is 'forward', the first image is
%   warped toward the second. 'backward' does the opposite. The optional
%   argument NO_PAD specifies whether or not to pad the unknown areas of
%   the warped image (default true).
%  
%   This is a private member function of the class 'hs_optical_flow'. 
%
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

  
  if (nargin < 4)
    no_pad = 1;
  end

  warped = zeros(size(this.images));

  switch (warping_mode)
    case 'forward'
      warped(:, :, 1) = imwarp(this.images(:, :, 1), -uv(:, :, 1), ...
                               -uv(:, :, 2), no_pad);
      warped(:, :, 2) = this.images(:, :, 2);
      
    case 'backward'
      warped(:, :, 1) = this.images(:, :, 1);
      warped(:, :, 2) = imwarp(this.images(:, :, 2), uv(:, :, 1), ...
                               uv(:, :, 2), no_pad);
  end