function make_S1_matlab(profile)
%MAKE_S1_MATLAB Build supplementary Figure S1 in MATLAB.
%   make_S1_matlab() builds the draft profile.
%   make_S1_matlab("final") builds the denser final profile.
%
% Output:
%   simulations/paper/R2/matlab_outputs/S1/panels
%   simulations/paper/R2/matlab_outputs/S1/previews

if nargin < 1
    profile = "draft";
end
profile = string(profile);
if ~ismember(profile, ["draft", "final", "publication"])
    error('Profile must be "draft", "final", or "publication".');
end

cfg = local_config(profile);
p = base_params();
ic = base_ics();
paths = local_paths();

ensure_dir(paths.out_root);
ensure_dir(paths.panels);
ensure_dir(paths.previews);

setup_style();

fprintf('============================================================\n');
fprintf(' MATLAB Supplementary Figure S1\n');
fprintf(' Profile: %s\n', profile);
fprintf(' Output : %s\n', paths.out_root);
fprintf('============================================================\n');

data = compute_s1_data(p, ic, cfg);
save_run_data(paths, data, p, ic, cfg);
export_s1(data, p, cfg, paths);

fprintf('============================================================\n');
fprintf(' Done.\n');
fprintf(' Panels : %s\n', paths.panels);
fprintf(' Preview: %s\n', paths.previews);
fprintf('============================================================\n');

end


function cfg = local_config(profile)
cfg.profile = profile;
cfg.ss_end = 300.0;
cfg.ss_tol = 1.0e-8;
cfg.ss_eps = 1.0e-12;
cfg.root_threshold = 0.08;
% Reference fold values from the independent continuation check.
% The grid-based estimate is stored separately as data.lam_c_grid_estimate.
cfg.fold_lower_ref = 0.1847487613;
cfg.fold_upper_ref = 1.0576546030;
cfg.time_end = 350.0;
cfg.lam_values = [0.12, 0.15, 0.18, 0.19, 0.40];
cfg.paper_ic = [0.30; 0.50; 0.05];
cfg.interp_multiplier = 4;
cfg.png_dpi = 500;
cfg.b_inset_xlim = [0.0, 25.0];
cfg.b_inset_ylim = [0.0, 0.3];

switch profile
    case "draft"
        cfg.s1_lam_main = 90;
        cfg.s1_lam_refine_low = 40;
        cfg.s1_lam_refine_high = 30;
        cfg.s1_lam_refine_critical = 36;
        cfg.s1_t_points = 1800;
        cfg.root_ns = 900;
    case "final"
        cfg.s1_lam_main = 180;
        cfg.s1_lam_refine_low = 90;
        cfg.s1_lam_refine_high = 70;
        cfg.s1_lam_refine_critical = 80;
        cfg.s1_t_points = 3500;
        cfg.root_ns = 1600;
        cfg.interp_multiplier = 6;
    case "publication"
        cfg.s1_lam_main = 240;
        cfg.s1_lam_refine_low = 120;
        cfg.s1_lam_refine_high = 90;
        cfg.s1_lam_refine_critical = 120;
        cfg.s1_t_points = 4500;
        cfg.root_ns = 2200;
        cfg.interp_multiplier = 6;
        cfg.png_dpi = 600;
end

cfg.colors.red = hex2rgb('#B61C2E');
cfg.colors.orange = hex2rgb('#E66100');
cfg.colors.gold = hex2rgb('#D8A10A');
cfg.colors.purple = hex2rgb('#5B3FA3');
cfg.colors.blue = hex2rgb('#2B6CB0');
cfg.colors.grey = hex2rgb('#595959');
cfg.colors.grey_light = hex2rgb('#9C9C9C');
cfg.colors.fill_ctrl = hex2rgb('#DDEAF7');
cfg.colors.fill_ctrl_band = hex2rgb('#DDEAF7');
cfg.colors.fill_escape_band = hex2rgb('#F4D8D8');
cfg.colors.annotation = hex2rgb('#444444');
cfg.colors.label_escape = hex2rgb('#8B0000');
cfg.colors.label_ctrl = hex2rgb('#1F5A92');
end


