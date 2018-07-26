function x = wrap(i,n)
% WRAP Wrap index to interval.
%   WRAP(I,N) wraps the linear index I to the integer interval [1,N].
%
%   Example:
%      wrap([1:7],3)
%
%   See also COLONN, MOD.

% Copyright 2017-2018 Alexander Schaefer

% Wrap index.
x = mod(i-1,n) + 1;

end
