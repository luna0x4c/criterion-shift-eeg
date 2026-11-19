%% take diff within task condition, THEN average across condition

cd /Volumes/toshiba/eeg_data_backup
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

study_dir = '/Volumes/toshiba/eeg_data_backup/09_study/with_design';
[STUDY, ALLEEG] = pop_loadstudy('filename', 'resp.study', 'filepath', study_dir);

% ===== incorrect-correct responses =====
% ERN 0-150 ms (Cz, FCz)

win_ern = [0 150];
roi_ern = {'Cz','FCz'};
min_n = 3;   % same min trial count as R 

% full scalp montage: same .ced as s01_load, EXG removed as in s05_runica
% [!!!] update path if .ced is not in the current folder
template_locs = readlocs('attlab64locs.ced');
is_exg = strncmpi({template_locs.labels}, 'EXG', 3);
template_locs = template_locs(~is_exg);
template_labels = string({template_locs.labels});
n_chan = numel(template_locs);

roi_ern_idx = find(ismember(template_labels, roi_ern));

n_sub = numel(ALLEEG);

% subject-level diffmap (chan x sub) 
% taskcond skipped if < min_n trials in either cell
% sub is NaN ONLY if every taskcond is skipped
ern_corr = nan(n_chan, n_sub);

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
    task      = strings(n_ep, 1);
    curr_cond = strings(n_ep, 1);
    resp_type = strings(n_ep, 1);

    for ep = 1:n_ep
        v = EEG.epoch(ep).eventtask;      if iscell(v), v = v{1}; end;  task(ep) = string(v);
        v = EEG.epoch(ep).eventcurr_cond; if iscell(v), v = v{1}; end;  curr_cond(ep) = string(v);
        v = EEG.epoch(ep).eventresp_type; if iscell(v), v = v{1}; end;  resp_type(ep) = string(v);
    end

    ern_time = EEG.times >= win_ern(1) & EEG.times <= win_ern(2);
    ern_cond = nan(n_chan, 5);   % chan x taskcond
 
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
        incorrect_trials = find(is_tc & (resp_type == "fa" | resp_type == "miss"));
        correct_trials = find(is_tc & (resp_type == "hit" | resp_type == "cr"));
 
        if numel(incorrect_trials) >= min_n && numel(correct_trials) >= min_n
            incorrect_erp = mean(EEG.data(chan_idx, :, incorrect_trials), 3);   % chan x time
            correct_erp = mean(EEG.data(chan_idx, :, correct_trials), 3);
            diff_erp = incorrect_erp - correct_erp;
            ern_cond(:, tc) = mean(diff_erp(:, ern_time), 2);   % mean over window
        end
    end
 
    ern_corr(:, i) = mean(ern_cond, 2, 'omitnan');

end

% ===== GRAND AVG across subs =====
ern_avg = mean(ern_corr, 2, 'omitnan');

n_ern = sum(~isnan(ern_corr(1, :)));

% ===== plot =====
% one shared color scale
lim = ceil(max(abs(ern_avg)));

figure('Position', [100 100 360 320], 'Color', 'w');
fig_tile = tiledlayout(1, 1, "TileSpacing", "compact", "Padding", "compact");

nexttile(fig_tile);
topoplot(ern_avg, template_locs, 'maplimits', [-lim lim], 'electrodes', 'on', 'emarker2', {roi_ern_idx, 'o', 'k', 5, 1});
title(sprintf('Incorrect - Correct\nERN %d-%d ms', win_ern(1), win_ern(2)));

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
file_name = fullfile(out_dir, 'topo_resp_incorrectcorrect.pdf');
exportgraphics(fig_tile, file_name, 'ContentType', 'vector');

msgbox('FINISHED');

beep on;
for bee = 1:3
    pause(0.5); beep;
end
