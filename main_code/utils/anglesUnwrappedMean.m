function [ avg_ang ] = anglesUnwrappedMean( ang_vec, deg_def, dim )
%ANGLESUNWRAPPEDMEAN Gives the mean angle given a set of angle over a
%certain dimension
%   ang_vec can be a matrix of any number of dimensions. deg_def tells if
%   the angles are in radians ('rad') or in degrees ('deg'). If not given
%   they are taken in radians. The dim gives the dimension across which the
%   average needs to be computed. If ang_vec is a vector, the mean is
%   computed for all the values given

    if ~exist('deg_def', 'var') || ischar(deg_def) ~= 1
        deg_def = 'rad';
    end

    if ~exist('dim', 'var') || isscalar(dim) ~= 1
        dim = 1;
    end
    
    if isvector(ang_vec)
        ang_vec = ang_vec(:);
    end
    
    if strcmpi(deg_def, 'rad')
        assert(all(ang_vec(:) >= -pi & ang_vec(:) <= pi), 'angles in the input matrix exceed the [-pi pi]');
        
        u = cos(ang_vec);
        v = sin(ang_vec);
        avg_ang = sumVecDimComputeAng(u, v, dim);
    elseif strcmpi(deg_def, 'deg')
        assert(all(ang_vec(:) >= -180 & ang_vec(:) <= 180), 'angles in the input matrix exceed the [-180 180]');
        
        u = cosd(ang_vec);
        v = sind(ang_vec);
        avg_ang = sumVecDimComputeAng(u, v, dim);
        avg_ang = avg_ang * (180/pi);
    else
        error('anglesUnwrappedMean:InvalidArg', 'Arguments for deg_def can either be ''rad'' or ''deg''');
    end
    
end


function [angs] = sumVecDimComputeAng(u, v, dim)
    u_sum = sum(u, dim);
    v_sum = sum(v, dim);
    angs = atan2(v_sum, u_sum);
end