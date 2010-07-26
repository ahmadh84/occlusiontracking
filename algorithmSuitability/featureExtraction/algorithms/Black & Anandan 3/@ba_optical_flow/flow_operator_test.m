function flow_operator_test(this)
%FLOW_OPERATOR_TEST compare the analytical flow operator with numerical
%   approximated derivatives w.r.t. flow fields 
%
%   This is a member function of the class 'ba_optical_flow'. 
%
%   Author: Deqing Sun, Department of Computer Science, Brown University
%   Contact: dqsun@cs.brown.edu
%   $Date: 2007- $
%
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

this.display = false;
imsz        = [20 20];
this.images = randn([imsz 2]);
uv          = max(-3, min(3, randn([imsz 2]))); 

%%% -- Black & Anandan
% Analytical results
% [A, b] = flow_operator(this, uv);
% Duv    = b;
% 
% % numerical approximation
% delta = 1E-6;
% 
% Duv2 = zeros(size(Duv));
% 
% for i = 1:prod(imsz)*2
%     
%     uvp = uv; uvm = uv;
%     uvp(i) = uvp(i) + delta;
%     uvm(i) = uvm(i) - delta;
% 
%     L1 = evaluate_log_posterior(this, uvp);
%     L2 = evaluate_log_posterior(this, uvm);
% 
%     Duv2(i) = (L1-L2) / (2*delta);
% end;
% 
% err     = (Duv2-Duv);
% nerr    = err/max(max(abs(Duv)), max(abs(Duv2)) );
% disp('maximum absolute error and maximum absolute relative error -- Black & Anandan');
% [max(abs(err(:)))  max(abs(nerr(:)))]    % should be around or less to 1e-6
% 
% if max(abs(err(:))) > 1e-3 | max(abs(nerr(:))) > 1e-3
%     figure;             % set a breakpoint here
%     pause; close;       
% end;

%%% -- pairwise MRF with GSM as expert function
p       = pairwise_gsm_mrf([9 9]);
gsm     = gsm_density(1, 6);
gsm.precision = 1;

% this.spatial_filters = {[1 -1 0], [1; -1; 0]};
this.spatial_filters = {[1 -1], [1; -1]};
this.rho_spatial_u   = {gsm, gsm};
this.rho_spatial_v   = {gsm, gsm};
this.rho_data        = gsm;

% Analytical results 
[A, b] = flow_operator(this, uv);
Duv    = b;

% numerical approximation
delta = 1E-6;

Duv2 = zeros(size(Duv));

for i = 1:prod(imsz)*2
    
    uvp = uv; uvm = uv;
    uvp(i) = uvp(i) + delta;
    uvm(i) = uvm(i) - delta;

    L1 = evaluate_log_posterior(this, uvp);
    L2 = evaluate_log_posterior(this, uvm);

    Duv2(i) = (L1-L2) / (2*delta);
end;

err     = (Duv2-Duv);
nerr    = err/max(max(abs(Duv)), max(abs(Duv2)) );
disp('maximum absolute error and maximum absolute relative error -- PMRF-PC');
[max(abs(err(:)))  max(abs(nerr(:)))]    % should be around or less to 1e-6

if max(abs(err(:))) > 1e-3 | max(abs(nerr(:))) > 1e-3
    figure;             % set a breakpoint here
    pause; close;
end;