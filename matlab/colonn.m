function x = colonn(i,j,n)
% COLONN Colon with overflow.
%   COLONN(I,J,N) corresponds to I:J with overflow at N.
%
%   I, J, and N are positive integer scalars with I,J<=N.
%   X is an integer row vector.
%   
%   If I<=J, COLONN(I,J,N) is equal to I:J.
%
%   If I>J, COLONN(I,J,N) overflows at N. For example, COLONWRAP(5,2,6)
%   returns [5,6,1,2].
%
%   Examples:
%      colonn(4,1,5)
%      colonn(3,6,6)
%
%   See also WRAP, MOD.

% Copyright 2017-2018 Alexander Schaefer

%% Validate input.
validateattributes(n,{'numeric'},{'scalar','integer','positive'},'','N')
validateattributes(i,{'numeric'},{'scalar','integer'},'','I')
validateattributes(j,{'numeric'},{'scalar','integer'},'','J')

%% Compute vector with overflow.
% Wrap input to interval.
i = wrap(i,n);
j = wrap(j,n);

% Compute output vector.
if i <= j
    x = i:j;
else
    x = wrap(i:j+n,n);
end

end
