% Add the folders of the repository to the MATLAB search path.
matlabdir = fileparts(mfilename('fullpath'));
addpath(fullfile(matlabdir, '.'))
addpath(fullfile(matlabdir, '..', 'data', 'carmen'))
outdir = fullfile(matlabdir, 'output');
if exist(outdir,'dir')
    addpath(outdir)
end
addpath(fullfile(matlabdir, 'script'))

% Clear all created variables.
clear 'matlabdir'
