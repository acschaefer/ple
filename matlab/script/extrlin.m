function extrlin
% EXTRLIN Example script for probabilistic line extraction.

% Read laser scans from carmen file.
datafile = fullfile('..','data','carmen','belgioioso-corrected.log.gz');
[~,ls] = carmenread(datafile);

% Select and subsample example scan.
lsi = ls(65).select(1:2:ls(65).count);

% Run PLE algorithm with visualization.
pm = lsi.extrlin('n', 10, 'lmax', 1, 'dr', 0.15, 'display', 'plot');

% Plot resulting polyline map.
hold off;
lsi.plot;
hold on;
pm.plot('linewidth',3);
axis([-5,15,-20,-5]);

end
