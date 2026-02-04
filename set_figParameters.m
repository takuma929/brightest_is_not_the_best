% script to save parameters for figure generation
repo_basedir = pwd;
figp.twocolumn = 17.8; % size for for two-column figure
figp.onecolumn = figp.twocolumn/2; % size for for one-column figure

figp.fontsize = 7; % fontsize for general use
figp.fontsize_axis = 8; % fontsize for axis label
figp.fontname = 'Helvetica'; % Use Arial for font

% save figure parameter
save(fullfile(repo_basedir,'data','fig_params.mat'),'figp','repo_basedir')
