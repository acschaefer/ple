classdef lslns < handle
    %LINES Handle class holding lines with laserscan-point associations
    %   TODO: This class can probably resolved into laserscan2?
    
    properties
        ls
        lns
    end
    
    methods
        function obj = lslns(ls)
            [N,~] = size(ls);
            obj.ls = ls;
            obj.lns = struct('ls1', 1, 'ls2', N, 'v1', ls(1,:), 'v2', ls(N,:));
        end
        
        function l = length(obj)
            l = length(obj.lns);
        end
        
        function i = find(obj, lsi)
            i = -1;
            for j = 1 : obj.length()
                if lsi >= obj.lns(j).ls1 && lsi <= obj.lns(j).ls2
                    i = j;
                    break
                end
            end
        end
        
        function d = dplin(obj, i)
            k = obj.find(i);
            d = -1;
            if k > 0
                d = dplin(obj.ls(i,:), obj.lns(k).v1, obj.lns(k).v2);
            end
        end
        
        function d = dplin_merge(obj, i)
             % TODO assumes that the first line is returned by find
            k = obj.find(i);
            %i, k, obj.length
            if k >= obj.length
                d = NaN;
                return
            end
            d = dplin(obj.ls(i,:), obj.lns(k).v1, obj.lns(k+1).v2);
        end
        
        function obj = split(obj, lsi)
            assert(~obj.isendp(lsi));
            i = obj.find(lsi);
            %fprintf('split line %i at laserscan %i\n', i, lsi);
            lsi2 = obj.lns(i).ls2;
            obj.lns(i).ls2 = lsi;
            obj.lns(i).v2 = obj.ls(lsi,:);
            line = struct('ls1', lsi, 'ls2', lsi2, 'v1', obj.ls(lsi,:), 'v2', obj.ls(lsi2,:));
            obj.lns = [obj.lns, line];
            [~, ind] = sort([obj.lns.ls1]);
            obj.lns = obj.lns(ind);
        end
        
        function obj = merge(obj, lsi)
            assert(obj.isendp(lsi));
            i = obj.find(lsi);
            % TODO assumes that the first line is returned by find
            %fprintf('merge lines %i and %i at laserscan %i\n', i, i+1, lsi);
            obj.lns(i).ls2 = obj.lns(i+1).ls2;
            obj.lns(i).v2 = obj.lns(i+1).v2;
            obj.lns(i+1) = [];
        end
        
        function b = isendp(obj, lsi)
            i = obj.find(lsi);
            b = false;
            if i > 0
                b = (lsi == obj.lns(i).ls1 | lsi == obj.lns(i).ls2);
            end
        end
        
        function b = isonline(obj, lsi)
            b = (obj.find(lsi) > 0);
        end
        
        function n = nvertex(obj)
            n = 0;
            for i = 1:obj.length-1
                % count start vertex of each line (except last)
                n = n + 1;
                d = norm(obj.lns(i).v2 - obj.lns(i+1).v1);
                if d > 1e-10
                    % count end vertex if distant to next start
                    n = n + 1;
                end
            end
            if obj.length > 0
                % count start and end of last line
                n = n + 2;
            end
        end
        
        function obj = select(obj, nmin)
            lns1 = [];
            for i = 1 : obj.length()
                if obj.lns(i).ls2 - obj.lns(i).ls1 + 1 >= nmin
                    lns1 = [lns1, obj.lns(i)];
                end
            end
            obj.lns = lns1;
        end
        
        function [a, r] = getar(obj, i)
            v1 = obj.lns(i).v1;
            v2 = obj.lns(i).v2;
            a = atan2(v2(1)-v1(1), v2(2)-v1(2));
            r = dplin([0,0], v1, v2);
        end
        
        function obj = setar(obj, i, a, r)
            ls1 = obj.ls(obj.lns(i).ls1,:);
            ls2 = obj.ls(obj.lns(i).ls2,:);
            obj.lns(i).v1 = obj.getcpa(a, r, ls1);
            obj.lns(i).v2 = obj.getcpa(a, r, ls2);
        end
        
        function v = getcpa(~, a, r, p)
            n = [cos(a), -sin(a)];
            d = [sin(a), cos(a)];
            d1 = norm(r*n-p); % TODO should correct for angle
            v = r*n - d1*d;
            v1 = r*n + d1*d; % TODO should do it w/o cases
            if norm(p-v1) < norm(p-v)
                v = v1;
            end
        end
        
        function d2 = getsumd2(obj, i)
            d2 = 0.;
            for lsi = obj.lns(i).ls1:obj.lns(i).ls2
                d2 = d2 + (dplin(obj.ls(lsi,:), obj.lns(i).v1, obj.lns(i).v2))^2;
            end
        end
        
        function f = evald2(obj, x0, i)
            obj.setar(i, x0(1), x0(2));
            f = obj.getsumd2(i);
        end
        
        function obj = fit(obj, i)
            lsN = obj.lns(i).ls2 - obj.lns(i).ls1 + 1;
            if lsN <= 2
                obj.lns(i).v1 = obj.ls(obj.lns(i).ls1,:);
                obj.lns(i).v2 = obj.ls(obj.lns(i).ls2,:);
                return
            end
            %fprintf('fit line %i of %i with %i scans\n', i, obj.length(), lsN)
            [a, r] = obj.getar(i);
            x0 = [a, r];
            fun = @(x) obj.evald2(x, i);
            solver = @fminunc;
            solveropt = optimoptions(solver, 'Display', 'none', ...
                'StepTolerance', 1e-6, 'FunctionTolerance', 1e-6);
            solver(fun, x0, solveropt);
        end
        
        function obj = fitall(obj)
            for i = 1 : obj.length
                obj.fit(i);
            end
        end
        
        function plot(obj)
            for j = 1 : obj.length
                plot([obj.lns(j).v1(1), obj.lns(j).v2(1)], [obj.lns(j).v1(2), obj.lns(j).v2(2)])
            end
        end
    end
    
end