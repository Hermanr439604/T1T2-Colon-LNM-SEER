# 结肠癌 LNM 完整分析代码包 V3.3

这是拟公开的代码与聚合结果资源。包中没有患者级原始数据、RDS、标识字段或个体预测。代码只能在获得合法 SEER 数据访问权限后复现；登记数据原件不应上传仓库。本包尚未发布，公开仓库 URL、版本及代码许可仍需作者落实。

## 在 RStudio 中使用

解压后打开 Colon_LNM_V3_3.Rproj，工作目录即代码包根目录。安装依赖后，可在 RStudio Terminal 运行下面的入口。也可在系统终端调用 Rscript。运行过程以文字进度显示，不要求 RStudio 图形窗口处于运行状态。

已有作者本地分析根目录时，使用 RUN_V3_3.R。它需要 02_clean_data 下的最终队列 RDS、08_models 下的原主模型 RDS，以及 01_raw_data 下用于完整病例对照的 renamed raw RDS。输入文件名称由脚本明确指定。结果写入新空目录，不覆盖原结果。

```
Rscript RUN_V3_3.R /path/to/author-held/Outputs_V3_0 /path/to/new-empty-output
```

该入口运行主模型和 2022 评价复现、缺失筛选对照、固定系数核对、1,000 次 bootstrap、10 轮五折交叉验证、独立指标核对及主图 2 和 3 的重建。Figure 1 是原队列流程图，原绘图代码在历史完整主流程中。图形检查另需 Python 3。全部运行需要数分钟或更久，取决于电脑性能。

若只有原始 SEER CSV，RUN_FROM_RAW_TO_V3_3.R 可先调用保存的 V2.2 主流程重建队列，再调用上述入口。该适配入口已作语法与路径配置检查，但本轮没有把历史全流程从原始 CSV 再运行一遍；勿把它视为已验证的端到端提取复现。旧主流程可能安装缺失依赖，执行前应检查。

```
Rscript RUN_FROM_RAW_TO_V3_3.R /path/to/authorized/SEER_export.csv /path/to/new-empty-output
```

## 结果对应关系

Aggregate_Results_Previous 保存已复现的 2022、T1/T2、逐年训练内结点、筛选对照、全精度系数及绘图聚合结果。Aggregate_Results_V3_3 保存当前 S16-S19、每次 bootstrap 的模型级指标和结点、各轮 CV 指标与选择频率、收敛及独立指标核查。analysis_plan.md 为新分析前记录的方案，种子为 20261015 和 20261016。Monte Carlo SE 衡量模拟误差，不是总体置信区间；CV 范围衡量划分变化。

## 历史代码与当前分析

Original_V2_2_Code_Archive 和 Original_V3_0_Code_Archive 保存完整历史 R 代码及说明，以供追溯。旧代码中的 prespecified 标注、固定结点滚动分析和旧 bootstrap 不作为新版历史预设性的证据。当前滚动和内部验证入口以根目录新脚本为准。S6/S3 旧 bootstrap、PNI、敏感性与阈值结果保留为历史结果；原 PNI/敏感性全流程和上游 SEER*Stat 提取本轮没有独立重跑。原始提取 session 尚待作者提供。

## 依赖和共享

当前已运行分析使用 R 4.5.1；确切包版本见两组结果各自的 sessionInfo.txt。主依赖为 rms、Hmisc、pROC、dplyr、readr、stringr、ggplot2、patchwork、ragg、svglite、jsonlite。历史代码另需 tidyr、forcats、tableone、broom、openxlsx、scales 等，详见脚本和历史 sessionInfo。不要声称存在未生成的 renv.lock。

建议将本目录发布到 GitHub 并冻结版本，再用 Zenodo 建立 DOI；当前没有创建仓库或 DOI。确认代码著作权与许可后再发布。SEER 访问入口为 https://seer.cancer.gov/data/，原始数据共享须遵循对应数据使用协议。所有研究解释、AI 使用声明和最终代码由署名作者审核负责。
