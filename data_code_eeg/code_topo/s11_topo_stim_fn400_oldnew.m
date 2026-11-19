%% take diff within task condition, THEN average across condition

cd /Volumes/toshiba/eeg_data_backup
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

study_dir = '/Volumes/toshiba/eeg_data_backup/09_study/with_design';
%[STUDY, ALLEEG] = pop_loadstudy('filename', 'test_stim.study', 'filepath', study_dir);
% [!!!] pop_loadstudy fails on test_stim.study (empty designs 3-4 from design index 5 in s08)
% only the dataset list is needed here, so read the .study file directly as a MAT file
tmp = load(fullfile(study_dir, 'test_stim.study'), '-mat');
STUDY = tmp.STUDY;

% ===== FPF all old - all new items =====
% old = hit + miss; new = fa + cr (pooled within condition, same as R combined response types)
% [KEEP LIB/CON SEPARATE: effect present in lib only]
% FN400 300-500 ms (Fz, FCz, Cz)

win_fn400 = [300 500];
roi_fn400 = {'Fz','FCz','Cz'};
min_n = 3;   % same min trial count as R 

% full scalp montage: same .ced as s01_load, EXG removed as in s05_runica
% [!!!] update path if .ced is not in the current folder
template_locs = readlocs('attlab64locs.ced');
is_exg = strncmpi({template_locs.labels}, 'EXG', 3);
template_locs = template_locs(~is_exg);
template_labels = string({template_locs.labels});
n_chan = numel(template_locs);

roi_fn400_idx = find(ismember(template_labels, roi_fn400));

%n_sub = numel(ALLEEG);
n_sub = numel(STUDY.datasetinfo);

% subject-level diffmap (chan x sub) 
% NaN if < min_n trials in EITHER cell
fn400_lib = nan(n_chan, n_sub);
fn400_con = nan(n_chan, n_sub);

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

    % trial selection (weighted pool across confidence and response type, same as R)
    is_ff   = task == "false_feed";
    is_old  = resp_type == "hit" | resp_type == "miss";
    is_new  = resp_type == "fa"  | resp_type == "cr";
    lib_old = find(is_ff & curr_cond == "lib" & is_old);
    lib_new = find(is_ff & curr_cond == "lib" & is_new);
    con_old = find(is_ff & curr_cond == "con" & is_old);
    con_new = find(is_ff & curr_cond == "con" & is_new);

    % LIB: old - new
    if numel(lib_old) >= min_n && numel(lib_new) >= min_n
        old_erp  = mean(EEG.data(chan_idx, :, lib_old), 3);   % chan x time
        new_erp  = mean(EEG.data(chan_idx, :, lib_new), 3);
        diff_erp = old_erp - new_erp;
        fn400_lib(:, i) = mean(diff_erp(:, fn400_time), 2);   % mean over window
    end

    % CON: old - new
    if numel(con_old) >= min_n && numel(con_new) >= min_n
        old_erp  = mean(EEG.data(chan_idx, :, con_old), 3);
        new_erp  = mean(EEG.data(chan_idx, :, con_new), 3);
        diff_erp = old_erp - new_erp;
        fn400_con(:, i) = mean(diff_erp(:, fn400_time), 2);
    end

end

% ===== GRAND AVG across subs =====
fn400_lib_avg = mean(fn400_lib, 2, 'omitnan');
fn400_con_avg = mean(fn400_con, 2, 'omitnan');

n_lib = sum(~isnan(fn400_lib(1, :)));
n_con = sum(~isnan(fn400_con(1, :)));

% sanity check: ROI means should match R (lib delta = 0.99, con delta = 0.11)
fprintf('LIB N = %d | FN400 ROI = %.2f uV\n', n_lib, mean(fn400_lib_avg(roi_fn400_idx)));
fprintf('CON N = %d | FN400 ROI = %.2f uV\n', n_con, mean(fn400_con_avg(roi_fn400_idx)));

% ===== plot =====
% [!!!] one shared color scale to compare lib vs con
lim = ceil(max(abs([fn400_lib_avg; fn400_con_avg])));

figure('Position', [100 100 650 320], 'Color', 'w');
fig_tile = tiledlayout(1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(fig_tile);
topoplot(fn400_lib_avg, template_locs, 'maplimits', [-lim lim], 'electrodes', 'on', 'emarker2', {roi_fn400_idx, 'o', 'k', 5, 1});
title(sprintf('Liberal FPF: Old - New\nFN400 %d-%d ms', win_fn400(1), win_fn400(2)));

nexttile(fig_tile);
topoplot(fn400_con_avg, template_locs, 'maplimits', [-lim lim], 'electrodes', 'on', 'emarker2', {roi_fn400_idx, 'o', 'k', 5, 1});
title(sprintf('Conservative FPF: Old - New\nFN400 %d-%d ms', win_fn400(1), win_fn400(2)));

cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = '\muV';

% ===== save =====
%out_dir = fullfile('./11_topo_plot');
out_dir = fullfile('/Users/lunarneko/Desktop/11_topo_plot');
if ~exist(out_dir, 'file')
    mkdir(out_dir);
end

set(gcf, 'Renderer', 'painters');   % painters not opengl
file_name = fullfile(out_dir, 'topo_stim_fn400_oldnew_fpf.pdf');
exportgraphics(fig_tile, file_name, 'ContentType', 'vector');

msgbox('FINISHED');

beep on;
for bee = 1:3
    pause(0.5); beep;
end
