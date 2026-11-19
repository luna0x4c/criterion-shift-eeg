
# ===== clean trials =====

prep_sdt = function(grouped_df) {
  # df needs to be grouped first
  x = grouped_df %>% 
    # use reframe() instead of summarise() to avoid empty/duplicate cell issues
    reframe(
      valid_trials = n(),
      n_hit   = sum(resp_type=="hit",na.rm=TRUE),
      n_fa    = sum(resp_type=="fa",na.rm=TRUE),
      n_miss  = sum(resp_type=="miss",na.rm=TRUE),
      n_cr    = sum(resp_type=="cr",na.rm=TRUE),
      n_isold  = n_hit + n_miss,
      n_isnew  = valid_trials - n_isold,
      n_sayold = n_hit + n_fa,
      n_saynew = valid_trials - n_sayold,
      
      meanRT = mean(resp_real.rt,na.rm=TRUE),
      medRT = median(resp_real.rt,na.rm=TRUE),
      
      n_rollfpf = case_when(task=="FPF" & cond=="Lib" ~ n_fa,
                            task=="FPF" & cond=="Con" ~ n_miss,
                            TRUE ~ NA),
      n_isfpf   = sum(trial_is_fpf,na.rm=TRUE),
      percent_fpf = round(n_isfpf/n_rollfpf,3),
      
      raw_hr  = n_hit/n_isold,
      raw_far = n_fa/n_isnew, 
      transform_hr = ifelse(raw_hr==1|raw_hr==0, 1, 0),
      transform_far = ifelse(raw_far==1|raw_far==0, 1, 0),
      hr = case_when(raw_hr==1 ~ 1 - 1/valid_trials,
                     raw_hr==0 ~ 1/valid_trials,
                     TRUE ~ raw_hr),
      far = case_when(raw_far==1 ~ 1 - 1/valid_trials,
                      raw_far==0 ~ 1/valid_trials,
                      TRUE ~ raw_far)
      
    ) %>% unique() %>%    # otherwise `reframe()` will return full df instead of 1 row per group
    ungroup()
  
  return(x)
  
}

# ===== get empirical s ===== 
prep_conf_counts = function(df) {
  x = df %>% 
    filter(!is.na(resp_type)) %>%   # or sum() will throw NA
    reframe(
      # ordered new>>>old, most to least confident on each end
      n1 = sum(resp_type=="cr"  & conf=="high"),
      n2 = sum(resp_type=="cr"  & conf=="med"),
      n3 = sum(resp_type=="cr"  & conf=="low"),
      n4 = sum(resp_type=="fa"  & conf=="low"),
      n5 = sum(resp_type=="fa"  & conf=="med"),
      n6 = sum(resp_type=="fa"  & conf=="high"),
      m1 = sum(resp_type=="miss" & conf=="high"),
      m2 = sum(resp_type=="miss" & conf=="med"),
      m3 = sum(resp_type=="miss" & conf=="low"),
      m4 = sum(resp_type=="hit"  & conf=="low"),
      m5 = sum(resp_type=="hit"  & conf=="med"),
      m6 = sum(resp_type=="hit"  & conf=="high")
    ) %>% unique() %>% ungroup()
  return(x)
}  

get_zroc_s = function(df) { 
  # one per subj, pooled across task/cond
  x = df %>% rowwise() %>%
    mutate(
      # NOTE: nested lists
      new_counts = list(c(n1,n2,n3,n4,n5,n6)),
      old_counts = list(c(m1,m2,m3,m4,m5,m6)),
      n_new = sum(unlist(new_counts),na.rm=TRUE),
      n_old = sum(unlist(old_counts),na.rm=TRUE),
      # hr/far from most old & high conf end
      hr  = list(rev(cumsum(rev(old_counts)))[2:6] / n_old),
      far = list(rev(cumsum(rev(new_counts)))[2:6] / n_new),
      # correct for 0/1
      hr  = list(pmin(pmax(unlist(hr),  1/(2*n_old)), 1 - 1/(2*n_old))),
      far = list(pmin(pmax(unlist(far), 1/(2*n_new)), 1 - 1/(2*n_new))),
      z_hr  = list(qnorm(unlist(hr))),
      z_far = list(qnorm(unlist(far))),
      # get lm fit
      lm = list(lm(unlist(z_hr) ~ unlist(z_far))),
      s = lm$coefficients[2],  # slope
      rsq = summary(lm)$r.squared
    ) %>% ungroup() %>%
    select(-c(new_counts,old_counts), -c(hr,far,z_hr,z_far), -lm) 
  return(x)
}


