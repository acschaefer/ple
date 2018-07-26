classdef polypoint
    % POLYPOINT Object for storing 2-D vertices.
    %   POLYPOINT(V) creates a polypoint object from the vertices V. V is
    %   an Nx2 matrix whose rows contain the vertex coordinates. N is the
    %   number of vertices.
    %
    %   POLYPOINT properties:
    %   VERTEX       - Vertices defining the geometric object
    %   COUNT        - Number of vertices
    %
    %   POLYPOINT methods:
    %   PLOT         - Plot vertices
    %
    %   See also POLYLINE, POLYGON, POLYSHAPE.
    
    % Copyright 2018 Alexander Schaefer
    
    properties
        % VERTEX Vertices defining the geometric object.
        %   NxD matrix, where N is the number of vertices and D is the
        %   number of dimensions of the space. Each row defines a vertex.
        vertex = zeros(0,2)
    end
    
    properties (Dependent)
        % COUNT Number of vertices.
        %   Integer scalar that tells how many vertices define the
        %   geometric object.
        count
    end
    
    methods
        function obj = set.vertex(obj, v)
            % SET.VERTEX Set vertices.
            
            if ~isempty(v)
                validateattributes(v, {'numeric'}, {'real','ncols',2}, ...
                    '', 'V')
            end
            
            obj.vertex = v;
        end
        
        function n = get.count(obj)
            % GET.COUNT Number of vertices.
            
            n = size(obj.vertex,1);
        end

    end
    
    methods
        function obj = polypoint(v)
            % POLY Constructor.
            
            if nargin > 0
                obj.vertex = v;
            end
        end
        
        function plot(obj, varargin)
            % PLOT Plot vertices.
            %   PLOT(OBJ,S) draws markers at the vertex locations of OBJ.
            %
            %   PLOT(OBJ,Name,Value) modifies the appearance of the line
            %   using one or more name-value argument pairs. For a
            %   selection of all supported name-value pairs, see PLOT.
            
            plot(obj.vertex(:,1), obj.vertex(:,2), 'LineStyle', 'none', ...
                'Marker', '.', varargin{:});
        end
    end
end
