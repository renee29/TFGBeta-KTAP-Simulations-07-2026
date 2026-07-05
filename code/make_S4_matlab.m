function make_S4_matlab(profile)
%MAKE_S4_MATLAB Build supplementary Figure S4 in MATLAB.
%   make_S4_matlab()        builds the draft profile (fast, ~30 s).
%   make_S4_matlab("final") builds the publication profile (~2 min).
%
%   Figure S4: Eigenvalue stability analysis of the coexistence equilibrium
%   E_coex along the bistable window for varying immunosuppression gamma.
%
%   Each panel shows max Re(lambda) and max |Im(lambda)| of the Jacobian
%   eigenvalues at E_coex as a function of lambda_1, for one value of gamma.
%   Panels are saved individually AND as a composite preview.
%
% Output:
%   matlab_outputs/S4/panels/    — individual panels (PDF + PNG)
%   matlab_outputs/S4/previews/  — composite figure

    if nargin < 1
        profile = "draft";
    end
    profile = validatestring(char(profile), {'draft', 'final'});

    cfg   = local_config(profile);
    p     = base_params();
    paths = local_paths();

    ensure_dir(paths.root);
    ensure_dir(paths.panels);
    ensure_dir(paths.previews);

    setup_style();

    fprintf('============================================================\n');
    fprintf(' MATLAB Supplementary Figure S4\n');
    fprintf(' Profile: %s\n', char(profile));
    fprintf(' Panels : %d gamma values\n', numel(cfg.gamma_values));
    fprintf(' Output : %s\n', paths.root);
    fprintf('============================================================\n');

    data = compute_s4_data(p, cfg);
    save_run_data(paths, data, p, cfg);
    export_s4(data, cfg, paths);

    fprintf('============================================================\n');
    fprintf(' Done.\n');
    fprintf(' Panels : %s\n', paths.panels);
    fprintf(' Preview: %s\n', paths.previews);
    fprintf('============================================================\n');
end


% ================================================================
%  LAYER 2 — CONFIGURATION
% ================================================================

function cfg = local_config(profile)
    cfg.profile = string(profile);

    % ----- Grid sizes (profile-dependent) -----
    switch profile
        case 'final'
            cfg.n_lam       = 400;
            cfg.root_tol    = 1e-12;
        otherwise  % draft
            cfg.n_lam       = 200;
            cfg.root_tol    = 1e-10;
    end

    % ----- Lambda range -----
    cfg.lam_range = [0.01, 1.6];

    % ----- Gamma sweep: 8 values for parametric exploration -----
    cfg.gamma_values = [0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0];
    cfg.gamma_ref    = 2.0;   % reference value from Table 1

    cfg.regime_names = { ...
        'Baseline ($\gamma = 0.5$)', ...
        'Weak suppression ($\gamma = 1.0$)', ...
        'Reference ($\gamma_{\mathrm{ref}} = 2.0$)', ...
        'Elevated suppression ($\gamma = 3.0$)', ...
        'Strong suppression ($\gamma = 4.0$)', ...
        'Very strong suppression ($\gamma = 6.0$)', ...
        'Severe suppression ($\gamma = 8.0$)', ...
        'Extreme suppression ($\gamma = 10.0$)'};

    % ----- Figure geometry -----
    cfg.panel_pos    = [0.5, 0.5, 5.5, 4.5];     % individual panel (inches)
    cfg.preview_pos  = [0.5, 0.5, 17.6, 9.0];    % 2x4 composite (inches)
    cfg.png_dpi      = 600;

    % ----- Plot limits -----
    cfg.ylim_eig     = [-0.64, 0.64];
    cfg.zero_lw      = 1.0;     % zero-line linewidth

    % ----- Colours (unified with S1/S2/S3 palette) -----
    cfg.colors.esc_shade   = hex2rgb('#B2182B');
    cfg.colors.ctrl_shade  = hex2rgb('#2166AC');
    cfg.colors.fold_line   = hex2rgb('#B2182B');
    cfg.colors.zero_line   = [0, 0, 0];
    cfg.colors.annotation  = hex2rgb('#333333');
    cfg.colors.label_esc   = hex2rgb('#8B0000');
    cfg.colors.label_ctrl  = hex2rgb('#1F5A92');
    cfg.colors.white       = [1, 1, 1];
    cfg.colors.black       = [0, 0, 0];

    % Per-panel curve colours (10 distinct pairs)
    base_hex = {'#D62728', '#1F77B4', '#2CA02C', '#FF7F0E', '#9467BD', ...
                '#8C564B', '#E377C2', '#17BECF', '#BCBD22', '#7F7F7F'};
    cfg.colors.panel_base = zeros(numel(base_hex), 3);
    cfg.colors.panel_pastel = zeros(numel(base_hex), 3);
    for k = 1:numel(base_hex)
        cfg.colors.panel_base(k,:) = hex2rgb(base_hex{k});
        cfg.colors.panel_pastel(k,:) = pastel_mix(hex2rgb(base_hex{k}), 0.45);
    end
