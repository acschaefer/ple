function [odo,ls] = carmenread(file)
% CARMENREAD Read Carmen log file.
%   [ODO,LS] = CARMENREAD(FILE) parses the Carmen log file FILE and returns
%   the robot odometry ODO and the laser scan data LS.
%
%   FILE is the full path to a Carmen logfile. If the file is compressed,
%   CARMENREAD uncompresses it automatically.
%
%   ODO is a timeseries object that contains the robot odometry data.
%   ODO.DATA is an Nx3 matrix, where N is the number of odometry
%   measurements in the log file. ODO.DATA(n,:) specifies the n-th odometry
%   reading in [x,y,yaw]. Yaw is the counterclockwise angle measured from
%   the positive x-axis in radians. ODO.TIME(n) contains the IPC timestamp
%   of the n-th reading.
%
%   LS is a vector of laserscan2 objects. Each laser scan in FILE is
%   converted to an individual laserscan2 object.
%
%   For more information on the Carmen format, see
%   http://carmen.sourceforge.net/home.html.
%
%   Example:
%      [odo,ls] = carmenread('seattle-corrected.log.gz')
%      odoplot(odo.data)
%      scatter(lsconcat(ls), '.')
%
%   See also PCDREAD, INTERPODO, LASERSCAN2.

% Copyright 2016-2018 Alexander Schaefer

%% Register cleanup method.
cleaner = onCleanup(@() cleanup);
    function cleanup
        % CLEANUP Closes open files and removes temporary folders.

        % Close opened files.
        if exist('fid', 'var') == 1
            fclose(fid);
        end

        % Remove temporary folders.
        if exist('gzfolder', 'dir') == 7
            rmdir(gzfolder);
        end
        if exist('tarfolder', 'dir') == 7
            rmdir(tarfolder);
        end
    end

%% Validate input.
% Check the input arguments.
validateattributes(file, {'char'}, {'nonempty', 'row'}, '', 'FILE')

% Check if the file exists.
if ~exist(file,'file')
    error(['File ''', file, ''' does not exist.'])
end

%% Uncompress file.
% If the file is a GNU zip file, uncompress it.
[~,~,ext] = fileparts(file);
if strcmpi(ext, '.gz')
    % Store the uncompressed file in a temporary folder.
    gzfolder = tempname;
    mkdir(gzfolder);
    file = gunzip(file, gzfolder);
    file = file{1};
end

% If the file is a tar archive, uncompress it.
[~,~,ext] = fileparts(file);
if strcmpi(ext, '.tar')
    % Store the uncompressed file in a temporary folder.
    tarfolder = tempname;
    mkdir(tarfolder);
    file = untar(file, tarfolder);
    file = file{1};
end

%% Open file.
[fid,msg] = fopen(file);
if fid == -1
    error(['Failed to open file ''', file, ''': ', msg, '.'])
end

%% Read parameters.
% Set angular resolution and maximum range parameters to default values.
res = [];
rmax = 50;

% Parse parameters to find angular resolution and maximum range.
line = fgetl(fid);
while ischar(line)
    if startsWith(line, 'PARAM')
        data = textscan(line, '%*s %s %f', 1);
        switch lower(data{1}{1})
            case 'laser_front_laser_resolution'
                res = data{2};
            case 'robot_front_laser_max'
                rmax = data{2};
        end
    end
    line = fgetl(fid);
end

%% Read odometry.
% Read all odometry measurements.
ododata = [];
frewind(fid);
line = fgetl(fid);
while ischar(line)
    if startsWith(line, 'ODOM')
        data = textscan(line, '%*s %f %f %f %*f %*f %*f %f %*s %*f');
        ododata = [ododata; data{1:4}]; %#ok<AGROW>
    end
    line = fgetl(fid);
end

% Create a timeseries object that contains the odometry data.
if isempty(ododata)
    odo = timeseries([], [], 'Name', 'odometry');
else
    odo = timeseries(ododata(:,1:3), ododata(:,4), 'Name', 'odometry');
end
odo = odo.setinterpmethod(@(tq,t,data) interpodo(t,data',tq)'); 

%% Read lidar data.
% Create an empty array of laserscan2 objects.
ls = laserscan2.empty(1,0);

% Read all laser scans in the log file.
frewind(fid);
line = fgetl(fid);
while ischar(line)
    if startsWith(line, {'FLASER','RLASER'})
        % Read the number of range measurements.
        [nray,p] = textscan(line, '%*s %f', 1);
        nray = nray{1};
        fp = 1 + p;
        
        % Read the range measurements.
        [radius,p] = textscan(line(fp:end), '%f', nray);
        fp = fp + p;
        
        % Read the sensor poses.
        pos = textscan(line(fp:end), '%f', 3);
        pos = repmat(pos{1}', nray, 1);
        
        % Create a vector that contains the azimuth angles of the
        % measurements.
        if nray == 1
            azimuth = 0;
        else
            % Define the field of view of the laser scanner.
            if isempty(res)
                fov = pi;
            else
                fov = deg2rad(res) * (nray-1);
            end
            
            azimuth = linspace(-fov/2, fov/2, nray)';
        end
        
        % Create the laserscan2 object.
        ls(end+1) = laserscan2(pos, azimuth, radius{1}); %#ok<AGROW>
        ls(end).rlim(2) = rmax;
    elseif startsWith(line, {'ROBOTLASER','RAWLASER'})
        % Read the scan parameters.
        [param,p] = textscan(line, '%*s %*d %f %f %f %f %*f %*d %f', 1);
        param = cell2struct(param, ...
            {'start', 'fov', 'res', 'rmax', 'nray'}, 2);
        fp = 1 + p;
        
        % Read the range measurements.
        [radius,p] = textscan(line(fp:end), '%f ', param.nray);
        fp = fp + p;
        
        % Get the sensor poses.
        if startsWith(line, 'ROBOTLASER')
            % Read the sensor position from file. 
            pos = textscan(line(fp:end), '%f', 3);
            pos = repmat(pos{1}', param.nray, 1);
        else % RAWLASER format
            % Parse the remission values.
            [n,p] = textscan(line(fp:end), '%d', 1);
            fp = fp + p;
            [~,p] = textscan(line(fp:end), '%*f', n{1});
            fp = fp + p;
            
            % Read the timestamp.
            t = textscan(line(fp:end), '%f');
            
            % Interpolate odometry to get sensor position.
            pos = repmat(odo.resample(t{1}).Data, param.nray, 1);
        end
        
        % Create a vector that contains the azimuth angles of the
        % measurements.
        azimuth = linspace(param.start, ...
            param.start + param.res*param.nray, param.nray);
        
        % Create the laserscan2 object.
        ls(end+1) = laserscan2(pos, azimuth, radius{1}); %#ok<AGROW>
        ls(end).rlim(2) = param.rmax;       
    end
    
    % Read next line.
    line = fgetl(fid);
end

end
