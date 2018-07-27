function runexp
% RUNEXP Perform line extraction using different algorithms.

%% Set parameters.
% Set maximum number of vertices.
n = [10,20,30,40,50];

% Define the algorithms to use for line extraction.
algorithmname = {'visvalingam','end2pm','maxprob','itepf','splam','veeck'};

%% Create result file.
% Create the output directory.
outdir = 'output';
[errorcode,msg] = mkdir(outdir);
if errorcode < 1
    error(['Failed to create output directory ''', outdir, ''': ', msg])
end

% Create result file.
resultfile = fullfile(outdir,'extrlin.mat');
save(resultfile, 'n', 'algorithmname')

%% Extract lines from datasets.
% Read datasets.
dataset = load(fullfile('..','output','dataset.mat'));
ls = dataset.ls;
datasetname = dataset.datasetname;

% Loop over all scans.
disp('Extracting lines from datasets ...')
pm = repmat(polymap,[size(ls,2),size(ls,1),numel(n),numel(algorithmname)]);
t = NaN(size(pm));
try
    for isc = 1 : size(ls,2)
        % Loop over all datasets.
        pmi = repmat(polymap, [size(ls,1),numel(n),numel(algorithmname)]);
        ti = NaN(size(pmi));
        for ids = 1 : size(ls,1)
            % Set maximum length between connected endpoints.
            if ids == 1
                lmax = 1;
            else
                lmax = Inf;
            end
            
            % Loop over all parameters and compute polymaps of extracted
            % lines.
            for ipm = 1 : numel(n)
                % Extract lines using Visvalingam's algorithm.
                tic;
                pmi(ids,ipm,1,1) = ls(ids,isc).visvalingam(...
                    'lmax', lmax, 'n', n(ipm));
                ti(ids,ipm,1,1) = toc;

                % Extract lines using measurement probability heuristic.
                tic;
                pmi(ids,ipm,2,1) = ls(ids,isc).extrlin(...
                    'lmax',lmax,'dr',0.5,'n',n(ipm),'optimize',false);
                ti(ids,ipm,2,1) = toc;

                % Extract lines using optimization.
                tic;
                pmi(ids,ipm,3,1) = ls(ids,isc).extrlin(...
                    'lmax',lmax,'dr',0.5,'n',n(ipm),'optimize',true);
                ti(ids,ipm,3,1) = toc;

                % Extract lines using iterative endpoint fit.
                tic;
                pmi(ids,ipm,4,1) = ls(ids,isc).itepf(...
                    'n', n(ipm), 'dth', 0.01, 'nmin', 0);
                ti(ids,ipm,4,1) = toc;

                % Extract lines using the split-and-merge algorithm.
                tic;
                pmi(ids,ipm,5,1) = ls(ids,isc).splam(...
                    'n', n(ipm), 'dth', 0.01, 'nmin', 0);
                ti(ids,ipm,5,1) = toc;

                % Read results of line extraction using Veeck's algorithm.
                log = sprintf(['../data/veeck/', ...
                    'lines_%sscan%03d.log'],datasetname{ids},isc); ...
                    %#ok<PFBNS>
                pmi(ids,ipm,6,1) = log2polymap(...
                    log, ls(ids,isc).start2cart(1,:)-30);
                filet = fopen(strrep(log, 'lines_', 'time_'), 'r');
                ti(ids,ipm,6,1) = fscanf(filet, '%f');
            end
        end

        % Save lines extracted in this iteration.
        pm(isc,:,:,:) = pmi;
        t(isc,:,:,:) = ti;

        % Update progress display.
        fprintf('Progress: %i/%i.\n', isc, size(ls,2))
    end
catch me
    % Save results before processing error.
    saveresult
    rethrow(me)
end

% Save results.
saveresult

    function saveresult
        % SAVERESULT Save results to file.
        
        pm = permute(pm, [2,1,4,3]);
        t = permute(t, [2,1,4,3]);
        save(resultfile, 'pm', 't', '-append')        
    end

end