# ===== get ev/uv sdt =====

get_sdt = function(df, s=NULL) { 
  if (is.null(s)) {
    s = 0.8
    message("s not specified, using default s = 0.8")
  } #else {
  #   message("Using empirical s")
  # }
  
  sdt_df = df %>% 
    mutate(    
      # d' & c
      dpr = qnorm(hr) - qnorm(far),
      cri = -(qnorm(hr) + qnorm(far))/2,
      # da & c2
      hit_minus_fa = qnorm(hr) - qnorm(far) * s,
      da = sqrt((2/(1+s^2))) * hit_minus_fa,
      hit_plus_fa = qnorm(hr) + qnorm(far),
      c2 = (-s / (s+1)) * hit_plus_fa,
      # c_far for meta-d calculation
      c_far = -qnorm(far)
    ) 
  return(sdt_df)
}


# ===== type 2 sdt =====
# adapted from maniscalco & lau 2012 MATLAB code

fit_meta_d_mle = function(nR_S1, nR_S2, da, s, c_far) {
  # nr_s1 = saynew, nr_s2 = sayold 
  # c_far is c1 here [NOT the c1 in M&C]
  nRatings = length(nR_S1) / 2   # number of conf bins on each side, no need to change 

  # convert da into sd??? units 
  f = s*sqrt(2/(1+s^2))
  d = da/f
  
  negLL = function(par) {
    meta_d = par[1]
    x = par[2:nRatings]
    y = par[(nRatings+1):(2*nRatings-1)]
    
    meta_c1 = c_far * (meta_d / d)
    t2c_S1 = sort(meta_c1 - cumsum(exp(x)))
    t2c_S2 = sort(meta_c1 + cumsum(exp(y)))
    crit = c(t2c_S1, meta_c1, t2c_S2)
    
    pS1_bounds = pnorm(crit)
    pS2_bounds = pnorm((crit - meta_d) * s)
    
    p_S1 = pmax(diff(c(0, pS1_bounds, 1)), 1e-10)
    p_S2 = pmax(diff(c(0, pS2_bounds, 1)), 1e-10)
    
    -sum(nR_S1 * log(p_S1)) - sum(nR_S2 * log(p_S2))
  }
  
  start = c(d, rep(log(0.5), 2*(nRatings-1)))
  opt = optim(par=start, fn=negLL, method = "BFGS")   # UNconstrained
  
  meta_da = opt$par[1] * f
  
  list(meta_d = opt$par[1], 
       meta_da = meta_da,
       mratio = opt$par[1] / d,
       logL = -opt$value, 
       convergence = opt$convergence)
}


get_sdt_type2 = function(df) {
  
  if (!"s_subj" %in% names(df)) {
    df$s_subj = 0.8
    message("No individual slope provided; using default s = 0.8")
  }
  
  meta_df = df %>% 
    rowwise() %>% 
    mutate(
      nR_S1 = list(c(n1,n2,n3,n4,n5,n6)),  # colnames from `prep_conf_counts`
      nR_S2 = list(c(m1,m2,m3,m4,m5,m6)),
      # remove da==0
      fit = list(fit_meta_d_mle(nR_S1, nR_S2, da, s_subj, c_far)),
      meta_da = fit$meta_da,
      mratio  = fit$mratio, 
      meta_convergence = fit$convergence   # 0=success!!!
    ) %>% 
    ungroup() %>% 
    select(-fit, -nR_S1, -nR_S2)
  
  message("NOTE: remeber to check convergence!")
  
  return(meta_df)
}


