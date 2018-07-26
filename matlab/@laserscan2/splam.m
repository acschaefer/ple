function pm = splam( obj, varargin )
%SPLAM Split-and-Merge line extraction
%   Example:
%      [~,ls] = carmenread('seattle-corrected.log.gz')
%      [ls.rlim] = deal([0.5, 10])
%      pm = ls(1).splam
%      ls(1).scatter
%      hold on
%      pm.plot
%      hold off
    %% Parse input arguments.
    parser = inputParser;
    parser.addOptional('n', 0, ...
        @(x) validateattributes(x, {'numeric'}, ...
        {'integer', 'nonnegative', 'scalar'}, '', 'DTH'))
    parser.addOptional('dth', 0.1, ...
        @(x) validateattributes(x, {'numeric'}, ...
        {'real', 'nonnegative', 'scalar'}, '', 'DTH'))
    parser.addOptional('nmin', 4, ...
        @(x) validateattributes(x, {'numeric'}, ...
        {'integer', 'nonnegative', 'scalar'}, '', 'DTH'))
    parser.addOptional('dofit', true)
    parse(parser, varargin{:});
    
    %% Init
    ls = obj.select(obj.ret).end2cart;
    [N, ~] = size(ls);
    lns = lslns(ls);
    if parser.Results.dofit
        lns.fit(1);
    end

    %% Split
    while true
        ds = arrayfun(@(i) lns.dplin(i), 1:N);
        ep = arrayfun(@(i) lns.isendp(i), 1:N);
        ds(ep) = NaN;
        [dmax, imax] = max(ds);
        %fprintf('Number of lines: %i, dmax: %f\n', lns.length, dmax);
        if dmax < parser.Results.dth
            if lns.nvertex >= parser.Results.n || parser.Results.n <= 0
                break
            end
        end
        lns.split(imax);
        if parser.Results.dofit
            lni = lns.find(imax);
            lns.fit(lni);
            lns.fit(lni+1);
        end
        if ~parser.Results.dofit && parser.Results.n > 0
            lns.select(parser.Results.nmin);
            if lns.nvertex >= parser.Results.n
                break
            end
        end
    end
    
    %% Merge
    while parser.Results.dofit
        ds = arrayfun(@(i) lns.dplin_merge(i), 2:N-1);
        ep = arrayfun(@(i) lns.isendp(i), 2:N-1);
        ds(~ep) = NaN;
        [dmin, imin] = min(ds);
        %fprintf('Number of lines: %i, dmin: %f\n', lns.length, dmin);
        if parser.Results.n <= 0
            if dmin >= parser.Results.dth
                break
            end
        else
            if lns.nvertex <= parser.Results.n
                break
            end
        end
        lns.merge(imin+1);
        if parser.Results.dofit
            lni = lns.find(imin+1);
            lns.fit(lni);
        end
    end

    %% Select only lines with nmin points.
    lns.select(parser.Results.nmin);
    
    %% Create polymap.
    pln = {};
    j = 1;
    plv = [lns.lns(1).v1];
    for i = 1:lns.length
        d = 1;
        if i < lns.length
            d = norm(lns.lns(i).v2 - lns.lns(i+1).v1);
        end
        plv = [plv; lns.lns(i).v2];
        if d > 1e-10
            pln{j} = polyline(plv);
            j = j + 1;
            if i < lns.length
                plv = [lns.lns(i+1).v1];
            end
        end
    end
    pm = polymap(pln);
end

