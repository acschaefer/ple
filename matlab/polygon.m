classdef polygon < polypoint
    % POLYGON Object for storing a 2-D polygon.
    %   PG = POLYGON(V) creates an polygon object from the vertices V.
    %   V is an Nx2 matrix whose rows contain the coordinates of the
    %   vertices. N is the number of vertices.
    %
    %   POLYGON properties:
    %   COUNT        - Number of vertices
    %   LENGTH       - Edge lengths
    %   REGION       - Bounding box of all vertices
    %   SEGMENT      - Line segments
    %   VERTEX       - Polygon vertices
    %
    %   POLYGON methods:
    %   AREA         - Polygon area
    %   PLOT         - Plot polygon
    %   RAND         - Generate random polygon
    %   RMEDGE       - Remove edge
    %   RMVERTEX     - Remove vertex and connected edges
    %   SPLIT        - Split polygon at index
    %   VISVALINGAM  - Simplify polygon using Visvalingam's algorithm
    %
    %   Example:
    %      polygon([5,6; 8,7; 4,1])
    %
    %   See also POLYPOINT, POLYLINE, POLYSHAPE.
    
    % Copyright 2017-2018 Alexander Schaefer, Daniel Buescher
    
    properties (Dependent)
        % LENGTH Edge lengths.
        %   N-element column vector that contains the lengths of the
        %   polygon edges, where N is the number of vertices. The i-th
        %   edge connects vertices i and i+1.
        length
        
        % SEGMENT Line segments.
        %   Nx4 matrix that contains the start and end vertex of each line
        %   segment, where N is the number of vertices. The first two
        %   columns hold the coordinates of the start vertices, the last
        %   two columns hold the coordinates of the end vertices.
        segment
    end
    
    methods
        function l = get.length(obj)
            % GET.LENGTH Get edge lengths.
            
            l = vecnorm(diff(obj.vertex([1:end,1],:)), 2, 2);
        end
        
        function s = get.segment(obj)
            % GET.SEGMENT Get line segments.
            
            s = [obj.vertex, circshift(obj.vertex,-1)];
        end
    end
    
    methods (Access = protected)
        function y = checkidx(obj, x)
            % CHECKIDX Check vertex or edge index index.
            %   Y = CHECKIDX(X) verifies the given logical or linear index
            %   matrix X and returns the corresponding column vector of
            %   linear vertex indices Y.
            
            % Convert the given logical or linear index matrix to a column
            % vector of linear indices.
            if islogical(x)
                validateattributes(x, {'logical'}, ...
                    {'numel', obj.count}, '', 'VI')
                
                % Convert logical to linear indices.
                y = find(x(:));
            else
                validateattributes(x, {'numeric'}, ...
                    {'integer', 'positive', '<=', obj.count}, '', 'VI')
                        
                % Make sure the indices are ordered.
                y = unique(x(:));
            end
        end
    end
    
    methods (Access = public)
        function obj = polygon(varargin)
            % POLYGON Constructor.
            
            % Call superclass constructor.
            obj@polypoint(varargin{:});
        end
        
        function a = area(obj)
            % AREA Calculate area of the polygon.
            
            a = polyarea(obj.vertex(:,1), obj.vertex(:,2));
        end
        
        function [obj,idx,err] = visvalingam(obj, varargin)
            % VISVALINGAM Simplify polygons by removing points.
            %   VISVALINGAM(OBJ) simplifies the polygon map OBJ by removing
            %   points from it using Visvalingam's algorithm.
            %
            %   VISVALINGAM(OBJ,Name,Value) configures the algorithm by
            %   specifying additional name-value pairs:
            %      'metric'      - error metric in Visvalingam's algorithm. 
            %                      The error corresponding to the removal
            %                      of a vertex of PG is computed by forming
            %                      a triangle of the vertex and its two
            %                      immediate neighbors and by applying one
            %                      of the following metrics: 
            %                      'area'     triangle area 
            %                      'alt'      altitude from the side 
            %                                 corresponding to the 
            %                                 simplified contour
            %                      'length'   length difference between the 
            %                                 side of the triangle that 
            %                                 corresponds to the simplified 
            %                                 contour and the two others
            %                      Defaults to 'area'.
            %      'emax'        - maximum admissible incremental error in
            %                      a step of Visvalingam's algorithm. For
            %                      more details, see algorithm description
            %                      below. Defaults to Inf.
            %      'n'           - minimum number of remaining vertices.
            %                      Defaults to 10.
            %
            %   [PGS,IDX,ERR] = PGVISVALINGAM(...) additionally returns two
            %   cell arrays. IDX contains for each polygon in the map the
            %   indices of the polygon that were removed. ERR contains the
            %   error corresponding to the removal of each vertex.
            %
            %   Algorithm description:
            %      Visvalingam's algorithm progressively removes points
            %      with the least-perceptible change. To determine which
            %      point removal incurs the smallest visible change, it
            %      computes triangles formed by successive triplets of
            %      points along the polygon; the point with the smallest
            %      error with respect to an error metric applied to the
            %      triangle is removed. After each removal, the error of
            %      the neighboring triangles is recomputed and the process
            %      is repeated.
            %
            %   Example:
            %      pg = polygon.rand
            %      pg.visvalingam
            
            % VISVALINGAM is an extension of Visvalingam's original line
            % simplification algorithm: 
            % M. Visvalingam and J. D. Whyatt.
            % Line generalisation by repeated elimination of points. 
            % The Cartographic Journal, vol. 30, pp. 46-51, 1993.
            
            %% Parse name-value pairs.
            parser = inputParser;
            parser.addParameter('metric', 'area', ...
                @(x) any(validatestring(x, {'area','alt','length'})));
            parser.addParameter('emax', Inf, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'scalar', 'real', 'nonnegative'}, ...
                '', '''emax'''));
            parser.addParameter('n', 10, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'scalar', 'integer', 'nonnegative'}, ...
                '', '''minVertices'''));
            parser.parse(varargin{:});

            % Define the error metric.
            switch parser.Results.metric
                case 'area'
                    errfun = @triarea;
                case 'alt'
                    errfun = @(x) sum([0,0,1].*trialt(x),2);
                case 'length'
                    errfun = @(x) sum([1,1,-1].*trilen(x),2);
            end

            %% Remove points.
            % Determine triplets of indices of neighboring vertices.
            i = (1:obj.count)';

            % Determine the coordinates of the triplets.
            t = reshape(obj.vertex(wrap(i+[-1,0,+1],obj.count)',:)',6,[])';

            % Compute the error corresponding to the removal of each
            % vertex.
            e = errfun(t);

            % Determine the vertex whose removal incurs the smallest error.
            [emin,imin] = min(e);

            % Create the output variables.
            idx = [];
            err = [];

            % Remove the vertex and recompute the errors of the neighboring
            % vertices until a stopping criterion is met.
            while size(t,1) > parser.Results.n ...
                    && emin <= parser.Results.emax
                % Add the index of the vertex to the list.
                idx(end+1) = i(imin); %#ok<AGROW>

                % Store the error incurred by removing the vertex.
                err(end+1) = e(imin); %#ok<AGROW>

                % Connect the previous triangle to the next triangle and
                % recompute the error.
                iprev = wrap(imin-1,numel(i));
                t(iprev,5:6) = t(imin,5:6);
                e(iprev) = errfun(t(iprev,:));

                % Connect the next triangle to the previous triangle and
                % recompute the error.
                inext = wrap(imin+1,numel(i));
                t(inext,1:2) = t(imin,1:2);
                e(inext) = errfun(t(inext,:));

                % Remove the vertex.
                i(imin,:) = [];
                t(imin,:) = [];
                e(imin) = [];

                % Determine the vertex whose removal incurs the smallest
                % error.
                [emin,imin] = min(e);
            end

            % Convert the output vectors to column vectors.
            idx = idx(:);
            err = err(:);

            % Simplify the input line.
            obj.vertex = obj.vertex(~ismember(1:obj.count,idx),:);
        end
        
        function plot(obj, varargin)
            % PLOT Plot map.
            %   PLOT(OBJ) plots the polygons the polygonmap object OBJ
            %   consists of.
            %
            %   PLOT(OBJ,Name,Value) modifies the appearance of the line
            %   using one or more name-value argument pairs. For a
            %   selection of all supported name-value pairs, see LINE.
            
            % Clear the current figure if it is not on hold.
            if ~ishold
                newplot
            end

            % Plot the polygon.
            line(obj.vertex([1:end,1],1), obj.vertex([1:end,1],2), ...
                varargin{:});
        end
        
        function pm = split(obj, i)
            % SPLIT Split polygon at index.
            %   PM = SPLIT(OBJ, I) splits the polygon at the vertices
            %   indicated by the index I and returns a polymap object PM
            %   that contains the corresponding polyline objects.
            %
            %   The index I can either be a matrix of linear indices or
            %   a vector of logical indices. 
            
            % Validate input.
            i = obj.checkidx(i);
            
            % Split polygon.
            switch numel(i)
                case 0 % Empty index.
                    % Return a polymap that contain the original polygon.
                    pm = polymap({obj});
                case 1 % One index given.
                    % Create a polyline that ends where it starts.
                    pm = polymap({polyline(...
                        obj.vertex(wrap(i:i+obj.count,obj.count),:))});
                otherwise % Multiple indices given.
                    % Create a polymap object that contains multiple
                    % polylines.
                    pm = polymap(cellfun(@(i,j) ...
                        polyline(obj.vertex(colonn(i,j,obj.count),:)), ...
                        num2cell(i), num2cell(circshift(i,-1)), ...
                        'UniformOutput', false));
            end
        end
        
        function pm = rmedge(obj, i)
            % RMEDGE Remove edge.
            %   PM = RMEDGE(OBJ, I) removes the edges indicated by the
            %   index I and returns the polymap PM that contains the
            %   resulting polyline objects.
            %
            %   The index I can either be a matrix of linear indices of a
            %   vector of logical indices. The i-th edge is the edge that
            %   connects vertices i and i+1.
            
            % If the index matrix is empty, return the original polygon.
            if isempty(i) || ~any(i(:))
                pm = polymap({obj});
            else
                % Split the polygon at the vertices where the edges which
                % shall be removed begin.
                pl = obj.split(i).element;

                % Remove the first vertex of every resulting polyline.
                pm = polymap;
                for pli = horzcat(pl{:})
                    ple = pli.rmvertex(1).element;
                    if ~isempty(ple)
                        pm.element = [pm.element, ple];
                    end
                end
            end
        end
        
        function pm = rmvertex(obj, i)
            % RMVERTEX Remove vertex and connected edges.
            %   PM = RMVERTEX(OBJ, I) removes the polygon vertices
            %   indicated by the index I and the edges that are connected
            %   to these vertices. It returns a polymap PM that contains
            %   the resulting polyline objects.
            %
            %   The index I can either be a matrix of linear indices of a
            %   vector of logical indices.
            
            % Validate input.
            i = obj.checkidx(i);
            
            % Remove the edges before and after the given vertices.
            pm = obj.rmedge(wrap(i(:)+repmat([-1,0],numel(i),1), ...
                obj.count));
        end
        
    end
    
    methods (Static)
        function pg = rand(c, s)
            % RAND Generate random polygon.
            %   PG = RAND generates a polygon PG with center [0,0] and
            %   scale 1.
            %
            %   PG = RAND(C, S) additionally specifies the center C and the
            %   scale S.
            %
            %   The generation works as follows: First, the number of
            %   polygon edges is chosen at random. Then, for each edge, a
            %   ray is drawn from the center C. The angles between the rays
            %   are uniformly distributed. The lengths of the rays are
            %   sampled from a Poisson distribution scaled by the scaling
            %   factor S. The end of a ray constitutes a vertex of the
            %   polygon.
            
            %% Validate input.
            if nargin < 2
                s = 1;
            else
                validateattributes(s, {'numeric'}, ...
                    {'real','finite','scalar','positive'}, '', 'S')
            end
            if nargin < 1
                c = [0,0];
            else
                validateattributes(c, {'numeric'}, ...
                    {'real','finite','numel',2}, '', 'C')
            end
            
            %% Generate polygon.
            % Define the possible numbers of polygon vertices.
            n = [3, 4, 5, 6, 12, 36, 180];
            
            % Sample a number of vertices.
            n = datasample(n,1);
            
            % Define the ray angles.
            a = rand + linspace(0, 2*pi*(1-1/n), n)';
            
            % Define the radii.
            lambda = n^2 / 5;
            r = s * (poissrnd(lambda,n,1)+1) / (lambda+1);
            
            % Create the polygon.
            [x,y] = pol2cart(a,r);
            pg = polygon(c(:)' + [x,y]);
        end
    end
end
