### Overview

This repository consists of codes to replicate the empirical analysis in my working thesis "The Effect of Financial Constraints on Firms’ Development and Adoption of Eco-innovation in Developing Countries."

### Repo structure

* data:
  - raw: raw data of the 2019 World Bank Enterprise Survey from 27 developing countries in central Asia and eastern Euroap
  - medium: processed data with problems fixed for appending 
  - clean: appended data with newly generated, recorded, and relabeled variables of select
* do_files:
  - 0_medium_data.do: the do file to generate medium data
  - 1_clean_data.do: the do file to generate clean data
  - 2_descriptive_analysis.do: the do file to perform descriptive analysis
  - 3_regression_model.do: the do file to run regressions, check robustness, and discuss inferential threats
  - test_append_WBES.do: the do file to append Enterprise data without pre-select variables
  - test_regression_model_with_weight.do: the do file to discuss the necessity of including sampling weights in the regression
* output:
  - image: images of descriptive analysis or robustness check
  - table: tables of regression results

**Important Note: This repo is meant to present the codes of analysis and research project management. Althrough this repo consists of a data folder, it is empty to protect data confidentiality in accordance with World Bank rules governing “strictly confidential” information. To access the raw datasets, please register with the Enterprise Analysis Unit (DECEA) by completing [the Enterprise Surveys Data Access Protocol](https://login.enterprisesurveys.org/content/sites/financeandprivatesector/en/signup.html).**