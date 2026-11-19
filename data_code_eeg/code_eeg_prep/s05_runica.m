
cd /Volumes/toshiba/eeg_data_backup

% using .set files after manual rejection
fileList = dir(fullfile('04_cleanset','sub*.set'));
fileNames = {fileList.name}; 

%%

n_sub = length(fileList);

start_with_file = 'sub78.set';  % start from here
start_with_file_pos = find(strcmp(fileNames, start_with_file));

% help eegplugin_viewprops


for i = start_with_file_pos:n_sub
%for i = start_with_file_pos:1

    % get file name
    fullPath = fullfile(fileList(i).folder, fileList(i).name);
    file = fileList(i).name;
    sub = erase(file,".set");
    disp(sub);

    % load .set file
    clean = pop_loadset(fullPath);

    % remove externals: EXG1-EXG8 [by label not index]
    all_chan = {clean.chanlocs.labels};
    is_exg = strncmpi(all_chan,'EXG',3);
    exg_locs = find(is_exg);
    clean = pop_select(clean,'nochannel',exg_locs);
    
    %exg_locs = eeg_chaninds(clean.chanlocs, {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8'});
    %clean = pop_select(clean,'nochannel',exg_locs);
    
    % run ica
    ica = pop_runica(clean, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
    ica = pop_iclabel(ica, 'default');
    %                      brain muscle  eye    heart  line   channel other
    ica = pop_icflag(ica, [0 0 ; 0.6 1 ; 0.6 1; 0.8 1; 0.6 1; 0.6 1 ; 0 0  ]); 
   
    % save ica set
    newName = fullfile('./05_ica_weights', [sub '.set']);   % save as copy
    pop_saveset(ica, 'filename', newName, 'savemode','onefile');
    newName2 = fullfile('./06_flag_ica', [sub '.set']);     % manually inspect ica & flag for rejection
    pop_saveset(ica, 'filename', newName2, 'savemode','onefile');
    
    % IC topo with labels/classifications
    % save ic maps as png - split into 2 batches 
    %%%%%comp_inds = 1:size(ica.icaweights,1);  % all ICs

    subdir = fullfile('./05_ica_maps', sub);
    if ~exist(subdir,'dir')
        mkdir(subdir);
    end

    pop_viewprops(ica, 0, 1:35, {}, {}, 0, 'ICLabel');  % 0 = components, 1 = channels
    figName = fullfile(subdir, [sub '_IC_summary_1.png']);
    exportapp(gcf, figName);
    close(gcf);

    pop_viewprops(ica, 0, 36:size(ica.icaweights,1), {}, {}, 0, 'ICLabel');  % 0 = components, 1 = channels
    figName = fullfile(subdir, [sub '_IC_summary_2.png']);
    exportapp(gcf, figName);
    close(gcf);

    % save individual ICs
    nIC = size(ica.icaweights, 1);
    for ic = 1:nIC
        pop_prop_extended(ica, 0, ic, NaN, {}, {}, 0, 'ICLabel');  % single IC
        figName = fullfile(subdir, [sub '_IC_' num2str(ic) '.png']);
        exportapp(gcf, figName);
        close(gcf);
    end

    clear gcf; 
        

    disp(datetime);


end 


% MANUALLY INSPECT IC
% eeglab recommends removing IC in STUDY, only mark rejections for now 
