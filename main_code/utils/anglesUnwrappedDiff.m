function [ diff_angs ] = anglesUnwrappedDiff(a, b, intv)
%ANGLESUNWRAPPEDDIFF This function subtracts all angles in the first
%matrix/scalar by the second matrix/scalar
%   If any of the two arguments is a single value, it will be treated as a
%   scalar and matrix subtraction. The intv variable is a length 2 vector
%   giving the range in which the angles lie. The default argument for this
%   is [-pi pi]

    if ~exist('intv', 'var') || length(intv) ~= 2
        intv = [-pi pi];
    end
    assert(all(a(:) >= intv(1) & a(:) <= intv(2)), 'angles in first matrix exceed the angle interval used');
    assert(all(b(:) >= intv(1) & b(:) <= intv(2)), 'angles in second matrix exceed the angle interval used');
    ang_window_sz = intv(2) - intv(1);
    
    if isscalar(a)
        a = repmat(a, size(b));
    elseif isscalar(b)
        b = repmat(b, size(a));
    else
        assert(all(size(a) == size(b)), 'Lengths across all dimensions should be the same in both matrices');
    end
    
    diff_angs = a - b;
    overboard_ang_idxs = diff_angs > intv(2);
    diff_angs(overboard_ang_idxs) = diff_angs(overboard_ang_idxs) - ang_window_sz;
    underboard_ang_idxs = diff_angs < intv(1);
    diff_angs(underboard_ang_idxs) = ang_window_sz + diff_angs(underboard_ang_idxs);
end