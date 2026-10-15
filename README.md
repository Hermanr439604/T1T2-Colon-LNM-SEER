# T1–T2 Colon Cancer Lymph Node Metastasis: SEER Analysis

Analysis code and aggregate results accompanying a manuscript evaluating clinicopathologic prediction of lymph node metastasis in operated, node-assessed T1–T2 colon adenocarcinoma.

## Obtain the complete runnable project

Download and extract **Colon_LNM_Complete_Code_Package_V3_3.zip**. The archive preserves the directory structure needed by the scripts and includes the historical V2.2 and V3.0 code, current analyses, aggregate results, analysis plan, session information, and SHA-256 manifest. Root-level scripts here are convenient browsing copies; run the extracted complete project, not those isolated copies.

Read `README_CN.md`, `DATA_DICTIONARY.md`, and `EXECUTION_STATUS.csv` before running analyses. `RUN_V3_3.R` runs the current update against an authorized, locally held study analysis directory. `RUN_FROM_RAW_TO_V3_3.R` is the raw-data adapter; it was syntax checked but has not been independently executed end to end in this update.

## Analysis scope

- SEER 2018–2022 study cohort: 14,498 patients; development in 2018–2021 and evaluation in 2022.
- Current update: 1,000 patient-level bootstrap samples with knot re-estimation, a development-only candidate-selection sensitivity analysis, ten repetitions of stratified five-fold cross-validation, and paired AUC-difference uncertainty.
- Previously obtained primary model coefficients and 2022 predictions were retained. Historical secondary analyses are identified separately in the execution-status file.
- Earlier use of 2022 results in model simplification limits interpretation as an untouched test cohort. Current internal validation does not remove this limitation.

## Data access

No patient-level SEER data, account credentials, or internal review reports are included. Users must obtain their own authorized SEER access and comply with the applicable data-use agreement: https://seer.cancer.gov/data/access.html. Public repository contents include analysis code and aggregate outputs only. Exact upstream extraction records remain an author documentation item; this release does not certify independent reproduction of the SEER*Stat extraction.

## Publication and review status

This is the V3.3 code resource for a manuscript being prepared for submission. The manuscript has no assigned publication DOI. The model has modest discrimination and is not validated for individual treatment decisions. This public GitHub account identifies the author; use a separately anonymized review resource if needed for double-anonymized peer review.

## Attribution and reuse

Third-party helper licensing is described in `THIRD_PARTY_NOTICE.txt`; the supplied Apache 2.0 text is included. A license for author-owned study code has not yet been assigned. Public visibility does not itself grant unrestricted reuse rights.

AI-assisted tools supported code development, analysis reporting, and writing during the revision. Authors remain responsible for checking scientific content and approving the manuscript.
