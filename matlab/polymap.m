classdef polymap
    % POLYMAP Map consisting of polypoint elements.
    %   PM = POLYMAP creates an empty polymap object.
    %   
    %   PM = POLYMAP(PO) creates a polymap object from the cell array PO.
    %   PO must contain polypoint objects and its derivatives polyline,
    %   polygon only.
    %   
    %   POLYMAP properties:
    %   COUNT        - Number of map elements
    %   ELEMENT      - Cell array of map elements
    %   SEGMENT      - Line segments of all map elements
    %   VERTEX       - Vertices of all map elements
    %   
    %   POLYMAP methods:
    %   PLOT         - Plot map
    %   SAMPLELS     - Sample laser scan from polymap
    %   
    %   Example:
    %      polymap({polypoint(rand(9,2)), polyline(rand(9,2))})
    %   
    %   See also POLYPOINT, POLYLINE, POLYGON, POLYSHAPE.
    
    % Copyright 2017-2018 Alexander Schaefer, Daniel Buescher
    
    properties
        % ELEMENT Map elements.
        %   Cell array of polypoint objects forming the map.
        element = {}
    end
    
    properties (Dependent)
        % COUNT Number of map elements.
        %   Integer scalar that tells how many elements the map consists
        %   of.
        count
        
        % VERTEX Vertices of all elements.
        %   Vx2 matrix whose rows contain the coordinates of the vertices
        %   in the map. V denotes the number of vertices in the map.
        vertex
        
        % SEGMENT Line segments of all elements.
        %   Sx4 matrix that contains the start and end vertex of each line
        %   segment, where S is the number of line segments in the map. The
        %   first two columns hold the coordinates of the start vertices,
        %   the last two columns hold the coordinates of the end vertices.
        segment
    end
    
    methods
        function obj = set.element(obj, po)
            % SET.ELEMENT Set map elements.
            
            % Check input argument type.
            validateattributes(po, {'cell'}, {}, '', 'PO')
            if ~all(cellfun(@(e) isa(e, 'polypoint'), po))
                error(['All elements of a polymap must be derived ', ...
                    'from class polypoint.'])
            end
            
            % Assign input to map elements.
            obj.element = po;
        end
        
        function n = get.count(obj)
            % GET.COUNT Get number of map elements.
            
            n = numel(obj.element);
        end

        function v = get.vertex(obj)
            % GET.VERTEX Get vertices of all map elements.
            
            v = cellfun(@(e) e.vertex, obj.element, ...
                'UniformOutput', false);
            v = vertcat(v{:});
        end
        
        function obj = set.vertex(obj, v)
            % SET.VERTEX Set vertices of all map elements.
            
            % If the vertices are not yet defined, set them.
            % Otherwise, check if the numbers of vertices in the map and
            % given vertices match. If so, set the vertices.
            if isempty(obj.vertex)
                validateattributes(v, {'numeric'}, ...
                    {'real', 'finite', 'ncols', 2}, '', 'V')
            else
                validateattributes(v, {'numeric'}, ...
                    {'real', 'finite', 'size', size(obj.vertex)}, '', 'V')
            
                % Set the vertices of all objects.
                v = mat2cell(v, cellfun(@(po) po.count, obj.element), 2);
                for i = 1 : obj.count
                    obj.element{i}.vertex = v{i};
                end
            end
        end
        
        function s = get.segment(obj)
            % GET.SEGMENT Get line segments of all map elements.
            
            i = cellfun(@(x) isa(x,'polyline') | isa(x,'polygon') ...
                | isa(x,'polymap'), obj.element);
            s = cellfun(@(po) po.segment, obj.element(i), ...
                'UniformOutput', false);
            s = vertcat(s{:});
        end
    end
    
    methods (Access = public)
        function obj = polymap(po)
            % POLYMAP Constructor.
            
            if nargin > 0
                obj.element = po;
            end
        end
        
        function plot(obj, varargin)
            % PLOT Plot map.
            %   PLOT(OBJ) plots the map.
            %
            %   PLOT(OBJ,Name,Value) modifies the appearance of the plot
            %   using one or more name-value argument pairs. For a
            %   selection of all supported name-value pairs, see PLOT.
            
            % Prepare the graphics object.
            h = ishold;
            resethold = onCleanup(@() sethold(h));
            if ~h
                newplot
            end
            hold on
            
            % Plot every map element in a different color.
            color = expnd(get(gca,'ColorOrder'), [obj.count,3]);
            cellfun(@(e,c) e.plot('Color',c,varargin{:}), ...
                obj.element(:), num2cell(color,2));
        end
        
        function ls = samplels(obj, lsinit, sr, sa)
            % SAMPLELS Sample laser scan from polymap.
            %   LS = SAMPLELS(OBJ, LSINIT, SR, SA) simulates the output of
            %   a lidar sensor in a line-shaped environment. To that end,
            %   SAMPLELS takes the polymap object OBJ, the initial
            %   laserscan2 object LSINIT, the standard deviation of the
            %   radial and angular noise SR and SA, and returns a simulated
            %   scan by the laserscan2 object LS. LS contains the same data
            %   as LSINIT, except for the ray radii: Those are sampled.
            
            %% Validate input.
            validateattributes(lsinit, {'laserscan2'}, ...
                {'scalar','nonempty'}, '', 'LSINIT')
            validateattributes(sr, {'numeric'}, ...
                {'real','finite','nonnegative'}, '', 'SR')
            validateattributes(sa, {'numeric'}, ...
                {'real','finite','nonnegative'}, '', 'SA')
            
            %% Sample scan.
            % Sample angles to simulate true azimuth angles.
            lstrue = lsinit.copy;
            lstrue.azimuth = normrnd(lsinit.azimuth,sa);
            
            % Compute true ray radii until intersection with polymap.
            r = lstrue.xpm(obj);
            
            % Sample radii to simulate measured radii.
            ls = lsinit.copy;
            ls.radius = normrnd(r,sr);
        end
    end
end
