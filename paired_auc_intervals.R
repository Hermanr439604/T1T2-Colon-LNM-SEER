args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==2)
suppressPackageStartupMessages({library(rms);library(pROC)})
d<-as.data.frame(readRDS(file.path(args[1],'02_clean_data/SEER_T1T2_colon_LNM_final_analysis_cohort.rds')))
d$site_model<-d$site_group;d$histology_model<-d$histology_group;d$grade_model<-d$grade_group;d$race_model<-d$race_group
tr<-d[d$year_dx<=2021,];te<-d[d$year_dx==2022,]
primary<-readRDS(file.path(args[1],'08_models/Primary_race_free_RCS_model_tumor_size_le150.rds'))
linear<-lrm(lnm_num~age+site_model+histology_model+grade_model+tumor_size_mm+t_stage,data=tr,x=TRUE,y=TRUE)
tonly<-lrm(lnm_num~t_stage,data=tr,x=TRUE,y=TRUE)
race<-readRDS(file.path(args[1],'08_models/Exploratory_race_inclusive_RCS_model_tumor_size_le150.rds'))
ro<-function(m,dd)roc(dd$lnm_num,as.numeric(predict(m,newdata=dd,type='fitted')),quiet=TRUE,direction='<')
pair<-function(a,b,label){delta<-as.numeric(auc(a)-auc(b));variance<-as.numeric(var(a,method='delong')+var(b,method='delong')-2*cov(a,b,method='delong'))
 stopifnot(variance>=0);se<-sqrt(variance);tt<-roc.test(a,b,paired=TRUE,method='delong')
 data.frame(Comparison=label,N=length(a$response),Delta_AUC=delta,SE=se,Lower=delta-qnorm(.975)*se,Upper=delta+qnorm(.975)*se,P=tt$p.value)}
a<-ro(primary,te)
z<-rbind(pair(a,ro(tonly,te),'Primary spline minus T-only'),pair(a,ro(linear,te),'Primary spline minus linear'),pair(ro(race,te),a,'Race-inclusive spline minus primary'))
# Saved PNI fits preserve their original factor coding and estimation sample.
pni_base<-readRDS(file.path(args[1],'08_models/Exploratory_PNI_known_race_inclusive_base_model.rds'))
pni_enh<-readRDS(file.path(args[1],'08_models/Exploratory_PNI_enhanced_model.rds'))
te$pni_binary<-factor(ifelse(as.character(te$pni_group)%in%c('Absent','Present'),as.character(te$pni_group),NA_character_),levels=c('Absent','Present'))
need<-all.vars(formula(pni_enh));stopifnot(all(need%in%names(te)))
pte<-te[complete.cases(te[,need]),]
stopifnot(nrow(pte)==2819)
z<-rbind(z,pair(ro(pni_enh,pte),ro(pni_base,pte),'PNI-enhanced minus paired race-inclusive base'))
write.csv(z,file.path(args[2],'paired_auc_difference_intervals.csv'),row.names=FALSE);print(z)
