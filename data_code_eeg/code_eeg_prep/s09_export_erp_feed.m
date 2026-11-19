cd /Volumes/toshiba/eeg_data_backup
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

% study_dir = '/Volumes/toshiba/eeg_data_backup/09_study/with_design';
% [STUDY, ALLEEG] = pop_loadstudy('filename', 'feed.study', 'filepath', study_dir);

epoch_dir = '/Volumes/toshiba/eeg_data_backup/08_epoch/feed';
file_list = dir(fullfile(epoch_dir, 'sub*.set'));

% FRN: Fz, FCz, Cz
% feedback P3 or Pe late positivity: Cz, CPz, Pz

time_window = [-200 900]; 
chan_list = {'Fz','FCz','Cz','CPz','Pz'};
chan_suffix = strjoin(chan_list, '');  % for csv file names; so that new exports do not overwrite old ones unless identical 

out = table();

for i = 1:numel(file_list)

    EEG = pop_loadset('filename', file_list(i).name, 'filepath', file_list(i).folder);
    sub = string(EEG.subject);
    disp(sub);

    labels = string({EEG.chanlocs.labels});
    [tf, chan_idx] = ismember(string(chan_list), labels);
    chan_idx = chan_idx(tf);
    use_chans = string(chan_list(tf));

    if isempty(chan_idx)
        warning(sub, '%s not found, skip');
        continue
    end

    time_idx = EEG.times >= time_window(1) & EEG.times <= time_window(2);
    times = EEG.times(time_idx);

    task         = get_epoch_field(EEG, 'eventtask');
    curr_cond    = get_epoch_field(EEG, 'eventcurr_cond');
    resp_type    = get_epoch_field(EEG, 'eventresp_type');
    is_correct   = get_epoch_field(EEG, 'eventis_correct');
    trial_is_fpf = get_epoch_field(EEG, 'eventtrial_is_fpf');
    critical_err = get_epoch_field(EEG, 'eventcritical_err');
    conf         = get_epoch_field(EEG, 'eventconf');

    combos = unique([task curr_cond resp_type is_correct trial_is_fpf critical_err conf], 'rows');

    for j = 1:size(combos,1)

        this_task         = combos(j,1);
        this_curr_cond    = combos(j,2);
        this_resp_type    = combos(j,3);
        this_is_correct   = combos(j,4);
        this_trial_is_fpf = combos(j,5);
        this_critical_err = combos(j,6);
        this_conf         = combos(j,7);

        trial_idx = find( ...
            task == this_task & ...
            curr_cond  == this_curr_cond & ...
            resp_type  == this_resp_type & ...
            is_correct == this_is_correct & ...
            trial_is_fpf == this_trial_is_fpf & ...
            critical_err == this_critical_err & ...
            conf == this_conf);

        if isempty(trial_idx)
            continue
        end

        X = EEG.data(chan_idx, time_idx, trial_idx);
        Xmean = mean(X, 3, 'omitnan');
        ntrials = numel(trial_idx);

        for ch = 1:numel(use_chans)
            %disp(use_chans(ch));

            tmp = table( ...
                repmat(sub, numel(times), 1), ...
                repmat("feed", numel(times), 1), ...
                repmat(this_task, numel(times), 1), ...
                repmat(this_curr_cond, numel(times), 1), ...
                repmat(this_resp_type, numel(times), 1), ...
                repmat(this_is_correct, numel(times), 1), ...
                repmat(this_trial_is_fpf, numel(times), 1), ...
                repmat(this_critical_err, numel(times), 1), ...
                repmat(this_conf, numel(times), 1), ...
                repmat(use_chans(ch), numel(times), 1), ...
                times(:), ...
                squeeze(Xmean(ch,:))', ...
                repmat(ntrials, numel(times), 1), ...
                'VariableNames', ...
                {'sub','study','task','curr_cond','resp_type','is_correct','trial_is_fpf','critical_err', 'conf', ...
                 'chan','time_ms','amp','ntrials'} ...
            );

            out = [out; tmp];
            %disp('DONE');
        end
    end
end

outname = fullfile('./10_erp_mean', "erp_feed_" + chan_suffix + ".csv")
disp(size(out));
writetable(out, outname);

msgbox('Finished!');

beep on;
for bee = 1:5
    pause(0.5); beep;
end

function vals = get_epoch_field(EEG, fieldname)
n = numel(EEG.epoch);
vals = strings(n,1);
for ii = 1:n
    if isfield(EEG.epoch(ii), fieldname)
        v = EEG.epoch(ii).(fieldname);
        if iscell(v)
            if isempty(v)
                vals(ii) = "";
            else
                vals(ii) = local_to_string(v{1});
            end
        else
            vals(ii) = local_to_string(v);
        end
    else
        vals(ii) = "";
    end
end
end

function s = local_to_string(v)
    if isstring(v)
        s = v;
    elseif ischar(v)
        s = string(v);
    elseif isnumeric(v) || islogical(v)
        s = string(v);
    else
        s = "";
    end
end