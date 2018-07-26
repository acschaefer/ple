function pm = extrlin(obj, varargin)
% EXTRLIN Extract lines from scan endpoints.
%   PM = EXTRLIN(OBJ) extracts a set of finite lines PM from the endpoints
%   of the laser scan OBJ. These lines represent a model of the environment
%   of the laser sensor.
%
%   PM is a polymap object that either contains a single polygon or a set
%   of polylines.
%
%   The line extraction algorithm consists of two steps. The first step
%   estimates a set of lines given the scan endpoints. The lines always
%   start and end at scan endpoints. It works as follows. First, all scan
%   endpoints are connected to form a polygon. All edges whose length
%   exceeds a given parameter LMAX are discarded, because they are not
%   sufficiently backed up by collected data. Then, for each endpoint, the
%   algorithm computes the error that would result from removing it. The
%   error is the sum of the squared distances between the recorded ray
%   endpoints and the intersection with the simplified polygon shape,
%   measured along the axis of the ray. It is motivated by the assumption
%   that the radial noise of the laser scanner is normally distributed. If
%   a line consists only of two points and removing a vertex from it would
%   result in removing the whole line, the corresponding per-line error is
%   set to the parameter DR. Next, the endpoint with the least error is
%   removed and the errors are recomputed. This procedure is repeated until
%   the error surpasses the given error threshold EMAX or until the number
%   of map vertices falls below N. The result of the line simplification
%   can be a polygon or a set of polylines.
%
%   The second step removes the restriction that the lines always start and
%   end at scan endpoints. To this end, an optimizer moves the vertices
%   around in order to maximize the measurement probability of the scan
%   given the lines.
%
%   The algorithm can be configured by calling EXTRLIN(OBJ,Name,Value)
%   with the following name-value pair arguments:
%      'lmax'      - maximum admissible distance between neighboring 
%                    endpoints. All edges that exceed this distance are 
%                    discarded.
%                    Defaults to Inf.
%      'emax'      - maximum admissible error in a line simplification 
%                    step.
%                    Defaults to Inf.
%      'n'         - maximum number of vertices of the resulting polymap.
%                    Defaults to 10.
%      'dr'        - per-line error corresponding to removal of line.
%                    Defaults to 1.
%      'optimize'  - logical scalar that enables the optimization step.
%                    Defaults to true.
%      'display' -   'plot' enables the graphical visualization of the 
%                           optimization process.
%                    'text' outputs the optimization process in the command
%                           window
%                    'none' suppresses all outputs.
%                    Defaults to 'none'.
%
%   Example:
%      [~,ls] = carmenread('intel-corrected.log.gz')
%      ls(1).extrlin

% Copyright 2017-2018 Alexander Schaefer
%
% EXTRLIN implements the line extraction algorithm proposed by Schaefer et
% al.:
% Alexander Schaefer, Daniel Buescher, Lukas Luft, Wolfram Burgard.
% A Maximum Likelihood Approach to Extract Polylines from 2-D Laser Range
% Scans.
% IEEE International Conference on Intelligent Robots 2018.
            
%% Validate input.
validateattributes(obj, {'laserscan2'}, {'scalar'}, '', 'OBJ')

%% Parse input arguments.
parser = inputParser;
parser.addParameter('lmax', Inf, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'nonnegative', 'scalar'}, '', '''lmax'''))
parser.addParameter('emax', Inf, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'nonnegative', 'scalar'}, '', '''emax'''))
parser.addParameter('n', 10, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'integer', 'scalar', '>=', 2}, '', '''n'''))
parser.addParameter('dr', 1, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'scalar'}, '', '''dr'''))
parser.addParameter('optimize', true, ...
    @(x) validateattributes(x, {'logical'}, ...
    {'scalar'}, '', '''optimize'''))
parser.addParameter('display', 'none', ...
    @(x) any(validatestring(x, {'plot','text','none'})))
parser.parse(varargin{:});

%% Remove invalid vertices and edges.
% Determine the angular gap between last and first laser ray
agap = mod(sign(angdiff(obj.azimuth([1,2]))) * ...
    (obj.azimuth(1)-obj.azimuth(end)), 2*pi);
if agap > 4 * pi / obj.count
    % In case of a large gap between first and last ray, create a polyline
    % consisting of the laser scan endpoints.
    pobj = polyline(obj.end2cart);
else
    % Otherwise create a polygon.
    pobj = polygon(obj.end2cart);
end

