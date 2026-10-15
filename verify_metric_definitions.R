args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==2)
suppressPackageStartupMessages({library(rms);library(pROC)})
d<-as.data.frame(readRDS(file.path(args[1],'02_clean_data/SEER_T1T2_colon_LNM_final_analysis_cohort.rds')))
d<-d[d$year_dx<=2021,];d$site_model<-d$site_group;d$histology_model<-d$histology_group;d$grade_model<-d$grade_group
m<-readRDS(file.path(args[1],'08_models/Primary_race_free_RCS_model_tumor_size_le150.rds'))
p<-as.numeric(predict(m,newdata=d,type='fitted'));y<-d$lnm_num;lp<-qlogis(p)
rank_auc<-(sum(rank(lp,ties.method='average')[y==1])-sum(y)*(sum(y)+1)/2)/(sum(y)*sum(y==0))
proc_auc<-as.numeric(auc(roc(y,p,direction='<',quiet=TRUE)))
s<-read.csv(file.path(args[2],'bootstrap_summary.csv'))
s<-s[s$Procedure=='Fixed primary with re-estimated knots',]
reference<-c(AUC=proc_auc,Brier=mean((y-p)^2),Calibration_intercept=unname(coef(glm(y~1,offset=lp,family=binomial()))[1]),Calibration_slope=unname(coef(glm(y~lp,family=binomial()))[2]))
delta<-s$Apparent-unname(reference[s$Metric]);stopifnot(abs(rank_auc-proc_auc)<1e-12,max(abs(delta))<1e-8)
write.csv(data.frame(Check=c('Rank AUC versus pROC AUC','Apparent metrics versus independent pROC/glm computation'),Maximum_absolute_difference=c(abs(rank_auc-proc_auc),max(abs(delta)))),file.path(args[2],'metric_definition_checks.csv'),row.names=FALSE)
cat('Metric definitions independently verified.\n')
