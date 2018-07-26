function sethold(h)
% SETHOLD Set hold state of plot.
% 
%    Example:
%       h = ishold
%       hold on
%       plot(rand(10,1))
%       sethold(h)
%
%    See also ISHOLD, HOLD.

% Copyright 2017-2018 Alexander Schaefer

% Validate input.
validateattributes(h, {'logical', 'numeric'}, {'scalar'}, '', 'H')

% Set hold state.
if h
    hold on
else
    hold off
end

end
