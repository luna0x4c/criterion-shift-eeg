%% take diff within task condition, THEN average across condition

cd /Volumes/toshiba/eeg_data_backup
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

study_dir = '/Volumes/toshiba/eeg_data_backup/09_study/with_design';
[STUDY, ALLEEG] = pop_loadstudy('filename', 'feed.study', 'filepath', study_dir);

% ===== true "incorrect"-"correct" feedback =====
% true feedback trials only 
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
% taskcond skipped if < min_n trials in either cell
% sub is NaN ONLY if every taskcond is skipped
frn_true = nan(n_chan, n_sub);
p3_true  = nan(n_chan, n_sub);

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
    frn_true_cond = nan(n_chan, 3);   % chan x taskcond (baseline, FPF lib, FPF con)
    p3_true_cond  = nan(n_chan, 3);

    for tc = 1:3
        if tc == 1
            is_tc = task == "true_feed";
        elseif tc == 2
            is_tc = task == "false_feed" & curr_cond == "lib" & trial_is_fpf == "0";
        else
            is_tc = task == "false_feed" & curr_cond == "con" & trial_is_fpf == "0";
        end

        % pooling across conf = trial-weighted, same as R pipeline
        inc_trials = find(is_tc & (resp_type == "fa"  | resp_type == "miss"));
        cor_trials = find(is_tc & (resp_type == "hit" | resp_type == "cr"));

        if numel(inc_trials) >= min_n && numel(cor_trials) >= min_n
            inc_erp  = mean(EEG.data(chan_idx, :, inc_trials), 3); % chan x time
            cor_erp  = mean(EEG.data(chan_idx, :, cor_trials), 3);
            diff_erp = inc_erp - cor_erp;
            frn_true_cond(:, tc) = mean(diff_erp(:, frn_time), 2); % mean over window
            p3_true_cond(:, tc)  = mean(diff_erp(:, p3_time), 2);
        end
    end

    frn_true(:, i) = mean(frn_true_cond, 2, 'omitnan');
    p3_true(:, i)  = mean(p3_true_cond, 2,  'omitnan');

end

% ===== GRAND AVG across subs =====
frn_true_avg = mean(frn_true, 2, 'omitnan');
p3_true_avg  = mean(p3_true, 2, 'omitnan');

n_true = sum(~isnan(frn_true(1, :)));

% sanity check: ROI means should match descriptives from R get_des
fprintf('TRUE FEED N = %d | FRN ROI = %.2f uV | P3 ROI = %.2f uV\n', n_true, mean(frn_true_avg(roi_frn_idx)), mean(p3_true_avg(roi_p3_idx)));

% ===== plot =====
% color scale
lim_frn = ceil(max(abs(frn_true_avg)));
lim_p3  = ceil(max(abs(p3_true_avg)));

figure('Position', [100 100 650 320], 'Color', 'w');
fig_tile = tiledlayout(1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(fig_tile);
topoplot(frn_true_avg, template_locs, 'maplimits', [-lim_frn lim_frn], 'electrodes', 'on', 'emarker2', {roi_frn_idx, 'o', 'k', 5, 1});
title(sprintf('"Incorrect" - "Correct"\nFRN %d-%d ms', win_frn(1), win_frn(2)));
cb = colorbar;
cb.Label.String = '\muV';

nexttile(fig_tile);
topoplot(p3_true_avg, template_locs, 'maplimits', [-lim_p3 lim_p3], 'electrodes', 'on', 'emarker2', {roi_p3_idx, 'o', 'k', 5, 1});
title(sprintf('"Incorrect" - "Correct"\nP3 %d-%d ms', win_p3(1), win_p3(2)));
cb = colorbar;
cb.Label.String = '\muV';

% ===== save =====
%out_dir = fullfile('./11_topo_plot');
out_dir = fullfile('/Users/lunarneko/Desktop/11_topo_plot');
if ~exist(out_dir, 'file')
    mkdir(out_dir);
end

set(gcf, 'Renderer', 'painters');   % painters not opengl
file_name = fullfile(out_dir, 'topo_feed_incorrectcorrect.pdf');
exportgraphics(fig_tile, file_name, 'ContentType', 'vector');

msgbox('FINISHED');

beep on;
for bee = 1:3
    pause(0.5); beep;
end
