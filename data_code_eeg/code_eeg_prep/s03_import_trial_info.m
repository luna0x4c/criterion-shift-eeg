
% take urevent csv files with COMPLETE trial info and import back into EEG.events/urevents

cd /Volumes/toshiba/eeg_data_backup

fileList_raw = dir(fullfile('01_rawset','*.set'));   % EEG
fileNames_raw = {fileList_raw.name}; 

fileList_events = dir(fullfile('01_urevent_complete','sub*.csv'));   % trials
% use "sub*.csv" matching pattern to remove invisile files that have ._ at the beginning 
fileNames_events = {fileList_events.name}; 

out_dir = "/Volumes/toshiba/eeg_data_backup/02_rawset_with_trial_info"


n_sub = length(fileList_raw);   % use EEG subs list instead of events sublist 

start_with_file = 'sub78.set';  % start from here
start_with_file_pos = find(strcmp(fileNames_raw, start_with_file));

for i = start_with_file_pos:n_sub

    % get .set file name
    fullPath_eeg = fullfile(fileList_raw(i).folder, fileList_raw(i).name);
    file_eeg = fileList_raw(i).name;
    sub_eeg  = erase(file_eeg,".set");
    disp(sub_eeg);
    
    % load rawset 
    EEG = pop_loadset(fullPath_eeg);    

    % find trials csv file
    for j = 1:length(fileList_events)
        % get file name
        fullPath_events = fullfile(fileList_events(j).folder, fileList_events(j).name);
        file_events = fileList_events(j).name;
        sub_events = erase(file_events,"_urevent_complete.csv");

        % if subID matches EEG subID, load csv 
        if sub_eeg == sub_events
            disp(sub_events);

            events = readtable(fullPath_events);
            % table to struct
            events_struct = table2struct(events);
           
            % replace events/urevents
            % IMPORTANT: need to be transposed!!! [either transpose() or .']
            EEG.event   = events_struct.';
            EEG.urevent = events_struct.';
            % save to new folder
            newName = fullfile('./02_rawset_with_trial_info', [sub_eeg '.set']); 
            pop_saveset(EEG, 'filename', newName, 'savemode','onefile');

        end

        end
    end

  
