%% take diff within task condition, THEN average across condition if applicable

cd /Volumes/toshiba/eeg_data_backup
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

study_dir = '/Volumes/toshiba/eeg_data_backup/09_study/with_design';
[STUDY, ALLEEG] = pop_loadstudy('filename', 'feed.study', 'filepath', study_dir);

% ===== FPF vs true correct, response-matched =====
% same cells as s10_plot_erp.Rmd "fpfvscorrect"
% LIB: FA|FPF - hit
% CON: miss|FPF - cr
% [KEEP LIB/CON SEPARATE because diff is not symmetrical!!!]
% FRN 250-375 ms (Cz, FCz); feedback P3 400-500 ms (Pz, CPz)

win_frn = [250 375];
win_p3  = [400 500];
roi_frn = {'Cz','FCz'};
roi_p3  = {'Pz','CPz'};
min_n   = 3;   % same min trial count as R 

% full scalp montage: same .ced as s01_load, EXG removed as in s05_runica
% [!!!] update path if .ced is not in the current folder
template_locs = readlocs('attlab64locs.ced');
is_exg = strncmpi({template_locs.labels}, 'EXG', 3);
template_locs = template_locs(~is_exg);
template_labels = string({template_locs.labels});
n_chan = numel(template_locs);

roi_frn_idx = find(ismember(template_labels, roi_frn));
roi_p3_idx  = find(ismember(template_labels, roi_p3));

n_sub = numel(ALLEEG);

% subject-level diffmap (chan x sub) 
% NaN if < min_n trials in EITHER cell
frn_lib = nan(n_chan, n_sub);
frn_con = nan(n_chan, n_sub);
p3_lib  = nan(n_chan, n_sub);
p3_con  = nan(n_chan, n_sub);

for i = 1:n_sub

    EEG = pop_loadset('filename', ALLEEG(i).filename, 'filepath', ALLEEG(i).filepath);
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
    task         = strings(n_ep, 1);
    curr_cond    = strings(n_ep, 1);
    resp_type    = strings(n_ep, 1);
    trial_is_fpf = strings(n_ep, 1);

    for ep = 1:n_ep
        v = EEG.epoch(ep).eventtask;         if iscell(v), v = v{1}; end;  task(ep) = string(v);
        v = EEG.epoch(ep).eventcurr_cond;    if iscell(v), v = v{1}; end;  curr_cond(ep) = string(v);
        v = EEG.epoch(ep).eventresp_type;    if iscell(v), v = v{1}; end;  resp_type(ep) = string(v);
        v = EEG.epoch(ep).eventtrial_is_fpf; if iscell(v), v = v{1}; end;  trial_is_fpf(ep) = string(v);
    end

    frn_time = EEG.times >= win_frn(1) & EEG.times <= win_frn(2);
    p3_time  = EEG.times >= win_p3(1)  & EEG.times <= win_p3(2);

    % trial selection (weighted pool across confidence, same as R)
    is_ff    = task == "false_feed";
    lib_fpf  = find(is_ff & curr_cond == "lib" & resp_type == "fa"   & trial_is_fpf == "1");
    lib_corr = find(is_ff & curr_cond == "lib" & resp_type == "hit");
    con_fpf  = find(is_ff & curr_cond == "con" & resp_type == "miss" & trial_is_fpf == "1");
    con_corr = find(is_ff & curr_cond == "con" & resp_type == "cr");

    % LIB: FA|FPF - hit
    if numel(lib_fpf) >= min_n && numel(lib_corr) >= min_n
        fpf_erp  = mean(EEG.data(chan_idx, :, lib_fpf), 3); % chan x time
        corr_erp = mean(EEG.data(chan_idx, :, lib_corr), 3);
        diff_erp = fpf_erp - corr_erp;
        frn_lib(:, i) = mean(diff_erp(:, frn_time), 2);     % mean over window
        p3_lib(:, i)  = mean(diff_erp(:, p3_time), 2);
    end

    % CON: miss|FPF - cr
    if numel(con_fpf) >= min_n && numel(con_corr) >= min_n
        fpf_erp  = mean(EEG.data(chan_idx, :, con_fpf), 3);
        corr_erp = mean(EEG.data(chan_idx, :, con_corr), 3);
        diff_erp = fpf_erp - corr_erp;
        frn_con(:, i) = mean(diff_erp(:, frn_time), 2);
        p3_con(:, i)  = mean(diff_erp(:, p3_time), 2);
    end

end

% ===== GRAND AVG across subs =====
frn_lib_avg = mean(frn_lib, 2, 'omitnan');
frn_con_avg = mean(frn_con, 2, 'omitnan');
p3_lib_avg  = mean(p3_lib, 2, 'omitnan');
p3_con_avg  = mean(p3_con, 2, 'omitnan');

n_lib = sum(~isnan(frn_lib(1, :)));
n_con = sum(~isnan(frn_con(1, :)));

% sanity check: ROI means should match descriptives from R get_des
fprintf('LIB N = %d | FRN ROI = %.2f uV | P3 ROI = %.2f uV\n', n_lib, mean(frn_lib_avg(roi_frn_idx)), mean(p3_lib_avg(roi_p3_idx)));
fprintf('CON N = %d | FRN ROI = %.2f uV | P3 ROI = %.2f uV\n', n_con, mean(frn_con_avg(roi_frn_idx)), mean(p3_con_avg(roi_p3_idx)));

% ===== plot =====
% one shared color scale
lim = ceil(max(abs([frn_lib_avg; frn_con_avg; p3_lib_avg; p3_con_avg])));

figure('Position', [100 100 650 600], 'Color', 'w');
fig_tile = tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(fig_tile);
topoplot(frn_lib_avg, template_locs, 'maplimits', [-lim lim], 'electrodes', 'on', 'emarker2', {roi_frn_idx, 'o', 'k', 5, 1});  % <- mark ROI sites
title(sprintf('Liberal: FA (FPF) - Hit\nFRN %d-%d ms', win_frn(1), win_frn(2)));

nexttile(fig_tile);
topoplot(frn_con_avg, template_locs, 'maplimits', [-lim lim], 'electrodes', 'on', 'emarker2', {roi_frn_idx, 'o', 'k', 5, 1});
title(sprintf('Conservative: Miss (FPF) - CR\nFRN %d-%d ms', win_frn(1), win_frn(2)));

nexttile(fig_tile);
topoplot(p3_lib_avg, template_locs, 'maplimits', [-lim lim], 'electrodes', 'on', 'emarker2', {roi_p3_idx, 'o', 'k', 5, 1});
title(sprintf('Liberal: FA (FPF) - Hit\nP3 %d-%d ms', win_p3(1), win_p3(2)));

nexttile(fig_tile);
topoplot(p3_con_avg, template_locs, 'maplimits', [-lim lim], 'electrodes', 'on', 'emarker2', {roi_p3_idx, 'o', 'k', 5, 1});
title(sprintf('Conservative: Miss (FPF) - CR\nP3 %d-%d ms', win_p3(1), win_p3(2)));

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
file_name = fullfile(out_dir, 'topo_feed_fpfcorrect.pdf');
exportgraphics(fig_tile, file_name, 'ContentType', 'vector');

msgbox('FINISHED');

beep on;
for bee = 1:3
    pause(0.5); beep;
end
