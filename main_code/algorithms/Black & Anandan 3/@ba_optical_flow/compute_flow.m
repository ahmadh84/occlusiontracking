function uv = compute_flow(this, init, gt)
%COMPUTE_FLOW   Compute flow field
%   UV = COMPUTE_FLOW(THIS[, INIT]) computes the flow field UV with
%   algorithm THIS and the optional initialization INIT.
%  
%   This is a member function of the class 'ba_optical_flow'. 

%   Author: Deqing Sun, Department of Computer Science, Brown University
%   Contact: dqsun@cs.brown.edu
%   $Date: 2007-- $

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


  % Frame size
  sz = [size(this.images, 1), size(this.images, 2)];

  % If we have no initialization argument, initialize with all zeros
  if (nargin < 2)
    uv = zeros([sz, 2]);
  else
    uv = init;
  end

  % If there are fewer than 1 pyramid levels, default to 1
  if (this.pyramid_levels < 1)
    this.pyramid_levels = 1;
  end

  % Construct image pyramid, using filter setting in Bruhn et al in "Lucas/Kanade.." (IJCV2005') page 218
  % For gnc stage 1
  smooth_sigma      = this.pyramid_spacing/2;
  f                 = fspecial('gaussian', 2*round(1.5*smooth_sigma) +1, smooth_sigma);        
  pyramid_images    = compute_image_pyramid(this.images, f, this.pyramid_levels, 1/this.pyramid_spacing);
  
  % For gnc stage 2 to gnc_iters
  smooth_sigma      = this.gnc_pyramid_spacing/2;
  f                 = fspecial('gaussian', 2*round(1.5*smooth_sigma) +1, smooth_sigma);        
  gnc_pyramid_images= compute_image_pyramid(this.images, f, this.gnc_pyramid_levels, 1/this.gnc_pyramid_spacing);
  

  for ignc = 1:this.gnc_iters     
  
      if this.display
          disp(['GNC stage: ', num2str(ignc)])
      end
          
      if ignc == 1
          pyramid_levels = this.pyramid_levels;
      else
          pyramid_levels = this.gnc_pyramid_levels;
      end;
      
      % Iterate through all pyramid levels starting at the top
      for l = pyramid_levels:-1:1

          if this.display
              disp(['-Pyramid level: ', num2str(l)])
          end

          % Generate copy of algorithm with single pyramid level and the
          % appropriate subsampling
          small = this;
          if ignc == 1
              small.images         = pyramid_images{l};
              ratio = size(pyramid_images{l},1) / size(uv,1);
              nsz   = [size(pyramid_images{l}, 1) size(pyramid_images{l}, 2)];
          else
              small.images         = gnc_pyramid_images{l};
              ratio = size(gnc_pyramid_images{l},1) / size(uv,1);
              nsz   = [size(gnc_pyramid_images{l}, 1) size(gnc_pyramid_images{l}, 2)];
          end;

          uv    =  resample_flow(uv, nsz);

          % Run flow method on subsampled images
          uv = compute_flow_base(small, uv);
      end
      
      % Update GNC parameters (linearly)
      if this.gnc_iters > 1
          this.alpha = 1 - ignc / (this.gnc_iters-1);
      end;


      if true %this.display

          fprintf('log-posterior\t%3.2e\n', evaluate_log_posterior(this, uv));
          if nargin == 3
              [aae stdae aepe] = flowAngErr(gt(:,:,1), gt(:,:,2), uv(:,:,1), uv(:,:,2), 10);        % ignore 10 boundary pixels
              fprintf('AAE %3.3f STD %3.3f average end point error %3.3f \n', aae, stdae, aepe);
          end;
          
      end;


  end;

