function y = expnd(x, s)
% EXPND Expand matrix to given size.
%   Y = EXPND(X, S) replicates the matrix X so it has size S. 
%   X is an M-D matrix. 
%   S is an N-element vector. N must be greater or equal M. 
%   Y is a matrix of size S.
%
%   Example:
%      expnd(4, [3,4,2])
%      expnd(1:5, [2,7,3])
%      expnd(zeros(0,3,1), [1,2,3])
%
%   See also REPMAT, REPELEM.

% Copyright 2017 Alexander Schaefer

%% Validate input.
validateattributes(s, {'numeric'}, ...
    {'integer', 'nonnegative', 'finite', 'vector'}, '', 'S')
s = s(:)';

%% Expand matrix.
% Determine the size of the input matrix.
sx = [size(x), ones(1,numel(s)-ndims(x))];

% Expand the input matrix.
if isempty(x)
    s(sx==0) = 0;
    y = zeros(s);
else
    y = repmat(x, ceil(s./sx));
    i = cellfun(@(x) 1:x, num2cell(s), 'UniformOutput', false);
    y = y(i{:});
end

end
