
# ===== LEGENDS =====

# hit --> FA --> (FA FPF) --> CR --> miss (--> miss FPF) [in this order]
# figure legend should be split into 2 rows

# resptype color legend
resptype_colors_4 <- c("#1b9e77","#d95f02","#7570b3","#e7298a")
# modified from Dark2 to add lighter shade variation for FPF
#resptype_colors_6 <- c("#1b9e77","#d95f02","#fdcdac",
#                       "#7570b3","#e7298a","#f4cae4")
# solid version for FPF - compensate with linetype & point shape 
resptype_colors_6 <- c("#1b9e77","#d95f02","#d95f02",
                       "#7570b3","#e7298a","#e7298a") 

# linetype for erpwave 
resptype_lines_4 = c("solid","solid","solid","solid")
resptype_lines_6 = c("solid","solid","dashed",
                     "solid","solid","dashed")

# point shape for avg amp
resptype_points_4 = c(19,19,19,19)
resptype_points_6 = c(19,19,21,19,19,21)  # 1=hollow circle, 21=fillable circle

# point fill for avg amp
shape_fill_4 = resptype_colors_4
shape_fill_6 = c("#1b9e77","#d95f02","white",
                 "#7570b3","#e7298a","white")




# ===== PREP: GET AMPS FOR CHAN & ROI OF INTEREST ===== 
# uses raw df loaded from csv 
prep_erp_cells = function(df, df_type, chanlist, erp_win=NULL, avg=c(TRUE,FALSE), save=FALSE) {
  
  # GET SUBJ X TASKCOND X RESPTYPE MEANS, weighted by ntrials of each cell
  # - full epoch erpwave: `erp_win=NULL` & `avg=FALSE`
  # - mean amp within erp window: `erp_win = c(t1,t2)` & `avg=TRUE`
  # - erpwave within erp window: `erp_win = c(t1,t2` & `avg=FALSE`  [probably will not need this]
  
  if (isTRUE(avg) & is.null(erp_win)) {
    stop("Computing window average but missing `erp_win`")
  } 
  
  epoch_min = min(df$time_ms)
  epoch_max = max(df$time_ms) 
  
  if (is.null(erp_win)) {
    # if no window specified, get full epoch
    t1 = plyr::round_any(epoch_min,10)
    t2 = plyr::round_any(epoch_max,10)
    erp_win = c(t1,t2)
  } else {
    # erp window only
    t1 = erp_win[1]
    t2 = erp_win[2]
    # check for invalid window
    if (t1 < epoch_min | t2 > epoch_max) {
      stop("`erp_win` out of range")
    }
  }
  
  # check for invalid channel
  epoch_chans = unique(df$chan)
  if (!all(chanlist %in% epoch_chans)) {
    stop("One or more channels out of range")
  }
  
  # dplyr grouping vars
  if (df_type == "feed") {
    vars = c("sub","cue_flip","task","cond","resptype","trial_is_fpf")
  } else {
    vars = c("sub","cue_flip","task","cond","resptype")
  }
  
  if (isFALSE(avg)) {
    vars = c(vars,"time_ms")  # get individual timepoints
  } 
  
  # for fig annotation
  chanlist_print = paste(chanlist, collapse =" ")
  win_print = paste0(paste(erp_win, collapse = "-")," ms)")
  
  # for filename
  chanlist_filename = paste(chanlist, collapse ="")
  win_filename = paste(erp_win, collapse = "_")
  
  summ = df %>% 
    filter(!is.na(resptype),
           chan %in% chanlist,
           time_ms>=t1, time_ms<=t2) %>% 
    group_by(across(all_of(vars))) %>% 
    summarise(cell_ntrials = sum(ntrials[chan==first(chan) & time_ms==first(time_ms)]),  # sum once per chan/timepoint
              mean_amp = weighted.mean(amp, ntrials, na.rm=TRUE),  # trial-weighted within subj
              .groups = "drop") %>% 
    filter(!is.na(mean_amp))   
  
  # formatting
  summ_clean = summ %>% 
    mutate(df_type = df_type,
           erp_win = paste(erp_win, collapse=" "),
           erp_chans = paste(chanlist, collapse=" ")) %>% 
    mutate(task0 = factor(task, levels=c("true_feed","false_feed","strategic"),
                          labels=c("Baseline","FPF","Strategic")), # 3 levels 
           cue  = factor(cue_flip, levels=c(0,1), labels=c("True","Reversed")),
           task = case_when(task=="true_feed"  ~ "Baseline",
                             task=="false_feed" ~ "FPF",
                             task=="strategic" & cue_flip==0 ~ "Strategic (true cue)",
                             task=="strategic" & cue_flip==1 ~ "Strategic (reversed cue)"),
           task = factor(task, levels=c("Baseline","FPF",
                                         "Strategic (true cue)","Strategic (reversed cue)")),  # 4 levels
           cond = factor(cond, levels=c("con","lib","NONE"),
                         labels=c("Con","Lib","Neutral")),
           resptype = factor(resptype,levels=c("hit","fa","cr","miss"),
                             labels=c("Hit","FA","CR","Miss"))) %>% 
    mutate(taskcond = paste(task0,cond),     # 5 levels, NOT split by cue [models]
           taskcond = factor(taskcond, 
                             levels=c("Baseline Neutral",
                                      "FPF Con", "FPF Lib", 
                                      "Strategic Con", "Strategic Lib"))) %>% 
    select(df_type,sub,cue_flip,cue,task0,task,cond,taskcond,resptype,everything())
  
  # additional FPF labeling for feed
  if (df_type=="feed") {
    summ_clean = summ_clean %>% 
      mutate(trial_is_fpf = replace_na(trial_is_fpf,0)) %>% 
      mutate(resptype_6 = case_when(resptype=="FA" & trial_is_fpf==1 ~ "FA (FPF)",
                                    resptype=="FA" & trial_is_fpf==0 ~ "FA (real)",
                                    resptype=="Miss" & trial_is_fpf==1 ~ "Miss (FPF)",
                                    resptype=="Miss" & trial_is_fpf==0 ~ "Miss (real)",
                                    .default = resptype)) %>% 
      mutate(resptype_6 = factor(resptype_6, 
                                 levels=c("Hit", "FA (real)",   "FA (FPF)",
                                          "CR",  "Miss (real)", "Miss (FPF)"))) %>% 
      select(df_type,sub,cue_flip,cue,task0,task,cond,taskcond,
             resptype,trial_is_fpf,resptype_6,everything())
    }
  
  # save csv
  if (isTRUE(save)) {
    folder = "/Users/lunarneko/Desktop/11_erp_amps/"
    if (isTRUE(avg)) {
      filename = paste0(folder,"erpamp_", df_type,"_",chanlist_filename,"_",win_filename,".csv")
    } else {
      filename = paste0(folder,"erpwave_",df_type,"_",chanlist_filename,"_",win_filename,".csv")
    }
    write.csv(summ_clean, filename, row.names = FALSE)
  }
  
  return(summ_clean)
  
}




