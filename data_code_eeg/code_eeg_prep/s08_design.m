
cd /Volumes/toshiba/eeg_data_backup

% erp=on, ersp=on, ersp params=on, specify baseline for ersp
% erp  -> .daterp
% ersp -> .datersp (may not appear in filelist)
% spec -> .datspec
% .dattimef = raw time freq data
% interp=on to avoid unequal matrix size for std_erspplot 
% recompute=off to re-link .study file with .daterp/.datersp files (if forgot to resave after running precomp) [this does not rerun precomp so will be very quick]

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

% MUST SPECIFY vartype & values for bins to be valid!!
% order of variableN and valuesN decide order of bins in the plot
% - make sure order of bins consistent with other erp plots 

% design:
% test_stim: old vs new
% resp: 
% feed: 
% cshift: 

% NECESSARY DESIGNS:
% resptype, respconf, isfpf, is_criticalerror

% OPTIONAL DESIGNS:
% taskcondXhitcr, taskcondXsayoldnew, taskcondXstudied, taskcondXiscorrect 
% these are redundant with resptype etc - reduce precomp time 


% init 
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab('nogui');
study_dir = '/Volumes/toshiba/eeg_data_backup/09_study'

% separate .study files: study_stim, test_stim, resp, feed

%% ===== PRECOMP SETTINGS =====
recomp_status = 'on'  % off if no changes to erp/ersp params and no changes to trial fields
recomp_date = '2026-09-28'
erp_on = 'on';
ersp_on = 'off';

if strcmp(recomp_status,'on') 
    curr_precomp_log = fopen(strcat('./09_study/with_design/precomp_log_', recomp_date, ".txt"), 'w')
end

%% ===== test_stim =====
% load .study files
[STUDY ALLEEG] = pop_loadstudy('filename', 'test_stim.study', 'filepath', study_dir);
STUDY = std_maketrialinfo(STUDY, ALLEEG);   % refresh trialinfo
STUDY.design = [];  % reset existing design 

% old/new effect [hit-cr]
% STUDY = std_makedesign(STUDY, ALLEEG, 1, ...
%     'name', 'taskcondXhitcr', ...
%     'variable1', 'task', 'values1', {'true_feed','strategic','false_feed'}, ...
%     'variable2', 'curr_cond', 'values2', {'NONE','lib','con'}, ...
%     'trialselect', {'resp_type', {'hit','cr'}});

