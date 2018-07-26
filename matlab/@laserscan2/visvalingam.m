function pm = visvalingam(obj, varargin)
% VISVALINGAM Extract lines from endpoints via Visvalingam's algorithm.
%   PM = VISVALINGAM(OBJ) extracts a polymap PM from the endpoints of the
%   laser scan OBJ. PM can either contain a polygon or a set of polylines.
%   The lines are extracted using Visvalingam's line simplification
%   algorithm.
%
%   The algorithm first connects all pairs of neighboring scan endpoints,
%   except for pairs that contain at least one no-return ray or pairs whose
%   points lie farther apart than a given parameter LMAX. Visvalingam's
%   algorithm then simplifies this initial map by iteratively removing the
%   vertex that incurs the least error under a given error metric and
%   connecting the two neighboring vertices.
%
%   The algorithm can be configured by calling
%   VISVALINGAM(OBJ,'Name','Value') with the following name-value pair
%   arguments:
%      'lmax'        - maximum admissible distance between neighboring
%                      endpoints of the initial polygon. All edges that
%                      exceed this distance are discarded. 
%                      Defaults to Inf.
%      'errorMetric' - error metric in Visvalingam's algorithm. The error 
%                      corresponding to the removal of a vertex of the
%                      polyline is computed by forming a triangle of the
%                      vertex and its two immediate neighbors and by
%                      applying one of the following metrics: 
%                      'area'     triangle area 
%                      'alt'      altitude from the side corresponding to 
%                                 the simplified contour
%                      'length'   length difference between the side of the 
%                                 triangle that corresponds to the 
%                                 simplified contour and the two others
%                      Defaults to 'area'.
%      'emax'        - maximum admissible incremental error in a step of
%                      Visvalingam's line simplification algorithm. 
%                      Defaults to Inf.
%      'n'           - minimum number of remaining vertices.
%                      Defaults to 10.
%
%   Example:
%      [~,ls] = carmenread('intel-corrected.log.gz')
%      ls(1).visvalingam

% Copyright 2018 Alexander Schaefer

%% Validate input.
parser = inputParser;
parser.addParameter('lmax', Inf, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'real', 'nonnegative', 'scalar'}, '', '''lmax'''))
parser.addParameter('n', 10, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'integer', 'scalar', '>=', 2}, '', '''n'''))
parser.addParameter('emax', Inf, ...
    @(x) validateattributes(x, {'numeric'}, ...
    {'scalar', 'real', 'nonnegative'}, ...
    '', '''emax'''));
parser.addParameter('metric', 'area');
parser.parse(varargin{:});

%% Remove invalid vertices and edges.
% Create a polygon consisting of the laser scan endpoints.
pg = polygon(obj.end2cart);

% Remove the vertices that correspond to no-return rays.
pmret = pg.rmvertex(~obj.ret);

% Remove overlength edges.
pm = polymap;
for pmi = horzcat(pmret.element{:})
    pm.element = [pm.element;
        pmi.rmedge(pmi.length>parser.Results.lmax).element];
end

%% Visvalingam's algorithm.
% For all vertices of all map elements, compute the errors corresponding to
% their removal.
e = [];
for i = 1 : pm.count
    [~,idx,err] = pm.element{i}.visvalingam('n', 0, 'emax', Inf, ...
        'metric', parser.Results.metric);
    e = [e; err,cumsum(err),repmat(i,size(idx)),idx]; %#ok<AGROW>
end

% Order the errors corresponding to the removal of the vertices of the
% different map elements.
e = sortrows(e,2);

% Determine how many map vertices are to remove.
nrm = size(pm.vertex,1) ...
    - min([parser.Results.n, find(e(:,1)>parser.Results.emax,1)]);

% Determine which vertices to remove.
e = e(1:nrm,:);

% For every map element, determine which vertices to remove.
e = sortrows(e,3);

% Remove vertices.
for i = 1 : max(e(:,3))
    pm.element{i}.vertex(e(e(:,3)==i,4),:) = [];
end

% Remove empty map elements.
empty = cellfun(@(po) po.count<2, pm.element);
pm.element(empty) = [];

end
