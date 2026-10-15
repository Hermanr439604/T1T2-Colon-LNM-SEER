# Computational reproduction of a fixed registry research model.
# These probabilities are not validated treatment recommendations.
score_fixed_model <- function(data, coefficients) {
  required <- c('age','site','histology','grade','size_mm','t_stage')
  stopifnot(all(required %in% names(data)))
  stopifnot(all(data$site %in% c('Right-sided colon','Left-sided colon','Overlapping/NOS')),
            all(data$histology %in% c('Adenocarcinoma','Mucinous adenocarcinoma','Signet-ring cell carcinoma')),
            all(data$grade %in% c('Well/moderately differentiated','Poorly/undifferentiated')),
            all(data$t_stage %in% c('T1','T2')),
            all(is.finite(data$age)),all(is.finite(data$size_mm)))
  a<-Hmisc::rcspline.eval(data$age,knots=c(46,62,72,86),inclx=TRUE,norm=2)
  s<-Hmisc::rcspline.eval(data$size_mm,knots=c(4,20,33,65),inclx=TRUE,norm=2)
  x<-cbind(1,a,as.integer(data$site=='Left-sided colon'),as.integer(data$site=='Overlapping/NOS'),
           as.integer(data$histology=='Mucinous adenocarcinoma'),as.integer(data$histology=='Signet-ring cell carcinoma'),
           as.integer(data$grade=='Poorly/undifferentiated'),s,as.integer(data$t_stage=='T2'))
  colnames(x)<-c('Intercept','age',"age'","age''",'site_model=Left-sided colon','site_model=Overlapping/NOS',
                'histology_model=Mucinous adenocarcinoma','histology_model=Signet-ring cell carcinoma',
                'grade_model=Poorly/undifferentiated','tumor_size_mm',"tumor_size_mm'","tumor_size_mm''",'t_stage=T2')
  stopifnot(all(colnames(x)%in%names(coefficients)))
  as.numeric(plogis(x%*%coefficients[colnames(x)]))
}
