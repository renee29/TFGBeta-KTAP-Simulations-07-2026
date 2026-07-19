function make_S2_matlab(profile)
%MAKE_S2_MATLAB Reproduce supplementary Figure S2 in MATLAB.
%   make_S2_matlab() generates draft-quality panel A (basins of attraction),
%   panel B (treatment trajectories), and a 1x2 preview under
%   matlab_outputs/S2/.
%
%   make_S2_matlab("final") switches to a denser grid for the basin panel.

    if nargin < 1
        profile = "draft";
    end

    profile = validatestring(char(profile), {'draft', 'final', 'publication'});

    cfg = local_config(profile);
    p = base_params();
    ic = base_initial_conditions();
    paths = local_paths();

    ensure_dir(paths.root);
    ensure_dir(paths.panels);
    ensure_dir(paths.previews);

    setup_style();

    fprintf('============================================================\n');
    fprintf(' MATLAB Supplementary Figure S2\n');
    fprintf(' Profile: %s\n', char(cfg.profile));
    fprintf(' Output : %s\n', paths.root);
    fprintf('============================================================\n');

    data = compute_s2_data(p, ic, cfg);
    save_run_data(paths, data, p, ic, cfg);
    export_s2(data, p, ic, cfg, paths);

    fprintf('============================================================\n');
    fprintf(' Done.\n');
    fprintf(' Panels : %s\n', paths.panels);
    fprintf(' Preview: %s\n', paths.previews);
    fprintf('============================================================\n');
end


function cfg = local_config(profile)
    cfg.profile = string(profile);

    switch profile
        case 'publication'
            cfg.basin_n = 260;
            cfg.basin_t_end = 500.0;
            cfg.ss_tol = 5.0e-9;
            cfg.progress_every = 20;
        case 'final'
            cfg.basin_n = 220;
            %cfg.basin_n = 46;
            cfg.basin_t_end = 300.0;
            cfg.ss_tol = 1.0e-8;
            cfg.progress_every = 10;
        otherwise  % draft
            cfg.basin_n = 220;
            %cfg.basin_n = 46;
            cfg.basin_t_end = 220.0;
            cfg.ss_tol = 1.0e-6;
            cfg.progress_every = 4;
    end

    cfg.ss_eps = 1.0e-12;

    cfg.figure_a_pos = [0.5, 0.5, 6.1, 6.0];
    cfg.figure_b_pos = [0.5, 0.5, 8.8, 5.2];
    cfg.preview_pos = [0.5, 0.5, 14.0, 6.0];

    cfg.basin_sigma = 1.0;
    cfg.basin_threshold = 0.5;
    cfg.ic_marker = [0.30, 0.50];
    cfg.png_dpi = 600;
    cfg.phi0 = 0.05;
    cfg.lam_basin = 0.25;
    cfg.basin_xmin = 0.01;
    cfg.basin_xmax = 20.0;
    cfg.basin_tmin = 0.01;
    cfg.basin_tmax = 20.0;

    cfg.t_treat = 50.0;
    cfg.t_end = 210.0;
    cfg.reductions = [0.0, 0.30, 0.50, 0.70];
    switch profile
        case 'publication'
            cfg.treat_pre_n = 1200;
            cfg.treat_post_n = 1600;
        case 'final'
            cfg.treat_pre_n = 1200;
            cfg.treat_post_n = 1600;
        otherwise  % draft
            cfg.treat_pre_n = 700;
            cfg.treat_post_n = 900;
    end

    cfg.colors.ctrl = hex2rgb('#DDEAF7');
    cfg.colors.esc = hex2rgb('#F4D8D8');
    cfg.colors.ctrl_band = hex2rgb('#DDEAF7');
    cfg.colors.treat_span = hex2rgb('#E4EFE3');
    cfg.colors.grey = [0.38, 0.38, 0.38];
    cfg.colors.annotation = [0.00, 0.00, 0.00];
    cfg.colors.black = [0.00, 0.00, 0.00];
    cfg.colors.white = [1.00, 1.00, 1.00];
    cfg.colors.time = [
        0.68, 0.68, 0.68;  % 0% reduction
        0.15, 0.46, 0.72;  % 30%
        0.20, 0.62, 0.22;  % 50%
        1.00, 0.50, 0.00   % 70%
    ];

    % Manual legend placement (relative to axes: [x y w h], all in [0, 1]).
    % Tune these values to move only the labels panel (legend).
    cfg.legend_manual = true;
    cfg.legend_rel_pos = [0.65, 0.2, 0.34, 0.23];

    cfg.ss_ode_opts = odeset( ...
        'RelTol', 1e-8, ...
        'AbsTol', 1e-10, ...
        'MaxStep', 0.5, ...
        'NonNegative', 1:3);

    cfg.ode_opts = odeset( ...
        'RelTol', 1e-9, ...
        'AbsTol', 1e-11, ...
        'NonNegative', 1:3);
