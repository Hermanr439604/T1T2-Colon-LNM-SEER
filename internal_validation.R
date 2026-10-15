args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2)
root <- normalizePath(args[1]); out <- args[2]
dir.create(out,recursive=TRUE,showWarnings=FALSE)
suppressPackageStartupMessages({library(Hmisc);library(rms)})
d <- as.data.frame(readRDS(file.path(root,'02_clean_data/SEER_T1T2_colon_LNM_final_analysis_cohort.rds')))
stopifnot(nrow(d)==14498, !anyDuplicated(d$patient_id))
d <- d[d$year_dx<=2021,]; y <- d$lnm_num; n <- nrow(d)
stopifnot(n==11490,sum(y)==1756)
d$site_model<-d$site_group;d$histology_model<-d$histology_group;d$grade_model<-d$grade_group
cats <- model.matrix(~site_model+histology_model+grade_model+t_stage,d)[,-1,drop=FALSE]
race <- model.matrix(~race_group,d)[,-1,drop=FALSE]
stopifnot(ncol(cats)==6,ncol(race)==4)
candidates <- c('Race-free linear','Race-free RCS','Race-inclusive RCS')
warnings_seen <- character()
safe_glm <- function(x, yy, offset=NULL) {
 f <- withCallingHandlers(glm.fit(x,yy,family=binomial(),offset=offset,
  control=glm.control(epsilon=1e-9,maxit=100)),warning=function(w){
   warnings_seen <<- c(warnings_seen,conditionMessage(w));invokeRestart('muffleWarning')})
 if(!f$converged || f$rank!=ncol(x) || any(!is.finite(f$coefficients)))stop('Convergence/rank/nonfinite failure')
 f
}
designs <- function(i,j) {
 a<-rcspline.eval(d$age[i],nk=4,inclx=TRUE,norm=2)
 s<-rcspline.eval(d$tumor_size_mm[i],nk=4,inclx=TRUE,norm=2)
 ak<-attr(a,'knots');sk<-attr(s,'knots')
 aj<-rcspline.eval(d$age[j],knots=ak,inclx=TRUE,norm=2)
 sj<-rcspline.eval(d$tumor_size_mm[j],knots=sk,inclx=TRUE,norm=2)
 xi<-list(cbind(1,d$age[i],d$tumor_size_mm[i],cats[i,,drop=FALSE]),
          cbind(1,a,s,cats[i,,drop=FALSE]),cbind(1,a,s,cats[i,,drop=FALSE],race[i,,drop=FALSE]))
 xj<-list(cbind(1,d$age[j],d$tumor_size_mm[j],cats[j,,drop=FALSE]),
          cbind(1,aj,sj,cats[j,,drop=FALSE]),cbind(1,aj,sj,cats[j,,drop=FALSE],race[j,,drop=FALSE]))
 list(train=xi,test=xj,age=ak,size=sk)
}
auc_rank <- function(yy,lp) {
 n1<-sum(yy);n0<-length(yy)-n1
 (sum(rank(lp,ties.method='average')[yy==1])-n1*(n1+1)/2)/(n1*n0)
}
metrics <- function(yy,lp) {
 a<-safe_glm(matrix(1,length(yy),1),yy,offset=lp)
 s<-safe_glm(cbind(1,lp),yy)
 c(AUC=auc_rank(yy,lp),Brier=mean((yy-plogis(lp))^2),
   Calibration_intercept=unname(a$coefficients[1]),Calibration_slope=unname(s$coefficients[2]))
}
choose <- function(fits) {
 aic<-sapply(fits,function(f)f$deviance+2*f$rank)
 ties<-which(abs(aic-min(aic))<1e-8)
 ties[which.min(sapply(fits[ties],function(f)f$rank))]
}
write <- function(z,name)write.csv(z,file.path(out,name),row.names=FALSE)
all <- seq_len(n); full <- designs(all,all)
fits <- lapply(full$train,function(x)safe_glm(x,y)); sel<-choose(fits)
lp <- lapply(seq_along(fits),function(k)drop(full$train[[k]]%*%fits[[k]]$coefficients))
saved<-readRDS(file.path(root,'08_models/Primary_race_free_RCS_model_tumor_size_le150.rds'))
delta<-max(abs(plogis(lp[[2]])-as.numeric(predict(saved,newdata=d,type='fitted'))))
stopifnot(delta<1e-6,all(full$age==c(46,62,72,86)),all(full$size==c(4,20,33,65)))
apparent <- do.call(rbind,lapply(seq_along(fits),function(k)
 data.frame(Candidate=candidates[k],Predictor_df=fits[[k]]$rank-1,AIC=fits[[k]]$deviance+2*fits[[k]]$rank,
  Selected=k==sel,t(metrics(y,lp[[k]])),check.names=FALSE)))
write(apparent,'candidate_development_apparent.csv')
write(data.frame(Check=c('Development N','Events','Prediction max difference','Bootstrap repetitions','CV repetitions','CV folds'),
 Value=c(n,sum(y),delta,1000,10,5)),'implementation_checks.csv')
