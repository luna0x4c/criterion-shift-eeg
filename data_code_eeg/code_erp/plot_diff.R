


# ===== GET DIFFWAVE (SUBJ OR GRAND AVERAGE) ===== 
# uses full epoch subj x cell raw amps df from `prep_erp_cells` 

prep_erp_diffwave = function(df, contrast_var, contrast_levels, avg=FALSE,
                             save_subj=FALSE, folder=NULL, filename=NULL) { 
  
  df_type = unique(df$df_type) 
  epoch_min = min(df$time_ms)
  epoch_max = max(df$time_ms) 
  e1 = plyr::round_any(epoch_min,10)
  e2 = plyr::round_any(epoch_max,10)
  
  # STEPS:
  # contrast levels, e.g. `c("Correct","Incorrect")` - should match actual values in df
  # filter df down to the only two levels 
  # `pivot_wider` for both `contrast_var` and `cell_ntrials` 
  # filter out sparse cells - row will be removed if ONE of the two cells are missing
  # [X] diff = var1 - var2     [subj-level diffscore]
  # [X] wt = 1 / (1/n1 + 1/n2) ["inverse of sampling variance"]
  # `group_by` taskcond, then compute weighted mean/SE  
  
  # get dynamic id vars to avoid cols clashing during pivot 
  id_vars = intersect(c("sub", "cue_flip", "cue", "task0", "task", "cond", "taskcond", "time_ms",
                        "df_type", "erp_win", "erp_chans"), names(df))
  
  subj = df %>% 
    # create extra vars to keep colnames consistent
    mutate(var = contrast_var,
           level = .data[[contrast_var]],
           contrast_order = ifelse(.data[[contrast_var]] == contrast_levels[1], 1, 2)) %>% 
    # remove original `contrast_var` column so it doesn't get in the way of pivot
    select(-all_of(contrast_var)) %>% 
    filter(level %in% contrast_levels) %>%   
    pivot_wider(id_cols     =all_of(c(id_vars, "var")),
                names_from  =contrast_order, 
                values_from =c(level,mean_amp,cell_ntrials)) %>% 
    # filter out sparse cells
    filter(cell_ntrials_1>=min_n & cell_ntrials_2>=min_n) %>% 
    mutate(wt = 1 / (1/cell_ntrials_1 + 1/cell_ntrials_2),  # weighting by variance - informational only, not used in later analysis 
           diff = mean_amp_1 - mean_amp_2) 
  # export this
  
  cell_vars = c("task","cond","taskcond","time_ms",
                "df_type","erp_win","erp_chans","var","level_1","level_2")   # preserve addl information for export
  
  cell = subj %>% 
    group_by(across(all_of(cell_vars))) %>%   # preserve addl information for output df
    summarise(#mean_diff = weighted.mean(diff,wt),
              #se = sqrt(sandwich::vcovHC(lm(diff ~ 1, weights = wt), type = "HC1")[1, 1]),
              mean_diff = mean(diff, na.rm=TRUE),
              sd = sd(diff, na.rm=TRUE),
              nsub = n_distinct(sub),
              se = sd/sqrt(nsub),
              .groups="drop")
  # use this for plotting
  
  if (isTRUE(save_subj)) {
    # ONLY save subj level
    
    if (is.null(folder)) {folder = "/Users/lunarneko/Desktop/11_erp_amps/"}
    
    if (is.null(filename)) {
      #erp_win = unique(df$erp_win)
      #erp_win_filename = str_replace(erp_win," ","_")
      erp_chans = unique(df$erp_chans)
      erp_chans_filename = str_remove_all(erp_chans," ")
      
      filename = paste0(folder,
                        "diffwave_",df_type,"_",erp_chans_filename,"_",e1,"_",e2,"_",
                        contrast_var,"_",paste0(contrast_levels,collapse=""),".csv")
    }
    write.csv(subj, filename, row.names=FALSE)
  }
  
  
  if (isTRUE(avg)) {    # DO NOT USE IFELSE OR SWITCH
    summ = cell
  } else {
    summ = subj
  }
  
  return(summ)
  
}


# ===== GET DIFFAMP (SUBJ OR GRAND AVERAGE) ===== 

