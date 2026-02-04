%% Plot human + model d' and criterion (C) for Aligned vs Separated trials
%
% TM — 3rd Feb 2026
%
% This script loads the saved SDT results for human observers and computational
% models and generates publication-ready figures (vector PDFs).
%
% Inputs:
%   <repo_basedir>/data/fig_params.mat
%   <repo_basedir>/results/dprime_human.mat
%   <repo_basedir>/results/dprime_models.mat
%
% Outputs:
%   <repo_basedir>/figs/*.pdf
%

clearvars; close all; clc;

%% ------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------
repo_basedir = pwd;  % set explicitly if running from outside repo root
dataDir = fullfile(repo_basedir, 'data');
figDir  = fullfile(repo_basedir, 'figs');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

%% ------------------------------------------------------------------------
% Load inputs
% -------------------------------------------------------------------------
S = load(fullfile(dataDir, 'fig_params.mat'));  % expects S.figp
figp = S.figp;

% Human observer SDT results (expects dprime.(All/Aligned/Separated) and C.(...))
rslt_human  = load(fullfile(dataDir, 'dprime_human.mat'));

% Computational observer SDT results
rslt_models = load(fullfile(dataDir, 'dprime_models.mat'));

%% ------------------------------------------------------------------------
% Colormaps / styling
% -------------------------------------------------------------------------
cmap.sphere = [232 244 246] / 255;
cmap.ps     = [251 243 233] / 255;

cmap.human_ps     = [109 56 0] / 255;
cmap.human_sphere = [0 76 63] / 255;

cmap.Brightest = [164 155 103] / 255;
cmap.MeanChrm  = [34 156 67] / 255;

cmap.CoS(1,:) = [0 0.8 0.8];
cmap.CoS(2,:) = [0 0.6 0.6];
cmap.CoS(3,:) = [0 0.4 0.4];

cmap.CoS1 = cmap.CoS(1,:);
cmap.CoS2 = cmap.CoS(2,:);
cmap.CoS3 = cmap.CoS(3,:);

edgeColor = 'none';

%% ------------------------------------------------------------------------
% Tables for downstream stats (example: sphere=cond 1:3, ps=cond 4:5)
% -------------------------------------------------------------------------
ANOVATable_d_sphere = [ ...
    squeeze(mean(rslt_human.dprime.Aligned(:,1:3,:),1))', ...
    squeeze(mean(rslt_human.dprime.Separated(:,1:3,:),1))' ...
];
ANOVATable_C_sphere = [ ...
    squeeze(mean(rslt_human.C.Aligned(:,1:3,:),1))', ...
    squeeze(mean(rslt_human.C.Separated(:,1:3,:),1))' ...
];

ANOVATable_d_ps = [ ...
    squeeze(mean(rslt_human.dprime.Aligned(:,4:5,:),1))', ...
    squeeze(mean(rslt_human.dprime.Separated(:,4:5,:),1))' ...
];
ANOVATable_C_ps = [ ...
    squeeze(mean(rslt_human.C.Aligned(:,4:5,:),1))', ...
    squeeze(mean(rslt_human.C.Separated(:,4:5,:),1))' ...
];

%% ------------------------------------------------------------------------
% Draw d' for humans (group mean across observers; SE across observers)
% -------------------------------------------------------------------------
condIdx.sphere = 1:3;
condIdx.ps     = 4:5;

xLim.sphere = [-0.01 0.05];
xLim.ps     = [ 0.01 0.05];

xvals.sphere = 0:0.02:0.04;
xvals.ps     = 0.02:0.02:0.04;

nHumans = size(rslt_human.dprime.All, 3);

for type = {'sphere','ps'}
    typeName = type{1};

    fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
    ax = axes(fig); hold(ax, 'on');

    % Mean across sessions and observers (matches original behavior)
    dAligned   = squeeze(mean(mean(rslt_human.dprime.Aligned(:,condIdx.(typeName),:),1),3));
    dSeparated = squeeze(mean(mean(rslt_human.dprime.Separated(:,condIdx.(typeName),:),1),3));

    % SE across observers (after averaging across sessions)
    dAligned_se   = squeeze(std(mean(rslt_human.dprime.Aligned(:,condIdx.(typeName),:),1),[],3)) / sqrt(nHumans);
    dSeparated_se = squeeze(std(mean(rslt_human.dprime.Separated(:,condIdx.(typeName),:),1),[],3)) / sqrt(nHumans);

    errorbar(ax, xvals.(typeName), dAligned,   dAligned_se,   'LineStyle','none', 'CapSize',0, 'Color',cmap.(['human_',typeName]));
    errorbar(ax, xvals.(typeName), dSeparated, dSeparated_se, 'LineStyle','none', 'CapSize',0, 'Color',cmap.(['human_',typeName]));

    plot(ax, xvals.(typeName), dAligned,   'o-', 'MarkerFaceColor',cmap.(['human_',typeName]), ...
        'MarkerEdgeColor',edgeColor, 'MarkerSize',6, 'LineWidth',0.5, 'Color',cmap.(['human_',typeName]));
    plot(ax, xvals.(typeName), dSeparated, 'd:', 'MarkerFaceColor',cmap.(['human_',typeName]), ...
        'MarkerEdgeColor',edgeColor, 'MarkerSize',6, 'LineWidth',1.0, 'Color',cmap.(['human_',typeName]));

    line(ax, [-100 100], [0 0], 'LineStyle','-', 'LineWidth',0.1, 'Color',[.7 .7 .7]);

    % Figure sizing
    fig_w = figp.twocolumn/4 * 0.95;
    fig_h = figp.twocolumn/4 * 0.95;
    fig.Position = [10 10 fig_w fig_h];

    % Axes formatting
    ax.XLim = xLim.(typeName);
    ax.YLim = [-0.3 2.4];
    ax.YTick = [0 1.2 2.4];
    ax.YTickLabel = ["0.00","1.20","2.40"];

    if strcmp(typeName,'sphere')
        ax.XTick = [0 0.02 0.04];
        ax.XTickLabel = ["0.00","0.02","0.04"];
    else
        ax.XTick = [0.02 0.04];
        ax.XTickLabel = ["0.02","0.04"];
    end

    xlabel(ax, '');
    ylabel(ax, '');

    ax.FontName = 'Arial';
    ax.FontSize = figp.fontsize;
    ax.Color    = cmap.(typeName);
    ax.XColor   = 'k';
    ax.YColor   = 'k';
    ax.Units    = 'centimeters';

    if strcmp(typeName,'sphere')
        ax.Position = [0.65 0.55 3.4 3.4];
    else
        ax.Position = [0.65 0.55 2.4 3.4];
    end

    grid(ax, 'off');
    box(ax, 'off');

    exportgraphics(ax, fullfile(figDir, sprintf('fig_dprime_human_mean_%s.pdf', typeName)), 'ContentType','vector');
end

%% ------------------------------------------------------------------------
% Draw d' for humans (individual observers; SD across sessions for each observer)
% -------------------------------------------------------------------------
observerIDs     = {'AKH', 'JH', 'SR', 'TD', 'TM', 'HH'};

for obsN = 1:nHumans
    for type = {'sphere','ps'}
        typeName = type{1};

        fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
        ax = axes(fig); hold(ax, 'on');

        dAligned   = squeeze(mean(rslt_human.dprime.Aligned(:,condIdx.(typeName),obsN),1));
        dSeparated = squeeze(mean(rslt_human.dprime.Separated(:,condIdx.(typeName),obsN),1));

        % SD across sessions (kept to match original behavior)
        dAligned_sd   = squeeze(std(rslt_human.dprime.Aligned(:,condIdx.(typeName),obsN),[],1)) / sqrt(size(rslt_human.dprime.Aligned,1));
        dSeparated_sd = squeeze(std(rslt_human.dprime.Separated(:,condIdx.(typeName),obsN),[],1)) / sqrt(size(rslt_human.dprime.Separated,1));

        errorbar(ax, xvals.(typeName), dAligned,   dAligned_sd,   'LineStyle','none', 'CapSize',0, 'Color',cmap.(['human_',typeName]));
        errorbar(ax, xvals.(typeName), dSeparated, dSeparated_sd, 'LineStyle','none', 'CapSize',0, 'Color',cmap.(['human_',typeName]));

        plot(ax, xvals.(typeName), dAligned,   'o-', 'MarkerFaceColor',cmap.(['human_',typeName]), ...
            'MarkerEdgeColor',edgeColor, 'MarkerSize',5, 'LineWidth',0.5, 'Color',cmap.(['human_',typeName]));
        plot(ax, xvals.(typeName), dSeparated, 'd:', 'MarkerFaceColor',cmap.(['human_',typeName]), ...
            'MarkerEdgeColor',edgeColor, 'MarkerSize',5, 'LineWidth',1.0, 'Color',cmap.(['human_',typeName]));

        line(ax, [-100 100], [0 0], 'LineStyle','-', 'LineWidth',0.1, 'Color',[.7 .7 .7]);

        fig_w = figp.twocolumn/6 * 0.95;
        fig_h = figp.twocolumn/6 * 0.95;
        fig.Position = [10 10 fig_w fig_h];

        ax.XLim = xLim.(typeName);
        ax.YLim = [-0.5 2.6];
        ax.YTick = [0 1.3 2.6];
        ax.YTickLabel = ["0.00","1.30","2.60"];

        if strcmp(typeName,'sphere')
            ax.XTick = [0 0.02 0.04];
            ax.XTickLabel = ["0.00","0.02","0.04"];
        else
            ax.XTick = [0.02 0.04];
            ax.XTickLabel = ["0.02","0.04"];
        end

        xlabel(ax, '');
        ylabel(ax, '');

        ax.FontName = 'Arial';
        ax.FontSize = figp.fontsize;
        ax.Color    = cmap.(typeName);
        ax.XColor   = 'k';
        ax.YColor   = 'k';
        ax.Units    = 'centimeters';
        ax.Position = [0.65 0.55 2.0 2.0];

        grid(ax, 'off');
        box(ax, 'off');

        exportgraphics(ax, fullfile(figDir, sprintf('fig_dprime_human_%s_%s.pdf', observerIDs{obsN}, typeName)), ...
            'ContentType','vector');
    end
end

%% ------------------------------------------------------------------------
% Draw d' for models
% -------------------------------------------------------------------------
observer_list = {'Brightest','CoS1','CoS2','CoS3'};
pixel = 1;

for obs = observer_list
    obsName = obs{1};

    fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
    ax = axes(fig); hold(ax, 'on');

    % Model results are assumed to have:
    %   rslt_models.dprime_avg.Aligned.(obsName).f_pixelX
    %   rslt_models.dprime_avg.Separated.(obsName).f_pixelX
    dAligned   = rslt_models.dprime_avg.Aligned.(obsName).(['f_pixel', num2str(pixel)]);
    dSeparated = rslt_models.dprime_avg.Separated.(obsName).(['f_pixel', num2str(pixel)]);

    plot(ax, 0:0.02:0.04, dAligned,   'o-', 'MarkerFaceColor',cmap.(obsName), 'MarkerEdgeColor',edgeColor, ...
        'MarkerSize',6, 'LineWidth',0.5, 'Color',cmap.(obsName));
    plot(ax, 0:0.02:0.04, dSeparated, 'd:', 'MarkerFaceColor',cmap.(obsName), 'MarkerEdgeColor',edgeColor, ...
        'MarkerSize',6, 'LineWidth',1.0, 'Color',cmap.(obsName));

    line(ax, [-100 100], [0 0], 'LineStyle','-', 'LineWidth',0.1, 'Color',[.7 .7 .7]);

    fig_w = figp.twocolumn/4 * 0.95;
    fig_h = figp.twocolumn/4 * 0.95;
    fig.Position = [10 10 fig_w fig_h];

    ax.XLim = [-0.01 0.05];
    ax.XTick = [0 0.02 0.04];
    ax.XTickLabel = ["0.00","0.02","0.04"];

    % --- Y axis: Brightest stays, CoS* uses 0..4.2 with ticks 0/2.1/4.2
    if startsWith(obsName, "CoS")
        ax.YLim = [-0.2 4.0];
        ax.YTick = [0.0 2.0 4.0];
        ax.YTickLabel = ["0.00","2.00","4.00"];
    else
        ax.YLim = [-0.1 2.0];
        ax.YTick = [0 1.0 2.0];
        ax.YTickLabel = ["0.00","1.00","2.00"];
    end

    xlabel(ax, '');
    ylabel(ax, '');

    ax.FontName = 'Arial';
    ax.FontSize = figp.fontsize;
    ax.Color    = cmap.sphere;
    ax.XColor   = 'k';
    ax.YColor   = 'k';
    ax.Units    = 'centimeters';
    ax.Position = [0.65 0.55 3.4 3.4];

    grid(ax, 'off');
    box(ax, 'off');

    exportgraphics(fig, fullfile(figDir, sprintf('fig_dprime_%s_fpixel%d.pdf', obsName, pixel)), 'ContentType','vector');
end

%% ------------------------------------------------------------------------
% Draw d' for models (effect of filter pixel size)
% -------------------------------------------------------------------------
observer_list = {'Brightest','CoS1','CoS2','CoS3'};
pixel_size = [1 3 5 10];

for spec = [1 2]
    for obs = observer_list
        obsName = obs{1};

        fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
        ax = axes(fig); hold(ax, 'on');

        dAligned = [];
        dSeparated = [];
        for pixel = pixel_size
            dAligned   = [dAligned;   rslt_models.dprime_avg.Aligned.(obsName).(['f_pixel',num2str(pixel)])(2:3)];
            dSeparated = [dSeparated; rslt_models.dprime_avg.Separated.(obsName).(['f_pixel',num2str(pixel)])(2:3)];
        end

        plot(ax, pixel_size, dAligned(:,spec),   'o-', 'MarkerFaceColor',cmap.(obsName), 'MarkerEdgeColor',edgeColor, ...
            'MarkerSize',6, 'LineWidth',0.5, 'Color',cmap.(obsName));
        plot(ax, pixel_size, dSeparated(:,spec), 'd:', 'MarkerFaceColor',cmap.(obsName), 'MarkerEdgeColor',edgeColor, ...
            'MarkerSize',6, 'LineWidth',1.0, 'Color',cmap.(obsName));

        line(ax, [-100 100], [0 0], 'LineStyle','-', 'LineWidth',0.1, 'Color',[.7 .7 .7]);

        fig_w = figp.twocolumn/4 * 0.95;
        fig_h = figp.twocolumn/4 * 0.95;
        fig.Position = [10 10 fig_w fig_h];

        ax.XLim = [0 11];
        ax.XTick = [1 3 5 10];
        ax.XTickLabel = ["1","3","5","10"];

        % --- Y axis: Brightest stays, CoS* uses 0..4.2 with ticks 0/2.1/4.2
        if startsWith(obsName, "CoS")
            ax.YLim = [-0.2 4.0];
            ax.YTick = [0.0 2.0 4.0];
            ax.YTickLabel = ["0.00","2.00","4.00"];
        else
            ax.YLim = [-0.1 2];
            ax.YTick = [0 1.0 2];
            ax.YTickLabel = ["0.00","1.00","2.00"];
        end

        xlabel(ax, '');
        ylabel(ax, '');

        ax.FontName = 'Arial';
        ax.FontSize = figp.fontsize;
        ax.Color    = cmap.sphere;
        ax.XColor   = 'k';
        ax.YColor   = 'k';
        ax.Units    = 'centimeters';
        ax.Position = [0.65 0.55 3.4 3.4];

        grid(ax, 'off');
        box(ax, 'off');

        exportgraphics(fig, fullfile(figDir, sprintf('fig_filterSizeEffect_dprime_%s_spec%d.pdf', obsName, spec)), ...
            'ContentType','vector');
    end
end

%% ------------------------------------------------------------------------
% Draw criterion C for humans (group mean across observers; SE across observers)
% -------------------------------------------------------------------------
for type = {'sphere','ps'}
    typeName = type{1};

    fig = figure('Color','w', 'InvertHardcopy','off', 'Units','centimeters');
    ax = axes(fig); hold(ax, 'on');

    CAligned   = squeeze(mean(mean(rslt_human.C.Aligned(:,condIdx.(typeName),:),1),3));
    CSeparated = squeeze(mean(mean(rslt_human.C.Separated(:,condIdx.(typeName),:),1),3));

    CAligned_se   = squeeze(std(mean(rslt_human.C.Aligned(:,condIdx.(typeName),:),1),[],3)) / sqrt(nHumans);
    CSeparated_se = squeeze(std(mean(rslt_human.C.Separated(:,condIdx.(typeName),:),1),[],3)) / sqrt(nHumans);

    errorbar(ax, xvals.(typeName), CAligned,   CAligned_se,   'LineStyle','none', 'CapSize',0, 'Color',cmap.(['human_',typeName]));
    errorbar(ax, xvals.(typeName), CSeparated, CSeparated_se, 'LineStyle','none', 'CapSize',0, 'Color',cmap.(['human_',typeName]));

    plot(ax, xvals.(typeName), CAligned,   'o-', 'MarkerFaceColor',cmap.(['human_',typeName]), ...
        'MarkerEdgeColor',edgeColor, 'MarkerSize',6, 'LineWidth',0.5, 'Color',cmap.(['human_',typeName]));
    plot(ax, xvals.(typeName), CSeparated, 'd:', 'MarkerFaceColor',cmap.(['human_',typeName]), ...
        'MarkerEdgeColor',edgeColor, 'MarkerSize',6, 'LineWidth',1.0, 'Color',cmap.(['human_',typeName]));

    line(ax, [-100 100], [0 0], 'LineStyle','-', 'LineWidth',0.1, 'Color',[.7 .7 .7]);

    fig_w = figp.twocolumn/4 * 0.95;
    fig_h = figp.twocolumn/4 * 0.95;
    fig.Position = [10 10 fig_w fig_h];

    ax.XLim = xLim.(typeName);
    ax.YLim = [-0.3 2.4];
    if strcmp(typeName,'sphere')
        ax.XTick = [0 0.02 0.04];
        ax.XTickLabel = ["0.00","0.02","0.04"];
    else
        ax.XTick = [0.02 0.04];
        ax.XTickLabel = ["0.02","0.04"];
    end
    ax.YTick = [0 1.2 2.4];
    ax.YTickLabel = ["0.00","1.20","2.40"];

    xlabel(ax, '');
    ylabel(ax, '');

    ax.FontName = 'Arial';
    ax.FontSize = figp.fontsize;
    ax.Color    = cmap.(typeName);
    ax.XColor   = 'k';
    ax.YColor   = 'k';
    ax.Units    = 'centimeters';

    if strcmp(typeName,'sphere')
        ax.Position = [0.65 0.55 3.4 3.4];
    else
        ax.Position = [0.65 0.55 2.4 3.4];
    end

    grid(ax, 'off');
    box(ax, 'off');

    exportgraphics(fig, fullfile(figDir, sprintf('fig_C_human_mean_%s.pdf', typeName)), 'ContentType','vector');
end

close all