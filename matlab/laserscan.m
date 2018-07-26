classdef laserscan < matlab.mixin.Copyable
    % LASERSCAN Interface handle class for 2-D and 3-D laser scans.
    %
    %   This documentation mentions two coordinate frames. The sensor
    %   coordinate frame is attached to the casing of the laser scanner and
    %   is moving in space. The global coordinate frame is an external
    %   reference system in which the laser scanner moves. This can be the
    %   base link of a robot, for example, or some georeferenced point in
    %   space.
    %
    %   LASERSCAN properties:
    %   AZIMUTH    - Azimuth angles [rad] in sensor frame  
    %   COUNT      - Number of rays
    %   DIR2CART   - Cartesian ray direction vectors in global frame
    %   END2CART   - Cartesian coordinates of ray endpoints in global frame
    %   RADIUS     - Ray lengths
    %   RET        - Reflection flag
    %   RLIM       - Sensor measurement range
    %   SP         - Sensor poses in global frame
    %   START2CART - Cartesian coordinates of start points in global frame
    %   SUB        - Reflection below range 
    %   SUPER      - Reflection beyond range 
    %
    %   LASERSCAN methods:
    %   PLOT       - Plot laser scan
    %   SCATTER    - Plot endpoints
    %   SELECT     - Select subset of measurements
    %
    %   See also LSREAD.
    
    % Copyright 2016-2018 Alexander Schaefer
    
    properties
        % RLIM Sensor measurement range.
        %   2-element row vector defining the minimum and maximum radius 
        %   the sensor is able to measure. Defaults to [0, Inf].
        rlim = [0, Inf]
    end
    
    properties (Access = protected, Abstract, Hidden)
        % SPDATA Stores sensor poses.
        %   Matrix that contains all sensor poses. If all sensor poses are
        %   equal, SPDATA only specifies one sensor pose.
        spdata
    end
    
    properties (Access = protected, Hidden)     
        % AZIMUTHDATA Stores azimuth angles.
        azimuthdata
        
        % RADIUSDATA Stores ray lengths.
        radiusdata
    end
    
    properties (Access = protected, Hidden, Transient)    
        % ENDDATA Stores Cartesian coordinates of ray endpoints.
        %   This matrix serves as a buffer that stores the current endpoint
        %   data in order to save computational resources. If SPDATA,
        %   RADIUSDATA, or AZIMUTHDATA change, ENDDATA must be invalidated
        %   by setting it to []. The next call to GET.END2CART recomputes
        %   the matrix.
        enddata
        
        % DIRDATA Stores the Cartesian ray direction vectors.
        %   This matrix serves as a buffer that stores the current
        %   direction vector data in order to save computational resources.
        %   If SPDATA or AZIMUTHDATA change, DIRDATA must be invalidated by
        %   setting it to []. The next call to GET.DIR2CART recomputes the
        %   matrix.
        dirdata
    end
    
    properties (Access = public, Dependent)
        % AZIMUTH Azimuth angles [rad] in sensor frame.
        %   N-element vector defining the azimuth angle of the rays with
        %   respect to the sensor frame in [rad]. The azimuth angle is the
        %   counterclockwise angle in the x-y plane measured from the
        %   positive x axis. N is the number of measured rays.
        azimuth
        
        % RADIUS Ray lengths.
        %   N-element vector defining the length of the rays originating
        %   from the laser sensor. N is the number of measured rays. NaN
        %   values identify no-return rays.
        radius
        
        % COUNT Number of rays.
        %   Integer scalar.
        count
        
        % RET Reflection flag.
        %   N-element logical column vector, where N is the number of rays.
        %   All true elements correspond to rays whose radius is in 
        %   [RLIM(1), RLIM(2)].
        ret
        
        % SUB Reflection below sensor range.
        %   N-element logical column vector, where N is the number of rays.
        %   All true elements correspond to rays whose radius falls below
        %   RLIM(1).
        sub
        
        % SUPER Reflection beyond sensor range.
        %   N-element logical column vector, where N is the number of rays.
        %   All true elements correspond to rays whose radius exceeds
        %   RLIM(2).
        super
    end
    
    properties (Access = public, Abstract, Dependent)      
        % SP Sensor poses in global frame.
        sp
        
        % START2CART Cartesian coordinates of ray start points.
        %   NxD matrix whose n-th row contains the Cartesian coordinates of
        %   the start point of the n-th ray with respect to the global
        %   coordinate frame. D is the number of dimensions of the scan.
        start2cart
        
        % END2CART Cartesian coordinates of ray endpoints.
        %   NxD matrix whose n-th row contains the Cartesian coordinates of
        %   the endpoint of the n-th ray with respect to the global
        %   coordinate frame. D is the number of dimensions of the scan.
        %
        %   The coordinates of no-return rays are set to NaN.        
        end2cart

        % DIR2CART Cartesian ray direction vectors.
        %   NxD matrix whose n-th row contains the normalized Cartesian
        %   direction vectors of the n-th ray with respect to the global
        %   coordinate frame. D is the number of dimensions of the scan.
        dir2cart
    end
        
    methods
        function azimuth = get.azimuth(obj)
            % GET.AZIMUTH Get azimuth angles in sensor frame in [rad].
            
            azimuth = obj.azimuthdata;
        end
            
        function set.azimuth(obj, azimuth)
            % SET.AZIMUTH Set azimuth angles in sensor frame in [rad].
            
            % Validate input.
            validateattributes(azimuth, {'numeric'}, ...
                {'real', 'finite', 'numel', obj.count}, '', 'AZIMUTH')
            
            % Assign new azimuth angles.
            obj.azimuthdata = azimuth(:);
            
            % Invalidate endpoint data and direction vector data.
            obj.enddata = [];
            obj.dirdata = [];
        end
        
        function radius = get.radius(obj)
            % GET.RADIUS Get ray radii.
            
            radius = obj.radiusdata;
        end
        
        function set.radius(obj, radius)
            % SET.RADIUS Set ray radii.
            
            % Validate input.
            validateattributes(radius, {'numeric'}, ...
                {'real', 'numel', obj.count}, '', 'RADIUS')
            
            % Assign new radius data to object.
            obj.radiusdata = radius(:);
            
            % Invalidate endpoint data.
            obj.enddata = [];
        end
        
        function set.rlim(obj, rlim)
            % SET.RLIM Set sensor radius limits.
            
            % Validate input.
            validateattributes(rlim, {'numeric'}, ...
                {'real', 'nonnegative', 'numel', 2, 'increasing'}, ...
                '', 'RLIM')
            
            % Assign new limits.
            obj.rlim = rlim(:)';
        end
        
        function n = get.count(obj)
            % GET.COUNT Get number of rays.
            
            n = numel(obj.azimuth);
        end
        
        function r = get.ret(obj)
            % GET.RET Identify valid returned rays.

            r = obj.radius >= obj.rlim(1) & obj.radius <= obj.rlim(2);
        end
        
        function b = get.sub(obj)
            % GET.SUB Identify rays falling below minimum sensor range.
            
            b = obj.radius < obj.rlim(1);
        end
        
        function b = get.super(obj)
            % GET.SUPER Identify rays exceeding maximum sensor range.
            b = obj.radius > obj.rlim(2);
        end
    end
    
    methods (Access = protected)       
        function i = idxchk(obj, i)
            % IDXCHK Check laser scan ray indices.
            %   I = IDXCHK(OBJ) returns an N-element vector that contains
            %   the indices of all rays of the laserscan object OBJ.
            %
            %   I = IDXCHK(OBJ, I) checks the given indices. If I is valid,
            %   IDXCHK returns I. If not, IDXCHK throws an error.
            
            if nargin < 2 % No I given.
                % Return the indices of all rays.
                i = 1 : obj.count;
            else % I given.
                % Check the data type of I.
                validateattributes(i, {'numeric', 'logical'}, ...
                    {'vector'}, '', 'I')

                % Check the properties of I depending on its data type.
                if islogical(i)
                    if numel(i) > obj.count
                        error('I contains too many elements.')
                    end
                elseif isnumeric(i)
                    validateattributes(i, {'numeric'}, ...
                        {'integer', 'positive', '<=', obj.count}, '', 'I')
                end
            end
        end
    end
    
    methods (Access = public, Abstract)  
        % SELECT Select subset of measurements.
        %   SUB = SELECT(OBJ, I) returns a laserscan object that contains
        %   only the laser measurements indexed by vector I.
        sub = select(obj, i)
        
        % SCATTER Plot laser scan endpoints.
        %   SCATTER(OBJ) displays the locations of the laser scan
        %   endpoints with respect to the global frame. Only returned
        %   rays are drawn.
        obj = scatter(obj)

        % PLOT Plot laser scan.
        %   PLOT(OBJ) visualizes the rays originating from the laser
        %   scanner with respect to the global coordinate frame. Returned
        %   rays are plotted in red. No-return rays are plotted in light
        %   gray with length equal to maximum sensor range.
        plot(obj)
    end
end