# [!!!] if collapsing across cells, create new var BEFORE using this function   
prep_erp_diffamp = function(df, contrast_var, contrast_levels, avg=FALSE,
                            save_subj=FALSE, folder=NULL, filename=NULL) {
  
  # uses mean ERP window amps df from `prep_erp_cells`:
  # factors already formatted, subj-level erp window avg calculated 
  
  # subj-level output should have same number of rows as input 
  
  # STEPS:
  # contrast levels, e.g. `c("Correct","Incorrect")` - should match actual values in df
  # filter df down to the only two levels 
  # `pivot_wider` for both `contrast_var` and `cell_ntrials` 
  # filter out sparse cells - row will be removed if ONE of the two cells are missing
  # diff = var1 - var2     [subj-level diffscore]
  # wt = 1 / (1/n1 + 1/n2) ["inverse of sampling variance"]
  # `group_by` taskcond, then compute weighted mean/SE  
  
  df_type = unique(df$df_type)
  
  # get dynamic id vars to avoid cols clashing during pivot 
  id_vars = intersect(c("sub", "cue_flip", "cue", "task0", "task", "cond", "taskcond",
                        "df_type", "erp_win", "erp_chans"), names(df))
  
  diff_subj = df %>% 
    # create extra vars to keep colnames consistent
    mutate(var = contrast_var,
           level = .data[[contrast_var]],
           contrast_order = ifelse(.data[[contrast_var]] == contrast_levels[1], 1, 2)) %>% 
    # remove original `contrast_var` column so it doesn't get in the way of pivot
    select(-all_of(contrast_var)) %>% 
    filter(level %in% contrast_levels) %>%   
    pivot_wider(id_cols     = all_of(c(id_vars, "var")),
                names_from  = contrast_order, 
                values_from = c(level,mean_amp,cell_ntrials)) %>% 
    # filter out sparse cells
    filter(cell_ntrials_1>=min_n & cell_ntrials_2>=min_n) %>% 
    mutate(wt = 1 / (1/cell_ntrials_1 + 1/cell_ntrials_2),   # wt not used in later analysis
           diff = mean_amp_1 - mean_amp_2) 
  # save this
  
  cell_vars = c("task","cond","taskcond",
                "df_type","erp_win","erp_chans","var","level_1","level_2")   # preserve addl information for output df
  
  diff_mean = diff_subj %>% 
    group_by(across(all_of(cell_vars))) %>%    
    summarise(#mean_diff = weighted.mean(diff,wt),
              #se = sqrt(sandwich::vcovHC(lm(diff ~ 1, weights = wt), type = "HC1")[1, 1]),
              mean_diff = mean(diff, na.rm=TRUE),
              sd = sd(diff, na.rm=TRUE),
              nsub = n_distinct(sub),
              se = sd/sqrt(nsub),
              .groups="drop")
  # use this for plotting
  
  if (isTRUE(save_subj)) { 
    # ONLY save subj level
    
    if (is.null(folder)) {folder = "/Users/lunarneko/Desktop/11_erp_amps/"}
    
    if (is.null(filename)) {
      erp_win = unique(df$erp_win)
      erp_win_filename = str_replace(erp_win," ","_")
      erp_chans = unique(df$erp_chans)
      erp_chans_filename = str_replace(erp_chans," ","")
      
      filename = paste0(folder,
                        "diffamp_",df_type,"_",erp_chans_filename,"_",erp_win_filename,"_",
                        contrast_var,"_",paste0(contrast_levels,collapse=""),".csv")
    }
    write.csv(diff_subj, filename, row.names=FALSE)
  }
  
  if (isTRUE(avg)) {    # DO NOT USE IFELSE OR SWITCH
    df_out = diff_mean
  } else {
    df_out = diff_subj
  }
  
  return(df_out)
  
}


# ===== PLOT GRAND AVERAGE DIFFWAVE BY TWO CONTRASTS ===== 

