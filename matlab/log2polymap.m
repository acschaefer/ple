function pm = log2polymap(file, offset)
% LOG2POLYMAP Convert log file to polymap object.
%   PM = LOG2POLYMAP(FILE, OFFSET) converts the log file FILE in the format
%   implemented by Veeck to a polymap object PM. The polymap consists of a
%   set of polyline objects. The offset is added to all polyline objects.
%   Note that the origin in the log files for a single laser scan is set to
%   [r,r], where r is the configured range of the laser scanner.
%
%   Examples:
%      pm = log2polymap('polylinemap.log', 0)
%      pm = log2polymap(...
%         'pcd/data/lineextract/veeck/lines_realscan072.log', ...
%         laserscan.start2cart(1,:)-30)
%
%   See also CARMENREAD.

% Copyright 2018 Alexander Schaefer
%
% LOG2POLYMAP accepts log files produced by the software accompanying the
% following paper:
% Michael Veeck and Wolfram Burgard. 
% Learning Polyline Maps from Range Scan Data Acquired with Mobile Robots. 
% Proceedings of the IEEE/RSJ International Conference on Intelligent 
% Robots and Systems (IROS), 2004.

%% Validate input.
% Check the input arguments.
validateattributes(file, {'char'}, {'nonempty', 'row'}, '', 'FILE')

% Check if the file exists.
if ~exist(file,'file')
    error(['File ''', file, ''' does not exist.'])
end

%% Open file.
% Open the given file.
fid = fopen(file, 'r');
if fid == -1
    error(['Cannot read ', file, '.'])
end

% Make sure the file is closed upon function termination.
cleaner = onCleanup(@() fclose(fid));

%% Read line segments.
% Create a matrix whose rows will contain the zero-based ordinal number of
% the line segment in the polyline and its vertices.
line = [];

% Read the file line by line. Whenever encountering a line segment, append
% it to the line segments matrix.
text = fgetl(fid);
while ischar(text)
    if ~isempty(text)
        l = textscan(text, '--> Line %f -> %f:%f _ %f:%f', ...
            'CollectOutput', true);
        l = [l{:}];
        if ~isempty(l)
            line = [line; l]; %#ok<AGROW>
        end
    end
    text = fgetl(fid);
end

%% Handle empty file
if isempty(line)
    pm = polymap();
    return
end

%% Add offset
line(:,2:3) = line(:,2:3) + offset;
line(:,4:5) = line(:,4:5) + offset;

%% Create polymap.
% Find out the number of line segments of each polyline.
nv = diff(find([line(:,1);0]==0));

% Convert the line segments matrix to a cell array. Each element of the
% cell array defines one polyline.
c = mat2cell(line, nv);

% Rearrange the data inside the cells so that the rows contain the vertex
% coordinates without duplicates.
c = cellfun(@(x) [x(:,2:3); x(end,4:5)], c, 'UniformOutput', false);

% Convert the cell array to a polymap of polylines.
pm = polymap(cellfun(@polyline, c, 'UniformOutput', false));

end
