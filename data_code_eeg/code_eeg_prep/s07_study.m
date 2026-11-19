
cd /Volumes/toshiba/eeg_data_backup

% trig_type: 
% task: true_feed, strategic, false_feed
% test_cond: 'NA', lib, con
% curr_cond: NONE, lib, con
% is_correct: '1', '0'
% studied: '1', '0'
% resp_old: old, new
% resp_type: hit, fa, miss, cr
% resp_real_key
% conf: low, med high
% critical_err: '0', '1'
% trial_is_fpf: 'NA', '1', '0'

% init 
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab('nogui');

% separate .study files: study_stim, test_stim, resp, feed

%% ===== study_stim =====

ALLEEG = [];
EEG = [];
CURRENTSET = 0;

fileList1 = dir(fullfile('08_epoch/study','sub*.set'));
fileNames1 = {fileList1.name}; 

for i = 1:length(fileList1) 

    disp(datetime);

    % get file name
    folder = fileList1(i).folder;
    file   = fileList1(i).name;
    sub    = erase(file,".set");
    disp(sub);

    % load .set file 
    % must use absolute paths!!
    EEG = pop_loadset('filename', file, 'filepath', folder);
    EEG.setname = sub;  % clean up name
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, i);

end

disp(datetime);

[STUDY_studystim ALLEEG] = std_editset([], ALLEEG, 'name', 'study_stim', 'updatedat', 'off', 'savedat', 'off');
% eeglab will check for & fill in uniform epoch info (all events within the same epoch)
% 'updatedat' = redraw eeglab window/workspace vars
% 'savedat'   = write back to .set files
[STUDY_studystim ALLEEG] = std_checkset(STUDY_studystim, ALLEEG);

% save to ./09_study
newName1 = fullfile('./09_study', 'study_stim.study'); 
pop_savestudy(STUDY_studystim, ALLEEG, 'filename', newName1);

%% ===== test_stim =====

ALLEEG = [];
EEG = [];
CURRENTSET = 0;

fileList2 = dir(fullfile('08_epoch/test_stim','sub*.set'));
fileNames2 = {fileList2.name}; 

for i = 1:length(fileList2) 

    disp(datetime);

    % get file name
    folder = fileList2(i).folder; 
    file   = fileList2(i).name;
    sub    = erase(file,".set");
    disp(sub);

    EEG = pop_loadset('filename', file, 'filepath', folder);
    EEG.setname = sub; 
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, i);

end

disp(datetime);

[STUDY_teststim ALLEEG] = std_editset([], ALLEEG, 'name', 'test_stim', 'updatedat', 'off', 'savedat', 'off');
[STUDY_teststim ALLEEG] = std_checkset(STUDY_teststim, ALLEEG);

% save to ./09_study
newName2 = fullfile('./09_study', 'test_stim.study'); 
pop_savestudy(STUDY_teststim, ALLEEG, 'filename', newName2);

%% ===== resp =====

ALLEEG = [];
EEG = [];
CURRENTSET = 0;

fileList3 = dir(fullfile('08_epoch/resp','sub*.set'));
fileNames3 = {fileList3.name}; 

for i = 1:length(fileList3) 

    disp(datetime);

    folder = fileList3(i).folder; 
    file   = fileList3(i).name;
    sub    = erase(file,".set");
    disp(sub);

    EEG = pop_loadset('filename', file, 'filepath', folder);
    EEG.setname = sub; 
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, i);

end

disp(datetime);

[STUDY_resp ALLEEG] = std_editset([], ALLEEG, 'name', 'resp', 'updatedat', 'off', 'savedat', 'off');
[STUDY_resp ALLEEG] = std_checkset(STUDY_resp, ALLEEG);

% save to ./09_study
newName3 = fullfile('./09_study', 'resp.study'); 
pop_savestudy(STUDY_resp, ALLEEG, 'filename', newName3);

%% ===== feed =====

ALLEEG = [];
EEG = [];
CURRENTSET = 0;

fileList4 = dir(fullfile('08_epoch/feed','sub*.set'));
fileNames4 = {fileList4.name}; 

for i = 1:length(fileList4) 

    % get file name
    folder = fileList4(i).folder; 
    file   = fileList4(i).name;
    sub    = erase(file,".set");
    disp(sub);

    EEG = pop_loadset('filename', file, 'filepath', folder);
    EEG.setname = sub; 
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, i);

end

disp(datetime);

[STUDY_feed ALLEEG] = std_editset([], ALLEEG, 'name', 'feed', 'updatedat', 'off', 'savedat', 'off');
[STUDY_feed ALLEEG] = std_checkset(STUDY_feed, ALLEEG);

% save to ./09_study
newName4 = fullfile('./09_study', 'feed.study'); 
pop_savestudy(STUDY_feed, ALLEEG, 'filename', newName4);


beep on;
for bee = 1:5
    pause(0.5); beep; 
end  