function p = base_params()
p = struct( ...
    'r', 0.5, ...
    'K', 1.0, ...
    'alpha', 0.9, ...
    'g1', 0.15, ...
    'sigma', 0.10, ...
    'mu', 0.15, ...
    'beta', 0.30, ...
    'gamma', 2.0, ...
    'delta1', 0.40, ...
    'delta2', 0.03, ...
    'lam', 0.30);
end


function ic = base_ics()
ic = struct();
ic.ctrl = [0.05; 0.50; 0.01];
ic.esc = [1.20; 0.05; 5.00];
ic.paper = [0.30; 0.50; 0.05];
end


function paths = local_paths()
base_dir = fileparts(mfilename('fullpath'));
paths.out_root = fullfile(base_dir, 'matlab_outputs', 'S1');
paths.panels = fullfile(paths.out_root, 'panels');
paths.previews = fullfile(paths.out_root, 'previews');
end


function data = compute_s1_data(p, ic, cfg)
lam_arr = unique(sort([ ...
    linspace(0.02, 1.50, cfg.s1_lam_main), ...
    linspace(0.12, 0.26, cfg.s1_lam_refine_low), ...
    linspace(0.175, 0.195, cfg.s1_lam_refine_critical), ...
    linspace(0.85, 1.35, cfg.s1_lam_refine_high)]));

fprintf('[1/3] Steady states on %d lambda values ...\n', numel(lam_arr));
Xc = nan(size(lam_arr));
Xe = nan(size(lam_arr));
for k = 1:numel(lam_arr)
    pk = p;
    pk.lam = lam_arr(k);
    y_ctrl = steady_state(pk, ic.ctrl, cfg);
    y_esc = steady_state(pk, ic.esc, cfg);
    Xc(k) = y_ctrl(1);
    Xe(k) = y_esc(1);
end

fprintf('[2/3] Saddle branch via scalar root search ...\n');
Xs = nan(size(lam_arr));
for k = 1:numel(lam_arr)
    if abs(Xe(k) - Xc(k)) > cfg.root_threshold
        pk = p;
        pk.lam = lam_arr(k);
        rr = scalar_roots(pk, cfg.root_ns);
        if numel(rr) >= 3
            Xs(k) = rr(2);
        end
    end
end

bist = abs(Xe - Xc) > cfg.root_threshold;
first_bist = find(bist, 1, 'first');
if isempty(first_bist)
    lam_c_grid_estimate = NaN;
else
    lam_c_grid_estimate = lam_arr(first_bist);
end
lam_c = cfg.fold_lower_ref;

fprintf('[3/3] Time series panel ...\n');
t_eval = linspace(0.0, cfg.time_end, cfg.s1_t_points);

[t_ref, x_ref] = no_messenger_trajectory(p, ic.paper(1:2), t_eval);

lam_values = cfg.lam_values;
X_paths = zeros(numel(lam_values), numel(t_eval));
for k = 1:numel(lam_values)
    pk = p;
    pk.lam = lam_values(k);
    [~, x_path] = full_trajectory(pk, cfg.paper_ic, t_eval);
    X_paths(k, :) = x_path;
end

data = struct();
data.lam_arr = lam_arr;
data.Xc = Xc;
data.Xe = Xe;
data.Xs = Xs;
data.bist = bist;
data.lam_c = lam_c;
data.lam_c_grid_estimate = lam_c_grid_estimate;
data.lam_upper_ref = cfg.fold_upper_ref;
data.t_ref = t_ref;
data.X_ref = x_ref;
data.t_series = t_eval;
data.lam_values = lam_values;
data.X_paths = X_paths;
end


function yss = steady_state(p, y0, cfg)
opts = odeset( ...
    'RelTol', 1.0e-9, ...
    'AbsTol', 1.0e-11, ...
    'MaxStep', 0.5, ...
    'Events', @(t, y) steady_event(t, y, p, cfg));

[~, Y, TE, YE] = ode113(@(t, y) rhs_full(t, y, p), [0.0, cfg.ss_end], y0(:), opts); %#ok<ASGLU>
if ~isempty(YE)
    yss = YE(end, :).';