plot_erp_diffwave = function(df, erp_win, contrast_title,
                             width=NULL, height=NULL, 
                             save=FALSE, folder=NULL, filename=NULL) {
  # use `avg=TRUE` version from `prep_erp_diffwave()`
  # `contrast_title` for main figure title
  
  df_type = unique(df$df_type)
  
  contrast_var = unique(df$var)  
  contrast_level1 = unique(df$level_1)   
  contrast_level2 = unique(df$level_2)
  contrast_levels_filename = str_remove_all(paste(contrast_level1,contrast_level2,sep="")," ")
  
  epoch_win = str_split_1(unique(df$erp_win)," ") 
  e1 = epoch_win[1]
  e2 = epoch_win[2]
  epoch_win_filename = paste(e1,e2,sep="_")
  
  t1 = erp_win[1]    # for highlighting erp window 
  t2 = erp_win[2] 
  erp_win_fig = paste0(t1,"-",t2," ms")
  erp_win_filename = paste(t1,t2,sep="_")
  
  chanlist_fig = unique(df$erp_chans)   # for fig title only
  chanlist = str_split_1(chanlist_fig," ")
  chanlist_filename = paste(chanlist,collapse="")  # for filename only 
  
  fig_title_main = case_when(df_type=="stim" ~ "Stimulus-locked",
                             df_type=="resp" ~ "Response-locked",
                             df_type=="feed" ~ "Feedback-locked") 
  fig_title = paste(fig_title_main,contrast_title, sep=" ")
  fig_subtitle = paste(chanlist_fig, sep=" ")  # does not include erpwin
  
  # set panel layout 
  # 1 row per task, con|lib side by side (baseline top left)
  panels = df %>% 
    distinct(task,cond) %>% 
    arrange(task,cond) %>% 
    mutate(letter = LETTERS[row_number()]) %>%   # A,B,C etc in panel order
    group_by(task) %>% 
    summarise(row = paste(letter, collapse=""), 
              n = n(), 
              .groups="drop")
  
  ncols_layout = max(panels$n)
  nrows_layout = nrow(panels)
  panels = panels %>% mutate(row = paste0(row, strrep("#", ncols_layout-n)))   # pad single-panel rows
  panel_design = paste(panels$row, collapse="\n")
  
  p_diffwave = ggplot(df, aes(x=time_ms, y=mean_diff)) +
    #ggh4x::facet_nested(cols=vars(task,cond)) +
    ggh4x::facet_manual(vars(task,cond), 
                        design = panel_design, 
                        strip = ggh4x::strip_nested()) +
    # use `annotate()` instead of `geom_rect()`
    annotate("rect", xmin=t1, xmax=t2, ymin=-Inf, ymax=Inf, fill="lightgray", alpha=0.5) +
    geom_vline(xintercept=0,color="lightgray",linetype="dashed") +  # epoch event 
    geom_hline(yintercept=0,color="lightgray",linetype="dashed") +  # diff=0 
    geom_ribbon(aes(ymin = mean_diff - se,
                    ymax = mean_diff + se), alpha = 0.3, colour=NA) +
    geom_line(aes(y = mean_diff), linewidth = 0.4) + 
    
    #scale_x_continuous(breaks = scales::breaks_width(500), expand = c(0,0)) +
    scale_y_continuous(expand = expansion(mult = 0.02)) +
    
    labs(x="Time (ms)", y="Amplitude (µV)", title=fig_title, subtitle=fig_subtitle,
         #color="Response", fill="Response", linetype="Response"
    ) +
    #theme_bw() 
    theme_bw(base_size = 10) +
    theme(panel.spacing = unit(4,"pt"),
          strip.text    = element_text(margin = margin(2,2,2,2)))
  
  if (isTRUE(save)) {
    if (is.null(folder)) {folder = "/Users/lunarneko/Desktop/11_erp_plot_ggsave/"}
    
    if (is.null(filename)) {
      filename = paste0(folder,"diffwave_",df_type,"_",chanlist_filename,"_",
                        epoch_win_filename,"_",erp_win_filename,"_",
                        contrast_var,"_",contrast_levels_filename,".pdf")
    }
    
    # if (is.null(width))  {
    #   nconds = nrow(distinct(df,task,cond))   # number of panels
    #   panel_width = 3
    #   width = panel_width * nconds
    # }
    # if (is.null(height)) {height=4}
    
    if (is.null(width))  {
      width  = ncols_layout * 3.25}
    if (is.null(height)) {
      height = nrows_layout*1.8 + 0.6}

    ggsave(filename, plot=p_diffwave, width=width, height=height)
  }
  
  
  return(p_diffwave)
  
}

