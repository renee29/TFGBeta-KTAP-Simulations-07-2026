function make_S3_matlab(profile)
%MAKE_S3_MATLAB Build supplementary Figure S3 in MATLAB.
%   make_S3_matlab()        builds the draft profile (fast, ~2 min).
%   make_S3_matlab("final") builds the publication profile (~15 min).
%
%   Figure S3: Robustness of the messenger-induced bistability in the
%   (lambda_1, beta) parameter plane.
%
%   Panel A — Heatmap of DeltaX* = X*_esc − X*_ctrl.  The fold curve
%             delimiting the bistable region is overlaid.
%   Panel B — One-dimensional bifurcation diagram X* vs. beta at fixed
%             lambda_1 = 0.30, showing the three equilibrium branches.
%
% Output:
%   matlab_outputs/S3/panels/
%   matlab_outputs/S3/previews/

    if nargin < 1
        profile = "draft";
    end
    profile = validatestring(char(profile), {'draft', 'final'});

    cfg   = local_config(profile);
    p     = base_params();
    ic    = base_ics();
    paths = local_paths();

    ensure_dir(paths.root);
    ensure_dir(paths.panels);
    ensure_dir(paths.previews);

    setup_style();

    fprintf('============================================================\n');
    fprintf(' MATLAB Supplementary Figure S3\n');
    fprintf(' Profile: %s\n', char(profile));
    fprintf(' Output : %s\n', paths.root);
    fprintf('============================================================\n');

    data = compute_s3_data(p, ic, cfg);
    save_run_data(paths, data, p, ic, cfg);
    export_s3(data, p, ic, cfg, paths);

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
            cfg.grid_lam        = 200;
            cfg.grid_beta       = 200;
            cfg.bif_n_main      = 200;
            cfg.bif_n_refine    = 200;     % refinement around upper fold
            cfg.root_ns         = 2000;
            cfg.ss_tol          = 1.0e-8;
            cfg.smooth_sigma    = 1.0;
        otherwise  % draft
            cfg.grid_lam        = 25;
            cfg.grid_beta       = 25;
            cfg.bif_n_main      = 120;
            cfg.bif_n_refine    = 60;
            cfg.root_ns         = 800;
            cfg.ss_tol          = 1.0e-7;
            cfg.smooth_sigma    = 1.2;
    end
    cfg.bif_refine_range = [1.0, 2.0];     % zone around beta_upper ≈ 1.61

    % ----- Parameter ranges -----
    cfg.lam_range  = [0.005, 20.0];
    cfg.beta_range = [0.005, 20.0];

    % ----- Steady-state integration -----
    cfg.ss_end = 400.0;
    %cfg.ss_tol = 1.0e-7;
    cfg.ss_eps = 1.0e-12;
    cfg.progress_every = 5;

    cfg.ode_opts = odeset( ...
        'RelTol', 1e-9, ...
        'AbsTol', 1e-11, ...
        'MaxStep', 0.5, ...
        'NonNegative', 1:3);

    % ----- Heatmap thresholds -----
    cfg.deltaX_threshold = 0.30;   % contour level for fold curve
    %cfg.smooth_sigma     = 1.2;    % Gaussian smoothing kernel

    % ----- Bifurcation in beta (Panel B) -----
    cfg.bif_lam_fixed = 0.30;              % reference lambda_1
    cfg.bif_beta_range = [0.005, 5.0];
    cfg.root_threshold = 0.06;

    % ----- Reference marker -----
    cfg.ref_lam  = 0.30;
    cfg.ref_beta = 0.30;

    % ----- ICs -----
    cfg.phi0 = 0.05;

    % ----- Figure geometry (inches) -----
    cfg.figure_a_pos  = [0.5, 0.5, 7.0, 5.8];
    cfg.figure_b_pos  = [0.5, 0.5, 7.0, 5.8];
    cfg.preview_pos   = [0.5, 0.5, 14.5, 5.8];
    cfg.png_dpi       = 600;
    cfg.legend_b_pos  = [0.11, 0.78, 0.33, 0.14];  % [x y w h], normalized

    % ----- Colour palette -----
    %  Divergent blue–white–red for DeltaX* heatmap
    cfg.colors.ctrl_deep   = hex2rgb('#1B4F72');   % strong immune control
    cfg.colors.ctrl_mid    = hex2rgb('#85C1E9');
    cfg.colors.white       = [1.00, 1.00, 1.00];
    cfg.colors.esc_mid     = hex2rgb('#F1948A');
    cfg.colors.esc_deep    = hex2rgb('#922B21');   % strong tumour escape

    cfg.colors.fill_ctrl   = hex2rgb('#DDEAF7');   % same as S1/S2
    cfg.colors.fill_esc    = hex2rgb('#F4D8D8');   % same as S1/S2
    cfg.colors.fill_bist   = hex2rgb('#E8E0F0');   % lavender for bistable

    cfg.colors.fold_curve  = hex2rgb('#1A1A1A');   % near-black fold
    cfg.colors.star        = hex2rgb('#E66100');    % orange reference star
    cfg.colors.branch_esc  = hex2rgb('#B61C2E');   % escape branch (red)
    cfg.colors.branch_ctrl = hex2rgb('#2B6CB0');   % control branch (blue)
    cfg.colors.branch_sad  = hex2rgb('#595959');   % saddle branch (grey)
    cfg.colors.black       = [0, 0, 0];
    cfg.colors.annotation  = hex2rgb('#333333');

    cfg.colors.label_esc   = hex2rgb('#8B0000');
    cfg.colors.label_ctrl  = hex2rgb('#1F5A92');
    cfg.colors.label_bist  = hex2rgb('#5B3FA3');