cat('Implementation verified; maximum probability difference:',delta,'\n');flush.console()
set.seed(20261015); B<-1000L
boot<-vector('list',B); knots<-vector('list',B)
for(b in seq_len(B)) {
 i<-sample.int(n,n,replace=TRUE); xx<-designs(i,all)
 ff<-lapply(xx$train,function(x)safe_glm(x,y[i])); ksel<-choose(ff)
 rows<-lapply(c(2L,ksel),function(k) {
  train_m<-metrics(y[i],drop(xx$train[[k]]%*%ff[[k]]$coefficients))
  test_m<-metrics(y,drop(xx$test[[k]]%*%ff[[k]]$coefficients))
  data.frame(Repeat=b,Candidate=candidates[k],Metric=names(train_m),Apparent=unname(train_m),
   Original=unname(test_m),Optimism=unname(train_m-test_m))
 })
 rows[[1]]$Procedure<-'Fixed primary with re-estimated knots'
 rows[[2]]$Procedure<-'AIC candidate selection sensitivity'
 boot[[b]]<-rbind(rows[[1]],rows[[2]])
 knots[[b]]<-data.frame(Repeat=b,Variable=rep(c('age','tumor_size_mm'),each=4),Order=rep(1:4,2),Knot=c(xx$age,xx$size))
 if(b%%100==0){cat('Bootstrap',b,'/',B,'completed\n');flush.console()}
}
bb<-do.call(rbind,boot);kk<-do.call(rbind,knots)
write(bb,'bootstrap_repeat_aggregate_metrics.csv');write(kk,'bootstrap_knot_values.csv')
summary<-do.call(rbind,lapply(unique(bb$Procedure),function(pr) {
 base<-if(pr=='Fixed primary with re-estimated knots')metrics(y,lp[[2]]) else metrics(y,lp[[sel]])
 do.call(rbind,lapply(names(base),function(mt){v<-bb$Optimism[bb$Procedure==pr & bb$Metric==mt]
  data.frame(Procedure=pr,Metric=mt,Apparent=unname(base[mt]),Mean_optimism=mean(v),
   Corrected=unname(base[mt])-mean(v),Monte_Carlo_SE=sd(v)/sqrt(B),Successful=B)}))
}))
write(summary,'bootstrap_summary.csv')
chosen<-bb[bb$Procedure=='AIC candidate selection sensitivity'&bb$Metric=='AUC','Candidate']
write(data.frame(Candidate=candidates,Selected_count=as.integer(table(factor(chosen,levels=candidates))),Total=B),'bootstrap_selection_frequencies.csv')
set.seed(20261016); cvs<-list();folds<-list()
for(r in 1:10) {
 fold<-integer(n)
 for(v in 0:1){idx<-which(y==v);fold[idx]<-sample(rep(1:5,length.out=length(idx)))}
 lp_primary<-lp_select<-rep(NA_real_,n)
 for(f in 1:5) {
  j<-which(fold==f);i<-which(fold!=f);xx<-designs(i,j)
  ff<-lapply(xx$train,function(x)safe_glm(x,y[i]));k<-choose(ff)
  lp_primary[j]<-drop(xx$test[[2]]%*%ff[[2]]$coefficients)
  lp_select[j]<-drop(xx$test[[k]]%*%ff[[k]]$coefficients)
  folds[[length(folds)+1]]<-data.frame(Repeat=r,Fold=f,Training_N=length(i),Held_out_N=length(j),Selected=candidates[k])
 }
 stopifnot(!anyNA(lp_primary),!anyNA(lp_select))
 cvs[[length(cvs)+1]]<-data.frame(Repeat=r,Procedure='Fixed primary with re-estimated knots',t(metrics(y,lp_primary)),check.names=FALSE)
 cvs[[length(cvs)+1]]<-data.frame(Repeat=r,Procedure='AIC candidate selection sensitivity',t(metrics(y,lp_select)),check.names=FALSE)
 cat('Cross-validation repetition',r,'/ 10 completed\n');flush.console()
}
cv<-do.call(rbind,cvs);foldout<-do.call(rbind,folds)
write(cv,'cross_validation_repeat_metrics.csv');write(foldout,'cross_validation_fold_selections.csv')
cvsum<-do.call(rbind,lapply(unique(cv$Procedure),function(pr)do.call(rbind,lapply(names(cv)[3:6],function(mt){v<-cv[cv$Procedure==pr,mt]
 data.frame(Procedure=pr,Metric=mt,Mean=mean(v),Minimum=min(v),Maximum=max(v),Repetitions=10)}))))
write(cvsum,'cross_validation_summary.csv')
write(data.frame(Candidate=candidates,Selected_count=as.integer(table(factor(foldout$Selected,levels=candidates))),Total=50),'cross_validation_selection_frequencies.csv')
write(data.frame(Step=c('Bootstrap candidate fits','CV candidate fits','Failed fits','Warnings','Missing OOF predictions'),
 Count=c(B*3,50*3,0,length(warnings_seen),0)),'convergence_audit.csv')
write(data.frame(Warning=unique(warnings_seen)),'warning_log.csv')
capture.output(sessionInfo(),file=file.path(out,'sessionInfo.txt'))
cat('All planned analyses completed.\n');print(summary);print(cvsum)