% task x cond 
STUDY = std_makedesign(STUDY, ALLEEG, 1, ... 
    'name', 'taskXcond', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'});

STUDY = std_makedesign(STUDY, ALLEEG, 2, ...  
    'name', 'taskcondXresptype', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
    'variable2', 'resp_type', 'values2', {'hit','fa','cr','miss'});

% SUBSETTING REQUIRES CREATING SEPARATE .SET AND DESIGN FILES
% STUDY = std_makedesign(STUDY, ALLEEG, 3, ...  
%     'name', 'taskcondXresptype_highconf', ...
%     'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
%     'variable2', 'resp_type', 'values2', {'hit','fa','cr','miss'});
% 
% STUDY = std_makedesign(STUDY, ALLEEG, 4, ...  
%     'name', 'taskcondXresptype_lowconf', ...
%     'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
%     'variable2', 'resp_type', 'values2', {'hit','fa','cr','miss'});

% say old/new
STUDY = std_makedesign(STUDY, ALLEEG, 5, ...
    'name', 'taskcondXsayoldnew', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
    'variable2', 'resp_old', 'values2', {'old','new'});

% is critical error [incorrect trialtype only]
% SUBSET TO FA & MISS ONLY
% STUDY = std_makedesign(STUDY, ALLEEG, 6, ... 
%     'name', 'taskcondXis_criticalerror', ...
%     'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
%     'variable2', 'critical_err', 'values2', {'0','1','NA'});

if strcmp(recomp_status,'on')
    fprintf(curr_precomp_log, strcat('stim precomp start: ',string(datetime)))
end

% precomp params
freq_low = 4; 
epoch_length = ALLEEG(1).xmax - ALLEEG(1).xmin; % in seconds
%baseline_window = [-200 0];   % not enough pre-stim time for this to work
baseline_window = NaN;    % do manual normalization later
cycles_low_max = floor(freq_low * epoch_length * 0.8);
cycles_low = max(2, min(3, cycles_low_max));
cycles = [cycles_low 0.5];

% precomp 
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels', 'interp', 'on', 'recompute', recomp_status , 'erp', erp_on, 'ersp', ersp_on, 'erspparams', {'baseline', baseline_window, 'cycles', [3 0.5], 'freqs', [freq_low 30], 'nfreqs', 30, 'ntimesout', 100}); % must specify params 
% testEEG = ALLEEG(1:3);  
% [testSTUDY, testALLEEG] = std_precomp(testSTUDY, testALLEEG, 'channels', 'recompute', 'on', 'erp', 'on', 'ersp', 'on', 'erspparams', {'baseline', baseline_window, 'cycles', cycles, 'freqs', [freq_low 30], 'nfreqs', 30, 'ntimesout', 100})

if strcmp(recomp_status,'on')
    fprintf(curr_precomp_log, strcat('stim precomp end: ',string(datetime)))
end

% save
newName = fullfile('./with_design',  'test_stim.study'); 
[STUDY ALLEEG] = pop_savestudy(STUDY, ALLEEG, 'filename', newName);
% dir('**/*.datersp');  % verify ersp files exist  <- exist but might be hidden!
% dir('../..dattimef);  % raw time freq data

% clear STUDY objects 
STUDY = [];
ALLEEG = [];

%% ================
%% ===== resp =====
%% ================

[STUDY ALLEEG] = pop_loadstudy('filename', 'resp.study', 'filepath', study_dir);
STUDY = std_maketrialinfo(STUDY, ALLEEG); 
STUDY.design = []; 

% old/new effect [hit-cr]
% SUBSET TO HIT & CR ONLY
% STUDY = std_makedesign(STUDY, ALLEEG, 1, ...
%     'name', 'taskcondXhitcr', ...
%     'variable1', 'task', 'values1', {'true_feed','strategic','false_feed'}, ...
%     'variable2', 'curr_cond', 'values2', {'NONE','lib','con'});

% task x cond 
STUDY = std_makedesign(STUDY, ALLEEG, 1, ... % originally 2
    'name', 'taskXcond', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'});

% taskcond x resptype
STUDY = std_makedesign(STUDY, ALLEEG, 2, ...  
    'name', 'taskcondXresptype', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
    'variable2', 'resp_type', 'values2', {'hit','fa','cr','miss'});

% taskcond x confidence 
STUDY = std_makedesign(STUDY, ALLEEG, 3, ...
    'name', 'taskcondXconf', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
    'variable2', 'conf', 'values2', {'low','med','high'}); 

% is critical error [incorrect only]
% SUBSET TO FA & MISS ONLY
% STUDY = std_makedesign(STUDY, ALLEEG, 4, ... 
%     'name', 'taskcondXis_criticalerror', ...
%     'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'strategic con', 'strategic lib', 'true_feed NONE'}, ...
%     'variable2', 'critical_err', 'values2', {'0','1','NA'});


% say old/new
% STUDY = std_makedesign(STUDY, ALLEEG, 4, ...
%     'name', 'taskcondXsayoldnew', ...
%     'variable1', 'task', 'values1', {'true_feed','strategic','false_feed'}, ...
%     'variable2', 'curr_cond', 'values2', {'NONE','lib','con'});

% correct vs incorrect
% STUDY = std_makedesign(STUDY, ALLEEG, 5, ...
%     'name', 'taskcondXiscorrect', ...
%     'variable1', 'task', 'values1', {'true_feed','strategic','false_feed'}, ...
%     'variable2', 'curr_cond', 'values2', {'NONE','lib','con'});

if strcmp(recomp_status,'on')
    fprintf(curr_precomp_log, strcat('resp precomp start: ',string(datetime)))
end

% precomp 
freq_low = 4;  
epoch_length = ALLEEG(1).xmax - ALLEEG(1).xmin; % in seconds
%baseline_window = [-400 -200];
baseline_window = NaN;
cycles_low_max = floor(freq_low * epoch_length * 0.8);
cycles_low = max(2, min(3, cycles_low_max));
cycles = [cycles_low 0.5];

[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels', 'interp', 'on', 'recompute', recomp_status, 'erp', erp_on, 'ersp', ersp_on, 'erspparams', {'baseline', baseline_window, 'cycles', [3 0.5], 'freqs', [freq_low 30], 'nfreqs', 30, 'ntimesout', 100}, 'spec', 'off', 'rmicacomps', 'off');   % default off

if strcmp(recomp_status,'on')
    fprintf(curr_precomp_log, strcat('resp precomp end: ',string(datetime)))
end

% save
newName = fullfile('./with_design',  'resp.study'); 
[STUDY ALLEEG] = pop_savestudy(STUDY, ALLEEG, 'filename', newName);

% clear STUDY objects 
STUDY = [];
ALLEEG = [];

%% ================
%% ===== feed =====
%% ================

[STUDY ALLEEG] = pop_loadstudy('filename', 'feed.study', 'filepath', study_dir);
STUDY = std_maketrialinfo(STUDY, ALLEEG); 
STUDY.design = [];  

% task x cond
STUDY = std_makedesign(STUDY, ALLEEG, 1, ...
    'name', 'taskXcond', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'true_feed NA'});

% taskcond x resptype
STUDY = std_makedesign(STUDY, ALLEEG, 2, ...  
    'name', 'taskcondXresptype', ...
    'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'true_feed NA'}, ...
    'variable2', 'resp_type', 'values2', {'hit','fa','cr','miss'});

% is FPF [true/false feed only] 
% SUBSET TASK 
% STUDY = std_makedesign(STUDY, ALLEEG, 3, ... 
%     'name', 'taskcondXresptype_fpf', ...
%     'variable1', 'taskcond', 'values1', {'false_feed con', 'false_feed lib', 'true_feed NA'}, ...
%     'variable2', 'resptype_fpf', 'values2', {'hit 0','fa 0','cr 0','miss 0', 'hit 1','fa 1','cr 1','miss 1', 'hit NA','fa NA','cr NA','miss NA'});

if strcmp(recomp_status,'on')
    fprintf(curr_precomp_log, strcat('feed precomp start: ',string(datetime)))
end

% precomp 
freq_low = 4;  
epoch_length = ALLEEG(1).xmax - ALLEEG(1).xmin; % in seconds
%baseline_window = [-200 0];
baseline_window = NaN;
cycles_low_max = floor(freq_low * epoch_length * 0.8);
cycles_low = max(2, min(3, cycles_low_max));
cycles = [cycles_low 0.5];

[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels', 'interp', 'on', 'recompute', recomp_status, 'erp', erp_on, 'ersp', ersp_on, 'erspparams', {'baseline', baseline_window, 'cycles', [3 0.5], 'freqs', [freq_low 30], 'nfreqs', 30, 'ntimesout', 100}, 'spec', 'off', 'rmicacomps', 'off');   % default off 

if strcmp(recomp_status,'on')
    fprintf(curr_precomp_log, strcat('feed precomp end: ',string(datetime)))
end

% save  
newName = fullfile('./with_design',  'feed.study'); 
[STUDY ALLEEG] = pop_savestudy(STUDY, ALLEEG, 'filename', newName);

% clear STUDY objects 
STUDY = [];
ALLEEG = [];


% beep on;
% for bee = 1:5
%     pause(0.5); beep;
% end

  