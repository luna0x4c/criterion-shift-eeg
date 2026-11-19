
% automatically remove nontask periods and mark with 'boundary'

cd /Volumes/toshiba/eeg_data_backup

fileList = dir(fullfile('02_rawset_with_trial_info','sub*.set'));   % EEG
fileNames = {fileList.name}; 

n_sub = length(fileList);   

start_with_file = 'sub78.set';  % start from here
start_with_file_pos = find(strcmp(fileNames, start_with_file));

for i = start_with_file_pos:n_sub

    % get .set file name
    fullPath = fullfile(fileList(i).folder, fileList(i).name);
    file = fileList(i).name;
    sub  = erase(file,".set");
    disp(sub);
    
    % load set 
    EEG = pop_loadset(fullPath); 

    m = 0; % timestamp tracker 
    trim_times = [];

    for j = 1:length(EEG.event)

        % get time points to mark stard/end (min/max) in pop_select()
        
        if EEG.event(j).boundary_time ~= "NA"   % ~= for "not equal to" 
            %disp(j);
            m = m+1;
            timestamp = EEG.event(j).boundary_time;
            timestamp = str2num(timestamp);
            trim_times(m) = timestamp;  % gather timestamps
        end 
        
        if sub == "sub60" & j == 2497 % special case for sub60: false_feed trial 100 had 3 events not tagged
            m = m+1;
            timestamp = EEG.event(j).latency_s + 0.5;
            trim_times(m) = timestamp;

            EEG.event(j).task = EEG.event(j-3).task;
            EEG.event(j).test_block = EEG.event(j-3).test_block;
            EEG.event(j).test_cond = EEG.event(j-3).test_cond;
            EEG.event(j).i_trial = EEG.event(j-3).i_trial;
            EEG.event(j).curr_cond = EEG.event(j-3).curr_cond;
            EEG.event(j).feed_text = EEG.event(j-3).feed_text;
            EEG.event(j).is_correct = EEG.event(j-3).is_correct;
            EEG.event(j).is_correct_text = EEG.event(j-3).is_correct_text;
            EEG.event(j).studied = EEG.event(j-3).studied;
            EEG.event(j).conf = EEG.event(j-3).conf;
            EEG.event(j).resp_old = EEG.event(j-3).resp_old;
            EEG.event(j).resp_type = EEG.event(j-3).resp_type;
            EEG.event(j).critical_err = EEG.event(j-3).critical_err;
            EEG.event(j).trial_is_fpf = EEG.event(j-3).trial_is_fpf;

            EEG.event(j-1).task = EEG.event(j-3).task;
            EEG.event(j-1).test_block = EEG.event(j-3).test_block;
            EEG.event(j-1).test_cond = EEG.event(j-3).test_cond;
            EEG.event(j-1).i_trial = EEG.event(j-3).i_trial;
            EEG.event(j-1).curr_cond = EEG.event(j-3).curr_cond;
            EEG.event(j-1).feed_text = EEG.event(j-3).feed_text;
            EEG.event(j-1).is_correct = EEG.event(j-3).is_correct;
            EEG.event(j-1).is_correct_text = EEG.event(j-3).is_correct_text;
            EEG.event(j-1).studied = EEG.event(j-3).studied;
            EEG.event(j-1).conf = EEG.event(j-3).conf;
            EEG.event(j-1).resp_old = EEG.event(j-3).resp_old;
            EEG.event(j-1).resp_type = EEG.event(j-3).resp_type;
            EEG.event(j-1).critical_err = EEG.event(j-3).critical_err;
            EEG.event(j-1).trial_is_fpf = EEG.event(j-3).trial_is_fpf;

            EEG.event(j-2).task = EEG.event(j-3).task;
            EEG.event(j-2).test_block = EEG.event(j-3).test_block;
            EEG.event(j-2).test_cond = EEG.event(j-3).test_cond;
            EEG.event(j-2).i_trial = EEG.event(j-3).i_trial;
            EEG.event(j-2).curr_cond = EEG.event(j-3).curr_cond;
            EEG.event(j-2).feed_text = EEG.event(j-3).feed_text;
            EEG.event(j-2).is_correct = EEG.event(j-3).is_correct;
            EEG.event(j-2).is_correct_text = EEG.event(j-3).is_correct_text;
            EEG.event(j-2).studied = EEG.event(j-3).studied;
            EEG.event(j-2).conf = EEG.event(j-3).conf;
            EEG.event(j-2).resp_old = EEG.event(j-3).resp_old;
            EEG.event(j-2).resp_type = EEG.event(j-3).resp_type;
            EEG.event(j-2).critical_err = EEG.event(j-3).critical_err;
            EEG.event(j-2).trial_is_fpf = EEG.event(j-3).trial_is_fpf;

        end

    end 


    if length(trim_times) ~= 18  % 9 segments x 2 (start+end) each
        error("MISSING OR EXTRA BOUNDARY TIMES")
    end

    trim_times = sort(trim_times);

    % remove nontask periods according to timestamps
    NEWEEG = pop_select(EEG, 'time', ...
    [trim_times(1) trim_times(2);  trim_times(3)  trim_times(4);  trim_times(5)  trim_times(6); ... 
    trim_times(7)  trim_times(8);  trim_times(9)  trim_times(10); trim_times(11) trim_times(12); ...
    trim_times(13) trim_times(14); trim_times(15) trim_times(16); trim_times(17) trim_times(18) ...
    ]);
    
    % save to trimset [keep as copy]
    newName1 = fullfile('./03_trimset', [sub '.set']); 
    pop_saveset(NEWEEG, 'filename', newName1, 'savemode','onefile');

    % save a copy to check for more segments that need to be removed!!!
    newName2 = fullfile('./04_cleanset', [sub '.set']); 
    pop_saveset(NEWEEG, 'filename', newName2, 'savemode','onefile');
    % can make changes to .set file directly in this folder; saves over itself

end 

 