# ===== GET GRAND AVERAGE FOR PLOTTING ERPWAVE ===== 
# uses full epoch subj x timepoint df from `prep_erp_cells()`
prep_erp_wave = function(df) {
  
  df_type = unique(df$df_type)
  
  # grouping vars
  vars = c("taskcond", "resptype", "time_ms",  # necessary for getting avg at each timepoint
           "task", "cond", "erp_win", "erp_chans", "df_type")   # information cols ONLY, preserve for plotting)
  
  if (df_type=="feed") {
    vars = c(vars,"trial_is_fpf","resptype_6")
  }
  
  # UNWEIGHTED VERSION 
  summ = df %>% group_by(across(all_of(vars))) %>%   
    summarise(nsub = n_distinct(sub),
              mean = mean(mean_amp, na.rm=TRUE),
              sd   = sd(mean_amp, na.rm = TRUE),
              se   = sd / sqrt(nsub),
              .groups = "drop")
  
  # WEIGHTED VERSION - DO NOT USE
  # summ = df %>% group_by(across(all_of(vars))) %>%   
  #   summarise(nsub = n(),
  #             mean = weighted.mean(mean_amp, cell_ntrials),
  #             # do not use unweighted SE since it uses unweighted mean 
  #             se = sqrt(sandwich::vcovHC(lm(mean_amp ~ 1, weights = cell_ntrials), type = "HC1")[1, 1]),
  #             #se = sqrt(sum(cell_ntrials^2 * (mean_amp-mean)^2)) / sum(cell_ntrials) * sqrt(nsub / (nsub - 1)),   # same as vcov
  #             .groups="drop")
  # # cite sandwich package: Zeileis et al 2019
  # # cite SE calculation method: https://www.jstatsoft.org/article/view/v011i10/0 
  
  return(summ)
}

