function ploteval
% PLOTEVAL Visualize results of line extraction experiments.

%% Load data.
% Load extracted maps.
pmdata = load(fullfile('..','output','extrlin.mat'));
pm = pmdata.pm;
n = pmdata.n;
t = pmdata.t;
algorithmname = pmdata.algorithmname;

% Load evaluation data.
evaluation = load(fullfile('..','output','eval.mat'));
rmse = evaluation.rmse;
rmsec = evaluation.rmsec;
f = evaluation.f;
fnr = evaluation.fnr;
a = evaluation.a;
iou = evaluation.iou;

%% Plot data.
makeplot('Time on real data', 'Mean time [s]', 't_real', ...
    n, squeeze(pm(1,:,:,:)), algorithmname, squeeze(t(1,:,:,:)));
makeplot('Time on simulated data', 'Mean time [s]', 't_sim', ...
    n, squeeze(pm(2,:,:,:)), algorithmname, squeeze(t(2,:,:,:)));
makeplot('RMSE on real data', 'Mean RMSE [m]', 'rmse_real', ...
    n, squeeze(pm(1,:,:,:)), algorithmname, squeeze(rmse(1,:,:,:)));
makeplot('RMSE on simulated data', 'Mean RMSE [m]', 'rmse_sim', ...
    n, squeeze(pm(2,:,:,:)), algorithmname, squeeze(rmse(2,:,:,:)));
makeplot('Common RMSE on real data', 'Mean RMSE [m]', 'rmsec_real', ...
    n, squeeze(pm(1,:,:,:)), algorithmname, squeeze(rmsec(1,:,:,:)));
makeplot('Common RMSE on simulated data', 'Mean RMSE [m]', 'rmsec_sim', ...
    n, squeeze(pm(2,:,:,:)), algorithmname, squeeze(rmsec(2,:,:,:)));
makeplot('Fraction of reflected rays on real data', 'f [1]', 'f_real', ...
    n, squeeze(pm(1,:,:,:)), algorithmname, squeeze(f(1,:,:,:)));
makeplot('Fraction of reflected rays on simulated data', 'f [1]', 'f_sim', ...
    n, squeeze(pm(2,:,:,:)), algorithmname, squeeze(f(2,:,:,:)));
makeplot('Fraction of non-return rays on real data', 'fnr [1]', 'fnr_real', ...
    n, squeeze(pm(1,:,:,:)), algorithmname, squeeze(fnr(1,:,:,:)));
makeplot('Error area on simulated data', 'a [1]', 'a_sim', ...
    n, squeeze(pm(2,:,:,:)), algorithmname, a);
makeplot('IoU on simulated data', 'IoU [1]', 'iou_sim', ...
    n, squeeze(pm(2,:,:,:)), algorithmname, iou);
end

function makeplot(title, ytitle, fname, n, pm, algorithmname, data)
    % Define line width in plots.
    lw = 1;

    % Plot data for all methods over all scans
    fig = figure('Name', title);
    hold on
    mdata = squeeze(mean(data,1,'omitnan'))';
    edata = squeeze(std(data,1,1,'omitnan'))';
    ndata = squeeze(sum(~isnan(data),1))';
    for ia = 1:5
        errorbar(n,mdata(:,ia),edata(:,ia)./sqrt(ndata(:,ia)),...
            'LineWidth',lw)
    end
    %plot(n,mdata,'LineWidth',2)
    mnveeck = mean(arrayfun(@(x) size(x.vertex,1), pm(:,6,1)));
    errorbar(mnveeck,mdata(1,6),edata(1,6)./sqrt(ndata(1,6)),...
        'LineWidth',lw)
    hold off
    xlabel('n')
    ylabel(ytitle)
    legend(algorithmname)
    fname = fullfile('..','output',[fname,'.fig']);
    savefig(fig, fname)
end
