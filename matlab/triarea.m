function a = triarea(c)
% TRIAREA Triangle area.
%   A = TRIAREA(C) computes the area A enclosed by the triangle C.
%
%   C is a Nx6 matrix, where N is the number of triangles to process. Each
%   row of C contains the coordinates of the vertices of a triangle in the
%   following order: [x1, y1, x2, y2, x3, y3].
%
%   A is an N-element column vector. A(n) is the area of the n-th triangle.
%
%   Example:
%      a = triarea(rand(10,6))
%
%   See also POLYAREA.

% Copyright 2017 Alexander Schaefer

% Validate input.
validateattributes(c, {'numeric'}, {'real', 'ncols', 6}, '', 'C')

% Compute triangle areas.
c = c(:,3:6) - repmat(c(:,1:2),1,2);
a = abs(c(:,1).*c(:,4) - c(:,3).*c(:,2)) / 2;

end