# ===== PLOT FULL WINDOW GRAND AVERAGE ERPWAVE =====
# uses grand average x timepoint df from `prep_erp_wave()`
plot_erp_wave = function(df, erp_win, width=NULL, height=NULL, 
                         export_option=c("full","none","no legend","legend only"),
                         save=FALSE, folder=NULL, filename=NULL) {
  
  if (isFALSE(save)) {
    export_option = "none"
  }
  
  df_type = unique(df$df_type)
  
  epoch_win = str_split_1(unique(df$erp_win)," ")  # erp_win COLUMN should contain FULL epoch, not `erp_win=c(t1,t2)` entered separately
  e1 = epoch_win[1]
  e2 = epoch_win[2]
  epoch_win_filename = paste(e1,e2,sep="_")
  
  chanlist_fig = unique(df$erp_chans)   # for fig title only
  chanlist = str_split_1(chanlist_fig," ")
  chanlist_filename = paste(chanlist,collapse="")  # for filename only
  
  t1 = erp_win[1]
  t2 = erp_win[2]  # highlight erp window
  erp_win_filename = paste(t1,t2,sep="_")
  
  fig_title = case_when(df_type=="stim" ~ "Stimulus-locked",
                        df_type=="resp" ~ "Response-locked",
                        df_type=="feed" ~ "Feedback-locked")
  fig_subtitle = chanlist_fig 
  
  # # resptype color legend
  # resptype_colors_4 <- c("#1b9e77","#d95f02","#7570b3","#e7298a")
  # 
  # # modified from Dark2 to add lighter shade variation for FPF
  # resptype_colors_6 <- c("#1b9e77","#d95f02","#fdcdac",
  #                        "#7570b3","#e7298a","#f4cae4")
  
  if (df_type=="feed") {
    # do not use ifelse, unknown bug causes these_colors to save only the first value
    these_colors = resptype_colors_6
    these_lines  = resptype_lines_6
    df$resptype_plot = df$resptype_6  # add a new col to keep plotting var consistent
  } else {
    these_colors = resptype_colors_4
    these_lines  = resptype_lines_4
    df$resptype_plot = df$resptype
  } 
  
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
  panels = panels %>% mutate(row = paste0(row, strrep("#", ncols_layout - n)))   # pad single-panel rows
  panel_design = paste(panels$row, collapse="\n")
  
  p_wave = ggplot(df, aes(x=time_ms, y=mean,
                          colour = resptype_plot,
                          fill   = resptype_plot,
                          linetype = resptype_plot)) +
    #facet_grid(cols=vars(task,cond)) +
    #ggh4x::facet_nested(cols=vars(task,cond)) +
    ggh4x::facet_manual(vars(task, cond), 
                        design = panel_design, 
                        strip = ggh4x::strip_nested()) +
    # use `annotate()` instead of `geom_rect()`
    annotate("rect", xmin=t1, xmax=t2, ymin=-Inf, ymax=Inf, fill="lightgray", alpha=0.5) +
    geom_vline(xintercept=0,color="lightgray",linetype="dashed") +  # epoch event 
    geom_ribbon(aes(ymin = mean - se,
                    ymax = mean + se), alpha = 0.3, colour=NA) +
    # geom_line(aes(y = mean)) + 
    geom_line(aes(y=mean), linewidth = 0.4) +
    
    scale_color_manual(values = these_colors) +
    scale_fill_manual(values  = these_colors) +
    scale_linetype_manual(values = these_lines) +
    
    #scale_x_continuous(breaks = scales::breaks_width(500), expand = c(0,0)) +
    scale_y_continuous(expand = expansion(mult = 0.02)) +
    
    labs(x="Time (ms)", y="Amplitude (µV)", title=fig_title, subtitle=fig_subtitle,
         color="Response", fill="Response", linetype="Response") +
    # theme_bw() +
    # theme(legend.position = "bottom") +
    theme_bw(base_size = 10) +
    theme(legend.position = "bottom",
          panel.spacing   = unit(4,"pt"),
          strip.text      = element_text(margin = margin(2,2,2,2))) +
    guides(color = guide_legend(nrow = 2, byrow = TRUE),
           fill  = guide_legend(nrow = 2, byrow = TRUE),
           linetype = guide_legend(nrow = 2, byrow = TRUE))
  
  if (isTRUE(save)) {
    if (is.null(folder)) {folder = "/Users/lunarneko/Desktop/11_erp_plot_ggsave/"}
    
    if (is.null(filename)) {
      filename_fig = paste0(folder,"erpwave_",df_type,"_",chanlist_filename,"_",
                            epoch_win_filename,"_",erp_win_filename,".pdf")
      filename_legend = paste0(folder,"legend_erpwave_",df_type,"_resptype.pdf")
      filename = ifelse(export_option=="legend only", filename_legend, filename_fig)
    }
    
    # create legend object and get actual legend height for exporting
    # keep width consistent with figure
    if (export_option=="legend only") {
      legend = ggpubr::get_legend(p_wave,position="bottom")
      legend_height = grid::convertHeight(sum(legend$heights), "in", valueOnly = TRUE)
    }
    
    # nconds = nrow(distinct(df, task, cond))   # number of panels 
    # 
    # if (is.null(width))  {panel_width = 3; width = panel_width * nconds}
    # if (is.null(height)) {height=ifelse(export_option=="legend only", legend_height, 5)}
    
    panel_width = 3.25; panel_height = 1.8   # hard coded panel size

    if (is.null(width))  {
      width = panel_width * ncols_layout}
    if (is.null(height)) {
      height = ifelse(export_option=="legend only", 
                      legend_height, panel_height * nrows_layout + 0.6)}
    
    # choose legend option for export 
    p_wave_save = switch (export_option,
                         "none" = p_wave,
                         "full" = p_wave,
                         "no legend" = p_wave + theme(legend.position="none"),
                         "legend only" = legend)
    
    ggsave(filename, plot=p_wave_save, width=width, height=height)
  }
  
  # returns full fig regardless of export options
  return(p_wave)
  
}


