function [ mask ] = loadGTMask( tuv, border_gap )
%LOADGTMASK Loads the mask to be used for finding valid regions (features 
%   those will eventually be used for training the classifier). The 
%   optional argument <border_gap> gives the number of pixels to ignore at
%   the border

    mask = ~(tuv(:,:,1)>200 | tuv(:,:,2)>200);
    
    if ~exist('border_gap', 'var')
        border_gap = 0;
    end
    
    mask(1:border_gap,:) = 0;
    mask(:,1:border_gap) = 0;
    mask(end-border_gap+1:end,:) = 0;
    mask(:,end-border_gap+1:end) = 0;
end

