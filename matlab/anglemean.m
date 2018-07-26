function m = anglemean(theta, varargin)
% ANGLEMEAN Mean of set of angles in radians.
%   M = ANGLEMEAN(THETA) is the mean value of the elements of THETA if
%   THETA is a vector.
%   For matrices, M is a row vector containing the mean value of each 
%   column.
%   For N-D arrays, M is the mean value of the elements along the first
%   array dimension whose size does not equal 1.
%   M is always wrapped to [-pi, +pi].
%
%   ANGLEMEAN(THETA,DIM) takes the mean along the dimension DIM of THETA.
%
%   M = ANGLEMEAN(...,METHOD) specifies the algorithm used:
%   'arcmin'    - If the mean angle and the given angles are drawn as 
%                 points on the unit circle, this method minimizes the 
%                 squared arc lengths between the mean angle and the given 
%                 angles.
%   'vectorsum' - Computes the unit vector corresponding to each angle, 
%                 sums up the vectors, and computes the arc tangent. 
%                 If the mean angle and the given angles are drawn as 
%                 points on the unit circle, this method minimizes the 
%                 squared chord lengths between the mean angle and the 
%                 given angles.
%   Default is 'arcmin'.
%
%   Example:
%      theta = [3,1,2; 2,3,-1; -3,0,2]
%      anglemean(theta,1)
%      anglemean(theta,2)
%
%   See also MEAN.

% Copyright 2016 Alexander Schaefer
%
% ANGLEMEAN implements the orientation averaging algorithm proposed by 
% Olson:
% Edwin Olson. On computing the average orientation of vectors and lines.
% 2011 IEEE International Conference on Robotics and Automation,
% Shanghai, China.

%% Validate input.
% Check the given angles.
validateattributes(theta, {'numeric'}, {'real'}, '', 'THETA')

% Validate the dimension value.
if ~isempty(varargin) && isnumeric(varargin{1})
    dim = varargin{1};
    validateattributes(dim, {'numeric'}, ...
        {'scalar', 'positive', 'integer', '<=', ndims(theta)}, '', 'DIM')
    varargin(1) = [];
else
    dim = find(size(theta)>1, 1);
end

% Validate the method string and set the method.
method = 'arcmin';
if ~isempty(varargin)
    validatestring(varargin{1}, {'arcmin', 'vectorsum'});
    method = varargin{1};
end

% If given no data or a scalar, return.
if isempty(theta) || isscalar(theta)
    m = theta;
    return
end

%% Compute mean.
% Permute the dimensions of the matrix so the mean is always calculated
% along the columns.
ndim = ndims(theta);
dimshift = [dim:ndim, 1:dim-1];
theta = permute(theta,dimshift);

% Compute the mean using the specified method.
switch lower(method)
    case 'arcmin'
        % Map all angles to [-pi, +pi] and sort them.
        theta = sort(wrapToPi(theta));

        % Compute the moments for all angle arrangements.
        N = size(theta,1);
        M1 = sum(theta) + (0:N-1)' * 2*pi;
        M2 = sum(theta.^2);
        idx = repmat({':'}, 1, ndim-1);
        M2 = [M2; M2 + cumsum(4*pi*(theta(1:end-1,idx{:}) + pi))];
        
        % Compute the mean and the variance for all arrangements.
        m = M1 / N;
        sigma = M2 - 2*M1.*m + N*m.^2;

        % Return the mean that minimizes the squared error.
        [~,imin] = min(sigma);
        m = wrapToPi(m(imin));
    case 'vectorsum'
        % Use the vector sum method.
        m = atan2(sum(sin(theta)), sum(cos(theta)));
end

% Revert the permutation of the matrix dimensions.
m = ipermute(m, dimshift);

end
