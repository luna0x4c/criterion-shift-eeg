
cd /Volumes/toshiba/eeg_data_backup
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab('nogui');

% dir = '/Volumes/toshiba/eeg_data_backup/09_study/with_design';
% [STUDY, ALLEEG] = pop_loadstudy('filename', 'test_stim.study', 'filepath', dir);

epoch_dir = '/Volumes/toshiba/eeg_data_backup/08_epoch/test_stim';
file_list = dir(fullfile(epoch_dir, 'sub*.set'));

time_window = [-200 1500];
chan_list = {'Fz','Cz','FCz','Pz','CPz','P3','P4'};
chan_suffix = strjoin(chan_list, '');  % for csv file names; so that new exports do not overwrite old ones unless identical 

out = table();

for i = 1:numel(file_list)

    % loads data into memory after setting 'only keep one dataset in memory' in eeglab preferences 
    EEG = pop_loadset('filename',file_list(i).name, 'filepath', file_list(i).folder);
    sub = string(EEG.subject);
    disp(sub);

    labels = string({EEG.chanlocs.labels});
    [tf, chan_idx] = ismember(string(chan_list), labels);
    chan_idx = chan_idx(tf);
    use_chans = string(chan_list(tf));

    if isempty(chan_idx)
        warning(sub, ' %s channel not found, skip');
        continue
    end

    time_idx = EEG.times >= time_window(1) & EEG.times <= time_window(2);
    times = EEG.times(time_idx);

    % variables used across all test_stim designs in s08_design.m
    task      = get_epoch_field(EEG, 'eventtask');
    curr_cond = get_epoch_field(EEG, 'eventcurr_cond');
    resp_type = get_epoch_field(EEG, 'eventresp_type');
    resp_old  = get_epoch_field(EEG, 'eventresp_old');
    is_old    = get_epoch_field(EEG, 'eventstudied');
    conf      = get_epoch_field(EEG, 'eventconf');

    % keep trialselect variables as explicit IV columns, not just filters
    combos = unique([task curr_cond resp_type resp_old is_old conf], 'rows');

    for j = 1:size(combos,1)

        this_task      = combos(j,1);
        this_curr_cond = combos(j,2);
        this_resp_type = combos(j,3);
        this_resp_old  = combos(j,4);
        this_is_old    = combos(j,5);
        this_conf      = combos(j,6);

        trial_idx = find( ...
            task == this_task & ...
            curr_cond == this_curr_cond & ...
            resp_type == this_resp_type & ...
            resp_old == this_resp_old & ...
            is_old   == this_is_old & ...
            conf == this_conf);

        if isempty(trial_idx)
            continue
        end

        X = EEG.data(chan_idx, time_idx, trial_idx);   % chan x time x trial
        Xmean = mean(X, 3, 'omitnan');                 % chan x time
        ntrials = numel(trial_idx);

        for ch = 1:numel(use_chans)
            %disp(use_chans(ch));

            tmp = table( ...
                repmat(sub, numel(times), 1), ...
                repmat("test_stim", numel(times), 1), ...
                repmat(this_task,   numel(times), 1), ...
                repmat(this_curr_cond, numel(times), 1), ...
                repmat(this_resp_type, numel(times), 1), ...
                repmat(this_resp_old, numel(times), 1), ...
                repmat(this_is_old,   numel(times), 1), ...
                repmat(this_conf, numel(times), 1), ...
                repmat(use_chans(ch), numel(times), 1), ...
                times(:), ...
                squeeze(Xmean(ch,:))', ...
                repmat(ntrials, numel(times), 1), ...
                'VariableNames', ...
                {'sub','study','task','curr_cond','resp_type','resp_old','is_old','conf', ...
                 'chan','time_ms','amp','ntrials'} ...
            );

            out = [out; tmp];
            %disp('DONE');
        end
    end
end

outname = fullfile('./10_erp_mean', "erp_teststim_" + chan_suffix + ".csv")
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