else
    yss = Y(end, :).';
end
yss = max(yss, 0.0);
end


function [value, isterminal, direction] = steady_event(~, y, p, cfg)
d = rhs_full(0.0, y, p);
scale = max(abs(y), cfg.ss_eps);
value = max(abs(d) ./ scale) - cfg.ss_tol;
isterminal = 1;
direction = -1;
end


function dy = rhs_full(~, y, p)
X = max(y(1), 0.0);
T = max(y(2), 0.0);
phi = max(y(3), 0.0);

s = phi / (1.0 + phi);
g2 = p.g1 ^ 2;

dX = p.r * X * (1.0 - X / p.K) - p.alpha * X ^ 2 * T / (g2 + X ^ 2) + p.beta * X * s;
dT = p.sigma - p.mu * T - p.gamma * T * s;
dphi = p.delta1 * X + p.delta2 * T - p.lam * phi;

dy = [dX; dT; dphi];
end


function dy = rhs_no_messenger(~, y, p)
X = max(y(1), 0.0);
T = max(y(2), 0.0);
g2 = p.g1 ^ 2;

dX = p.r * X * (1.0 - X / p.K) - p.alpha * X ^ 2 * T / (g2 + X ^ 2);
dT = p.sigma - p.mu * T;

dy = [dX; dT];
end


function [t_eval, x_path] = full_trajectory(p, y0, t_eval)
opts = odeset('RelTol', 1.0e-10, 'AbsTol', 1.0e-12);
sol = ode113(@(t, y) rhs_full(t, y, p), [t_eval(1), t_eval(end)], y0(:), opts);
Y = deval(sol, t_eval);
x_path = Y(1, :);
end


function [t_eval, x_path] = no_messenger_trajectory(p, y0, t_eval)
opts = odeset('RelTol', 1.0e-10, 'AbsTol', 1.0e-12);
sol = ode113(@(t, y) rhs_no_messenger(t, y, p), [t_eval(1), t_eval(end)], y0(:), opts);
Y = deval(sol, t_eval);
x_path = Y(1, :);
end


function roots_x = scalar_roots(p, ns)
xs = linspace(1.0e-5, p.K * 1.6, ns);
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

if isempty(roots_x)
    return;
end

roots_x = unique(round(roots_x, 12));
roots_x = sort(roots_x);
end


function g = scalar_balance(X, p)
[T, phi] = qss_tphi(X, p);
s = phi / (1.0 + phi);
g = p.r * (1.0 - X / p.K) - p.alpha * X * T / (p.g1 ^ 2 + X ^ 2) + p.beta * s;
end


function [T, phi] = qss_tphi(X, p)
T = p.sigma / p.mu;
for k = 1:200
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


function export_s1(data, p, cfg, paths)
panel_a = figure('Color', 'w', 'Units', 'inches', 'Position', [0.5, 0.5, 6.0, 5.4]);
ax = axes('Parent', panel_a, 'Position', [0.13, 0.12, 0.80, 0.80]);
plot_panel_a(ax, data, cfg);
save_figure(panel_a, fullfile(paths.panels, "S1_panelA_" + cfg.profile), cfg);

panel_b = figure('Color', 'w', 'Units', 'inches', 'Position', [0.5, 0.5, 10.8, 5.4]);
ax = axes('Parent', panel_b, 'Position', [0.08, 0.12, 0.88, 0.80]);
plot_panel_b(ax, data, p, cfg);
save_figure(panel_b, fullfile(paths.panels, "S1_panelB_" + cfg.profile), cfg);

panel_b_inset = figure('Color', 'w', 'Units', 'inches', 'Position', [0.5, 0.5, 3.5, 3.0]);
ax = axes('Parent', panel_b_inset, 'Position', [0.14, 0.16, 0.80, 0.78]);
plot_panel_b_inset(ax, data, cfg);
save_figure(panel_b_inset, fullfile(paths.panels, "S1_panelB_inset_" + cfg.profile), cfg);

