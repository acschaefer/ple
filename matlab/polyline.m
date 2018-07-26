classdef polyline < polypoint
    % POLYLINE Object for storing a 2-D polyline.
    %   A polyline is a continuous line composed of one or more line
    %   segments.
    %
    %   PL = POLYLINE(V) creates a polyline object from the vertices V.
    %   V is an Nx2 matrix whose rows contain the vertex coordinates. N is
    %   the number of vertices.
    %
    %   POLYLINE properties:
    %   COUNT        - Number of vertices
    %   LENGTH       - Edge lengths
    %   REGION       - Bounding box of all vertices
    %   SEGMENT      - Line segments
    %   VERTEX       - Polyline vertices
    %
    %   POLYLINE methods:
    %   PLOT         - Plot polyline
    %   RMEDGE       - Remove edge
    %   RMVERTEX     - Remove vertex and connected edges
    %   VISVALINGAM  - Visvalingam's line simplification algorithm
    %
    %   Example:
    %      polyline(rand(10,2))
    %
    %   See also POLYPOINT, POLYGON, POLYSHAPE.
    
    % Copyright 2018 Alexander Schaefer
    
    properties (Dependent)
        % LENGTH Edge lengths.
        %   (N-1)-element column vector that contains the lengths of the
        %   polygon edges, where N is the number of vertices. The i-th
        %   edge connects the vertices i and i+1.
        length
        
        % SEGMENT Line segments.
        %   (N-1)x4 matrix that contains the start and end vertex of each
        %   line segment, where N is the number of vertices. The first two
        %   columns hold the coordinates of the start vertices, the last
        %   two columns hold the coordinates of the end vertices.
        segment
    end
    
    methods
        function l = get.length(obj)
            % GET.LENGTH Get edge lengths.
            
            l = vecnorm(diff(obj.vertex), 2, 2);
        end
        
        function s = get.segment(obj)
            % GET.SEGMENT Get line segments.
            
            s = [obj.vertex(1:end-1,:), obj.vertex(2:end,:)];
        end
    end
       
    methods (Access = public)
        function obj = polyline(varargin)
            % POLYLINE Constructor.
            
            % Call superclass constructor.
            obj@polypoint(varargin{:});
        end
        
        function [obj,idx,err] = visvalingam(obj, varargin)
            % VISVALINGAM Simplify polyline by removing points.
            %   PLS = VISVALINGAM(OBJ) simplifies the polyline OBJ by
            %   removing points from it using Visvalingam's algorithm and
            %   returns the simplified polyline object PLS.
            %
            %   VISVALINGAM(OBJ,Name,Value) configures the algorithm by
            %   specifying additional name-value pairs:
            %      'metric'      - error metric in Visvalingam's algorithm. 
            %                      The error corresponding to the removal
            %                      of a vertex of the polyline is computed
            %                      by forming a triangle of the vertex and
            %                      its two immediate neighbors and by
            %                      applying one of the following metrics:
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
            %                      a step of Visvalingam's line
            %                      simplification algorithm. For more
            %                      details, see algorithm description
            %                      below. Defaults to Inf.
            %      'n'           - minimum number of remaining vertices.
            %                      Defaults to 10.
            %   
            %   [PLS,IDX,ERR] = VISVALINGAM(...) additionally returns two
            %   (M-N)-element column vectors. IDX contains the indices into
            %   the rows of the given polyline that were removed. ERR
            %   contains the error corresponding to the removal of each
            %   index.
            %
            %   Algorithm description:
            %      Visvalingam's algorithm progressively removes points
            %      with the least-perceptible change. To determine which
            %      point removal incurs the smallest visible change, it
            %      computes triangles formed by successive triplets of
            %      points along the line; the point with the smallest error
            %      with respect to an error metric applied to the triangle
            %      is removed. After each removal, the error of the
            %      neighboring triangles is recomputed and the process is
            %      repeated.
            %
            %   Example:
            %      pl = polyline(rand(20,2))
            %      pl.visvalingam
            %
            %   See also REDUCEM.
            
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
                {'scalar', 'real'}, '', '''emax'''));
            parser.addParameter('n', 10, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'scalar', 'integer', 'nonnegative'}, '', '''n'''));
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
            % Create triplets of indices of neighboring points.
            i = (2:obj.count-1)';

            % Determine the coordinates of the triplets.
            t = reshape(obj.vertex(i+[-1,0,+1],:)',6,[])';

            % Compute the error corresponding to the removal of each point.
            e = errfun(t);

            % Determine the point whose removal incurs the smallest error.
            [emin,imin] = min(e);

            % Create the output variables.
            idx = [];
            err = [];

            % Remove the point and recompute the errors of the neighboring
            % points until a stopping criterion is met.
            while ~isempty(e) && e(imin) <= parser.Results.emax ...
                    && size(t,1)+2 > parser.Results.n
                % Add the index of the point to the list.
                idx(end+1) = i(imin); %#ok<AGROW>

                % Store the error incurred by removing the point.
                err(end+1) = emin; %#ok<AGROW>

                % Connect the previous triangle to the next triangle and
                % recompute the error.
                if imin > 1
                    t(imin-1,5:6) = t(imin,5:6);
                    e(imin-1) = errfun(t(imin-1,:));
                end

                % Connect the next triangle to the previous triangle and
                % recompute the error.
                if imin < numel(i)
                    t(imin+1,1:2) = t(imin,1:2);
                    e(imin+1) = errfun(t(imin+1,:));
                end

                % Invalidate the removed point.
                i(imin) = [];
                t(imin,:) = [];
                e(imin) = [];

                % Determine the point whose removal incurs the smallest
                % error.
                [emin,imin] = min(e);
            end
            
            % If the number of desired vertices is smaller than two, reduce
            % the line to a point or delete it.
            if parser.Results.n < 2
                idxappend = [obj.count, 1];
                idx = [idx, idxappend(1:2-parser.Results.n)];
                err(end+(1:2-parser.Results.n)) = 0;
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

            % Plot the polyline.
            line(obj.vertex(:,1), obj.vertex(:,2), varargin{:});
        end
        
        function pm  = rmedge(obj, i)
            % RMEDGE Remove edge
            %   PM = RMEDGE(OBJ, I) removes the edges indicated by the
            %   index vector I from the polyline object OBJ and returns a
            %   polymap object PM that contains the resulting polylines.
            %
            %   The index I can either be a matrix of linear indices or
            %   a vector of logical indices. The i-th edge is the edge that
            %   connects vertices i and i+1.
            
            %% Validate input.
            % Check whether the index matrix has the correct type and size.
            if islogical(i)
                validateattributes(i, {'logical'}, ...
                    {'numel', obj.count-1}, '', 'I')
                
                % Convert logical to linear indices.
                i = find(i(:));
            else
                validateattributes(i, {'numeric'}, ...
                    {'integer', 'positive', '<=', obj.count-1}, '', 'I')
                        
                % Make sure the indices are ordered.
                i = unique(i(:));
            end
            
            %% Remove edges.
            % Determine the start and end indices of the resulting
            % polylines.
            iline = [[1; i+1], [i; obj.count]];
            
            % Remove the indices of empty polylines.
            iline(diff(iline,1,2)<1,:) = [];
            
            % Create a polymap that contains the polylines.
            pm = polymap(cellfun(@(i) polyline(obj.vertex(i(1):i(2),:)),...
                num2cell(iline,2), 'UniformOutput', false));
        end
        
        function pm = rmvertex(obj, i)
            % RMVERTEX Remove vertex and connected edges.
            %   PM = RMVERTEX(OBJ, I) removes the polyline vertices
            %   indicated by the index I and the edges that are connected
            %   to these vertices. It returns a polymap PM that contains
            %   the resulting polyline objects.
            %
            %   The index I can either be a matrix of linear indices of a
            %   vector of logical indices.

            %% Validate input.
            % Check whether the index matrix has the correct type and size.
            if islogical(i)
                validateattributes(i, {'logical'}, ...
                    {'numel', obj.count}, '', 'I')
                
                % Convert logical to linear indices.
                i = find(i(:));
            else
                validateattributes(i, {'numeric'}, ...
                    {'integer', 'positive', '<=', obj.count}, '', 'I')
                        
                % Make sure the indices are ordered.
                i = unique(i(:));
            end
            
            %% Remove vertices.
            % Remove the edges before and after the given vertices.
            pm = obj.rmedge(constrain(i(:)+repmat([-1,0],numel(i),1), ...
                [1,obj.count-1]));
        end
    end
end