end


function p = base_params()
    % Identical to S1/S2/S3 — Table 1.
    p.r      = 0.50;
    p.K      = 1.00;
    p.alpha  = 0.90;
    p.g1     = 0.15;
    p.sigma  = 0.10;
    p.mu     = 0.15;
    p.beta   = 0.30;
    p.gamma  = 2.00;
    p.delta1 = 0.40;
    p.delta2 = 0.03;
    p.lam    = 0.30;
end


function paths = local_paths()
    here = fileparts(mfilename('fullpath'));
    paths.root     = fullfile(here, 'matlab_outputs', 'S4');
    paths.panels   = fullfile(paths.root, 'panels');
    paths.previews = fullfile(paths.root, 'previews');
end


% ================================================================
%  LAYER 3 — COMPUTATION
% ================================================================

function data = compute_s4_data(p, cfg)
    lam_arr = linspace(cfg.lam_range(1), cfg.lam_range(2), cfg.n_lam);
    n_gamma = numel(cfg.gamma_values);

    data.lam_arr = lam_arr;
    data.gamma_values = cfg.gamma_values;
    data.panels = cell(1, n_gamma);

    for ig = 1:n_gamma
        gam = cfg.gamma_values(ig);
        fprintf('[%d/%d] Eigenvalue continuation: gamma = %.1f ...\n', ig, n_gamma, gam);
        data.panels{ig} = continuation_branch(p, gam, lam_arr, cfg);
    end
end