end


function p = base_params()
    % Identical to make_S1_matlab.m and make_S2_matlab.m — Table 1.
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


function ic = base_ics()
    ic.ctrl = [0.05; 0.50; 0.01];
    ic.esc  = [1.20; 0.05; 5.00];
end


function paths = local_paths()
    here = fileparts(mfilename('fullpath'));
    paths.root     = fullfile(here, 'matlab_outputs', 'S3');
    paths.panels   = fullfile(paths.root, 'panels');
    paths.previews = fullfile(paths.root, 'previews');
end


% ================================================================
%  LAYER 3 — COMPUTATION
% ================================================================

function data = compute_s3_data(p, ic, cfg)
    data = struct();

    % --- Panel A: 2D sweep (lambda_1, beta) ---
    fprintf('[1/2] Phase diagram: %d x %d grid ...\n', cfg.grid_lam, cfg.grid_beta);
    data.phase = compute_phase_panel(p, ic, cfg);

    % --- Panel B: 1D bifurcation in beta ---
    %fprintf('[2/2] Bifurcation in beta (%d points) ...\n', cfg.bif_n);
    fprintf('[2/2] Bifurcation in beta (%d+%d points) ...\n', cfg.bif_n_main, cfg.bif_n_refine);
    data.bif = compute_bif_panel(p, ic, cfg);
end


