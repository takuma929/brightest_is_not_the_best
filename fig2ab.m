%% Figures: daylight spectra + chromatic directions (reflectance-change / illuminant-change)
%
% TM — 3rd Feb 2026
%
% This script generates three figures:
%   1) fig_sunlight_skylight.pdf
%   2) fig_chromatic_direction_refchange.pdf
%   3) fig_chromatic_direction_illchange.pdf
%
% Inputs (expected in <repo_basedir>/data):
%   - fig_params.mat (contains struct "figp")
%   - material.mat (contains variable "material")
%   - sunlight.spd, skylight.spd (2-column: wavelength[nm], energy)
%   - ill_ref_change_material_idx.mat (contains "refchange_idx", "illchange_idx")
%
% Dependencies:
%   - SplineSpd() (for visualization-only interpolation of SPDs)
%   - spectralvectortoMBandRGB_400to700nm() (maps spectra to MacLeod–Boynton coordinates)
%
% Notes:
%   - Paths are OS-independent via fullfile().
%   - Outputs are written to <repo_basedir>/figs (created if missing).
%   - This is a plotting script; it does not modify source data.

clear; close all; clc;

%% ------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------
repo_basedir = pwd;  % set explicitly if running from outside the repo root
dataDir = fullfile(repo_basedir, 'data');
outDir  = fullfile(repo_basedir, 'figs');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% ------------------------------------------------------------------------
% Load inputs
% -------------------------------------------------------------------------
% Figure parameters
S = load(fullfile(dataDir, 'fig_params.mat'));  % expects S.figp
figp = S.figp;

% Materials and indices
Smat = load(fullfile(dataDir, 'material.mat'));                 % expects Smat.material
Sidx = load(fullfile(dataDir, 'ill_ref_change_material_idx.mat')); % expects refchange_idx, illchange_idx
material      = Smat.material;
refchange_idx = Sidx.refchange_idx;
illchange_idx = Sidx.illchange_idx;

% SPDs (two-column: wavelength[nm], energy)
sunlight_raw = load(fullfile(dataDir, 'sunlight.spd'));
skylight_raw = load(fullfile(dataDir, 'skylight.spd'));

%% ------------------------------------------------------------------------
% Common settings
% -------------------------------------------------------------------------
% Plot colors (RGB)
SunRGB = [0.30, 0.30, 0.30];
SkyRGB = [0.45, 0.53, 0.73];

% Common figure sizing (uses fig_params convention)
fig_h = figp.twocolumn/4 * 0.95;
fig_w = figp.twocolumn/4 * 0.95;

% Common MB axis formatting (used by ref/ill change plots)
mb_xlim = [0.64 0.76];
mb_ylim = [0 4];
mb_xtick = [0.64 0.70 0.76];
mb_ytick = [0 2 4];

% Marker/line styling (thin, many segments)
segLineWidth = 0.2;
ptSize       = 10;
ptAlpha      = 0.5;

%% ------------------------------------------------------------------------
% (1) Plot daylight spectra (sunlight vs skylight)
% -------------------------------------------------------------------------
% Interpolate for smooth visualization only (400–700 nm)
wls = (400:700)';

skylight = SplineSpd(skylight_raw(:,1), skylight_raw(:,2), wls);
sunlight = SplineSpd(sunlight_raw(:,1), sunlight_raw(:,2), wls);

% Normalize to peak = 1 for comparison
skylight = skylight ./ max(skylight);
sunlight = sunlight ./ max(sunlight);

fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
ax  = axes(fig); hold(ax, 'on');

plot(ax, wls, skylight, 'Color', SkyRGB, 'LineWidth', 1);
plot(ax, wls, sunlight, 'Color', SunRGB, 'LineWidth', 1);

% Axis formatting
ax.XLim = [390 710];
ax.YLim = [0 1.1];
ax.XTick = [400 550 700];
ax.XTickLabel = ["400","550","700"];
ax.YTick = [0 0.5 1.0];
ax.YTickLabel = ["0.00","0.50","1.00"];

xlabel(ax, '\lambda [nm]');
ylabel(ax, 'Relative energy');

ax.FontName = 'Arial';
ax.FontSize = figp.fontsize;
ax.Color    = [0.97 0.97 0.97];
ax.XColor   = 'k';
ax.YColor   = 'k';
ax.LineWidth = 0.5;

grid(ax, 'off');
box(ax, 'off');

% Apply consistent sizing / placement
fig.Position = [10, 10, fig_w, fig_h];
ax.Units     = 'centimeters';
ax.Position  = [0.95 0.85 3.0 3.0];

% Export
exportgraphics(ax, fullfile(outDir, 'fig_sunlight_skylight.pdf'), 'ContentType', 'vector');

%% ------------------------------------------------------------------------
% Compute MacLeod–Boynton coordinates for each reflectance under each illuminant
% -------------------------------------------------------------------------
% Material format:
%   - material(:, 2:241) are reflectance spectra sampled 400–700 nm (240 samples)
% 
Ref = material(:, 2:241);  % [nRef x 240]

