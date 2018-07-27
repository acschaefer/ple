function gendata
% GENDATA Create datasets to evaluate line extraction from laser scan.

%% Set parameters.
% Make random number generation predictable.
rng(0)

% Set number of extracted scans per log file.
nsc = 20;

% Generate initial laser scan for simulation.
lsinit = laserscan2([0,0,0], deg2rad(linspace(-180,180,360)), 1);

% Define standard deviations of measurement noise in simulation.
sr = 0.03;
sa = deg2rad(0.2);

% Define directory where to write the extracted log files.
outdir = 'output';

% Define the names of the datasets.
datasetname = {'real','sim'}; %#ok<NASGU>

% Create the output directory.
[errorcode,msg] = mkdir(outdir);
if errorcode < 1
    error(['Failed to create output directory ''', outdir, ''': ', msg])
end

%% Create real-world dataset.
% Find all available Carmen log files.
wb = waitbar(0, 'Creating real-world dataset ...', 'Name', mfilename);
wbcleaner = onCleanup(@() close(wb));
file = dir(fullfile('..','data','carmen'));
datafile = {};
for i = 1 : numel(file)
    if endsWith(file(i).name,'-corrected.log.gz')
        datafile{end+1} = file(i).name; %#ok<AGROW>
    end
end
ndf = numel(datafile);

% Read the log files and extract a subset of laser scans.
lsreal = laserscan2.empty(0,1);
for i = 1 : ndf
    [~,lsi] = carmenread(datafile{i});
    lsreal = [lsreal, lsi(randsample(numel(lsi),nsc))]; %#ok<AGROW>
    waitbar(i/ndf, wb);
end

%% Create simulated dataset.
% Simulate laser scans from random polygons.
waitbar(0, wb, 'Creating simulated dataset ...');
pg = polygon.empty(0,1);
lssim = laserscan2.empty(0,1);
for i = 1 : nsc*ndf
    % Generate random polygon.
    pg(i) = polygon.rand([0,0],5+rand*5);

    % Simulate lidar data.
    lssim = [lssim, polymap({pg(i)}).samplels(lsinit,sr,sa)]; %#ok<AGROW>
    waitbar(i/(nsc*ndf), wb);
end
ls = [lsreal; lssim]; %#ok<NASGU>

%% Write datasets.
% Write the laser scans to a MAT file.
save(fullfile(outdir,'dataset.mat'), 'ls', 'pg', 'datasetname');

end
