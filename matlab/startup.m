% Add the folders of the repository to the MATLAB search path.
matlabdir = fileparts(mfilename('fullpath'));
addpath(fullfile(matlabdir, '.'))
addpath(fullfile(matlabdir, '..', 'data', 'carmen'))
addpath(fullfile(matlabdir, '..', 'output'))
addpath(fullfile(matlabdir, 'script'))

% Clear all created variables.
clear 'matlabdir'
