
cd /Volumes/toshiba/eeg_data_backup

% using .set files after manual rejection
fileList = dir(fullfile('06_flag_ica','sub*.set'));
fileNames = {fileList.name}; 

%%

n_sub = length(fileList);

%start_with_file = 'sub78.set';  % start from here
start_with_file = 'sub11.set';  % start from here
start_with_file_pos = find(strcmp(fileNames, start_with_file));
end_with_file = 'sub12.set';
end_with_file_pos = find(strcmp(fileNames, end_with_file));


for i = start_with_file_pos:n_sub

    disp(datetime);

    % get file name
    fullPath = fullfile(fileList(i).folder, fileList(i).name);
    file = fileList(i).name;
    sub = erase(file,".set");
    disp(sub);

    % load .set file
    ica = pop_loadset(fullPath);

    % remove flagged ica components
    ic_reject = find(ica.reject.gcompreject);
    ica_clean = pop_subcomp(ica,ic_reject,0);  % 0=no confirmation needed

    % add new vars 
    for e = 1:length(ica_clean.event)
        task = ica_clean.event(e).task;
        cond = ica_clean.event(e).curr_cond;
        ica_clean.event(e).taskcond = [task ' ' cond];
        resptype = ica_clean.event(e).resp_type;
        isfpf = ica_clean.event(e).trial_is_fpf;
        ica_clean.event(e).resptype_fpf = [resptype ' ' isfpf]; 

        % test_block_half [trial number 1-50 vs 51-100]
        %curr_cond_half = 

        % test_block_quad [each 25] 
        %curr_cond_quad

        % c placement quad in each task cond

        % cshift quad in each task

    end 

    ica_clean = eeg_checkset(ica_clean, 'eventconsistency');

    newName = fullfile('./07_ica_clean', [sub '.set']); 
    pop_saveset(ica_clean, 'filename', newName, 'savemode','onefile');

    % ===== epoch ===== 
    %% !!! pop_epoch() uses seconds, pop_rmbase() uses miliseconds !!!

    if sub ~= "sub24"
        study_stim = pop_epoch(ica_clean, {33 63 93}, [-0.25,1.2], 'epochinfo', 'yes');
        study_stim = pop_rmbase(study_stim, [-200 0]);
    end

    test_stim = pop_epoch(ica_clean, {34 35 64 65 94 95}, [-0.25,1.5], 'epochinfo', 'yes');
    test_stim = pop_rmbase(test_stim, [-200 0]);

    resp = pop_epoch(ica_clean, {...
    41 42 43 44 45 46 ...
    71 72 73 74 75 76 ...
    101 102 103 104 105 106}, ...
        [-0.55 0.5], 'epochinfo', 'yes');
    resp = pop_rmbase(resp, [-400 -200]);

    feed = pop_epoch(ica_clean, {...
    51 52 53 54 55 56 57 59 ...
    81 82 83 84 85 86 87 89 ...
    111 112 113 114 115 116 117 118}, ...
        [-0.25 0.9], 'epochinfo', 'yes');
    feed = pop_rmbase(feed, [-200 0]);  % re-epoched from -50

    % save 
    dir_study = fullfile('./08_epoch/study');
    dir_test  = fullfile('./08_epoch/test_stim');
    dir_resp  = fullfile('./08_epoch/resp');
    dir_feed  = fullfile('./08_epoch/feed');

    if ~exist(dir_study, 'file')
        mkdir(dir_study);
    end 
    if ~exist(dir_test, 'file')
        mkdir(dir_test);
    end 
    if ~exist(dir_resp, 'file')
        mkdir(dir_resp);
    end 
    if ~exist(dir_feed, 'file')
        mkdir(dir_feed);
    end 

    newName = fullfile(dir_study, [sub '.set']); 
    pop_saveset(study_stim, 'filename', newName, 'savemode','onefile');
    newName = fullfile(dir_test, [sub '.set']); 
    pop_saveset(test_stim, 'filename', newName, 'savemode','onefile');
    newName = fullfile(dir_resp, [sub '.set']); 
    pop_saveset(resp, 'filename', newName, 'savemode','onefile');
    newName = fullfile(dir_feed, [sub '.set']); 
    pop_saveset(feed, 'filename', newName, 'savemode','onefile');


end

beep on;
for bee = 1:5
    pause(0.5); beep;
end  

