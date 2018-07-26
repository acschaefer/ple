function [r,io,iv] = xpm(obj, pm)
% XPM Ray radii to first intersection point with polymap.
%   R = XPM(OBJ, PM) returns the distances R that the rays of the
%   laserscan2 OBJ travel from the sensor pose along their semi-infinite
%   trajectories until they intersect a line segment of the polymap PM.
%
%   R is an N-element column vector, where N is the number of rays in the
%   laser scan OBJ. The order of the rays in R is the same as in OBJ. R is
%   not limited to the interval defined by OBJ.RLIM. If a ray does not
%   intersect the polymap, the corresponding radius R is Inf.
%
%   [R,IO,IV] = XPM(OBJ, PM) additonally returns the two index vectors IO
%   and IV of length N.
%  
%   IO identifies for each laser ray which polymap element first reflects
%   the ray. If the ray is not reflected, the corresponding element of IO
%   is NaN.
%
%   IV identifies for each laser ray which line segment of the polymap
%   element with index IO reflects the ray. If the ray is not reflected,
%   the corresponding element of IV is NaN.
%
%   Example:
%      ls = laserscan2([0,0,0], deg2rad(-90:5:+90), 10)
%      pm = polymap({polygon([-5,-5; 5,-5; 5,5; -5,5])})
%      [r,io,iv] = ls.xpm(pm)
%
%   See also POLYXPOLY, POLYSHAPE.

% Copyright 2018 Alexander Schaefer

%% Validate input.
validateattributes(pm, {'polymap'}, {'scalar'}, '', 'PM')

% Initialize output.
r = Inf(obj.count,1);
io = NaN(obj.count,1);
iv = NaN(obj.count,1);

% Check if the polymap contains any elements.
if isempty(pm.element)
    return
end

%% Find intersection points.
% Loop over all map elements.
for i = 1 : pm.count
    % Loop over all line segments.
    s = pm.element{i}.segment;
    for j = 1 : size(s,1)        
        % For each ray, compute the polar coordinates of the startpoint and
        % of the endpoint of the line segment.
        [ths,~] = cart2pol(s(j,1)-obj.start2cart(:,1), ...
            s(j,2)-obj.start2cart(:,2));
        [the,~] = cart2pol(s(j,3)-obj.start2cart(:,1), ...
            s(j,4)-obj.start2cart(:,2));
        
        % Determine which rays intersect the line.
        dth = angdiff(ths,the);
        daz = (-1).^(dth<0) .* angdiff(ths,obj.sp(:,3)+obj.azimuth);
        tol = 1e-3;
        ir = find(daz>=-tol & daz<=abs(dth)+tol);
        
        % Check if there is an intersection.
        if ~isempty(ir)
            % Compute the ray radii.
            x = linxlin(obj.start2cart(ir,:),obj.end2cart(ir,:),...
                s(j,1:2),s(j,3:4));
            rir = vecnorm(x - obj.start2cart(ir,:),2,2);
            r(ir(isfinite(rir) &  rir>0)) = rir(isfinite(rir) & rir>0);

            % Store which ray intersected which map element.
            io(ir) = i;
            iv(ir) = j;
        end
    end
end

end
