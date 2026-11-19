%% take diff within task condition, THEN average across condition

cd /Volumes/toshiba/eeg_data_backup
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

study_dir = '/Volumes/toshiba/eeg_data_backup/09_study/with_design';
%[STUDY, ALLEEG] = pop_loadstudy('filename', 'test_stim.study', 'filepath', study_dir);
% [!!!] pop_loadstudy fails on test_stim.study (empty designs 3-4 from design index 5 in s08)
% only the dataset list is needed here, so read the .study file directly as a MAT file
tmp = load(fullfile(study_dir, 'test_stim.study'), '-mat');
STUDY = tmp.STUDY;

% ===== hit - CR =====
% FN400 300-500 ms (Fz, FCz, Cz); LPC 600-800 ms (P3, P4)

win_fn400 = [300 500];
win_lpc   = [600 800];
roi_fn400 = {'Fz','FCz','Cz'};
roi_lpc   = {'P3','P4'};
min_n = 3;   % same min trial count as R 

% full scalp montage: same .ced as s01_load, EXG removed as in s05_runica
% [!!!] update path if .ced is not in the current folder
template_locs = readlocs('attlab64locs.ced');
is_exg = strncmpi({template_locs.labels}, 'EXG', 3);
template_locs = template_locs(~is_exg);
template_labels = string({template_locs.labels});
n_chan = numel(template_locs);

roi_fn400_idx = find(ismember(template_labels, roi_fn400));
roi_lpc_idx   = find(ismember(template_labels, roi_lpc));

%n_sub = numel(ALLEEG);
n_sub = numel(STUDY.datasetinfo);

% subject-level diffmap (chan x sub) 
% taskcond skipped if < min_n trials in either cell
% sub is NaN ONLY if every taskcond is skipped
fn400_hitcr = nan(n_chan, n_sub);
lpc_hitcr   = nan(n_chan, n_sub);

for i = 1:n_sub

    %EEG = pop_loadset('filename', ALLEEG(i).filename, 'filepath', ALLEEG(i).filepath);
    EEG = pop_loadset('filename', STUDY.datasetinfo(i).filename, 'filepath', STUDY.datasetinfo(i).filepath);
    sub = string(EEG.subject);
    disp(sub);

    % interpolate channels removed during manual cleaning
    % [!!!] std_precomp interp=on only applies to .daterp files, not .set data
    if EEG.nbchan < n_chan
        EEG = pop_interp(EEG, template_locs, 'spherical');
    end

    % match channel order to template
    labels = string({EEG.chanlocs.labels});
    [tf, chan_idx] = ismember(template_labels, labels);
    if any(~tf)
        warning('%s missing channels after interp, skip', sub);
        continue
    end

    % trial info: first event in each epoch (same as get_epoch_field in s09)
    n_ep = numel(EEG.epoch);
    task      = strings(n_ep, 1);
    curr_cond = strings(n_ep, 1);
    resp_type = strings(n_ep, 1);

    for ep = 1:n_ep
        v = EEG.epoch(ep).eventtask;      if iscell(v), v = v{1}; end;  task(ep) = string(v);
        v = EEG.epoch(ep).eventcurr_cond; if iscell(v), v = v{1}; end;  curr_cond(ep) = string(v);
        v = EEG.epoch(ep).eventresp_type; if iscell(v), v = v{1}; end;  resp_type(ep) = string(v);
    end

    fn400_time = EEG.times >= win_fn400(1) & EEG.times <= win_fn400(2);
    lpc_time   = EEG.times >= win_lpc(1)   & EEG.times <= win_lpc(2);

    % trial selection (weighted pool across confidence, same as R)
    fn400_cond = nan(n_chan, 5);   % chan x taskcond
    lpc_cond   = nan(n_chan, 5);
 
    for tc = 1:5
        if tc == 1
            is_tc = task == "true_feed";
        elseif tc == 2
            is_tc = task == "false_feed" & curr_cond == "lib";
        elseif tc == 3
            is_tc = task == "false_feed" & curr_cond == "con";
        elseif tc == 4
            is_tc = task == "strategic" & curr_cond == "lib";
        else
            is_tc = task == "strategic" & curr_cond == "con";
        end
 
        % pooling across conf = trial-weighted, same as R pipeline
        hit_trials = find(is_tc & resp_type == "hit");
        cr_trials  = find(is_tc & resp_type == "cr");
 
        if numel(hit_trials) >= min_n && numel(cr_trials) >= min_n
            hit_erp  = mean(EEG.data(chan_idx, :, hit_trials), 3); % chan x time
            cr_erp   = mean(EEG.data(chan_idx, :, cr_trials), 3);
            diff_erp = hit_erp - cr_erp;
            fn400_cond(:, tc) = mean(diff_erp(:, fn400_time), 2);  % mean over window
            lpc_cond(:, tc)   = mean(diff_erp(:, lpc_time), 2);
        end
    end
 
    fn400_hitcr(:, i) = mean(fn400_cond, 2, 'omitnan');
    lpc_hitcr(:, i)   = mean(lpc_cond, 2, 'omitnan');

end

% ===== GRAND AVG across subs =====
fn400_hitcr_avg = mean(fn400_hitcr, 2, 'omitnan');
lpc_hitcr_avg   = mean(lpc_hitcr, 2, 'omitnan');

n_hitcr = sum(~isnan(fn400_hitcr(1, :)));

% sanity check: ROI means should match descriptives from R get_des
fprintf('HIT-CR N = %d | FN400 ROI = %.2f uV | LPC ROI = %.2f uV\n', n_hitcr, mean(fn400_hitcr_avg(roi_fn400_idx)), mean(lpc_hitcr_avg(roi_lpc_idx)));

% ===== plot =====
% color scale
lim_fn400 = ceil(max(abs(fn400_hitcr_avg)));
lim_lpc   = ceil(max(abs(lpc_hitcr_avg)));

figure('Position', [100 100 650 320], 'Color', 'w');
fig_tile = tiledlayout(1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(fig_tile);
topoplot(fn400_hitcr_avg, template_locs, 'maplimits', [-lim_fn400 lim_fn400], 'electrodes', 'on', 'emarker2', {roi_fn400_idx, 'o', 'k', 5, 1});
title(sprintf('Hit - CR\nFN400 %d-%d ms', win_fn400(1), win_fn400(2)));
cb = colorbar;
cb.Label.String = '\muV';

nexttile(fig_tile);
topoplot(lpc_hitcr_avg, template_locs, 'maplimits', [-lim_lpc lim_lpc], 'electrodes', 'on', 'emarker2', {roi_lpc_idx, 'o', 'k', 5, 1});
title(sprintf('Hit - CR\nLPC %d-%d ms', win_lpc(1), win_lpc(2)));
cb = colorbar;
cb.Label.String = '\muV';

% ===== save =====
%out_dir = fullfile('./11_topo_plot');
out_dir = fullfile('/Users/lunarneko/Desktop/11_topo_plot');
if ~exist(out_dir, 'file')
    mkdir(out_dir);
end

set(gcf, 'Renderer', 'painters');   % painters not opengl
file_name = fullfile(out_dir, 'topo_stim_hitcr.pdf');
exportgraphics(fig_tile, file_name, 'ContentType', 'vector');

msgbox('FINISHED');

beep on;
for bee = 1:3
    pause(0.5); beep;
end
