function uv = compute_flow_base(this, uv)
%
%COMPUTE_FLOW_BASE   Base function for computing flow field
%   UV = COMPUTE_FLOW_BASE(THIS, INIT) computes the flow field UV with
%   algorithm THIS and the initialization UV.
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

  % Iterate flow computation
  for i = 1:this.max_iters
      
    duv = zeros(size(uv));
    % Compute spatial and temporal partial derivatives
    [It Ix Iy] = partial_deriv(this.images, uv, this.interpolation_method);

    for j = 1:this.max_linear
        
        % Compute linear flow operator
        [A, b, parm, iterative] = flow_operator(this, uv, duv, It, Ix, Iy);
        
        % Terminate early if the flow_operator doesn't require multiple interations
        if (~iterative)
            break;
        end
        
        % Invoke the selected linear equation solver
        switch (lower(this.solver))
            case 'backslash'
                x = reshape(A \ b, size(uv));
            case 'sor'
                [x, flag, res, n] = sor(A', b, 1.9, 1000, 1E-2, uv(:));
                x = reshape(x, size(uv));
                fprintf('%d %d %d  ', flag, res, n);
            case 'bicgstab'
                x = reshape(bicgstab(A, b, 1E-3, 200, [], [], uv(:), parm), size(uv));
            case 'pcg'
                [x flag] = pcg(A,b, [], 100);
                x        = reshape(x, size(uv));
            otherwise
                error('Invalid solver!')
        end

        % Print status information
        if this.display
            disp(['--Iteration: ', num2str(i), '    (', ...
                num2str(norm(x(:))), ')'])
        end;

        %     % Terminate iteration early if flow doesn't change substantially
        %     if (length(this.lambda) == 1 && norm(uv(:) - x(:)) < 1E-3)
        %       break
        %     end

        % If limiting the incremental flow to [-1, 1] is requested, do so
        if (this.limit_update)
            x(x > 1)  = 1;
            x(x < -1) = -1;
        end
    
        duv = duv + x;       
        
    end;
    
    uv = uv + duv;
    
  end
