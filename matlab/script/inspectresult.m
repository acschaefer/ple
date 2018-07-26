function inspectresult(dataset,scan,algorithm,parameter)
% INSPECTRESULT Visualize result of line extraction.
%   INSPECTRESULT(DATASET,SCAN,ALGORITHM,PARAMETER) visualizes the result
%   of the line extraction of the dataset indexed by DATASET, the scan
%   indexed by SCAN, the method indexed by ALGORITHM, and the parameter
%   indexed by PARAMETER.

% Load dataset.
data = load(fullfile('..','output','dataset.mat'));
ls = data.ls;
datasetname = data.datasetname;

% Load extracted lines.
pmdata = load(fullfile('..','output','extrlin.mat'));
pm = pmdata.pm;
algorithmname = pmdata.algorithmname;
n = pmdata.n;

% Plot original laser scan.
ls(dataset,scan).plot
hold on

% Plot extracted lines.
pm(dataset,scan,algorithm,parameter).plot('LineWidth',2,'Color','green')
hold off

% Add figure title.
title(['Dataset: ', datasetname{dataset}, ...
    ', algorithm: ', algorithmname{algorithm}, ...
    ', scan: ', num2str(scan), ...
    ', parameter: n=', num2str(n(parameter))])

end
