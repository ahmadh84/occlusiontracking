function [DistsSqrdToEachK membershipIndex] = MembershipToKpts( data, kPts )
%Usage: 
%   [DistsSqrdToEachK membershipIndex] = MembershipToKpts( data, kPts )
%
%   data: should be columns of data, many rows long
%   kPts: nDim rows x k points



    numPts = size(data,1);
    numDims = size(data,2);
    numClusts = size(kPts, 2);

    DistToKpts = zeros( numPts, numDims*numClusts);
    for( iClust= 0:numClusts-1 )
        for( iDim = 0:numDims-1 )
            %sprintf('%d', iClust*numDims + iDim + 1) 
            DistToKpts(:, iClust*numDims + iDim + 1) = data(:,iDim+1) - kPts(iDim+1, iClust+1);
        end %Endfor over Dims
    end %Endfor over BGclusts
    DistToKpts = DistToKpts.^2; 

    % Now, each dimension's squared-distance (to each of K pts) is stored 
    % separately. Need to find the total distance:

    DistsSqrd = zeros(numPts, numClusts);
    for( iClust= 0:numClusts-1 )
        DistsSqrd(:,iClust+1) = sum( DistToKpts( :, iClust*numDims + 1 : iClust*numDims + numDims), 2);
    end
    [DistsSqrdToEachK membershipIndex] = min(DistsSqrd, [], 2);

end