function x = constrain(x, lim)
% CONSTRAIN Fit value into interval.
%   CONSTRAIN(X, LIM) fits all values of matrix X into the interval defined
%   by the ordered 2-element vector LIM.
%
%   NaN values remain NaN.
%
%   Example:
%      constrain(1:9, [3,6])
%
%   See also MIN, MAX.

% Copyright 2016-2018 Alexander Schaefer

% Validate input.
validateattributes(lim, {'numeric'}, {'numel', 2}, '', 'LIM')

% Fit input into interval.
if diff(lim) >= 0
    x(x < lim(1)) = lim(1);
    x(x > lim(2)) = lim(2);
else
    x = [];
end

end
