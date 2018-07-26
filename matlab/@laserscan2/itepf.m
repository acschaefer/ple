function pm = itepf( obj, varargin )
%ITEPF Iterative-End-Point-Fit line extraction
%   Example: see SPLAM and use
%       pm = ls(1).itepf
    %% Parse input arguments.
    parser = inputParser;
    parser.addOptional('n', 0)
    parser.addOptional('dth', 0.1)
    parser.addOptional('nmin', 4)
    parse(parser, varargin{:});
    
    %% Call SPLAM w/o fitting
    pm = splam(obj, parser.Results.n, parser.Results.dth, parser.Results.nmin, false);
end