end


function p = base_params()
    p.r = 0.50;
    p.K = 1.00;
    p.alpha = 0.90;
    p.g1 = 0.15;
    p.beta = 0.30;
    p.sigma = 0.10;
    p.mu = 0.15;
    p.gamma = 2.00;
    p.delta1 = 0.40;
    p.delta2 = 0.03;
    p.lam = 0.30;
end


function ic = base_initial_conditions()
    ic.marker = [0.30, 0.50, 0.05];
    ic.treatment = [1.20, 0.05, 5.00];
end


function paths = local_paths()
    here = fileparts(mfilename('fullpath'));
    paths.root = fullfile(here, 'matlab_outputs', 'S2');
    paths.panels = fullfile(paths.root, 'panels');
    paths.previews = fullfile(paths.root, 'previews');
end


function data = compute_s2_data(p, ic, cfg)
    data = struct();

    fprintf('[1/2] Treatment trajectories ...\n');
    data.treatment = compute_treatment_panel(p, ic.treatment, cfg);

    fprintf('[2/2] Basin map on %d x %d grid ...\n', cfg.basin_n, cfg.basin_n);
    data.basin = compute_basin_panel(p, cfg);
end


function basin = compute_basin_panel(p_base, cfg)
    p = p_base;
    p.lam = cfg.lam_basin;
    ss_ode_opts = odeset(cfg.ss_ode_opts, 'Events', @(t, y) steady_event(t, y, p, cfg));

    X0r = geomspace_local(cfg.basin_xmin, cfg.basin_xmax, cfg.basin_n);
    T0r = geomspace_local(cfg.basin_tmin, cfg.basin_tmax, cfg.basin_n);

    Xf = zeros(numel(X0r), numel(T0r));

    for ix = 1:numel(X0r)
        for it = 1:numel(T0r)
            y0 = [X0r(ix), T0r(it), cfg.phi0];
            Xf(ix, it) = asymptotic_tumor_density(p, y0, cfg.basin_t_end, ss_ode_opts);
        end

        if mod(ix, cfg.progress_every) == 0 || ix == numel(X0r)
            fprintf('  basin row %d / %d\n', ix, numel(X0r));
            drawnow;
        end
    end

    Xf_s = smooth2d_gaussian(Xf, cfg.basin_sigma);
    cls = double(Xf_s > cfg.basin_threshold);

    basin = struct();
    basin.X0r = X0r;
    basin.T0r = T0r;
    basin.Xf = Xf;
    basin.Xf_s = Xf_s;
    basin.cls = cls;
end


function treatment = compute_treatment_panel(p_base, ic, cfg)
    reductions = cfg.reductions;
    t_treat = cfg.t_treat;
    t_end = cfg.t_end;
    t_eval1 = linspace(0.0, t_treat, cfg.treat_pre_n);
    t_eval2 = linspace(t_treat, t_end, cfg.treat_post_n);

    [t_pre, y_pre] = ode113(@(t, y) ode_rhs(t, y, p_base), t_eval1, ic, cfg.ode_opts);
    y_treat = y_pre(end, :);

    traces = cell(numel(reductions), 1);
    for k = 1:numel(reductions)
        eps = reductions(k);
        p_post = p_base;
        p_post.delta1 = p_base.delta1 * (1.0 - eps);

        [t_post, y_post] = ode113(@(t, y) ode_rhs(t, y, p_post), t_eval2, y_treat, cfg.ode_opts);

        traces{k} = struct( ...
            'reduction', eps, ...
            't_pre', t_pre, ...
            'x_pre', y_pre(:, 1), ...
            't_post', t_post, ...
            'x_post', y_post(:, 1));
    end

    treatment = struct();
    treatment.traces = traces;
    treatment.t_treat = t_treat;
    treatment.t_end = t_end;
