args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)==3)
input<-args[1];out<-args[2];qa<-args[3]
dir.create(out,recursive=TRUE,showWarnings=FALSE);dir.create(qa,recursive=TRUE,showWarnings=FALSE)
suppressPackageStartupMessages({library(ggplot2);library(patchwork)})
source('panel_alignment_local.R')
theme_set(theme_classic(base_size=9,base_family='sans')+theme(axis.line=element_line(linewidth=.35),axis.ticks=element_line(linewidth=.35),plot.title=element_text(size=10,face='bold'),plot.margin=margin(6,12,6,6),panel.grid=element_blank(),plot.background=element_rect(fill='white',colour=NA)))
saveplot<-function(g,name,w=180,h=95){
 stem<-file.path(out,name);ww<-w/25.4;hh<-h/25.4
 if(inherits(g,'patchwork'))require_patchwork_panel_alignment(g,manifest_path=file.path(qa,paste0(name,'.layout.json')),report_path=file.path(qa,paste0(name,'.alignment.json')),width_in=ww,height_in=hh,audit_script='audit_panel_alignment.py',python=Sys.which('python3'),strict=TRUE)
 svglite::svglite(paste0(stem,'.svg'),width=ww,height=hh);print(g);dev.off()
 grDevices::pdf(paste0(stem,'.pdf'),width=ww,height=hh,family='Helvetica',useDingbats=FALSE);print(g);dev.off()
 ragg::agg_tiff(paste0(stem,'.tiff'),width=w,height=h,units='mm',res=600);print(g);dev.off()
 ragg::agg_png(paste0(stem,'.png'),width=w,height=h,units='mm',res=600);print(g);dev.off()
 grDevices::cairo_pdf(file.path(qa,paste0(name,'.cairo-probe.pdf')),width=ww,height=hh,family='sans');print(g);dev.off()
}
b<-read.csv(file.path(input,'benchmark_2022.csv'))
b$Model<-factor(b$Analysis,levels=rev(b$Analysis));b$Primary<-b$Analysis=='RCS clinicopathologic'
g<-ggplot(b,aes(x=AUC,y=Model))+geom_errorbar(aes(xmin=AUC_lower,xmax=AUC_upper),orientation='y',width=.12,linewidth=.6,colour='#6E6E6E')+geom_point(aes(colour=Primary),size=2.8)+scale_colour_manual(values=c('FALSE'='#777777','TRUE'='#0072B2'),guide='none')+scale_x_continuous(limits=c(.50,.72),breaks=seq(.50,.70,.05))+labs(x='Area under the ROC curve in 2022',y=NULL)+theme(axis.text.y=element_text(colour='black'),axis.text.x=element_text(colour='black'))
saveplot(g,'Figure_2_Model_Benchmark',180,70)
r<-read.csv(file.path(input,'roc_curve.csv'));c<-read.csv(file.path(input,'calibration_curve.csv'));d<-read.csv(file.path(input,'calibration_deciles.csv'))
a<-ggplot(r,aes(FPR,TPR))+geom_segment(data=data.frame(x=0,y=0,xend=1,yend=1),aes(x=x,y=y,xend=xend,yend=yend),inherit.aes=FALSE,linetype=2,linewidth=.4,colour='#888888')+geom_path(linewidth=.7,colour='#0072B2')+scale_x_continuous(limits=c(0,1),breaks=seq(0,1,.25),expand=c(0,0))+scale_y_continuous(limits=c(0,1),breaks=seq(0,1,.25),expand=c(0,0))+labs(x='False positive rate',y='True positive rate',title='A  Discrimination')
bb<-ggplot()+geom_ribbon(data=c,aes(Predicted,ymin=Lower,ymax=Upper),fill='#0072B2',alpha=.15)+geom_segment(data=data.frame(x=0,y=0,xend=1,yend=1),aes(x=x,y=y,xend=xend,yend=yend),inherit.aes=FALSE,linetype=2,linewidth=.4,colour='#888888')+geom_line(data=c,aes(Predicted,Observed),linewidth=.7,colour='#0072B2')+geom_errorbar(data=d,aes(Predicted,ymin=Lower,ymax=Upper),width=.008,linewidth=.45,colour='#333333')+geom_point(data=d,aes(Predicted,Observed),size=1.7,colour='#333333')+scale_x_continuous(limits=c(0,1),breaks=seq(0,1,.25),expand=c(0,0))+scale_y_continuous(limits=c(0,1),breaks=seq(0,1,.25),expand=c(0,0))+labs(x='Predicted LNM probability',y='Observed LNM probability',title='B  Calibration')
combined<-a+bb+plot_layout(nrow=1,widths=c(1,1))
saveplot(combined,'Figure_3_Primary_Performance',180,95)