% Remove the vertices that correspond to no-return rays.
pmret = pobj.rmvertex(~obj.ret);

% Remove overlength edges.
pm = polymap;
for pmi = horzcat(pmret.element{:})
    pm.element = [pm.element; 
        pmi.rmedge(pmi.length>parser.Results.lmax).element];
end

%% Remove least significant vertices.
% Define the function that computes the error corresponding the removal of
% a vertex.     
    function e = rmverror(po, iv)
        % RMVERROR Error corresponding to removal of vertex.
        %   E = RMVERROR(PO, IV) computes the change in the measurement
        %   log-likelihood that results from removing the vertex indexed by
        %   IV from the polygon or the polyline PO. 
        %   E has the same size as IV.
        
        % Loop over all given indices.
        e = NaN(size(iv));
        for j = 1 : numel(iv)
            % Check if the vertex is the starting point or endpoint of a
            % line.
            if isa(po,'polyline') && (iv(j)==1 || iv(j)==po.count)
                % Create the line segment that would be removed.
                s = po.segment(constrain(iv(j),[1,size(po.segment,1)]),:);
                l = polyline(reshape(s,2,2)');
                
                % Compute the ray radii to the intersections with the line
                % segment.
                r = obj.xpm(polymap({l}));
                
                % Determine which rays are reflected by the line.
                iret = isfinite(r);
                
                % Use a heuristic to determine the negative measurement
                % log-likelihood of the scan given no line.
                drsqrm = parser.Results.dr^2;
                
                % Compute the negative measurement log-likelihood of the
                % scan given the line.
                drsq = (obj.radius(iret) - r(iret)).^2;
            
                % Compute the change in the measurement log-likelihood
                % caused by the removal of the vertex. If the line is only
                % one segment of a polyline, account for the one ray that
                % corresponds to the vertex that links the segment to the
                % remainder of the polyline. This ray is still reflected.
                e(j) = sum(drsqrm-drsq) - drsqrm*(po.count>2);
            else
                % Build a polyline out of the two line segments that are
                % joined by the vertex.
                l = polyline(po.vertex(wrap(iv(j)+[-1,0,1],po.count),:));
                
                % Compute the ray radii to the intersections with the line
                % segments.
                r = obj.xpm(polymap({l}));
                
                % Determine which rays are reflected by the original two
                % line segments.
                iret = isfinite(r);
                
                % Build a line that corresponds to the removal of the
                % vertex.
                lrm = l;
                lrm.vertex(2,:) = [];
                
                % Compute the ray radii to the intersections with the line.
                rrm = obj.xpm(polymap({lrm}));
                
                % Compute the negative measurement log-likelihood of the
                % scan given the line.
                drsqrm = (obj.radius(iret) - rrm(iret)).^2;
                
                % Compute the negative measurement log-likelihood of the
                % scan given the line.
                drsq = (obj.radius(iret) - r(iret)).^2;

                % Compute the change in the measurement log-likelihood
                % caused by the removal of the vertex.
                e(j) = sum(drsqrm-drsq);
            end
        end
        
    end

% Compute the errors that correspond to the removal of every map vertex.
e = cellfun(@(po) rmverror(po,1:po.count), pm.element, ...
    'UniformOutput', false);

% Determine the vertex whose removal incurs the smallest error.
[emin,iomin,ivmin] = cellmin(e);

% Iteratively remove the vertex whose removal incurs the smallest error.
while ~(size(pm.vertex,1)<=parser.Results.n || emin>parser.Results.emax)
    % Check if the polymap element degenerates.
    if pm.element{iomin}.count <= 2
        % If a line degenerates to a point, delete it.
        pm.element(iomin) = [];
        e(iomin) = [];
    else
        % Remove the vertex.
        pm.element{iomin}.vertex(ivmin,:) = [];
        e{iomin}(ivmin) = [];

        % Recompute the errors of the neighboring vertices.
        iv = wrap([ivmin-1,ivmin],pm.element{iomin}.count);
        e{iomin}(iv) = rmverror(pm.element{iomin},iv);
    end
    
    % Determine the vertex whose removal incurs the smallest error.
    [emin,iomin,ivmin] = cellmin(e);
end

%% Optimize vertex locations.
if parser.Results.optimize
    % Optimize the elements of the polymap one after another.
    for i = 1 : pm.count
        % Get the polymap element.
        po = pm.element{i};
        
        % Select the subset of laser rays that are reflected by the map
        % element.
        lsi = obj.select(isfinite(obj.xpm(polymap({po}))));
        
        % Convert the map element to the initial parameter vector.
        x0 = po2x(po,lsi);
        
        % Define the function to convert the parameter vector to the map
        % element.
        x2p = @(x) x2po(x,po,lsi);
        
        % Parameterize the optimizer.
        switch parser.Results.display
            case 'plot'
                opt = optimset('Display', 'iter', ...
                    'PlotFcns', @(x,~,~) plotprogress(x2p(x),lsi));
            case 'text'
                opt = optimset('Display', 'iter');
            case 'none'
                opt = optimset('Display', 'none');
        end
        opt.TolX = 1e-2;
        opt.TolFun = 1e-2;
        
        % Perform optimization.
        xopt = fminsearch(@(x) poerror(x2p(x),obj), x0, opt);
    
        % Convert the optimal parameter vector back to a polymap element.
        pm.element{i} = x2p(xopt);
    end
end

% Visualize result.
if strcmpi(parser.Results.display, 'plot')
    plotprogress(pm, obj);
end

end

function e = poerror(po, ls)
% POERROR Radius error between polyline or polygon and laser scan.
%   E = POERROR(PO, LS) computes the sum of the squared ray radius
%   differences between the measured laser scan LS and the laser scan LS
%   intersected by the polyline or polygon object PO. E is a scalar.

% Compute the ray radii of the laser scan intersected with the polyline or
% polygon.
r = ls.xpm(polymap({po}));
iret = isfinite(r);

% Compute the squared radius difference between the measured laser scan and
% the intersected laser scan.
e = sum((ls.radius(iret)-r(iret)).^2);

end

function x = po2x(po, ls)
% PO2X Convert polyline or polygon to state vector.
%   X = PO2X(PO, LS) converts polyline or polygon object PO to the state
%   vector X.
%   
%   X is a column vector. For every vertex in PO with one degree of
%   freedom, X contains one element. It denotes the distance from
%   the laser sensor position to the vertex. For every vertex in PM
%   with two degrees of freedom, X contains two elements. They
%   denote the polar coordinates of the vertex.

% For each map vertex, determine the index of the corresponding laser ray.
[~,ir] = ismembertol(po.vertex, ls.end2cart, 'ByRows', true);

% Compute the vector from the laser sensor to the vertex.
d = po.vertex - ls.start2cart(ir,:);

% Convert the vectors to polar coordinates.
[th,r] = cart2pol(d(:,1), d(:,2));

% Construct the parameter vector.
if isa(po,'polyline') % Polyline.
    x = [r(1); reshape([th(2:end-1), r(2:end-1)]',[],1); r(end)];
else % Polygon.
    x = reshape([th,r]',[],1);
end

end

function po = x2po(x, poinit, ls)
% X2PO Convert state vector to polyline or polygon.
%   PO = X2PO(X, POINIT, LS) converts the state vector X to the polyline or
%   polygon object PO. POINIT is the initial polygon or polyline and serves
%   as a template to parameterize PO. LS is the corresponding laser scan.
%   
%   X is a column vector. For every vertex in PO with one degree of
%   freedom, X contains one element. It denotes the distance from
%   the laser sensor position to the vertex. For every vertex in PM
%   with two degrees of freedom, X contains two elements. They
%   denote the polar coordinates of the vertex.

% For each map vertex, determine the index of the corresponding laser ray.
[~,ir] = ismembertol(poinit.vertex, ls.end2cart, 'ByRows', true);

% Restore vertex coordinates in polar coordinate system.
if isa(poinit,'polyline') % Polyline.
    vpol = [ls.sp(ir(1),3)+ls.azimuth(ir(1)), x(1); 
        reshape(x(2:end-1),2,[])'; 
        ls.sp(ir(end),3)+ls.azimuth(ir(end)), x(end)];
else % Polygon.
    vpol = reshape(x,2,[])';
end

% Convert polar to Cartesian coordinates.
[vx,vy] = pol2cart(vpol(:,1),vpol(:,2));
po = poinit;
po.vertex = ls.start2cart(ir,:) + [vx,vy];

end

function stop = plotprogress(po, ls)
% PLOTPMLS Plot polymap element and laser scan.
%   PLOTPROGRESS(PM, LS) plots the polymap element PO and the laserscan2 
%   object LS.

stop = false; 
ls.plot
hold on
po.plot('LineWidth',1.5,'Color','green')
hold off

end
