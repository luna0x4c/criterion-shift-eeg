% IF NEEDED:
addpath '/Users/lunarneko/Documents/MATLAB/plugins/eeglab2026.0.0'

eeglab; 

% cd('CODE FOLDER PATH')

% ===== load raw bdf file, reref, downsample, basic filter =====
s01_load 
% from: ./raw_good_subs
% to:   ./01_rawset
% this include exporting complete urevent info as csv

% ===== fix event codes / add trial info =====
% FIRST use clean_data.Rmd in beh_data folder to export clean test trials;

% update subinfo (task cond etc)
s02_get_subinfo_for_eeg.Rmd  

% fix urevent
s02_add_trial_info.Rmd  
% export clean urevent csv to: ./01_urevent_fixed;
% merge urevent with trial info (resp_type etc);
% export merged csv to: ./01_urevent_complete 

% ===== add complete events back in to EEG files =====
s03_import_trial_info 
% match rawset and urevent_complete 
% export to: ./02_rawset_with_trial_info

% ===== remove nontask periods =====
s04_trim_nontask 
% makes it easier for manual cleaning
% export to: ./03_trimset as copy
% export to: ./04_cleanset for more manual cleaning


% ===== manual cleaning =====
% individually check .set files in 04_cleanset to see if there are any other noisy segments that need to be removed
% save to the same file, no need to SaveAs
% more noisy than normal: sub19
% [not keeping track of invalid event types across all subjs]
% sub23: FC4 FC5 C5 FT7; removed large chunk of unusable trials during event codes 60-90 (task 2 test)
% sub24 missing study phases??
% sub25 has a few lines periodically glitching
% sub27 has invalid event types: -2015 -2016
% sub28 has invalid event types: -2020 -2021
% sub29 has invalid event types: -2014; removed two chunks of unusable trials during test 1
% sub31: one chunk removed in t1
% sub32: removed a few trials in test1
% sub34: several lines have periodic glitches
% sub35: EYE
% sub38: removed several large chunks unusable throughout
% sub42: large frontline glitches periodically
% sub43: EYE
% sub44: EYE + removed 1 chunk + several sites noisy/glitchy
% sub45: removed 1 trial in t3
% sub46: removed EXG8
% sub47: removed 1 large chunk in study1
% sub48: removed F3
% sub49: RESP TOO FAST
% sub50: EYE
% sub51: noisy frontal sites 
% sub52: RESP TOO FAST + EYE + noisy frontal sites + noisy trials not removed
% sub54: noisy trials not removed
% sub55: MASSIVE EYE+FRONTAL+EXG not removed due to not being global (other electrodes not affected)
% sub58: 1 chunk removed in t3; t3 RESP TOO FAST
% sub60: RESP TOO FAST
% sub61: front line noisy
% sub62: FRONT/EYE + RESP TOO FAST SOMETIMES 
% sub63: FRONT/EYE
% sub64: REMOVED 1:320S (partly thru t1) + still has front/eye noise
% sub65: front/eye
% sub66[!!!]: removed EXG8, removed study1 t1 study2 unusable chunks; BAD FRONTAL NOISE ON B SIDE
% sub71: eye
% sub72: removed 1 chunk in t1
% sub73: eye
% sub74: removed 2 chunks of large drifts
% sub75: LARGE messy chunks (not all electrodes) not removed
% sub76 77: eye


% ===== RUN ICA =====
s05_runica 
% export to: ./05_ica_weights [.set files] & ./05_ica_maps [IC images]
% export to: ./06_flag_ica for manual cleaning (SaveAs)
% sub25 lots of channel noise ICs

% ==========
% BEHAVIORAL DATA FIXES SHOULD HAPPEN HERE, BEFORE EPOCHING
% ==========


% ===== REJECT FLAGGED ICA & EPOCH ===== 
s06_epoch 
% cleaned ICA export to: ./07_ica_clean 
% epochs study_stim, test_stim, resp, feed export to ./08_epoch SUBFOLDERS

% ===== CREATE STUDY ===== 
s07_study 
% export 4 .study files to ./09_study 

% ===== SPECIFY DESIGN + PRECOMP =====
s08_design 
% export 3 .study files (without study_stim) to ./09_study/with_design 
% also export each subject's .daterp files back into ./08_epoch 
% .dattimef for time freq data
% precomp ERP + ERSP, interpolate missing electrodes

% ===== ERP ===== 
% get average amps at each sub x electrode x timepoint for each cond combo of interest 
s09_export_erp_teststim
s09_export_erp_resp
s09_export_erp_feed
% export to ./10_erp_mean
% then load csv in R, compute avg & SE and plot 
s10_plot_erp.Rmd 
% uses `plot_erp.R` and `plot_diff.R`
% export to ./10_erp_plot_ggsave 

% ===== TOPO =====
s11_topo_stim_hitcr
s11_topo_stim_fn400_oldnew
s11_topo_resp_incorrectcorrect
s11_topo_feed_incorrectcorrect
s11_topo_feed_fpfcorrect