preview = figure('Color', 'w', 'Units', 'inches', 'Position', [0.4, 0.4, 16.0, 5.3]);
ax1 = axes('Parent', preview, 'Position', [0.06, 0.12, 0.30, 0.80]);
ax2 = axes('Parent', preview, 'Position', [0.44, 0.12, 0.52, 0.80]);
plot_panel_a(ax1, data, cfg);
plot_panel_b(ax2, data, p, cfg);
save_figure(preview, fullfile(paths.previews, "S1_preview_" + cfg.profile), cfg);
end


function plot_panel_a(ax, data, cfg)
lam_arr = data.lam_arr;
Xc = data.Xc;
Xe = data.Xe;
Xs = data.Xs;
bist = data.bist;
lam_c = data.lam_c;

hold(ax, 'on');

mask_b = bist & (Xe > Xc + cfg.root_threshold);
if any(mask_b)
    x_fill = lam_arr(mask_b);
    y_lo = Xc(mask_b);
    y_hi = Xe(mask_b);
    [x_fill_s, y_lo_s] = smooth_curve(x_fill, y_lo, cfg.interp_multiplier);
    [~, y_hi_s] = smooth_curve(x_fill, y_hi, cfg.interp_multiplier);
    patch(ax, [x_fill_s, fliplr(x_fill_s)], [y_lo_s, fliplr(y_hi_s)], ...
        cfg.colors.fill_ctrl, 'EdgeColor', 'none', 'FaceAlpha', 0.42, ...
        'HandleVisibility', 'off');
end

mask_e = bist & (Xe > Xc + cfg.root_threshold);
[x_e, y_e] = smooth_curve(lam_arr(mask_e), Xe(mask_e), cfg.interp_multiplier);
plot(ax, x_e, y_e, 'Color', cfg.colors.red, 'LineWidth', 1.9, ...
    'DisplayName', '$E_{\mathrm{esc}}$ (stable)');

mask_s = isfinite(Xs);
if any(mask_s)
    [x_s, y_s] = smooth_curve(lam_arr(mask_s), Xs(mask_s), cfg.interp_multiplier);
    plot(ax, x_s, y_s, '--', 'Color', cfg.colors.grey, 'LineWidth', 1.5, ...
        'DisplayName', '$E_{\mathrm{sad}}$ (unstable)');
    idx_s = find(mask_s);
    for idx = [idx_s(1), idx_s(end)]
        plot(ax, lam_arr(idx), Xs(idx), 'o', ...
            'MarkerSize', 8.5, ...
            'MarkerFaceColor', 'w', ...
            'MarkerEdgeColor', cfg.colors.grey, ...
            'LineWidth', 1.0, ...
            'HandleVisibility', 'off');
    end
end

mask_c = Xc < 0.4;
[x_c, y_c] = smooth_curve(lam_arr(mask_c), Xc(mask_c), cfg.interp_multiplier);
plot(ax, x_c, y_c, 'Color', cfg.colors.blue, 'LineWidth', 1.9, ...
    'DisplayName', '$E_{\mathrm{coex}}$ (stable)');

xline(ax, lam_c, ':', ...
    'Color', [0.68, 0.68, 0.68], ...
    'LineWidth', 1.2, ...
    'HandleVisibility', 'off');

text(ax, 0.075, 0.48, ...
    {'Monostable (escape only)'}, ...
    'Units', 'normalized', ...
    'Interpreter', 'latex', ...
    'Rotation', 90, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 14, ...
    'Color', [0.40, 0.40, 0.40], ...
    'BackgroundColor', [0.97, 0.97, 0.97], ...
    'Margin', 3);

text(ax, lam_c-0.01, 0.48, ...
    { sprintf('$\\lambda_c \\approx %.3f$', lam_c)}, ...
    'Units', 'normalized', ...
    'Interpreter', 'latex', ...
    'Rotation', 90, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 14, ...
    'Color', [0.35, 0.35, 0.35], ...
    'BackgroundColor', 'none', ...
    'Margin', 1);

text(ax, 0.5, 0.54, 'Bistable region', ...
    'Units', 'normalized', ...
    'Interpreter', 'latex', ...
    'FontSize', 22, ...
    'FontAngle', 'italic', ...
    'Color', cfg.colors.blue, ...
    'HorizontalAlignment', 'center');