# ===== GET AVERAGE ERP WINDOW AVG ===== 
prep_erp_amp = function(df) {
  
  df_type = unique(df$df_type)
  
  # grouping vars
  vars = c("taskcond", "resptype",  # NOT grouped by time_ms
           "task", "cond", "erp_win", "erp_chans", "df_type")   # information cols ONLY, preserve for plotting)
  
  if (df_type=="feed") {
    vars = c(vars,"trial_is_fpf","resptype_6")
  }
  
  # UNWEIGHTED VERSION
  summ = df %>% group_by(across(all_of(vars))) %>%   
    summarise(nsub = n_distinct(sub),
              mean = mean(mean_amp, na.rm=TRUE),
              sd   = sd(mean_amp, na.rm = TRUE),
              se   = sd / sqrt(nsub),
              .groups = "drop")
  
  # WEIGHTED VERSION - DO NOT USE
  # summ = df %>% group_by(across(all_of(vars))) %>%   
  #   summarise(nsub = n(),
  #             mean = weighted.mean(mean_amp, cell_ntrials),
  #             # do not use unweighted SE since it uses unweighted mean 
  #             se = sqrt(sandwich::vcovHC(lm(mean_amp ~ 1, weights = cell_ntrials), type = "HC1")[1, 1]),
  #             #se = sqrt(sum(cell_ntrials^2 * (mean_amp-mean)^2)) / sum(cell_ntrials) * sqrt(nsub / (nsub - 1)),
  #             .groups="drop")
  # # cite sandwich package: Zeileis et al 2019
  # # cite SE calculation method: https://www.jstatsoft.org/article/view/v011i10/0 
  
  return(summ)
  
}

