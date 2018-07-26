classdef laserscan2 < laserscan
    % LASERSCAN2 Handle object representing a 2-D laser scan.
    %   L = LASERSCAN2(SP, AZIMUTH, RADIUS, RLIM) creates a 2-D laser scan
    %   object.
    %
    %   This documentation mentions two coordinate frames. The sensor
    %   coordinate frame is attached to the casing of the laser scanner and
    %   is moving in space. The global coordinate frame is an external
    %   reference system in which the laser scanner moves. This can be the
    %   base link of a robot, for example, or some georeferenced point in
    %   space.
    %
    %   SP is an Nx3 matrix, where N is the number of rays of the laser
    %   scan. Its n-th row defines the laser sensor pose with respect to
    %   the global coordinate frame at the moment of the n-th observation.
    %   The columns specify the coordinates [x,y,yaw]. Yaw is the
    %   counterclockwise angle in the x-y plane measured from the positive
    %   x-axis.
    %
    %   AZIMUTH and RADIUS are N-element vectors that contain the polar
    %   coordinates of the rays measured by the laser sensor with respect
    %   to the sensor frame.
    %   AZIMUTH must contain finite angles in [rad].
    %   RADIUS may contain real and infinite values. All RADIUS values 
    %   outside the interval RLIM are interpreted as no-return rays.
    %
    %   RLIM is a 2-element vector that defines the minimum and maximum 
    %   radius that the sensor is able to measure. It defaults to [0, Inf].
    %
    %   LASERSCAN2 properties:
    %   AZIMUTH     - Azimuth angles [rad] in sensor frame 
    %   COUNT       - Number of rays
    %   DIR2CART    - Cartesian ray direction vectors in global frame
    %   END2CART    - Cartesian ray endpoints in global frame
    %   POL2CART    - Polar to Cartesian coordinates in sensor frame
    %   RADIUS      - Ray lengths
    %   RET         - Reflection flag
    %   RLIM        - Sensor measurement range
    %   SP          - Sensor poses in global frame
    %   START2CART  - Cartesian coordinates of start points in global frame
    %   SUB         - Reflection below range 
    %   SUPER       - Reflection beyond range 
    %
    %   LASERSCAN2 methods:
    %   DOWNSAMPLE  - Select measurements at random
    %   EXTRLIN     - Extract lines via maximizing measurement probability
    %   ITEPF       - Extract lines via iterative endpoint fit
    %   PC          - Transform laser scan to point cloud
    %   PCD         - Transform laser scan to point cloud struct
    %   POLYMAP     - Convert to polymap
    %   PLOT        - Plot laser scan
    %   SCATTER     - Plot endpoints
    %   SELECT      - Select subset of measurements
    %   SPLAM       - Extract lines via split and merge
    %   VISVALINGAM - Extract lines via Visvalingam's algorithm
    %   XPM         - Radius to intersection with polymap
    %
    %   See also LASERSCAN3, CARMENREAD.
    
    % Copyright 2016-2018 Alexander Schaefer, Daniel Buescher
    
    properties (Access = protected, Hidden)
        % SPDATA Stores sensor poses.
        %   Matrix that contains all sensor poses. If all sensor poses are
        %   equal, SPDATA only specifies one sensor pose.
        spdata
    end
    
    properties (Dependent)
        % SP Sensor poses in global frame.
        %   Nx3 matrix whose n-th row contains the [x,y,yaw] coordinates of
        %   the laser sensor at the time of the n-th observation with
        %   respect to the global frame. Yaw is the
        %   counterclockwise angle in the x-y plane measured from the
        %   positive x-axis. N is the number of rays.
        sp
       
        % START2CART Cartesian coordinates of ray start points.
        %   Nx2 matrix whose n-th row contains the Cartesian coordinates of
        %   the start point of the n-th ray with respect to the global
        %   coordinate frame.
        start2cart
        
        % END2CART Cartesian coordinates of ray endpoints.
        %   Nx2 matrix whose n-th row contains the Cartesian coordinates of
        %   the endpoint of the n-th ray with respect to the global
        %   coordinate frame.
        %
        %   The coordinates of no-return rays are set to NaN.        
        end2cart

        % DIR2CART Cartesian ray direction vectors.
        %   Nx2 matrix whose n-th row contains the normalized Cartesian
        %   direction vectors of the n-th ray with respect to the global
        %   coordinate frame.
        dir2cart
        
        % POL2CART Polar to Cartesian coordinates.
        %   Nx2 matrix that contains the Cartesian coordinates of the ray
        %   endpoints with respect to the sensor frame at the time the ray
        %   was measured. N is the number of rays.
        pol2cart
    end
    
    methods
        function set.spdata(obj, spdata)
            % SET.SPDATA Set sensor pose data.
            
            % Check if all sensor poses are identical.
            if size(spdata,1) > 1
                % Compute the differences between the sensor poses.
                d = diff(spdata, 1, 1);
            
                % If all sensor poses are identical, merge them to one.
                if all(d(:)==0)
                    spdata = spdata(1,:);
                end
            end
            
            obj.spdata = spdata;
            
            % Invalidate the endpoint data and the direction vector data.
            obj.enddata = [];
            obj.dirdata = [];
        end
        
        function sp = get.sp(obj)
            % GET.SP Get sensor poses in global frame.
            
            n = obj.count/size(obj.spdata,1);
            n(~isfinite(n)) = 0;
            sp = repmat(obj.spdata, n, 1);
        end
        
        function set.sp(obj, sp)
            % SET.SP Set sensor poses in global frame.
            
            % Validate input.
            validateattributes(sp, {'numeric'}, ...
                {'finite', 'real', 'ncols', 3}, '', 'SP')
            if all(size(sp,1) ~= [1,obj.count])
                error('SP must have 1 or %i rows.', obj.count)
            end
            
            obj.spdata = sp;
        end
        
        function c = get.pol2cart(obj)
            % GET.POL2CART Polar to Cartesian coordinates.
            
            [x,y] = pol2cart(obj.azimuth, obj.radius); %#ok<CPROP>
            c = [x,y];
        end
        
        function p = get.start2cart(obj)
            % GET.START2CART Cartesian coordinates of ray start points.

            p = obj.sp(:,1:2);
        end
        
        function p = get.end2cart(obj)
            % GET.END2CART Cartesian coordinates of ray endpoints.
            
            % If the endpoint coordinates have not yet been computed or if
            % they have been invalidated, recompute them.
            if isempty(obj.enddata)
                [x,y] = pol2cart(...
                    obj.spdata(:,3)+obj.azimuth, obj.radius); %#ok<CPROP>
                obj.enddata = obj.spdata(:,1:2) + [x,y];
            end
            
            p = obj.enddata;
        end
        
        function v = get.dir2cart(obj)
            % GET.DIR2CART Cartesian ray direction vectors.
            
            % If the direction vector data have not yet been computed or if
            % they have been invalidated, recompute them.
            if isempty(obj.dir2cart)
                [x,y] = pol2cart(obj.spdata(:,3)+obj.azimuth, 1); ...
                    %#ok<CPROP>
                obj.dirdata = [x,y];
            end
            
            v = obj.dirdata;
        end
    end
    
    methods (Access = public)
        function obj = laserscan2(sp, azimuth, radius, rlim)
            % LASERSCAN2 Constructor.

            %% Validate input.
            % Check the types of the input arguments.
            if isempty(sp)
                validateattributes(sp, {'numeric'}, ...
                    {'real', 'finite'}, '', 'SP')
            else
                validateattributes(sp, {'numeric'}, ...
                    {'real', 'finite', 'ncols', 3}, '', 'SP')
            end
            validateattributes(azimuth, {'numeric'}, ...
                {'real', 'finite'}, '', 'AZIMUTH')
            validateattributes(radius, {'numeric'}, {'real'}, '', 'RADIUS')
            
            % Check the consistency of the input arguments.
            s = unique([size(sp,1), numel(azimuth), numel(radius)]);
            if numel(s) > 1
                % If the input arguments have differing sizes, match them.
                if s(1) == 1 && numel(s) == 2
                    azimuth = repmat(azimuth, s(2)/numel(azimuth), 1);
                    radius = repmat(radius, s(2)/numel(radius), 1);
                else
                    error(['SP, AZIMUTH, and RADIUS ', ...
                        'must contain the same number of measurements.'])
                end
            end
            
            %% Create object.            
            % Save input arguments.
            obj.spdata = sp;
            obj.azimuthdata = azimuth(:);
            obj.radiusdata = radius(:);
            if nargin >= 4
                obj.rlim = rlim(:)';
            end
        end
        
        function sub = select(obj, i)
            % SELECT Select subset of measurements.
            %   SUB = SELECT(OBJ, I) returns a laserscan2 object that
            %   contains only the laser measurement indexed by I.
            
            % Validate input.
            i = obj.idxchk(i);
            
            % Select subset of measurements.
            if size(obj.spdata,1)==1
                isp = sum(i)>0;
            else
                isp = i;
            end
            sub = laserscan2(obj.spdata(isp,:), obj.azimuth(i), ...
                obj.radius(i), obj.rlim);
        end
               
        function pm = polymap(obj)
            % POLYMAP Convert to polymap.
            %   PM = POLYMAP(OBJ) converts the laser scan to the polymap
            %   object PM. PM consists of N polyline objects, where N is
            %   the number of laser rays in the scan. Each line represents
            %   a laser ray.
            
            pm = polymap(cellfun(@(s,e) polyline([s; e]), ...
                num2cell(obj.start2cart,2), num2cell(obj.end2cart,2), ...
                'UniformOutput', false));
        end
    
        function plot(obj, varargin)
            % PLOT Plot laser scan.
            %   PLOT(OBJ) visualizes the rays originating from the laser
            %   scanner with respect to the global frame. Returned rays are
            %   plotted in red. No-return rays are plotted in light gray
            %   with length equal to maximum sensor range.
            %
            %   PLOT(OBJ,'ShowNoReturn',false) does not plot no-return
            %   rays. Defaults to true.
            
            % Parse input.
            parser = inputParser;
            parser.addOptional('ShowNoReturn', true);
            parser.parse(varargin{:});
            
            % Prepare the graphics object.
            h = ishold;
            resethold = onCleanup(@() sethold(h));
            if ~h
                newplot
            end
            hold on
                       
            % Compute coordinates of points to plot.
            sr = [];
            er = [];
            snr = [];
            enr = [];
            for i = 1 : numel(obj)
                % Create laserscan2 objects that contain the returned rays
                % to plot and the no-returns to plot.
                lsr = obj(i).select(obj(i).ret);
                lsnr = obj(i).select(~obj(i).ret);
                lsnr.radius = repmat(obj(i).rlim(2), lsnr.count, 1);

                % Compute plotted ray starting points and endpoints.
                sr = [sr; lsr.start2cart]; %#ok<AGROW>
                er = [er; lsr.end2cart]; %#ok<AGROW>
                snr = [snr; lsnr.start2cart]; %#ok<AGROW>
                enr = [enr; lsnr.end2cart]; %#ok<AGROW>
            end
            
            % Plot no-return rays.
            if parser.Results.ShowNoReturn
                line([snr(:,1),enr(:,1)]', [snr(:,2),enr(:,2)]', ...
                    'Color', [0.3,0.3,0.3]);
            end

            % Plot endpoints of returned rays.
            scatter(er(:,1), er(:,2), 'r.')

            % Plot returned rays.
            line([sr(:,1),er(:,1)]', [sr(:,2),er(:,2)]', 'Color', 'r');

            % Plot starting points of all rays.
            scatter(sr(:,1), sr(:,2), 'ok');
        end
        
        function scatter(obj, varargin)
            % SCATTER Plot laser scan endpoints.
            %   SCATTER(OBJ) displays the locations of the laser scan
            %   endpoints with respect to the global frame. Only returned
            %   rays are drawn.
            %
            %   SCATTER(OBJ,M) uses the marker M instead of 'o'.
            %   SCATTER(OBJ,'filled') fills the markers.
            
            % Prepare the graphics object.
            h = ishold;
            resethold = onCleanup(@() sethold(h));
            if ~h
                newplot
            end
            hold on
            
            % Plot endpoints.
            for i = 1 : numel(obj)
                p = obj(i).end2cart(obj(i).ret,:);
                scatter(p(:,1), p(:,2), varargin{:})
            end
        end
        
        % XPM Ray radii to first intersection point with polymap.
        [r,io,iv] = xpm(obj, pm)

        % EXTRLIN Extract lines via maximizing measurement probability.
        pm = extrlin(obj, varargin)
        
        % ITEPF Extract lines via iterative endpoint fit.
        pm = itepf(obj, varargin)
        
        % SPLAM Extract lines via split and merge.
        pm = splam(obj, varargin)
        
        % VISVALINGAM Extract lines via Visvalingam's algorithm.
        pm = visvalingam(obj, varargin)
    end
end