function branch = continuation_branch(p_base, gamma, lam_arr, cfg)
%CONTINUATION_BRANCH  Track E_coex backward from large lambda_1.
%   Returns eigenvalue data along the coexistence branch.

    n = numel(lam_arr);
    re_vals = nan(n, 3);
    im_vals = nan(n, 3);
    exists  = false(n, 1);
    eq_X    = nan(n, 1);
    eq_T    = nan(n, 1);
    eq_phi  = nan(n, 1);

    % Initial guess: at large lambda_1, E_coex is near (small X, large T, small phi)
    pk = p_base;
    pk.gamma = gamma;
    pk.lam   = lam_arr(end);
    guess = [0.05; 0.50; 0.01];

    % Backward sweep for smooth continuation
    for idx = n:-1:1
        pk.lam = lam_arr(idx);

        % Solve F(y) = 0
        opts = optimset('Display', 'off', 'TolFun', cfg.root_tol, 'TolX', cfg.root_tol);
        [eq, fval, exitflag] = fsolve(@(y) ode_rhs_vec(y, pk), guess, opts);

        res = max(abs(fval));
        if exitflag > 0 && eq(1) > 1e-8 && eq(2) > 1e-8 && res < 1e-6
            exists(idx) = true;
            guess = eq;   % use as next guess (continuation)

            eq_X(idx)   = eq(1);
            eq_T(idx)   = eq(2);
            eq_phi(idx) = eq(3);

            % Compute Jacobian and eigenvalues
            J = jacobian_analytic(pk, eq(1), eq(2), eq(3));
            eigs_val = eig(J);

            % Sort by descending real part
            [~, ord] = sort(real(eigs_val), 'descend');
            eigs_val = eigs_val(ord);

            re_vals(idx, :) = real(eigs_val(:).');
            im_vals(idx, :) = imag(eigs_val(:).');
        end
    end

    % Find lambda_c: first lambda where E_coex exists (from left)
    if any(exists)
        branch.lam_c = lam_arr(find(exists, 1, 'first'));
    else
        branch.lam_c = lam_arr(end);
    end

   % Find Hopf crossing: where max Re(lambda) crosses zero
    branch.has_hopf = false;
    branch.lam_hopf = NaN;
    if any(exists)
        max_re_full = max(re_vals, [], 2);
        % Method 1: scan for sign change
        for j = 1:(numel(lam_arr)-1)
            if exists(j) && exists(j+1)
                if max_re_full(j) < 0 && max_re_full(j+1) >= 0
                    branch.has_hopf = true;
                    frac = -max_re_full(j) / (max_re_full(j+1) - max_re_full(j));
                    branch.lam_hopf = lam_arr(j) + frac * (lam_arr(j+1) - lam_arr(j));
                    break;
                end
            end
        end
        % Method 2: fallback — if any Re > 0 exists, Hopf occurred
        if ~branch.has_hopf
            valid_re = max_re_full(exists);
            if any(valid_re > 0)
                branch.has_hopf = true;
                % Find first positive index
                idx_pos = find(exists & max_re_full > 0, 1, 'first');
                branch.lam_hopf = lam_arr(idx_pos);
            end
        end
    end

    branch.re_vals = re_vals;
    branch.im_vals = im_vals;
    branch.exists  = exists;
    branch.eq_X    = eq_X;
    branch.eq_T    = eq_T;
    branch.eq_phi  = eq_phi;
    branch.gamma   = gamma;

    fprintf('    lam_c = %.4f', branch.lam_c);
    if branch.has_hopf
        fprintf(', Hopf at lam_H = %.4f', branch.lam_hopf);
    else
        fprintf(', no Hopf');
    end
    fprintf('\n');
end


% ================================================================
%  LAYER 4 — EXPORT
% ================================================================

function export_s4(data, cfg, paths)
    suffix = char(cfg.profile);
    n_gamma = numel(cfg.gamma_values);

    % --- Individual panels ---
    for ig = 1:n_gamma
        fig_k = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.panel_pos);
        ax_k = axes('Parent', fig_k, 'Position', [0.15, 0.15, 0.78, 0.78]);
        plot_single_panel(ax_k, data.lam_arr, data.panels{ig}, ig, cfg);
        panel_name = sprintf('S4_panel_%02d_gamma%.1f_%s', ig, cfg.gamma_values(ig), suffix);
        save_figure_bundle(fig_k, fullfile(paths.panels, panel_name), cfg);
    end

    % --- Composite preview (2 x 4) ---
    n_rows = 2;
    n_cols = 4;
    fig_c = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.preview_pos);

    for ig = 1:min(n_gamma, n_rows * n_cols)
        row = ceil(ig / n_cols);
        col = ig - (row - 1) * n_cols;

        left   = 0.05 + (col - 1) * 0.19;
        bottom = 0.56 - (row - 1) * 0.48;
        w      = 0.155;
        h      = 0.38;

        ax_c = axes('Parent', fig_c, 'Position', [left, bottom, w, h]);
        plot_single_panel(ax_c, data.lam_arr, data.panels{ig}, ig, cfg);

        % Smaller fonts for composite
        ax_c.FontSize = 10;
        ax_c.XLabel.FontSize = 12;
        ax_c.YLabel.FontSize = 12;

        % Only left column gets Y label
        if col > 1
            ylabel(ax_c, '');
        end
        % Only bottom row gets X label
        if row < n_rows
            xlabel(ax_c, '');
            set(ax_c, 'XTickLabel', {});
        end
    end

    save_figure_bundle(fig_c, fullfile(paths.previews, ['S4_preview_' suffix]), cfg);
end


% ================================================================
%  LAYER 5 — PLOTTING
% ================================================================

