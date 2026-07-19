function check_matlab_release(run_smoke)
%CHECK_MATLAB_RELEASE Static and optional smoke checks for the MATLAB release.
%
% Usage:
%   check_matlab_release
%   check_matlab_release(true)
%
% The default performs MATLAB Code Analyzer checks and targeted text checks.
% With run_smoke=true, the draft profiles are executed. This can take minutes.

if nargin < 1
    run_smoke = false;
end

this_dir = fileparts(mfilename('fullpath'));
files = { ...
    'make_S1_matlab.m', ...
    'make_S2_matlab.m', ...
    'make_S3_matlab.m', ...
    'make_S4_matlab.m', ...
    'run_all_figures.m'};

fprintf('============================================================\n');
fprintf(' TFGBeta MATLAB release checks\n');
fprintf(' MATLAB: %s\n', version);
fprintf(' Directory: %s\n', this_dir);
fprintf('============================================================\n');

has_error = false;
for k = 1:numel(files)
    f = fullfile(this_dir, files{k});
    if ~isfile(f)
        fprintf(2, 'Missing file: %s\n', files{k});
        has_error = true;
        continue;
    end
    issues = checkcode(f, '-id');
    fprintf('[checkcode] %s: %d issue(s)\n', files{k}, numel(issues));
end

text_checks = { ...
    '''Color'', [cfg.colors.fold_line, 0.7]', 'RGBA fold-line colour in S4'; ...
    '''BackgroundColor'', [1 1 1 0.80]', 'RGBA background colour in S4'; ...
    'Stable focus', 'over-specific S4 stability label'; ...
    'TFG-$\beta$', 'transposed TGF-beta abbreviation'; ...
    'Eigenvalue $\lambda$', 'ambiguous S4 spectral-axis label'; ...
    'Re$(\lambda)$', 'ambiguous S4 real-part legend'; ...
    '\mathrm{Im}(\lambda)', 'ambiguous S4 imaginary-part legend'; ...
    'AÑADIR', 'editorial Spanish marker'; ...
    'era [', 'editorial Spanish marker'};

for k = 1:numel(files)
    txt = fileread(fullfile(this_dir, files{k}));
    for j = 1:size(text_checks, 1)
        if contains(txt, text_checks{j,1})
            fprintf(2, '[text-check] %s: %s\n', files{k}, text_checks{j,2});
            has_error = true;
        end
    end
    if ~contains(txt, 'save_run_data') && startsWith(files{k}, 'make_')
        fprintf(2, '[text-check] %s: no save_run_data helper found.\n', files{k});
        has_error = true;
    end
end

if run_smoke
    fprintf('Running smoke profile. This may take several minutes.\n');
    run_all_figures("fast");
end

if has_error
    error('Release checks failed. See messages above.');
end
fprintf('Release checks passed.\n');
end
