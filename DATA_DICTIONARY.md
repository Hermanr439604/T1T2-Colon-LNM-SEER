# Source variable and result dictionary

Source cohort fields required by supplemental validation: year_dx (diagnosis year, development restricted to 2018-2021), age (years, 90+ coded as 90), tumor_size_mm (1-150 mm), lnm_num (0/1 from positive regional nodes), site_group, histology_group, grade_group, t_stage, race_group, and patient_id (local uniqueness audit only). No source rows are supplied.

Categorical references: Right-sided colon; Adenocarcinoma; Well/moderately differentiated; T1; White for the race-inclusive candidate. Site additionally Left-sided colon and Overlapping/NOS. Histology additionally Mucinous adenocarcinoma and Signet-ring cell carcinoma. Grade additionally Poorly/undifferentiated. Race additionally Black, Asian or Pacific Islander, American Indian/Alaska Native, Unknown. Source factor levels and order are retained and matrix rank is verified.

Aggregate Repeat identifies a computational resample or split repetition, never a patient. Bootstrap Apparent is performance in the resample; Original is performance in the original development cohort; Optimism = Apparent - Original. Corrected subtracts mean optimism from full-development apparent performance. Predictor_df excludes intercept. AIC includes the intercept parameter. CV Minimum/Maximum are across ten repeated splits, not uncertainty limits. Calibration_intercept is an offset logistic intercept; Calibration_slope estimates an intercept and coefficient of prediction logit. AUC is rank-based and verified against pROC; Brier is mean squared probability error.

No patient-level synthetic replacement is included. The hypothetical scoring examples are clearly labeled computational profiles, not observations.