function plot_single_panel(ax, lam_arr, branch, panel_idx, cfg)
    hold(ax, 'on');

    % --- Background shading ---
    lam_c = branch.lam_c;
    yl = cfg.ylim_eig;

    % Escape region (lambda < lambda_c): red shading
    if lam_c > cfg.lam_range(1)
        patch(ax, [cfg.lam_range(1), lam_c, lam_c, cfg.lam_range(1)], ...
            [yl(1), yl(1), yl(2), yl(2)], ...
            cfg.colors.esc_shade, ...
            'FaceAlpha', 0.18, 'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end

    % Control region (lambda > lambda_c): blue shading
    patch(ax, [lam_c, cfg.lam_range(2), cfg.lam_range(2), lam_c], ...
        [yl(1), yl(1), yl(2), yl(2)], ...
        cfg.colors.ctrl_shade, ...
        'FaceAlpha', 0.10, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');

    % Fold line at lambda_c
    xline(ax, lam_c, '--', ...
        'Color', cfg.colors.fold_line, ...
        'LineWidth', 1.2, ...
        'HandleVisibility', 'off');

    % Zero line
    yline(ax, 0, '-', ...
        'Color', cfg.colors.zero_line, ...
        'LineWidth', cfg.zero_lw, ...
        'HandleVisibility', 'off');

    % --- Eigenvalue curves ---
    mask = branch.exists;
    if any(mask)
        lam_plot = lam_arr(mask);
        re_plot  = branch.re_vals(mask, :);
        im_plot  = branch.im_vals(mask, :);

        max_re     = max(re_plot, [], 2);
        max_abs_im = max(abs(im_plot), [], 2);

        % Growth rate: max Re(lambda) — solid, pastel
        c_growth = cfg.colors.panel_pastel(panel_idx, :);
        c_osc    = cfg.colors.panel_base(panel_idx, :);

        plot(ax, lam_plot, max_re, '-', ...
            'Color', c_growth, 'LineWidth', 2.5, ...
            'DisplayName', 'max Re$(\lambda)$');

        % Oscillation frequency: max |Im(lambda)| — dashed, saturated
        plot(ax, lam_plot, max_abs_im, '--', ...
            'Color', c_osc, 'LineWidth', 2.5, ...
            'DisplayName', 'max $|\mathrm{Im}(\lambda)|$');

        % Mark Hopf crossing if exists
        if branch.has_hopf
            plot(ax, branch.lam_hopf, 0, 'o', ...
                'MarkerSize', 8, ...
                'MarkerFaceColor', cfg.colors.white, ...
                'MarkerEdgeColor', cfg.colors.black, ...
                'LineWidth', 1.5, ...
                'HandleVisibility', 'off');
        end
    end

    % --- Region labels ---
    if lam_c > 0.05
        text(ax, lam_c * 0.5, yl(2) * 0.48, ...
            {'Escape'}, ...
            'Interpreter', 'latex', 'FontSize', 12, ...
            'FontWeight', 'bold', 'FontAngle', 'italic', ...
            'Rotation', 90, ...
            'Color', cfg.colors.label_esc, ...
            'HorizontalAlignment', 'center');
    end

    text(ax, (lam_c + cfg.lam_range(2)) / 2.0, yl(1) * 0.52, ...
        {'Control'}, ...
        'Interpreter', 'latex', 'FontSize', 12, ...
        'Rotation', 90, ...
        'FontWeight', 'bold', 'FontAngle', 'italic', ...
        'Color', cfg.colors.label_ctrl, ...
        'HorizontalAlignment', 'center');

    % --- Info box ---
    gamma_val = branch.gamma;
    if abs(gamma_val - cfg.gamma_ref) < 0.01
        tag = sprintf('$\\gamma_{\\mathrm{ref}} = %.1f$', gamma_val);
    else
        tag = sprintf('$\\gamma = %.1f$', gamma_val);
    end

    stability = '';
    if branch.has_hopf
        stability = sprintf('Hopf at $\\lambda_1 \\approx %.2f$', branch.lam_hopf);
    else
        stability = 'No Hopf detected';
    end

    info_str = {tag, stability};
    text(ax, 0.97, 0.97, info_str, ...
        'Units', 'normalized', ...
        'Interpreter', 'latex', 'FontSize', 12, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'BackgroundColor', [1 1 1], 'Margin', 3, ...
        'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 0.5);

    % --- Axes ---
    xlabel(ax, 'TGF-$\beta$ clearance rate $\lambda_1$', ...
        'Interpreter', 'latex', 'FontSize', 16);
    ylabel(ax, 'Eigenvalue $\lambda$', ...
        'Interpreter', 'latex', 'FontSize', 16);

    xlim(ax, cfg.lam_range);
    ylim(ax, cfg.ylim_eig);

    % --- Legend ---
    lgd = legend(ax, 'Location', 'southeast', ...
        'Interpreter', 'latex', 'Box', 'off', 'FontSize', 12);
    style_legend(lgd);

    finish_axes(ax);
end


% ================================================================
%  LAYER 6 — ODE / MATH CORE
% ================================================================

function dy = ode_rhs_vec(y, p)
%ODE_RHS_VEC  RHS of the 3D macroscopic ODE (vector form for fsolve).
    X   = y(1);
    T   = y(2);
    phi = y(3);

    g2 = p.g1^2;
    s  = phi / (1.0 + phi);

    dX   = p.r * X * (1.0 - X / p.K) ...
         - p.alpha * X^2 * T / (g2 + X^2) ...
         + p.beta * X * s;
    dT   = p.sigma - p.mu * T - p.gamma * T * s;
    dphi = p.delta1 * X + p.delta2 * T - p.lam * phi;

    dy = [dX; dT; dphi];
end


function J = jacobian_analytic(p, X, T, phi)
%JACOBIAN_ANALYTIC  Exact Jacobian of the 3D macroscopic ODE.
%   Entries derived analytically from the ODE system.
    g2 = p.g1^2;
    s  = phi / (1.0 + phi);
    ds = 1.0 / (1.0 + phi)^2;   % d(s)/d(phi)

    J = zeros(3, 3);

    % Row 1: dX/d(X, T, phi)
    J(1,1) = p.r * (1.0 - 2.0*X/p.K) ...
           - p.alpha * 2.0*X*T*g2 / (g2 + X^2)^2 ...
           + p.beta * s;
    J(1,2) = -p.alpha * X^2 / (g2 + X^2);
    J(1,3) = p.beta * X * ds;

    % Row 2: dT/d(X, T, phi)
    J(2,1) = 0.0;
    J(2,2) = -p.mu - p.gamma * s;
    J(2,3) = -p.gamma * T * ds;

    % Row 3: dphi/d(X, T, phi)
    J(3,1) = p.delta1;
    J(3,2) = p.delta2;
    J(3,3) = -p.lam;
end


% ================================================================
%  LAYER 7 — UTILITIES
% ================================================================

function rgb = hex2rgb(hex)
    hex = char(hex);
    if hex(1) == '#', hex = hex(2:end); end
    rgb = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255;
end


function rgb_p = pastel_mix(rgb, mix)
%PASTEL_MIX  Mix a colour with white to obtain a pastel variant.
    rgb_p = rgb * (1.0 - mix) + mix;
end


function save_run_data(paths, data, p, cfg)
    data_dir = fullfile(paths.root, 'data');
    ensure_dir(data_dir);
    metadata = release_metadata('S4', cfg);
    save(fullfile(data_dir, ['S4_data_' char(cfg.profile) '.mat']), ...
        'data', 'p', 'cfg', 'metadata', '-v7.3');
    fprintf('  -> %s\n', fullfile(data_dir, ['S4_data_' char(cfg.profile) '.mat']));
end

function metadata = release_metadata(figure_id, cfg)
    metadata = struct();
    metadata.figure_id = char(figure_id);
    metadata.profile = char(cfg.profile);
    metadata.generated_on = datestr(now, 30);
    metadata.matlab_version = version;
    metadata.note = 'Generated by TFGBeta GitHub release scripts.';
end


function setup_style()
    set(groot, 'DefaultAxesFontSize', 16);
    set(groot, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(groot, 'DefaultAxesLabelFontSizeMultiplier', 1.0);
    set(groot, 'DefaultTextInterpreter', 'latex');
    set(groot, 'DefaultLegendInterpreter', 'latex');
    set(groot, 'DefaultAxesBox', 'on');
    set(groot, 'DefaultAxesLineWidth', 0.8);
    set(groot, 'DefaultLineLineWidth', 1.5);
end


function finish_axes(ax)
    set(ax, 'Box', 'off', 'TickDir', 'out', 'TickLength', [0.015 0.015]);
    set(ax, 'XMinorTick', 'on', 'YMinorTick', 'on');
    % Draw box lines without top/right ticks
    xl = xlim(ax);  yl = ylim(ax);
    plot(ax, [xl(2) xl(2)], yl, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
    plot(ax, xl, [yl(2) yl(2)], 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
    xl = xlim(ax);
    yl = ylim(ax);
    set(ax, 'Layer', 'top');
    xlim(ax, xl);
    ylim(ax, yl);
end


function style_legend(lgd)
    lgd.FontSize = 12;
    lgd.Box = 'off';
    lgd.ItemTokenSize = [18, 10];
end


function save_figure_bundle(fig, stem, cfg)
    exportgraphics(fig, [stem '.pdf'], 'ContentType', 'vector');
    exportgraphics(fig, [stem '.png'], 'Resolution', cfg.png_dpi);
    fprintf('  -> %s.pdf\n', stem);
    fprintf('  -> %s.png\n', stem);
    close(fig);
end


function ensure_dir(d)
    if ~isfolder(d), mkdir(d); end
end