function phase = compute_phase_panel(p_base, ic, cfg)
    lam_arr  = logspace(log10(cfg.lam_range(1)),  log10(cfg.lam_range(2)),  cfg.grid_lam);
    beta_arr = logspace(log10(cfg.beta_range(1)), log10(cfg.beta_range(2)), cfg.grid_beta);
    

    Xf_ctrl = zeros(cfg.grid_lam, cfg.grid_beta);
    Xf_esc  = zeros(cfg.grid_lam, cfg.grid_beta);

    for il = 1:cfg.grid_lam
        for ib = 1:cfg.grid_beta
            pk = p_base;
            pk.lam  = lam_arr(il);
            pk.beta = beta_arr(ib);

            ss_opts = odeset(cfg.ode_opts, ...
                'Events', @(t, y) steady_event(t, y, pk, cfg));

            Xf_ctrl(il, ib) = run_to_steady(pk, ic.ctrl, cfg.ss_end, ss_opts);
            Xf_esc(il, ib)  = run_to_steady(pk, ic.esc,  cfg.ss_end, ss_opts);
        end

        if mod(il, cfg.progress_every) == 0 || il == cfg.grid_lam
            fprintf('  phase row %d / %d\n', il, cfg.grid_lam);
        end
    end

    DeltaX = Xf_esc - Xf_ctrl;
    DeltaX_s = smooth2d_gaussian(DeltaX, cfg.smooth_sigma);

    phase.lam_arr  = lam_arr;
    phase.beta_arr = beta_arr;
    phase.Xf_ctrl  = Xf_ctrl;
    phase.Xf_esc   = Xf_esc;
    phase.DeltaX   = DeltaX;
    phase.DeltaX_s = DeltaX_s;
end


function bif = compute_bif_panel(p_base, ~, cfg)
    beta_main   = logspace(log10(cfg.bif_beta_range(1)), ...
                           log10(cfg.bif_beta_range(2)), cfg.bif_n_main);
    beta_refine = linspace(cfg.bif_refine_range(1), ...
                           cfg.bif_refine_range(2), cfg.bif_n_refine);
    beta_arr    = unique(sort([beta_main, beta_refine]));

    Xc = nan(size(beta_arr));
    Xe = nan(size(beta_arr));
    Xs = nan(size(beta_arr));

    % Single-root classifier: "small" vs "large" equilibrium.
    mono_split = p_base.K;

    for k = 1:numel(beta_arr)
        pk = p_base;
        pk.lam  = cfg.bif_lam_fixed;
        pk.beta = beta_arr(k);

        rr = scalar_roots(pk, cfg.root_ns);
        rr = rr(isfinite(rr) & rr > 0);
        rr = sort(rr(:).');

        if numel(rr) >= 3
            % Three-equilibria case: smallest=E_coex, middle=E_sad, largest=E_esc.
            Xc(k) = rr(1);
            Xs(k) = rr(2);
            Xe(k) = rr(end);
        elseif numel(rr) == 1
            % One-equilibrium case: classify by size (small -> E_coex, large -> E_esc).
            if rr(1) <= mono_split
                Xc(k) = rr(1);
            else
                Xe(k) = rr(1);
            end
        elseif numel(rr) == 2
            % Degenerate near-fold sampling: keep extreme branches.
            Xc(k) = rr(1);
            Xe(k) = rr(2);
        end
    end

    bif.beta_arr = beta_arr;
    bif.Xc = Xc;
    bif.Xe = Xe;
    bif.Xs = Xs;
    bif.bist = ~isnan(Xs);
end


% ================================================================
%  LAYER 4 — EXPORT
% ================================================================

function export_s3(data, p, ic, cfg, paths)
    suffix = char(cfg.profile);

    % --- Panel A ---
    fig_a = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.figure_a_pos);
    ax_a = axes('Parent', fig_a, 'Position', [0.13, 0.13, 0.74, 0.80]);
    plot_panel_a(ax_a, data.phase, cfg);
    save_figure_bundle(fig_a, fullfile(paths.panels, ['S3_panelA_' suffix]), cfg);

    % --- Panel B ---
    fig_b = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.figure_b_pos);
    ax_b = axes('Parent', fig_b, 'Position', [0.13, 0.13, 0.80, 0.80]);
    plot_panel_b(ax_b, data.bif, cfg);
    save_figure_bundle(fig_b, fullfile(paths.panels, ['S3_panelB_' suffix]), cfg);

    % --- Preview 1x2 ---
    fig_p = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.preview_pos);
    ax1 = axes('Parent', fig_p, 'Position', [0.07, 0.13, 0.38, 0.80]);
    ax2 = axes('Parent', fig_p, 'Position', [0.55, 0.13, 0.40, 0.80]);
    plot_panel_a(ax1, data.phase, cfg);
    plot_panel_b(ax2, data.bif, cfg);
    save_figure_bundle(fig_p, fullfile(paths.previews, ['S3_preview_' suffix]), cfg);
