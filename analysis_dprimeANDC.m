%% Compute d' and criterion (C) for human observers across sessions/conditions
%
% TM — 3rd Feb 2026
%
% This script loads per-block behavioral .mat files, aggregates trials into a
% consistent order (sorted by condition, then stimulus), splits trials into
% "Aligned" vs "Separated" using separated_idx, and computes signal detection
% metrics (d' and criterion C) for each observer/session/condition.
%
% Expected folder structure:
%   <repo_basedir>/
%     rawdata/<observer>/<observer>_<session>-<block>.mat
%     data/separated_idx.mat                  (contains vector "separated_idx")
%     results/
%
% Outputs:
%   results/dprime_human.mat  (variables: dprime, C, observerIDs)
%
% Notes:
% - Each block contains trialsPerBlock trials and includes fields:
%     stimList.condition, stimList.stimn, stimList.changeType, response, correct
% - separated_idx(stimIndex)==0 => Aligned, ==1 => Separated

clearvars; close all; clc;

%% ------------------------------------------------------------------------
% Paths
% -------------------------------------------------------------------------
repo_basedir = pwd;  % set explicitly if running from outside repo root
dataDir = fullfile(repo_basedir, 'data');
rawDir  = fullfile(repo_basedir, 'rawdata');

%% ------------------------------------------------------------------------
% Experiment constants
% -------------------------------------------------------------------------
observerIDs     = {'AKH', 'JH', 'SR', 'TD', 'TM', 'HH'};
nObservers      = numel(observerIDs);

nSessions       = 4;
nConditions     = 5;
nBlocks         = 4;

trialsPerCond   = 100;
nTrialsSession  = nConditions * trialsPerCond;
trialsPerBlock  = nTrialsSession / nBlocks;

% Column convention for Results arrays (size: nTrialsSession x 5):
%   [1] condition, [2] stimIndex, [3] changeType, [4] response, [5] correct
nCols = 5;

%% ------------------------------------------------------------------------
% Load alignment/separation index (defines "Aligned" vs "Separated" per stimIndex)
% -------------------------------------------------------------------------
S = load(fullfile(dataDir, 'separated_idx.mat'));  % expects S.separated_idx
separated_idx = S.separated_idx;

nAlignedStim    = sum(separated_idx == 0);
nSeparatedStim  = sum(separated_idx == 1);

%% ------------------------------------------------------------------------
% Preallocate results
% -------------------------------------------------------------------------
Results.All = zeros(nTrialsSession, nCols, nSessions, nObservers);
Results.raw = zeros(nTrialsSession, nCols, nSessions, nObservers);  % unsorted accumulation

% Diagnostics (optional sanity checks)
stimCountByCond       = zeros(100, nConditions);   % counts stimIndex within each condition (expects stimIndex <= 100)
changeTypeCountByCond = zeros(2,   nConditions);   % counts changeType (1/2) within each condition

%% ------------------------------------------------------------------------
% Load and aggregate data: observer -> session -> block
% -------------------------------------------------------------------------
for oi = 1:nObservers
    obsID = observerIDs{oi};

    for si = 1:nSessions
        for bi = 1:nBlocks
            % rawdata/<obs>/<obs>_<session>-<block>.mat
            f = fullfile(rawDir, obsID, sprintf('%s_%d-%d.mat', obsID, si, bi));
            V = load(f);

            % Sanity check trial count
            if numel(V.response) ~= trialsPerBlock
                error('Unexpected #trials in %s (got %d, expected %d).', f, numel(V.response), trialsPerBlock);
            end

            % Optional distribution checks (mirrors original "1:125" logic)
            nCheck = min(125, numel(V.stimList.condition));
            for k = 1:nCheck
                ct = V.stimList.changeType(k);
                cd = V.stimList.condition(k);
                st = V.stimList.stimn(k);

                if ct >= 1 && ct <= 2 && cd >= 1 && cd <= nConditions
                    changeTypeCountByCond(ct, cd) = changeTypeCountByCond(ct, cd) + 1;
                end
                if st >= 1 && st <= 100 && cd >= 1 && cd <= nConditions
                    stimCountByCond(st, cd) = stimCountByCond(st, cd) + 1;
                end
            end

            % Pack block trials into [condition stimIndex changeType response correct]
            blockRows = [V.stimList.condition(:), V.stimList.stimn(:), V.stimList.changeType(:), ...
                         V.response(:), V.correct(:)];

            r0 = trialsPerBlock * (bi - 1) + 1;
            r1 = trialsPerBlock * bi;
            Results.raw(r0:r1, :, si, oi) = blockRows;
        end

        % Sort: condition -> stimIndex
        Results.All(:, :, si, oi) = sort_trials_by_condition_then_stim(Results.raw(:, :, si, oi), nConditions, trialsPerCond);
    end
end

%% ------------------------------------------------------------------------
% Split into Aligned / Separated (per session/observer)
% -------------------------------------------------------------------------
nAlignedTrialsSession   = nAlignedStim   * trialsPerCond;
nSeparatedTrialsSession = nSeparatedStim * trialsPerCond;

Results.Aligned   = zeros(nAlignedTrialsSession,   nCols, nSessions, nObservers);
Results.Separated = zeros(nSeparatedTrialsSession, nCols, nSessions, nObservers);

for si = 1:nSessions
    for oi = 1:nObservers
        a = 1;  % aligned row counter
        s = 1;  % separated row counter

        for ti = 1:nTrialsSession
            stimIndex = Results.All(ti, 2, si, oi);

            % Convention: 0 => Aligned, 1 => Separated
            if separated_idx(stimIndex) == 0
                Results.Aligned(a, :, si, oi) = Results.All(ti, :, si, oi);
                a = a + 1;
            else
                Results.Separated(s, :, si, oi) = Results.All(ti, :, si, oi);
                s = s + 1;
            end
        end
    end
end

%% ------------------------------------------------------------------------
% Compute SDT metrics: d' and criterion C
% -------------------------------------------------------------------------
types = {'All','Aligned','Separated'};

% Preallocate metric containers (struct of 3D arrays: session x condition x observer)
for t = 1:numel(types)
    name = types{t};
    Hit.(name)     = zeros(nSessions, nConditions, nObservers);
    Miss.(name)    = zeros(nSessions, nConditions, nObservers);
    FA.(name)      = zeros(nSessions, nConditions, nObservers);
    CR.(name)      = zeros(nSessions, nConditions, nObservers);
    nNoise.(name)  = zeros(nSessions, nConditions, nObservers); % RefChange ("noise") count
    nSignal.(name) = zeros(nSessions, nConditions, nObservers); % IllChange ("signal") count

    dprime.(name)  = zeros(nSessions, nConditions, nObservers);
    C.(name)       = zeros(nSessions, nConditions, nObservers);
end

for oi = 1:nObservers
    for ci = 1:nConditions
        for si = 1:nSessions
            for t = 1:numel(types)
                name = types{t};
                data = Results.(name)(:, :, si, oi);

                [h, m, fa, cr, nN, nS] = calculateMetrics(data, ci);

                Hit.(name)(si, ci, oi)     = h;
                Miss.(name)(si, ci, oi)    = m;
                FA.(name)(si, ci, oi)      = fa;
                CR.(name)(si, ci, oi)      = cr;
                nNoise.(name)(si, ci, oi)  = nN;
                nSignal.(name)(si, ci, oi) = nS;

                [dprime.(name)(si, ci, oi), C.(name)(si, ci, oi)] = ...
                    calculateRatesAndDprimeAndCriterion(h, fa, nS, nN);
            end
        end
    end
end

%% ------------------------------------------------------------------------
% Summary: mean and (sample) std across ALL sessions
% -------------------------------------------------------------------------
for oi = 1:nObservers
    for ci = 1:nConditions
        for t = 1:numel(types)
            name = types{t};
            vals = squeeze(dprime.(name)(:, ci, oi));  % all sessions

            dprime_mean.(name)(ci, oi) = mean(vals);
            dprime_sd.(name)(ci, oi)   = std(vals);    % std (not SE) to match prior behavior
        end
    end
end

%% ------------------------------------------------------------------------
% Save
% -------------------------------------------------------------------------
save(fullfile(dataDir, 'dprime_human.mat'), 'dprime', 'C', 'observerIDs');

%% ========================================================================
% Local functions
% ========================================================================

function out = sort_trials_by_condition_then_stim(in, nConditions, trialsPerCond)
%SORT_TRIALS_BY_CONDITION_THEN_STIM Sort rows by condition, then by stimIndex within condition.
%
% Input "in" is [nTrialsSession x 5]:
%   [condition, stimIndex, changeType, response, correct]

% Primary sort: condition
[~, idxCond] = sort(in(:, 1), 'ascend');
tmp = in(idxCond, :);

% Secondary sort: stimIndex within each condition block
out = zeros(size(tmp));
for c = 1:nConditions
    r0 = (c - 1) * trialsPerCond + 1;
    r1 = c * trialsPerCond;

    [~, idxStim] = sort(tmp(r0:r1, 2), 'ascend');
    out(r0:r1, :) = tmp(r0 - 1 + idxStim, :);
end
end

function [Hit, Miss, FA, CR, nNoise, nSignal] = calculateMetrics(data, condition)
%CALCULATEMETRICS Compute hit/miss/FA/CR counts for a given condition.
%
% Column meaning (data is N x 5):
%   1=condition, 2=stimIndex, 3=changeType, 4=response, 5=correct
%
% Assumptions (from original code):
%   - changeType==2 is "signal" trials (IllChange) and response==2 indicates "signal" response.
%   - changeType==1 is "noise" trials (RefChange) and response==1 indicates "noise" response.

isCond = (data(:,1) == condition);

Hit  = sum(isCond & data(:,3) == 2 & data(:,4) == 2);
Miss = sum(isCond & data(:,3) == 2 & data(:,4) == 1);
FA   = sum(isCond & data(:,3) == 1 & data(:,4) == 2);
CR   = sum(isCond & data(:,3) == 1 & data(:,4) == 1);

% Totals
nNoise  = sum(isCond & data(:,3) == 1); % RefChange ("noise")
nSignal = sum(isCond & data(:,3) == 2); % IllChange ("signal")
end

function [dprime, C] = calculateRatesAndDprimeAndCriterion(Hit, FA, nSignal, nNoise)
%CALCULATERATESANDDPRIMEANDCRITERION Compute d' and criterion C.
%
% Uses Z(H) - Z(FA) and clips rates away from {0,1} to avoid infinite Z-scores.

if nSignal == 0 || nNoise == 0
    dprime = NaN;
    C = NaN;
    return;
end

H = Hit / nSignal;
F = FA  / nNoise;

% Clip rates to avoid +/-Inf from norminv
epsRate = 1e-5;
H = min(max(H, epsRate), 1 - epsRate);
F = min(max(F, epsRate), 1 - epsRate);

zH  = norminv(H);
zFA = norminv(F);

dprime = zH - zFA;
C      = -0.5 * (zH + zFA);
end
