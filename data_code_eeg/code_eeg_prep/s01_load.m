
cd /Volumes/toshiba/eeg_data_backup

% load channel location file
chanlocs = readlocs('attlab64locs.ced'); % 'Status' (73rd) removed


fileList = dir(fullfile('./raw_good_subs','sub*.bdf'));
fileNames = {fileList.name}; 

%%

n_sub = length(fileList);

start_with_file = 'sub78.bdf'  % start processing new files from here
start_with_file_pos = find(strcmp(fileNames, start_with_file))


for i = start_with_file_pos:n_sub

    fullPath = fullfile(fileList(i).folder, fileList(i).name)
    file = fileList(i).name;
    sub = erase(file,".bdf");
    disp(sub);

    % load file, set ref 
    refLocs = eeg_chaninds(chanlocs, {'EXG1','EXG2'});
    raw = pop_biosig(fullPath,'channels',1:72,'ref',refLocs,'refoptions',{'keepref' 'on'});
    raw.setname = sub;
    raw.subject = sub;

    % write raw urevent to folder BEFORE downsampling
    newNameEvents = fullfile('./01_urevent_1024', [sub '_urevent.csv']);
    eeg_urevent = struct2table(raw.urevent);
    writetable(eeg_urevent, newNameEvents); 

    % downsample 1024 to 256
    raw = pop_resample(raw, 256);  
    % needs signal processing toolbox

    % write raw urevent to folder AFTER downsampling
    newNameEvents = fullfile('./01_urevent_256', [sub '_urevent.csv']);
    eeg_urevent = struct2table(raw.urevent);
    writetable(eeg_urevent, newNameEvents); 
    % the only difference should be in latency (sampling points)
    % latency_s (seconds) = (latency-1)/srate

    %continue   % if only exporting events, not preprocessing

    % load chanlocs 
    raw.chanlocs   = chanlocs;  % current
    raw.urchanlocs = chanlocs;  % original 

    %nchan = size(raw.data,1);  % verify number of channels
    raw = eeg_checkset(raw,'chanlocsize');  % validate chanlocs 

    % basic filter 
    % high pass = 0.1, then low pass = 30; or band pass 0.1 30
    filt0 = pop_eegfiltnew(raw, 0.1, 30);   % this takes longer than pop_basicfilter()

    %//filt0 = pop_basicfilter(raw, 1:72, 'Boundary', 'boundary', 'Cutoff', [0.1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
    % pop_basicfilter() is from ERPLAB

    % save to new folder
    newName = fullfile('./01_rawset', [sub '.set']); 
    pop_saveset(filt0, 'filename', newName, 'savemode','onefile')  
    % if not specifying save as one file, default saves both .set (header) and .fdt (data)
    
    disp(datetime);  % timestamp 

end 


%%
% 