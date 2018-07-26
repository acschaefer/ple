function [y,i,j] = cellmin(x)
% CELLMIN Find index of minimum element in cell array.
%   [Y,I,J] = CELLMIN(X) returns the minimum element Y in the cell array X.
%   I is the index of the cell where the minimum element Y is to be found,
%   J is the index of the minimum element inside the cell indexed by I.
%
%   Example:
%      x = {rand(2),rand(3)}
%      [y,i,j] = cellmin(x)
%
%   See also MIN, MAX, CELLFUN.

% Copyright 2018 Alexander Schaefer

% Find the minimum of all numbers in the cell array.
x = cellfun(@(x) x(:), x, 'UniformOutput', false);
[y,k] = min(vertcat(x{:}));

% If the cell array is empty, return empty indices.
if isempty(k)
    i = k;
    j = k;
else
    % Determine the number of elements in each cell of the cell array.
    n = cellfun(@numel, x(:));

    % Determine the cell index of the minimum element.
    csn = [0; cumsum(n)];
    i = find(k > csn, 1, 'last');

    % Determine the index of the minimum element inside the cell.
    j = k - csn(i);
end

end
