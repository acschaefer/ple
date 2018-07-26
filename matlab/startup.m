% Add the folders of the repository to the MATLAB search path.
matlabdir = fileparts(mfilename('fullpath'));
addpath(fullfile(matlabdir, '.'))
addpath(fullfile(matlabdir, '..', 'data', 'carmen'))
outputdir = fullfile(matlabdir, '..', 'output');
if exist(outputdir,'dir')
    addpath(fullfile(matlabdir, '..', 'output'))
end
addpath(fullfile(matlabdir, 'script'))

% Clear all created variables.
clear 'matlabdir'