# ===== PLOT ERP AMP ===== 
plot_erp_amp = function(df, erp_win=NULL, width=NULL, height=NULL, 
                        layout=c("panel","column"), 
                        export_option=c("full","none","no legend","legend only"),
                        save=FALSE, folder=NULL, filename=NULL) {
  
  if (isFALSE(save)) {
    export_option = "none"
  }
  
  #df = df %>% mutate(taskcond = str_replace(taskcond," ","\n"))
  
  df_type = unique(df$df_type)
  
  erp_win = str_split_1(unique(df$erp_win)," ")  
  t1 = erp_win[1]
  t2 = erp_win[2] 
  erp_win_filename = paste(t1,t2,sep="_")
  erp_win_fig = paste0(t1,"-",t2," ms")
  
  chanlist_fig = unique(df$erp_chans)   # for fig title only
  chanlist = str_split_1(chanlist_fig," ")
  chanlist_filename = paste(chanlist,collapse="")  # for filename only 
  
  fig_title = case_when(df_type=="stim" ~ "Stimulus-locked",
                        df_type=="resp" ~ "Response-locked",
                        df_type=="feed" ~ "Feedback-locked")
  fig_subtitle = paste(chanlist_fig, erp_win_fig, sep=" ")
  
  # # resptype color legend
  # resptype_colors_4 <- c("#1b9e77","#d95f02","#7570b3","#e7298a")
  # 
  # # modified from Dark2 to add lighter shade variation for FPF
  # resptype_colors_6 <- c("#1b9e77","#d95f02","#fdcdac",
  #                        "#7570b3","#e7298a","#f4cae4")
  
  if (df_type=="feed") {
    # do not use ifelse, unknown bug causes these_colors to save only the first value
    these_colors = resptype_colors_6
    these_points = resptype_points_6
    shapes_fill = shape_fill_6
    df$resptype_plot = df$resptype_6  # add a new col to keep plotting var consistent
  } else {
    these_colors = resptype_colors_4
    these_points = resptype_points_4 
    shapes_fill = shape_fill_4
    df$resptype_plot = df$resptype
  } 
  
  p_amp = ggplot(df, aes(taskcond, mean,
                         color = resptype_plot,
                         fill  = resptype_plot,
                         shape = resptype_plot)) +
    # draw errorbar first so it doesn't go over white circle
    geom_errorbar(aes(ymin = mean - se,
                      ymax = mean + se),
                  position = position_dodge(0.5), width = 0.1, linewidth = 0.4) +
    geom_point(position = position_dodge(0.5), size=2) +
    scale_color_manual(values = these_colors, name = "Response") +
    scale_fill_manual(values  = shapes_fill,  name = "Response") +
    scale_shape_manual(values = these_points, name = "Response") +
    labs(x = "Task and condition", y = "Mean amplitude (\u00b5V)",
         title = fig_title, subtitle = fig_subtitle) +  
    theme_bw(base_size=10) +
    theme(legend.position = "bottom") +
    guides(color = guide_legend(nrow = 2, byrow = TRUE),
           fill  = guide_legend(nrow = 2, byrow = TRUE),
           shape = guide_legend(nrow = 2, byrow = TRUE))
  
  # half paneled version
  p_amp_panel = p_amp + aes(x=cond) +
    facet_wrap(~task, scales="free_x", space="free_x") +  # [!!!]
    #theme(strip.background = element_rect(fill = NA)) +  # make strip box blank
    labs(x = "Condition")
  
  # fully task x cond paneled - discarded  
  # p_amp_panel = p_amp + aes(x = resptype_plot) +
  #   ggh4x::facet_nested(cols=vars(task,cond)) +
  #   theme(legend.position="none") +
  #   guides(color="none",fill="none",shape="none") +
  #   labs(x = "Response")
  
  # choose panel or column layout
  p_amp_out = switch (layout,
    "panel"  = p_amp_panel,
    "column" = p_amp
  )
  
  if (isTRUE(save)) {
    if (is.null(folder)) {folder = "/Users/lunarneko/Desktop/11_erp_plot_ggsave/"}
    
    if (is.null(filename)) {
      filename_fig = paste0(folder,"erpamp_",df_type,"_",chanlist_filename,"_",
                            erp_win_filename,".pdf")
      filename_legend = paste0(folder,"legend_erpamp_",df_type,"_resptype.pdf")
      filename = ifelse(export_option=="legend only", filename_legend, filename_fig)
    }
    
    # create legend object and get actual legend height for exporting
    # keep width consistent with figure
    if (export_option=="legend only") {
      legend = ggpubr::get_legend(p_amp_out,position="bottom")
      legend_height = grid::convertHeight(sum(legend$heights), "in", valueOnly = TRUE)
    }
    
    nconds = nrow(distinct(df, task, cond))   # number of panels
    
    if (is.null(width))  {col_width = 1; width = nconds * col_width}
    if (is.null(height)) {height=ifelse(export_option=="legend only", legend_height, 4)}
    
    # choose legend option for export 
    p_amp_save = switch (export_option,
                         "none" = p_amp_out,
                         "full" = p_amp_out,
                         "no legend" = p_amp_out + theme(legend.position="none"),
                         "legend only" = legend)
    
    ggsave(filename, plot=p_amp_save, width=width, height=height)
    
  }
  
  # returns full fig regardless of export options
  return(p_amp_out)
  
}




