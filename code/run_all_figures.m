function run_all_figures(profile_set)
%RUN_ALL_FIGURES Generate all MATLAB figures and data files for the paper.
%
% Usage:
%   run_all_figures
%   run_all_figures("fast")
%   run_all_figures("release")
%
% The release profile is intended for the GitHub/Zenodo archive.
% Outputs are written under code/matlab_outputs/S*/.

if nargin < 1
    profile_set = "release";
end
profile_set = string(profile_set);

this_dir = fileparts(mfilename('fullpath'));
old_dir = pwd;
cleanup = onCleanup(@() cd(old_dir));
cd(this_dir);

fprintf('============================================================\n');
fprintf(' TFGBeta messenger KTAP reproducibility driver\n');
fprintf(' Profile set: %s\n', profile_set); 
fprintf(' MATLAB    : %s\n', version); 
fprintf('============================================================\n');

switch profile_set
    case "fast"
        make_S1_matlab("draft");
        make_S2_matlab("draft");
        make_S3_matlab("draft");
        make_S4_matlab("draft");
    case "final"
        make_S1_matlab("final");
        make_S2_matlab("final");
        make_S3_matlab("final");
        make_S4_matlab("final");
    case "release"
        make_S1_matlab("publication");
        make_S2_matlab("publication");
        make_S3_matlab("final");
        make_S4_matlab("final");
    otherwise
        error('Unknown profile_set. Use "fast", "final", or "release".');
end

fprintf('============================================================\n');
fprintf(' All requested figures completed.\n');
fprintf('============================================================\n');
end