end


function export_s2(data, p, ic, cfg, paths)
    suffix = char(cfg.profile);

    panel_a = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.figure_a_pos);
    ax_a = axes('Parent', panel_a, 'Position', [0.14, 0.14, 0.79, 0.79]);
    plot_panel_a(ax_a, data.basin, cfg);
    save_figure_bundle(panel_a, fullfile(paths.panels, ['S2_panelA_' suffix]), cfg);

    panel_b = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.figure_b_pos);
    ax_b = axes('Parent', panel_b, 'Position', [0.10, 0.14, 0.85, 0.79]);
    plot_panel_b(ax_b, data.treatment, p, ic.treatment, cfg);
    save_figure_bundle(panel_b, fullfile(paths.panels, ['S2_panelB_' suffix]), cfg);

    preview = figure('Color', 'w', 'Units', 'inches', 'Position', cfg.preview_pos);
    tl = tiledlayout(preview, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    ax1 = nexttile(tl, 1);
    ax2 = nexttile(tl, 2);
    plot_panel_a(ax1, data.basin, cfg);
    plot_panel_b(ax2, data.treatment, p, ic.treatment, cfg);
    save_figure_bundle(preview, fullfile(paths.previews, ['S2_preview_' suffix]), cfg);
end


function plot_panel_a(ax, basin, cfg)
    hold(ax, 'on');

    x_edges = geom_edges_from_centers(basin.X0r);
    y_edges = geom_edges_from_centers(basin.T0r);

    cmap = [cfg.colors.ctrl; cfg.colors.esc];
    h = pcolor(ax, x_edges, y_edges, pad_for_pcolor(basin.cls)');
    set(h, 'EdgeColor', 'none');
    shading(ax, 'interp');
    colormap(ax, cmap);
    caxis(ax, [0, 1]);

    [~, hcont] = contour(ax, basin.X0r, basin.T0r, basin.Xf_s', [cfg.basin_threshold, cfg.basin_threshold], ...
        'LineStyle', '--', 'LineWidth', 2.0, 'LineColor', cfg.colors.black);
    hcont.HandleVisibility = 'off';

    plot(ax, cfg.ic_marker(1), cfg.ic_marker(2), 'o', ...
        'MarkerFaceColor', cfg.colors.white, ...
        'MarkerEdgeColor', cfg.colors.black, ...
        'MarkerSize', 7.5, ...
        'LineWidth', 1.3, ...
        'HandleVisibility', 'off');

    set(ax, 'XScale', 'log', 'YScale', 'log');
    xlim(ax, [basin.X0r(1), basin.X0r(end)]);
    ylim(ax, [basin.T0r(1), basin.T0r(end)]);

    xlabel(ax, 'Initial tumour load $X(0)$', 'Interpreter', 'latex', 'FontSize', 18, 'Color', cfg.colors.black);
    ylabel(ax, 'Initial T-cell level $T(0)$', 'Interpreter', 'latex', 'FontSize', 18, 'Color', cfg.colors.black);

    text(ax, 0.02, 2.9, {'Immune control'}, ...
        'Interpreter', 'latex', 'FontSize', 18, 'Color', [0.17, 0.42, 0.69], ...
        'FontWeight', 'bold', 'BackgroundColor', [1, 1, 1], 'Margin', 2);
    text(ax, 0.5, 0.085, {'Tumour escape'}, ...
        'Interpreter', 'latex', 'FontSize', 18, 'Color', [0.79, 0.19, 0.22], ...
        'FontWeight', 'bold', 'BackgroundColor', [1, 1, 1], 'Margin', 2);
    text(ax, 0.070, 0.7, {'Initial condition'}, ...
        'Interpreter', 'latex', 'FontSize', 14, 'Color', cfg.colors.black, ...
        'BackgroundColor', [1, 1, 1], 'Margin', 2);
    %text(ax, 0.16, 0.13, 'Separatrix $(W^s$ of $E_{\mathrm{sad}})$', ...
     %  'Interpreter', 'latex', 'FontSize', 13, 'Color', cfg.colors.black, ...
    %    'Rotation', -33, 'BackgroundColor', [1, 1, 1], 'Margin', 2);

    text(ax, 0.3, 0.018, sprintf('$\\lambda_1 = %.2f,\\;\\varphi(0)=%.2f$', cfg.lam_basin, cfg.phi0), ...
        'Interpreter', 'latex', 'FontSize', 14, 'Color', [0.35, 0.35, 0.35], ...
        'BackgroundColor', [1.00, 1.00, 1.00], 'Margin', 4);

    finish_axes(ax);
end


function plot_panel_b(ax, treatment, p, ic, cfg)
    hold(ax, 'on');

    % Plot all traces first to establish auto y-limits
    labels = cell(numel(treatment.traces), 1);
    for k = 1:numel(treatment.traces)
        tr = treatment.traces{k};
        col = cfg.colors.time(k, :);
        pre_col = 0.45 * col + 0.55 * cfg.colors.white;

        plot(ax, tr.t_pre, tr.x_pre, '-', 'Color', pre_col, 'LineWidth', 1.0, ...
            'HandleVisibility', 'off');
        plot(ax, tr.t_post, tr.x_post, '-', 'Color', col, 'LineWidth', 2.2);

        if tr.reduction == 0
            labels{k} = 'No treatment';
        else
            labels{k} = sprintf('%d\\%% reduction', round(100 * tr.reduction));
        end
    end

    % Set limits from auto-computed range with padding
    xlim(ax, [0.0, treatment.t_end]);
    yl = ylim(ax);
    yl = [yl(1) - 0.02, yl(2) + 0.02];
    ylim(ax, yl);

    % Background patch and decorations using actual limits
    patch(ax, [treatment.t_treat, treatment.t_end, treatment.t_end, treatment.t_treat], ...
        [yl(1), yl(1), yl(2), yl(2)], cfg.colors.treat_span, ...
        'FaceAlpha', 0.45, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    uistack(findobj(ax, 'Type', 'patch'), 'bottom');

    xline(ax, treatment.t_treat, '--', 'Color', cfg.colors.black, 'LineWidth', 1.3, 'HandleVisibility', 'off');

    xlabel(ax, 'Time $t$', 'Interpreter', 'latex', 'FontSize', 18, 'Color', cfg.colors.black);
    ylabel(ax, 'Tumour density $X(t)$', 'Interpreter', 'latex', 'FontSize', 18, 'Color', cfg.colors.black);

    text(ax, treatment.t_treat + 2.0, yl(2) - 0.04, {'Treatment start'}, ...
        'Interpreter', 'latex', 'FontSize', 14, 'Color', cfg.colors.black, ...
        'VerticalAlignment', 'top', ...
        'BackgroundColor', [1.00, 1.00, 1.00], 'Margin', 2);

    lgd = legend(ax, labels, 'Location', 'none', 'Interpreter', 'latex', 'Box', 'off');
    style_legend(lgd);
    if isfield(cfg, 'legend_manual') && cfg.legend_manual
        ax_pos = ax.Position;
        rel = cfg.legend_rel_pos;
        lgd.Units = 'normalized';
        lgd.Position = [ ...
            ax_pos(1) + rel(1) * ax_pos(3), ...
            ax_pos(2) + rel(2) * ax_pos(4), ...
            rel(3) * ax_pos(3), ...
            rel(4) * ax_pos(4)];
    end

    finish_axes(ax);
end


function val = asymptotic_tumor_density(p, y0, t_end, ode_opts)
    [~, y, ~, ye] = ode113(@(t, yy) ode_rhs(t, yy, p), [0, t_end], y0, ode_opts); %#ok<ASGLU>
    if ~isempty(ye)
        val = ye(end, 1);
    else
        val = y(end, 1);
    end
end


function [value, isterminal, direction] = steady_event(~, y, p, cfg)
    scale = max(abs(y), cfg.ss_eps);
    value = max(abs(ode_rhs(0, y, p)) ./ scale) - cfg.ss_tol;
    isterminal = 1;
    direction = -1;
end


function dy = ode_rhs(~, y, p)
    X = max(y(1), 0.0);
    T = max(y(2), 0.0);
    phi = max(y(3), 0.0);

    kill = p.alpha * (X^2 / (p.g1^2 + X^2)) * T;
    messenger = p.beta * X * phi / (1.0 + phi);
    suppress = p.gamma * T * phi / (1.0 + phi);

    dX = p.r * X * (1.0 - X / p.K) - kill + messenger;
    dT = p.sigma - p.mu * T - suppress;
    dphi = p.delta1 * X + p.delta2 * T - p.lam * phi;

    dy = [dX; dT; dphi];
end


function x = geomspace_local(a, b, n)
    x = logspace(log10(a), log10(b), n);
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


function edges = geom_edges_from_centers(c)
    edges = zeros(1, numel(c) + 1);
    edges(2:end-1) = sqrt(c(1:end-1) .* c(2:end));
    edges(1) = c(1)^2 / edges(2);
    edges(end) = c(end)^2 / edges(end-1);
end


function out = pad_for_pcolor(arr)
    out = zeros(size(arr, 1) + 1, size(arr, 2) + 1);
    out(1:end-1, 1:end-1) = arr;
    out(end, 1:end-1) = arr(end, :);
    out(1:end-1, end) = arr(:, end);
    out(end, end) = arr(end, end);
end


function finish_axes(ax)
    set(ax, 'Color', 'w');
    set(ax, ...
        'Box', 'off', ...
        'Layer', 'top', ...
        'LineWidth', 1.0, ...
        'TickDir', 'out', ...
        'TickLength', [0.014, 0.008], ...
        'FontName', 'Times New Roman', ...
        'FontSize', 16, ...
        'XColor', [0, 0, 0], ...
        'YColor', [0, 0, 0], ...
        'XMinorTick', 'on', ...
        'YMinorTick', 'on');

    xl = xlim(ax);
    yl = ylim(ax);

    line(ax, xl, [yl(2) yl(2)], ...
        'Color', [0 0 0], ...
        'LineWidth', 1.0, ...
        'Clipping', 'off', ...
        'HandleVisibility', 'off');

    line(ax, [xl(2) xl(2)], yl, ...
        'Color', [0 0 0], ...
        'LineWidth', 1.0, ...
        'Clipping', 'off', ...
        'HandleVisibility', 'off');
end


function style_legend(lgd)
    lgd.TextColor = [0, 0, 0];
    lgd.FontName = 'Times New Roman';
    lgd.FontSize = 14;
    lgd.Box = 'off';
    lgd.Color = 'none';
end


function save_run_data(paths, data, p, ic, cfg)
    data_dir = fullfile(paths.root, 'data');
    ensure_dir(data_dir);
    metadata = release_metadata('S2', cfg);
    save(fullfile(data_dir, ['S2_data_' char(cfg.profile) '.mat']), ...
        'data', 'p', 'ic', 'cfg', 'metadata', '-v7.3');
    fprintf('  -> %s\n', fullfile(data_dir, ['S2_data_' char(cfg.profile) '.mat']));
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
    set(groot, 'defaultLegendInterpreter', 'latex');
    set(groot, 'defaultTextInterpreter', 'latex');
    set(groot, 'defaultAxesFontName', 'Times New Roman');
    set(groot, 'defaultTextFontName', 'Times New Roman');
end


function save_figure_bundle(fig, stem, cfg)
    exportgraphics(fig, [stem '.png'], 'Resolution', cfg.png_dpi, 'BackgroundColor', 'white');
    exportgraphics(fig, [stem '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
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
