# Run from this package directory in a fresh R session or with Rscript.
args <- commandArgs(trailingOnly=TRUE)
if (length(args)!=2) stop("Usage: Rscript RUN_V3_3.R AUTHOR_HELD_OUTPUT_ROOT NEW_OUTPUT_DIRECTORY")
source_root <- normalizePath(args[1],mustWork=TRUE)
run_output <- args[2]
if (dir.exists(run_output) && length(list.files(run_output,all.files=TRUE,no..=TRUE))) stop("Use a new empty output directory to avoid mixing results.")
dir.create(run_output,recursive=TRUE,showWarnings=FALSE)
run_output <- normalizePath(run_output)
required <- c("rms","Hmisc","pROC","dplyr","readr","stringr","ggplot2","patchwork","ragg","svglite","jsonlite")
missing <- required[!vapply(required,requireNamespace,quietly=TRUE,FUN.VALUE=logical(1))]
if(length(missing)) stop("Install missing dependencies first: ",paste(missing,collapse=", "))
runner <- file.path(R.home("bin"),"Rscript")
run <- function(script,a) {
 message("Running ",script)
 status <- system2(runner,args=c(shQuote(script),vapply(a,shQuote,character(1))))
 if(status!=0)stop("Analysis failed: ",script)
}
aggregate_dir <- file.path(run_output,"aggregate_results")
internal_dir <- file.path(run_output,"internal_validation")
dir.create(aggregate_dir);dir.create(internal_dir)
for(s in c("reanalysis.R","missingness.R","verify_scoring.R"))run(s,c(source_root,aggregate_dir))
run("internal_validation.R",c(source_root,internal_dir))
run("verify_metric_definitions.R",c(source_root,internal_dir))
run("paired_auc_intervals.R",c(source_root,internal_dir))
run("make_figures.R",c(aggregate_dir,file.path(run_output,"figures"),file.path(run_output,"figure_QA")))
message("V3.3 downstream analyses complete. Upstream extraction and historical secondary modules are separate archive workflows.")
