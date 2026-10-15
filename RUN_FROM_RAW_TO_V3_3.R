# Rebuild author-held cohort from an authorized original export, then run V3.3.
# This full legacy rebuild was not independently executed during V3.3 preparation.
# The legacy source may install absent packages. Inspect it before executing.
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=2)stop("Usage: Rscript RUN_FROM_RAW_TO_V3_3.R AUTHORIZED_RAW_CSV NEW_EMPTY_OUTPUT_DIRECTORY")
raw_input<-normalizePath(args[1],mustWork=TRUE)
run_output<-args[2]
if(dir.exists(run_output)&&length(list.files(run_output,all.files=TRUE,no..=TRUE)))stop("Use an empty directory.")
dir.create(run_output,recursive=TRUE,showWarnings=FALSE);run_output<-normalizePath(run_output)
legacy_out<-file.path(run_output,"legacy_rebuild")
script<-readLines("Original_V2_2_Code_Archive/MASTER_PIPELINE_T1T2_COLON_LNM_FINAL_V2_2.R",warn=FALSE)
loc<-which(grepl('^project_dir <- ',script));stopifnot(length(loc)==1)
script[loc]<-paste0("project_dir <- ",deparse(dirname(raw_input)))
loc<-which(grepl('^raw_csv_name <- ',script));stopifnot(length(loc)==1)
script[loc]<-paste0("raw_csv_name <- ",deparse(basename(raw_input)))
loc<-which(grepl('^output_root <- file.path',script));stopifnot(length(loc)==1)
end<-loc+which(trimws(script[(loc+1):length(script)])==")")[1]
script<-c(script[seq_len(loc-1)],paste0("output_root <- ",deparse(legacy_out)),script[(end+1):length(script)])
patched<-file.path(run_output,"legacy_runner_local.R");writeLines(script,patched)
runner<-file.path(R.home("bin"),"Rscript")
status<-system2(runner,shQuote(patched));if(status!=0)stop("Legacy cohort rebuild failed; no V3.3 analysis was run.")
status<-system2(runner,c(shQuote("RUN_V3_3.R"),shQuote(legacy_out),shQuote(file.path(run_output,"v3_3"))))
if(status!=0)stop("V3.3 downstream analysis failed.")
