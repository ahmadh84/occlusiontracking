function uvo = estimate_flow_demo(iSequence, isColor, varargin)
%ESTIMATE_FLOW_DEMO   Optical flow computation using Horn & Schunck's
%                     method; demo program
% Run without input parameters: read the gray level RubberWhale sequence
%   and uses default parameters
%
% output UV is an M*N*2 matrix. UV(:,:,1) is the horizontal flow and
% UV(:,:,2) is the vertical flow.
%
% You can also provide parameters in the following way
% UV = ESTIMATE_FLOW_DEMO(ISEQUENCE, ISCOLOR, 'LAMBDA', 0.05, 'SIGMA_D', 6);
%
%     ISEQUENCE: selects the sequence in the following cell arrays to process
%       SeqName = {'Venus', 'Dimetrodon',   'Hydrangea',    'RubberWhale',...
%                'Grove2', 'Grove3', 'Urban2', 'Urban3', ...
%                'Walking', 'Beanbags',     'DogDance',     'MiniCooper'};
%     ISCOLOR:   0 means loading the gray level images, otherwise color
%     'lambda'                trade-off (regularization) parameter for the B&A formulation; default is 200, larger produces smoother flow fields 
%     'pyramid_levels'        pyramid levels; default is 4
%     'pyramid_spacing'       reduction ratio up each pyramid level; default is 2
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

addpath(genpath('utils'));

SeqName = {'Venus', 'Dimetrodon',   'Hydrangea',    'RubberWhale',...
           'Grove2', 'Grove3', 'Urban2', 'Urban3', ...
           'Walking', 'Beanbags',     'DogDance',     'MiniCooper'};

% Load flow estimation method
ope           = hs_optical_flow;
% ope.display   = false;        % uncomment to avoid printing information
ope.solver    = 'pcg'; 

% Parse parameters
if nargin == 0
    iSequence   = 4;
    isColor     = 0;
elseif length(varargin) >=2
    ope = parse_input_parameter(ope, varargin);    
end;


% Load image files
if (isColor == 0)     
    imFileDir   = ['data' filesep 'other-data-gray' filesep SeqName{iSequence} filesep];
else
    imFileDir   = ['data' filesep 'other-data' filesep SeqName{iSequence} filesep];
end;

im1         = double(imread([imFileDir 'frame10.png']));
im2         = double(imread([imFileDir 'frame11.png']));
ope.images  = cat(length(size(im1))+1, im1, im2);

if iSequence <=8    
    
    % GT flow available
    flowFilename= ['data' filesep 'other-gt-flow' filesep SeqName{iSequence} filesep 'flow10.flo'];
    tuv         = readFlowFile(flowFilename);
    UNKNOWN_FLOW_THRESH = 1e9;
    tuv (tuv>UNKNOWN_FLOW_THRESH) = NaN;      % unknown flow

    % Estimate flow fields
    uv  = compute_flow(ope, zeros(size(tuv)), tuv);
    
    % Compute AAE, endpoint error
    [aae stdae aepe] = flowAngErr(tuv(:,:,1), tuv(:,:,2), uv(:,:,1), uv(:,:,2), 0); % ignore 0 boundary pixels
    if ope.display
        fprintf('\nAll pixels considered AAE %3.3f STD %3.3f average end point error %3.3f \n', aae, stdae, aepe);
        fprintf('log posterior\t %3.3e\n', evaluate_log_posterior(ope, uv));
    end;
    
else    
    
    % Estimate flow fields
    uv  = compute_flow(ope, zeros([size(im1,1) size(im1,2) 2]));
    
end;
 
% Display estimated flow fields
figure; 
imshow(uint8(flowToColor(uv)));

% Uncomment below and change FN to save the flow fields
% fn  = sprintf('estimated_flow.flo');
% writeFlowFile(uv, fn);

% Uncomment below to read the save flow field
% uv = readFlowFile(fn);

if nargout == 1
    uvo = uv;
end;

% Uncomment below if you do not want to add 'utils/' to your
% matlab search path

% rmpath(genpath('utils'));