# ===== PLOT GRAND AVERAGE DIFFAMP BY TASKCOND ===== 
plot_erp_diffamp = function(df, erp_win=NULL, contrast_title, 
                            plot_subj=FALSE, subj_df=NULL, 
                            width=NULL, height=NULL, 
                            save=FALSE, folder=NULL, filename=NULL) {
  
  df_type = unique(df$df_type)
  
  contrast_var = unique(df$var)  # redundancy
  contrast_level1 = unique(df$level_1)   
  contrast_level2 = unique(df$level_2)
  contrast_levels_filename = str_remove_all(paste(contrast_level1,contrast_level2,sep="")," ")
  
  erp_win = str_split_1(unique(df$erp_win)," ")  
  t1 = erp_win[1]
  t2 = erp_win[2] 
  erp_win_filename = paste(t1,t2,sep="_")
  erp_win_fig = paste0(t1,"-",t2," ms")
  
  chanlist_fig = unique(df$erp_chans)   # for fig title only
  chanlist = str_split_1(chanlist_fig," ")
  chanlist_filename = paste(chanlist,collapse="")  # for filename only 
  
  fig_title_main = case_when(df_type=="stim" ~ "Stimulus-locked",
                             df_type=="resp" ~ "Response-locked",
                             df_type=="feed" ~ "Feedback-locked")
  fig_title = paste(fig_title_main,contrast_title, sep=" ")
  fig_subtitle = paste(chanlist_fig, erp_win_fig, sep=" ") 
  
  # taskcond grand average
  p_diffamp = ggplot(df, aes(cond, mean_diff)) +
    facet_wrap(~task, scales="free_x", space="free_x",  # [!!!]
               labeller=label_wrap_gen(width=15)) +  
    geom_hline(yintercept=0,color="lightgray",linetype="dashed") +  # diff=0 
    geom_errorbar(aes(ymin = mean_diff - se,
                      ymax = mean_diff + se),width = 0.1, linewidth = 0.4) +
    geom_point(size=2) +
    theme_bw(base_size=10) +
    theme(strip.text = element_text(margin=margin(2,1,2,1))) +
    #theme(strip.background = element_rect(fill = NA))  # make strip box blank
    labs(x = "Condition", y = "Mean difference (\u00b5V)",
         title = fig_title, subtitle = fig_subtitle)  
  
    if (isTRUE(plot_subj)) {
      # with individual datapoints - will be MUCH MORE zoomed out 
      p_diffamp_subj = ggplot(df, aes(cond, mean_diff)) +
        facet_wrap(~task, scales="free_x", space="free_x",  # [!!!]
                   labeller=label_wrap_gen(width=15)) +  
        geom_hline(yintercept=0,color="lightgray",linetype="dashed") +  # diff=0 
        geom_point(data = subj_df, aes(y = diff),
                   size=0.7,shape=19,color="gray",fill="gray",
                   position = position_jitter(width=0.08, height=0, seed=5183)) +
        geom_errorbar(aes(ymin = mean_diff - se,
                          ymax = mean_diff + se),width = 0.1, linewidth = 0.4) +
        geom_point(size=1) +   # adjust size
        theme_bw(base_size=10) +
        theme(strip.text = element_text(margin=margin(2,1,2,1))) +
        #theme(strip.background = element_rect(fill = NA))  # make strip box blank
        labs(x = "Condition", y = "Mean difference (\u00b5V)",
             title = fig_title, subtitle = fig_subtitle) 
      p_diffamp_out = p_diffamp_subj
    } else {
      p_diffamp_out = p_diffamp
    }


  if (isTRUE(save)) {
    if (is.null(folder)) {folder = "/Users/lunarneko/Desktop/11_erp_plot_ggsave/"}
    
    if (is.null(filename)) {
      filename = paste0(folder,"diffamp_",df_type,"_",chanlist_filename,"_",erp_win_filename,"_",
                        contrast_var,"_",contrast_levels_filename,".pdf")
      if (isTRUE(plot_subj)) {
        filename = str_replace(filename,"diffamp_","diffampsubj_")
      }
      
    }
    
    if (is.null(width))  {width=4}
    if (is.null(height)) {height=4}
    
    ggsave(filename, plot=p_diffamp_out, width=width, height=height)
    
  }
  
  
  return(p_diffamp_out)
  
  
}

# ===== [TO DO: LMER FOR DIFFAMPS]
# PRETTY MUCH THE SAME AS THE RAW AMPS VERSION?? 
# either copy over and rewrite or modify to take either amps or diffamps (should only differ in DV name in the model & exported csv filename)