xlabel(ax, 'TGF-$\beta$ clearance coefficient $\lambda_1$', 'Interpreter', 'latex');
ylabel(ax, 'Asymptotic tumour density $X^\ast$', 'Interpreter', 'latex');
xlim(ax, [0.0, 1.1]);
ylim(ax, [-0.02, 1.38]);
set(ax, 'XTick', 0:0.25:1.5);
finish_axes(ax);

lgd = legend(ax, 'Location', 'northeast', 'Interpreter', 'latex', 'Box', 'off');
style_legend(lgd);
end


function plot_panel_b(ax, data, p, cfg)
hold(ax, 'on');

patch(ax, [0, 350, 350, 0], [1.28, 1.28, 1.55, 1.55], ...
    cfg.colors.fill_escape_band, 'FaceAlpha', 0.28, 'EdgeColor', 'none', ...
    'HandleVisibility', 'off');
patch(ax, [0, 350, 350, 0], [0.00, 0.00, 0.14, 0.14], ...
    cfg.colors.fill_ctrl_band, 'FaceAlpha', 0.28, 'EdgeColor', 'none', ...
    'HandleVisibility', 'off');

yline(ax, p.K, ':', 'Color', cfg.colors.grey_light, 'LineWidth', 1.2, 'HandleVisibility', 'off');
text(ax, 10, p.K + 0.0, '$K$', ...
    'Interpreter', 'latex', 'FontSize', 14, 'Color', [0.45, 0.45, 0.45], ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');

[x_ref, y_ref] = smooth_curve(data.t_ref, data.X_ref, cfg.interp_multiplier);
plot(ax, x_ref+3, y_ref, '--', 'Color', cfg.colors.grey, 'LineWidth', 2.0, ...
    'DisplayName', 'No messenger ($\varphi = 0$)');

time_colors = [
    cfg.colors.red;
    cfg.colors.orange;
    cfg.colors.gold;
    cfg.colors.purple;
    cfg.colors.blue];

for k = 1:numel(data.lam_values)
    [xk, yk] = smooth_curve(data.t_series, data.X_paths(k, :), cfg.interp_multiplier);
    if data.lam_values(k) < data.lam_c
        label = sprintf('$\\lambda_1 = %.2f\\;(< \\lambda_c)$', data.lam_values(k));
    else
        label = sprintf('$\\lambda_1 = %.2f\\;(> \\lambda_c)$', data.lam_values(k));
    end
    plot(ax, xk, yk, 'Color', time_colors(k, :), 'LineWidth', 2.2, 'DisplayName', label);
end

text(ax, 0.65, 0.75, '$X(0)=0.3,\;T(0)=0.5,\;\varphi(0)=0.05$', ...
    'Units', 'normalized', ...
    'Interpreter', 'latex', ...
    'FontSize', 14, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'BackgroundColor', [0.99, 0.99, 0.99], ...
    'Margin', 3);

text(ax, 0.98, 0.56, {sprintf('Saddle-node bifurcation $\\lambda_c \\approx %.3f$', data.lam_c)}, ...
    'Units', 'normalized', ...
    'Interpreter', 'latex', ...
    'FontSize', 13, ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'middle', ...
    'FontAngle', 'italic', ...
    'Color', cfg.colors.annotation, ...
    'BackgroundColor', [0.99, 0.99, 0.96], ...
    'Margin', 4);

text(ax, 320, 1.485, 'Tumour escape', ...
    'Interpreter', 'latex', ...
    'FontSize', 18, ...
    'FontAngle', 'italic', ...
    'FontWeight', 'bold', ...
    'Color', cfg.colors.label_escape, ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'middle');

text(ax, 333, 0.065, 'Immune control', ...
    'Interpreter', 'latex', ...
    'FontSize', 18, ...
    'FontAngle', 'italic', ...
    'FontWeight', 'bold', ...
    'Color', cfg.colors.label_ctrl, ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'bottom');

xlabel(ax, 'Time $t$', 'Interpreter', 'latex');
ylabel(ax, 'Cancer cell density $X(t)$', 'Interpreter', 'latex');
xlim(ax, [0.0, 350.0]);
%set(ax, 'XScale', 'log');
%xlim(ax, [1, 350]);
ylim(ax, [-0.03, 1.55]);
set(ax, 'XTick', 0:50:350);
finish_axes(ax);

lgd = legend(ax, 'Interpreter', 'latex', 'Box', 'off');
lgd.Units = 'normalized';
ax_pos = ax.Position;
lgd.Position = [ax_pos(1) + 0.75 * ax_pos(3), ...
                ax_pos(2) + 0.18 * ax_pos(4), ...
                0.25 * ax_pos(3), ...
                0.30 * ax_pos(4)];
style_legend(lgd);
end


function plot_panel_b_inset(ax, data, cfg)
hold(ax, 'on');

[x_ref, y_ref] = smooth_curve(data.t_ref, data.X_ref, cfg.interp_multiplier);
plot(ax, x_ref + 3, y_ref, '--', 'Color', cfg.colors.grey, 'LineWidth', 3.0, ...
    'HandleVisibility', 'off');

time_colors = [
    cfg.colors.red;
    cfg.colors.orange;
    cfg.colors.gold;
    cfg.colors.purple;
    cfg.colors.blue];

for k = 1:numel(data.lam_values)
    [xk, yk] = smooth_curve(data.t_series, data.X_paths(k, :), cfg.interp_multiplier);
    plot(ax, xk, yk, 'Color', time_colors(k, :), 'LineWidth', 3.0, ...
        'HandleVisibility', 'off');
end

xlim(ax, cfg.b_inset_xlim);
ylim(ax, cfg.b_inset_ylim);
set(ax, 'XTick', 0:20:80);
set(ax, 'YTick', 0:0.1:0.4);
finish_axes(ax);
set(ax, 'FontSize', 20);
xlabel(ax, '');
ylabel(ax, '');
end


function save_figure(fig, base_path, cfg)
exportgraphics(fig, base_path + ".png", 'Resolution', cfg.png_dpi, 'BackgroundColor', 'white');
exportgraphics(fig, base_path + ".pdf", 'ContentType', 'vector', 'BackgroundColor', 'white');
close(fig);
fprintf('  -> %s.png\n', base_path);
fprintf('  -> %s.pdf\n', base_path);
end


function finish_axes(ax)
    set(ax, 'Color', 'w');
    set(ax, ...
        'Box', 'off', ...
        'Layer', 'top', ...
        'LineWidth', 1.0, ...
        'TickDir', 'in', ...
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
lgd.FontName = 'Times New Roman';
lgd.FontSize = 12;
lgd.TextColor = [0.20, 0.20, 0.20];
lgd.EdgeColor = [0.25, 0.25, 0.25];
lgd.Color = [1.0, 1.0, 1.0];
lgd.LineWidth = 1.0;
end


function [xq, yq] = smooth_curve(x, y, multiplier)
x = x(:).';
y = y(:).';
mask = isfinite(x) & isfinite(y);
x = x(mask);
y = y(mask);

if numel(x) < 4
    xq = x;
    yq = y;
    return;
end

[x, uniq_idx] = unique(x);
y = y(uniq_idx);
nq = max(numel(x) * multiplier, 300);
xq = linspace(x(1), x(end), nq);
yq = pchip(x, y, xq);
end


function save_run_data(paths, data, p, ic, cfg)
data_dir = fullfile(paths.out_root, 'data');
ensure_dir(data_dir);
metadata = release_metadata('S1', cfg);
save(fullfile(data_dir, "S1_data_" + cfg.profile + ".mat"), ...
    'data', 'p', 'ic', 'cfg', 'metadata', '-v7.3');
fprintf('  -> %s\n', fullfile(data_dir, "S1_data_" + cfg.profile + ".mat"));
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


function ensure_dir(path_str)
if exist(path_str, 'dir') ~= 7
    mkdir(path_str);
end
end


function rgb = hex2rgb(hex)
hex = char(strrep(hex, '#', ''));
rgb = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255.0;
end