# ******************************************************************************



# ******************************************************************************

# ===== LMER-BASED EMMEAN/CONTRAST BY TASK/COND/RESPTYPE ===== 

test_amp_lmer = function(df, model, save=FALSE) { 
  # uses subj-level mean amps df
  
  data = df  # avoid conflict with `df` column in emmeans output 
  
  df_type = unique(data$df_type)
  chanlist_filename = str_remove_all(unique(data$erp_chans)," ")
  erp_win_filename  = str_replace(unique(data$erp_win)," ","_")
  
  if (df_type=="feed") {
    data$resptype_iv = data$resptype_6   # "iv"=predictor variable for model only
  } else {
    data$resptype_iv = data$resptype
  }
  
  # get model-based cell mean/SE for figures
  # add 0 term (`mean_amp ~ 0 + taskcond + ...`) to remove intercept (ref level mean) in coefs, no difference in model result
  if (is.null(model)) {
    # default model taskcond x resptype
    model = lmer(mean_amp ~ taskcond:resptype_iv + (1|sub) + (1|sub:taskcond) + (1|sub:resptype_iv), 
                 #weights=cell_ntrials, 
                 data=data)   # rank deficient warning is ok! this is just because of empty cells
  }
  summary(model)   # if intercept removed, coef is each cell's emmean 
  
  m1 = emmeans(model, ~ taskcond,    lmer.df = "satterthwaite")   # avg over resptype
  m2 = emmeans(model, ~ resptype_iv, lmer.df = "satterthwaite")   # avg over taskcond
  m3 = emmeans(model, ~ taskcond|resptype_iv, lmer.df = "satterthwaite")  
  m4 = emmeans(model, ~ resptype_iv|taskcond, lmer.df = "satterthwaite")  
  
  emm_all = bind_rows(
    as.data.frame(m1) %>% mutate(resptype_iv=NA),
    as.data.frame(m2) %>% mutate(taskcond=NA),
    as.data.frame(m3) 
  ) %>% 
    filter(!is.na(emmean)) %>% 
    rename(resptype = resptype_iv) %>% 
    select(taskcond,resptype,everything())
  
  pairs_all = bind_rows(
    as.data.frame(summary(pairs(m1, adjust = "none"), infer = TRUE)) %>% 
      mutate(family = "taskcond",
             resptype_iv = NA),
    as.data.frame(summary(pairs(m2, adjust = "none"), infer = TRUE)) %>% 
      mutate(family = "resptype",
             taskcond = NA),
    as.data.frame(summary(pairs(m3, adjust = "none"), infer = TRUE)) %>% 
      mutate(family="taskcond", by="resptype",
             resptype_iv = resptype_iv),
    as.data.frame(summary(pairs(m4, adjust = "none"), infer = TRUE)) %>% 
      mutate(family="resptype", by="family",
             taskcond = taskcond)) %>% 
    filter(!is.na(estimate)) %>% # drop empty-cell (nonEst) pairs
    group_by(family,by) %>% 
    mutate(p.holm = p.adjust(p.value, method = "holm")) %>% 
    rename(p.unadj = p.value,
           diff = estimate,
           resptype = resptype_iv) %>% 
    ungroup() %>% 
    separate(col=contrast,sep=" - ", into=c("var1","var2"), remove=FALSE) %>% 
    select(family, by, contrast, var1, var2, taskcond, resptype, 
           diff, SE, df, lower.CL, upper.CL, p.holm, p.unadj,everything())
  
  if (isTRUE(save)) {
    folder = "/Users/lunarneko/Desktop/11_erp_stats/"
    
    filename_emm   = paste0(folder,"erpamp_emm_",df_type,"_",chanlist_filename,"_",
                            erp_win_filename,".csv")
    filename_pairs = str_replace(filename_emm,"_emm_","_pairs_")
    
    write.csv(emm_all,  filename_emm,row.names=FALSE)
    write.csv(pairs_all,filename_pairs,row.names=FALSE)
  }
  
  return(list(emm_all,pairs_all))   # shows both together
  
}




## PLOT EMMEANS / CONTRAST


