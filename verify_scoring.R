args<-commandArgs(trailingOnly=TRUE)
suppressPackageStartupMessages(library(rms))
source('score_model.R')
m<-readRDS(file.path(args[1],'08_models/Primary_race_free_RCS_model_tumor_size_le150.rds'))
b<-coef(m)
write.csv(data.frame(Term=names(b),Coefficient=as.numeric(b)),file.path(args[2],'primary_coefficients_full_precision.csv'),row.names=FALSE)
p<-data.frame(age=c(50,67,75),site=c('Right-sided colon','Left-sided colon','Right-sided colon'),
 histology='Adenocarcinoma',grade=c('Well/moderately differentiated','Poorly/undifferentiated','Well/moderately differentiated'),
 size_mm=c(20,35,25),t_stage=c('T1','T2','T2'))
p$site_model<-factor(p$site,levels=c('Right-sided colon','Left-sided colon','Overlapping/NOS'))
p$histology_model<-factor(p$histology,levels=c('Adenocarcinoma','Mucinous adenocarcinoma','Signet-ring cell carcinoma'))
p$grade_model<-factor(p$grade,levels=c('Well/moderately differentiated','Poorly/undifferentiated'))
p$tumor_size_mm<-p$size_mm
pred<-as.numeric(predict(m,p,type='fitted'));manual<-score_fixed_model(p,b)
stopifnot(max(abs(pred-manual))<1e-12)
p$Expected_probability<-pred
write.csv(p[,c('age','site','histology','grade','size_mm','t_stage','Expected_probability')],file.path(args[2],'hypothetical_scoring_checks.csv'),row.names=FALSE)
write.csv(data.frame(Check='Fixed-coefficient scoring vs rms prediction on three hypothetical profiles',Maximum_absolute_difference=max(abs(pred-manual))),file.path(args[2],'scoring_reproduction_check.csv'),row.names=FALSE)
cat('Scoring reproduced to',format(max(abs(pred-manual))), '\n')
