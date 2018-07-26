function [ d ] = dplin( p, v1, v2 )
%DPLIN Closest distance between point and line.
%   TODO should take endpoints into account
    p = [p, 0];
    v1 = [v1, 0];
    v2 = [v2, 0];
    a = v1 - v2;
    b = p - v2;
    d = norm(cross(a,b)) / norm(a);
end