end


% ================================================================
%  LAYER 5 — PLOTTING
% ================================================================

function plot_panel_a(ax, phase, cfg)
    hold(ax, 'on');

    % --- Build divergent colourmap ---
    cmap = build_divergent_cmap( ...
        cfg.colors.ctrl_deep, cfg.colors.ctrl_mid, cfg.colors.white, ...
        cfg.colors.esc_mid, cfg.colors.esc_deep, 256);

    % --- Heatmap of DeltaX* ---
    h = imagesc(ax, phase.lam_arr, phase.beta_arr, phase.DeltaX_s');
    set(ax, 'YDir', 'normal');
    set(ax, 'XScale', 'log', 'YScale', 'log');
    xticks(ax, [1e-2, 1e-1, 1e0, 1e1]);
    yticks(ax, [1e-2, 1e-1, 1e0, 1e1]);
    xticklabels(ax, {'$10^{-2}$', '$10^{-1}$', '$10^{0}$', '$10^{1}$'});
    yticklabels(ax, {'$10^{-2}$', '$10^{-1}$', '$10^{0}$', '$10^{1}$'});
    colormap(ax, cmap);

    max_abs = max(abs(phase.DeltaX_s(:)));
    caxis(ax, [-max_abs * 0.05, max_abs]);

    cb = colorbar(ax, 'Location', 'eastoutside');
    cb.Label.String = 'Tumour escape potential $(\Delta X^* = X^*_{\mathrm{esc}} - X^*_{\mathrm{ctrl}})$';
    cb.Label.Interpreter = 'latex';
    cb.Label.FontSize = 16;
    cb.TickLabelInterpreter = 'latex';
    cb.FontSize = 14;

    % --- Fold curve (contour of DeltaX_s = threshold) ---
    [~, hc] = contour(ax, phase.lam_arr, phase.beta_arr, phase.DeltaX_s', ...
        [cfg.deltaX_threshold, cfg.deltaX_threshold], ...
        'LineColor', cfg.colors.fold_curve, ...
        'LineWidth', 2.5, ...
        'LineStyle', '-');
    hc.HandleVisibility = 'off';

    % --- Zero contour (monostable boundary where DeltaX ≈ 0) ---
    [~, hc0] = contour(ax, phase.lam_arr, phase.beta_arr, phase.DeltaX_s', ...
        [0.02, 0.02], ...
        'LineColor', cfg.colors.fold_curve, ...
        'LineWidth', 1.5, ...
        'LineStyle', '--');
    hc0.HandleVisibility = 'off';

    % --- Reference star ---
    plot(ax, cfg.ref_lam, cfg.ref_beta, 'p', ...
        'MarkerFaceColor', cfg.colors.star, ...
        'MarkerEdgeColor', cfg.colors.black, ...
        'MarkerSize', 18, ...
        'LineWidth', 1.2, ...
        'HandleVisibility', 'off');

    % --- Region annotations (matched to the CorelDRAW composition) ---
    text(ax, 0.12, 0.73, {'Monostable', '(tumour escape)'}, ...
        'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 13, ...
        'Color', cfg.colors.label_esc, 'HorizontalAlignment', 'center', ...
        'BackgroundColor', [1 1 1], 'Margin', 2);

    text(ax, 0.61, 0.59, 'Bistable', ...
        'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 15, ...
        'Color', cfg.colors.label_bist, 'HorizontalAlignment', 'center', ...
        'BackgroundColor', [1 1 1], 'Margin', 2);

    text(ax, 0.82, 0.10, {'Monostable', '(immune control)'}, ...
        'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 13, ...
        'Color', cfg.colors.label_ctrl, 'HorizontalAlignment', 'center', ...
        'BackgroundColor', [1 1 1], 'Margin', 2);
    % --- Star label ---
    %text(ax, cfg.ref_lam + 0.06, cfg.ref_beta + 0.06, ...
    %    'Table 1', ...
    %    'Interpreter', 'latex', 'FontSize', 12, ...
    %    'Color', cfg.colors.star, ...
    %    'BackgroundColor', [1 1 1 0.85], 'Margin', 2);

    % --- Axes ---
    xlabel(ax, 'TGF-$\beta$ clearance coefficient $\lambda_1$', ...
        'Interpreter', 'latex', 'FontSize', 18);
    ylabel(ax, 'Tumour promotion coefficient $\beta$', ...
        'Interpreter', 'latex', 'FontSize', 18);

    xlim(ax, cfg.lam_range);
    ylim(ax, cfg.beta_range);

    finish_axes(ax);
end


function plot_panel_b(ax, bif, cfg)
    hold(ax, 'on');
    set(ax, 'XScale', 'log');

    beta_arr = bif.beta_arr;
    Xc = bif.Xc;
    Xe = bif.Xe;
    Xs = bif.Xs;
    bist = bif.bist;

    % --- Shaded bistable region (fill between E_coex and E_esc) ---
    if any(bist)
        bist_idx = find(bist);
        mask_b = bist & ~isnan(Xe) & ~isnan(Xc);
        x_fill = beta_arr(mask_b);
        y_lo   = Xc(mask_b);
        y_hi   = Xe(mask_b);
        patch(ax, [x_fill, fliplr(x_fill)], [y_lo, fliplr(y_hi)], ...
            cfg.colors.fill_ctrl, ...
            'FaceAlpha', 0.42, 'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end

 % --- Monostable escape shading (HIGH beta, right of upper fold) ---
    if any(bist)
        b_upper = beta_arr(bist_idx(end));
        b_end   = beta_arr(end);
        yl_patch = ylim(ax);
        if isempty(yl_patch) || yl_patch(2) <= yl_patch(1)
            yl_patch = [0.01, 12.0];
        end
        if b_end > b_upper
            patch(ax, [b_upper, b_end, b_end, b_upper], ...
                [yl_patch(1), yl_patch(1), yl_patch(2), yl_patch(2)], ...
                cfg.colors.fill_esc, ...
                'FaceAlpha', 0.30, 'EdgeColor', 'none', ...
                'HandleVisibility', 'off');
        end
    end

    % --- Escape branch ---
    hEsc = plot(ax, beta_arr, Xe, '-', ...
        'Color', cfg.colors.branch_esc, ...
        'LineWidth', 2.5);

    % --- Control branch ---
    hCoex = plot(ax, beta_arr, Xc, '-', ...
        'Color', cfg.colors.branch_ctrl, ...
        'LineWidth', 2.5);

    % --- Saddle branch ---
    hSad = [];
    valid_s = ~isnan(Xs);
    if any(valid_s)
        hSad = plot(ax, beta_arr(valid_s), Xs(valid_s), '--', ...
            'Color', cfg.colors.branch_sad, ...
            'LineWidth', 2.0);
    end

    % --- Reference line at beta_ref ---
    xline(ax, cfg.ref_beta, ':', ...
        'Color', cfg.colors.annotation, ...
        'LineWidth', 1.5, ...
        'HandleVisibility', 'off');
    ref_x_norm = log10(cfg.ref_beta / cfg.bif_beta_range(1)) / ...
        log10(cfg.bif_beta_range(2) / cfg.bif_beta_range(1));
    text(ax, ref_x_norm - 0.015, 0.93, ...
        sprintf('$\\beta_{\\mathrm{ref}} = %.2f$', cfg.ref_beta), ...
        'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 13, ...
        'Color', cfg.colors.annotation, 'Rotation', 90, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'BackgroundColor', [1 1 1], 'Margin', 2);
    % --- Fold point markers ---
    if any(bist)
        % Lower fold (onset of bistability)
%         plot(ax, beta_arr(bist_idx(1)), Xe(bist_idx(1)), 'o', ...
%             'MarkerFaceColor', cfg.colors.black, ...
%             'MarkerEdgeColor', cfg.colors.black, ...
%             'MarkerSize', 8, 'LineWidth', 1.2, ...
%             'HandleVisibility', 'off');
%         plot(ax, beta_arr(bist_idx(1)), Xc(bist_idx(1)), 'o', ...
%             'MarkerFaceColor', cfg.colors.black, ...
%             'MarkerEdgeColor', cfg.colors.black, ...
%             'MarkerSize', 8, 'LineWidth', 1.2, ...
%             'HandleVisibility', 'off');

        % Upper fold
        plot(ax, beta_arr(bist_idx(end)), Xe(bist_idx(end)), 'o', ...
            'MarkerFaceColor', cfg.colors.white, ...
            'MarkerEdgeColor', cfg.colors.black, ...
            'MarkerSize', 8, 'LineWidth', 1.5, ...
            'HandleVisibility', 'off');
        plot(ax, beta_arr(bist_idx(end)), Xc(bist_idx(end)), 'o', ...
            'MarkerFaceColor', cfg.colors.white, ...
            'MarkerEdgeColor', cfg.colors.black, ...
            'MarkerSize', 8, 'LineWidth', 1.5, ...
            'HandleVisibility', 'off');
    end

    % --- Region annotations (matched to the CorelDRAW composition) ---
    text(ax, 0.08, 0.20, 'Immune control', ...
        'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 14, ...
        'Color', cfg.colors.label_ctrl, ...
        'BackgroundColor', [1 1 1], 'Margin', 2);

    text(ax, 0.44, 0.53, 'Bistable', ...
        'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 14, ...
        'Color', cfg.colors.label_bist, 'HorizontalAlignment', 'center', ...
        'BackgroundColor', [1 1 1], 'Margin', 2);

    text(ax, 0.93, 0.34, 'Tumour escape', ...
        'Units', 'normalized', 'Interpreter', 'latex', 'FontSize', 14, ...
        'Color', cfg.colors.label_esc, 'Rotation', 90, ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [1 1 1], 'Margin', 2);
    % --- Legend ---
    if isempty(hSad)
        lgd = legend(ax, [hEsc, hCoex], ...
            {'$E_{\mathrm{esc}}$ (stable)', ...
             '$E_{\mathrm{coex}}$ (stable)'}, ...
            'Location', 'southeast', ...
            'Interpreter', 'latex', ...
            'Box', 'off');
    else
        lgd = legend(ax, [hEsc, hSad, hCoex], ...
            {'$E_{\mathrm{esc}}$ (stable)', ...
             '$E_{\mathrm{sad}}$ (unstable)', ...
             '$E_{\mathrm{coex}}$ (stable)'}, ...
            'Location', 'southeast', ...
            'Interpreter', 'latex', ...
            'Box', 'off');
    end
    style_legend(lgd);
    if isfield(cfg, 'legend_b_pos') && ~isempty(cfg.legend_b_pos)
        lgd.Units = 'normalized';
        lgd.Position = cfg.legend_b_pos;
    end

    % --- Axes ---
    xlabel(ax, 'Tumour promotion coefficient $\beta$', ...
        'Interpreter', 'latex', 'FontSize', 18);
    ylabel(ax, 'Asymptotic tumour density $X^*$', ...
        'Interpreter', 'latex', 'FontSize', 18);

    xlim(ax, cfg.bif_beta_range);
    set(ax, 'YScale', 'log');
    ylim(ax, [0.01, 12.0]);

    finish_axes(ax);
end


% ================================================================
%  LAYER 6 — ODE CORE
% ================================================================

function dy = ode_rhs(~, y, p)
    X   = max(y(1), 0.0);
    T   = max(y(2), 0.0);
    phi = max(y(3), 0.0);

    g2  = p.g1 ^ 2;
    s   = phi / (1.0 + phi);

    dX   = p.r * X * (1.0 - X / p.K) ...
         - p.alpha * X^2 * T / (g2 + X^2) ...
         + p.beta * X * s;
    dT   = p.sigma - p.mu * T - p.gamma * T * s;
    dphi = p.delta1 * X + p.delta2 * T - p.lam * phi;

    dy = [dX; dT; dphi];
end


function val = run_to_steady(p, y0, t_end, ode_opts)
    [~, Y, ~, YE] = ode113(@(t, y) ode_rhs(t, y, p), ...
        [0, t_end], y0(:), ode_opts);
    if ~isempty(YE)
        val = max(YE(end, 1), 0.0);
    else
        val = max(Y(end, 1), 0.0);
    end
end


function yss = run_to_steady_full(p, y0, t_end, ode_opts)
    [~, Y, ~, YE] = ode113(@(t, y) ode_rhs(t, y, p), ...
        [0, t_end], y0(:), ode_opts);
    if ~isempty(YE)
        yss = max(YE(end, :)', 0.0);
    else
        yss = max(Y(end, :)', 0.0);
    end
end


function [value, isterminal, direction] = steady_event(~, y, p, cfg)
    d = ode_rhs(0, y, p);
    scale = max(abs(y), cfg.ss_eps);
    value = max(abs(d) ./ scale) - cfg.ss_tol;
    isterminal = 1;
    direction  = -1;
end


function roots_x = scalar_roots(p, ns)
    K_beta = p.K * (1.0 + p.beta / p.r);
    xs = linspace(1.0e-5, K_beta * 1.5, ns);
    gv = arrayfun(@(x) scalar_balance(x, p), xs);
    roots_x = [];

    for j = 1:(numel(xs) - 1)
        if gv(j) == 0
            roots_x(end + 1) = xs(j); %#ok<AGROW>
        elseif gv(j) * gv(j + 1) < 0
            try
                xr = fzero(@(x) scalar_balance(x, p), [xs(j), xs(j + 1)]);
                roots_x(end + 1) = xr; %#ok<AGROW>
            catch
            end
        end
    end

    if isempty(roots_x), return; end
    roots_x = unique(round(roots_x, 12));
    roots_x = sort(roots_x);
end


function g = scalar_balance(X, p)
    [T, phi] = qss_tphi(X, p);
    s = phi / (1.0 + phi);
    g = p.r * (1.0 - X / p.K) ...
      - p.alpha * X * T / (p.g1^2 + X^2) ...
      + p.beta * s;
end


function [T, phi] = qss_tphi(X, p)
    T = p.sigma / p.mu;
    for iter = 1:200
        phi = (p.delta1 * X + p.delta2 * T) / p.lam;
        T_new = p.sigma / (p.mu + p.gamma * phi / (1.0 + phi));
        if abs(T_new - T) < 1.0e-14
            T = T_new;
            break;
        end
        T = T_new;
    end
    phi = (p.delta1 * X + p.delta2 * T) / p.lam;
end


% ================================================================
%  LAYER 7 — UTILITIES
% ================================================================

function cmap = build_divergent_cmap(c1, c2, c3, c4, c5, n)
%BUILD_DIVERGENT_CMAP  Blue–white–red divergent colourmap.
%   c1 = deep blue, c2 = mid blue, c3 = white, c4 = mid red, c5 = deep red.
    half = floor(n / 2);
    seg1 = interp_colors(c1, c2, round(half * 0.4));
    seg2 = interp_colors(c2, c3, round(half * 0.6));
    seg3 = interp_colors(c3, c4, round(half * 0.6));
    seg4 = interp_colors(c4, c5, round(half * 0.4));
    cmap = [seg1; seg2(2:end, :); seg3(2:end, :); seg4(2:end, :)];
    % Ensure exactly n rows
    if size(cmap, 1) > n
        cmap = cmap(1:n, :);
    elseif size(cmap, 1) < n
        cmap = [cmap; repmat(cmap(end, :), n - size(cmap, 1), 1)];
    end
end


function c = interp_colors(c_start, c_end, n)
    t = linspace(0, 1, n)';
    c = (1 - t) .* c_start + t .* c_end;
end


function arr_s = smooth2d_gaussian(arr, sigma)
    if sigma <= 0
        arr_s = arr;
        return;
    end
    radius = max(1, ceil(3 * sigma));
    idx = -radius:radius;
    g = exp(-(idx .^ 2) / (2 * sigma ^ 2));
    g = g / sum(g);
    arr_s = conv2(g, g, arr, 'same');
end


function finish_axes(ax)
    set(ax, 'Color', 'w');
    set(ax, ...
        'Box',        'off', ...
        'Layer',      'top', ...
        'LineWidth',  1.0, ...
        'TickDir',    'out', ...
        'TickLength', [0.014, 0.008], ...
        'FontName',   'Times New Roman', ...
        'FontSize',   16, ...
        'XColor',     [0, 0, 0], ...
        'YColor',     [0, 0, 0], ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on');

    xl = xlim(ax);
    yl = ylim(ax);

    line(ax, xl, [yl(2) yl(2)], ...
        'Color', [0 0 0], 'LineWidth', 1.0, ...
        'Clipping', 'off', 'HandleVisibility', 'off');
    line(ax, [xl(2) xl(2)], yl, ...
        'Color', [0 0 0], 'LineWidth', 1.0, ...
        'Clipping', 'off', 'HandleVisibility', 'off');
end


function style_legend(lgd)
    lgd.TextColor = [0, 0, 0];
    lgd.FontName  = 'Times New Roman';
    lgd.FontSize  = 14;
    lgd.Box       = 'off';
    lgd.Color     = 'none';
end


function save_run_data(paths, data, p, ic, cfg)
    data_dir = fullfile(paths.root, 'data');
    ensure_dir(data_dir);
    metadata = release_metadata('S3', cfg);
    save(fullfile(data_dir, ['S3_data_' char(cfg.profile) '.mat']), ...
        'data', 'p', 'ic', 'cfg', 'metadata', '-v7.3');
    fprintf('  -> %s\n', fullfile(data_dir, ['S3_data_' char(cfg.profile) '.mat']));
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
    set(groot, 'defaultFigureColor', 'w');
    set(groot, 'defaultAxesColor', 'w');
    set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
    set(groot, 'defaultLegendInterpreter',        'latex');
    set(groot, 'defaultTextInterpreter',           'latex');
    set(groot, 'defaultAxesFontName',              'Times New Roman');
    set(groot, 'defaultTextFontName',              'Times New Roman');
end


function save_figure_bundle(fig, stem, cfg)
    exportgraphics(fig, [stem '.png'], ...
        'Resolution', cfg.png_dpi, 'BackgroundColor', 'white');
    exportgraphics(fig, [stem '.pdf'], ...
        'ContentType', 'vector', 'BackgroundColor', 'white');
    close(fig);
    fprintf('  -> %s.png\n', stem);
    fprintf('  -> %s.pdf\n', stem);
end


function ensure_dir(pathstr)
    if ~exist(pathstr, 'dir')
        mkdir(pathstr);
    end
end


function rgb = hex2rgb(hex)
    hex = char(hex);
    if hex(1) == '#'
        hex = hex(2:end);
    end
    rgb = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255.0;
end
