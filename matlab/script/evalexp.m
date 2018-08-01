function evalexp
% EVALEXP Evaluate line extraction experiments.

%% Evaluate experimental results.
% Load dataset.
dataset = load(fullfile('output','dataset.mat'));
ls = dataset.ls;
pgt = dataset.pg;

% Load experimental results.
pmdata = load(fullfile('output','extrlin.mat'));
pm = pmdata.pm;
algorithmname = pmdata.algorithmname;

% Initialize progress display.
it = 0;
nit = size(pm,1) * size(pm,2) * size(pm,4);
disp('Evaluating results ...')

% Initialize result
a = NaN(size(pm,2), size(pm,3), size(pm,4));
iou = NaN(size(pm,2), size(pm,3), size(pm,4));

% Loop over all datasets.
for ids = 1 : size(pm,1)
    % Loop over all scans.
    for isc = 1 : size(pm,2)
        % Consider only the (non-)reflected rays of the scan.
        lsi = ls(ids,isc).select(ls(ids,isc).ret);
        lsinr = ls(ids,isc).select(~ls(ids,isc).ret);

        % Loop over all parameters.
        for ipm = 1 : size(pm,4)
            % Determine which rays of the laser scan are reflected by all
            % estimated maps.
            retc = true(lsi.count,1);
            for ia = 1 : size(pm,3)
                % Veeck is only stored for ipm == 1
                ipm1 = ipm;
                if strcmp(algorithmname{ia}, 'VB')
                    ipm1 = 1;
                end
                retc = retc & isfinite(lsi.xpm(pm(ids,isc,ia,ipm1)));
            end
            
            % Loop over all line extraction methods.
            for ia = 1 : size(pm,3)
                % Predict radii of the scans reflected by extracted lines.
                r = lsi.xpm(pm(ids,isc,ia,ipm));
                rnr = lsinr.xpm(pm(ids,isc,ia,ipm));

                % Compute the radius differences between the original scan
                % and the scan reflected by the extracted lines.
                dr = lsi.radius - r;
                drret = dr(isfinite(dr));

                % Compute the root of the mean of the squared radius
                % differences.
                rmse(ids,isc,ia,ipm) = sqrt(mean(drret.^2));...
                    %#ok<*NASGU,*AGROW>
                
                % Compute the root of the mean of the squared radius
                % differences of the rays that were reflected by all maps,
                % regardless of with which methods they are produced.
                rmsec(ids,isc,ia,ipm) = sqrt(mean(dr(retc).^2));

                % Compute the fraction of rays that were correctly
                % reflected by the extracted lines.
                f(ids,isc,ia,ipm) = numel(drret) / lsi.count;
                
                % Compute the fraction of rays that were correctly not
                % reflected by the extracted lines.
                fnr(ids,isc,ia,ipm) = sum(~isfinite(rnr)) / lsinr.count;

                % Compute error area between true and estimated polygon.
                if ids == 2 && size(pm(ids,isc,ia,ipm).vertex,1) >= 3
                    % Get ground-truth polygon.
                    pst = polyshape(pgt(isc).vertex);

                    % Compute estimated polygon. Order the vertices
                    % according to their azimuth angles in order not to get
                    % a self-intersecting polygon.
                    v = pm(ids,isc,ia,ipm).vertex - lsi.start2cart(1,:);
                    [th,r] = cart2pol(v(:,1),v(:,2));
                    [th,i] = sort(th);
                    r = r(i);
                    [vx,vy] = pol2cart(th,r);
                    pse = polyshape([vx,vy]+lsi.start2cart(1,:));

                    % Compute intersection and union of ground-truth
                    % polygon and estimated polygon.
                    psi = intersect(pst,pse);
                    psu = union(pst,pse);

                    % Compute error area.
                    au = area(psu);
                    ai = area(psi);
                    at = area(pst);
                    a(isc,ia,ipm) = (au-ai)/at;
                    if au > 0
                        iou(isc,ia,ipm) = ai/au;
                    end
                end               
            end
            
            % Update progress display.
            it = it + 1;
            fprintf('Progress: %i/%i.\n', it, nit)            
        end
    end
end

%% Save evaluation.
evalfile = fullfile('output','eval.mat');
save(evalfile, 'rmse', 'rmsec', 'f', 'fnr', 'a', 'iou');

end
