function x = linxlin(p1,p2,q1,q2)
% LINXLIN Intersection point for infinite lines.
%   X = LINXLIN(P1,P2,Q1,Q2) returns the intersection point of the infinite
%   lines defined by the point pairs P1, P2 and Q1, Q2.
%
%   P1, P2, Q1, Q2, and X are Nx2 matrices. Every row represents a 2-D
%   coordinate. The n-th row of X represents the intersection of two lines:
%   The first line passes through P1(n,:) and P2(n,:), the second passes
%   through Q1(n,:) and Q2(n,:). If the lines are collinear or if the
%   defining points are identical, the corresponding row of X is NaN.
%   
%   Example:
%      linxlin(rand(10,2), rand(10,2), rand(10,2), rand(10,2))
%
%   See also POLYXPOLY.

% Copyright 2017-2018 Alexander Schaefer

%% Validate input.
% Check types of input arguments.
validateattributes(p1,{'numeric'},{'real','2d','ncols',2},'','P1')
validateattributes(p2,{'numeric'},{'real','2d','ncols',2},'','P2')
validateattributes(q1,{'numeric'},{'real','2d','ncols',2},'','Q1')
validateattributes(q2,{'numeric'},{'real','2d','ncols',2},'','Q2')

% Check consistency of sizes of input arguments.
s = unique([size(p1,1),size(p2,1),size(q1,1),size(q2,1)]);
if numel(s)>=2 && s(end-1)~=1
    error('Dimensions of input arguments must agree.')
end

% Expand input arguments, if required.
nr = max(s);
p1 = repmat(p1,nr/size(p1,1),1);
p2 = repmat(p2,nr/size(p2,1),1);
q1 = repmat(q1,nr/size(q1,1),1);
q2 = repmat(q2,nr/size(q2,1),1);

%% Compute intersections.
% Precompute terms.
dp = p1 - p2;
dq = q1 - q2;
denom = dp(:,1).*dq(:,2) - dp(:,2).*dq(:,1);  

% Compute intersections.
x = [ (p1(:,1).*p2(:,2) - p1(:,2).*p2(:,1)) .* dq(:,1) ...
    - (q1(:,1).*q2(:,2) - q1(:,2).*q2(:,1)) .* dp(:,1), ...
      (p1(:,1).*p2(:,2) - p1(:,2).*p2(:,1)) .* dq(:,2) ...
    - (q1(:,1).*q2(:,2) - q1(:,2).*q2(:,1)) .* dp(:,2)] ./ denom;

% Set intersection points of collinear lines to NaN.
icol = abs(angdiff(cart2pol(dp(:,1),dp(:,2)), ...
    cart2pol(dq(:,1),dq(:,2)))) < 1e-12;
x(icol,:) = NaN;

end