% Multiply reflectance by illuminant SPD (energy), then convert to MB coordinates.
% SPD vectors are expected to align with the 240-sample reflectance grid.
MB_Sunlight = spectralvectortoMB_400to700nm((Ref .* repmat(sunlight_raw(:,2), 1, 240))');
MB_Skylight = spectralvectortoMB_400to700nm((Ref .* repmat(skylight_raw(:,2), 1, 240))');

%% ------------------------------------------------------------------------
% Helper: apply consistent axis cosmetics for MB plots
% -------------------------------------------------------------------------
apply_mb_axes_style = @(axh) local_apply_mb_axes_style(axh, figp, mb_xlim, mb_ylim, mb_xtick, mb_ytick);

%% ------------------------------------------------------------------------
% (2) Reflectance-change: chromatic direction segments and endpoints
% -------------------------------------------------------------------------
fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
ax  = axes(fig); hold(ax, 'on');

% Draw line segments (chromatic change within the same illuminant)
for n = 1:size(refchange_idx, 1)
    n1 = refchange_idx(n, 1);
    n2 = refchange_idx(n, 2);
    isSun = (refchange_idx(n, 3) == 1);

    if isSun
        p1 = MB_Sunlight(n1, 1:2);
        p2 = MB_Sunlight(n2, 1:2);
        col = SunRGB;
    else
        p1 = MB_Skylight(n1, 1:2);
        p2 = MB_Skylight(n2, 1:2);
        col = SkyRGB;
    end

    l = line(ax, [p1(1) p2(1)], [p1(2) p2(2)], 'Color', col, 'LineWidth', segLineWidth);
end

% Draw endpoints (semi-transparent)
for n = 1:size(refchange_idx, 1)
    n1 = refchange_idx(n, 1);
    n2 = refchange_idx(n, 2);
    isSun = (refchange_idx(n, 3) == 1);

    if isSun
        scatter(ax, MB_Sunlight(n1,1), MB_Sunlight(n1,2), ptSize, SunRGB, 'filled', ...
            'MarkerEdgeColor','none', 'MarkerFaceAlpha', ptAlpha);
        scatter(ax, MB_Sunlight(n2,1), MB_Sunlight(n2,2), ptSize, SunRGB, 'filled', ...
            'MarkerEdgeColor','none', 'MarkerFaceAlpha', ptAlpha);
    else
        scatter(ax, MB_Skylight(n1,1), MB_Skylight(n1,2), ptSize, SkyRGB, 'filled', ...
            'MarkerEdgeColor','none', 'MarkerFaceAlpha', ptAlpha);
        scatter(ax, MB_Skylight(n2,1), MB_Skylight(n2,2), ptSize, SkyRGB, 'filled', ...
            'MarkerEdgeColor','none', 'MarkerFaceAlpha', ptAlpha);
    end
end

% Mark reference material (index 240 as in original script)
scatter(ax, MB_Sunlight(240,1), MB_Sunlight(240,2), 50, 'kx', 'LineWidth', 1);
scatter(ax, MB_Skylight(240,1), MB_Skylight(240,2), 50, 'bx', 'LineWidth', 1);

xlabel(ax, 'L/(L+M)');
ylabel(ax, 'S/(L+M)');

apply_mb_axes_style(ax);

% Apply consistent sizing / placement
fig.Position = [10, 10, fig_w, fig_h];
ax.Units     = 'centimeters';
ax.Position  = [0.95 0.85 3.0 3.0];

% Export
exportgraphics(ax, fullfile(outDir, 'fig_chromatic_direction_refchange.pdf'), 'ContentType', 'vector');

%% ------------------------------------------------------------------------
% (3) Illuminant-change: chromatic direction segments and endpoints
% -------------------------------------------------------------------------
fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
ax  = axes(fig); hold(ax, 'on');

% Draw line segments (same reflectance under two illuminants)
for n = 1:size(illchange_idx, 1)
    n1 = illchange_idx(n, 1);

    pSun = MB_Sunlight(n1, 1:2);
    pSky = MB_Skylight(n1, 1:2);

    line(ax, [pSun(1) pSky(1)], [pSun(2) pSky(2)], ...
        'Color', [0.3 0.3 0.3], 'LineWidth', segLineWidth);
end

% Draw endpoints (semi-transparent)
for n = 1:size(illchange_idx, 1)
    n1 = illchange_idx(n, 1);

    scatter(ax, MB_Sunlight(n1,1), MB_Sunlight(n1,2), ptSize, SunRGB, 'filled', ...
        'MarkerEdgeColor','none', 'MarkerFaceAlpha', ptAlpha);
    scatter(ax, MB_Skylight(n1,1), MB_Skylight(n1,2), ptSize, SkyRGB, 'filled', ...
        'MarkerEdgeColor','none', 'MarkerFaceAlpha', ptAlpha);
end

% Mark reference material (index 240)
scatter(ax, MB_Sunlight(240,1), MB_Sunlight(240,2), 50, 'kx', 'LineWidth', 1);
scatter(ax, MB_Skylight(240,1), MB_Skylight(240,2), 50, 'bx', 'LineWidth', 1);

xlabel(ax, 'L/(L+M)');
ylabel(ax, 'S/(L+M)');

apply_mb_axes_style(ax);

% Apply consistent sizing / placement
fig.Position = [10, 10, fig_w, fig_h];
ax.Units     = 'centimeters';
ax.Position  = [0.95 0.85 3.0 3.0];

% Export
exportgraphics(ax, fullfile(outDir, 'fig_chromatic_direction_illchange.pdf'), 'ContentType', 'vector');

%% ------------------------------------------------------------------------
% Local function(s)
% -------------------------------------------------------------------------
function local_apply_mb_axes_style(ax, figp, xlimv, ylimv, xtickv, ytickv)
% Consistent formatting for MB chromaticity plots.

ax.XLim = xlimv;
ax.YLim = ylimv;

ax.XTick = xtickv;
ax.XTickLabel = string(xtickv);

ax.YTick = ytickv;
ax.YTickLabel = compose("%.2f", ytickv);

ax.FontName = 'Arial';
ax.FontSize = figp.fontsize;
ax.Color    = [0.97 0.97 0.97];
ax.XColor   = 'k';
ax.YColor   = 'k';
ax.LineWidth = 0.5;

grid(ax, 'off');
box(ax, 'off');
end
