# Databricks notebook source
# /*start-header
################################################################################
# Type of File     : R
#
# Program Name     : 147a_primary_analyses.R
#			
# Program Path     : sasCCW\DUA_FOLDER\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 01Sep2026	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Primary analyses for paper - Aim 1
#
# Input files      : all_storms_first_elig
#
# Output file      : 
#
#################################################################################
# end-header*/

# COMMAND ----------

library(haven)
library(survival)
library(readxl)
# COMMAND ----------
cohort <- read_excel("PATH/all_storms_first_elig.xlsx"
    , sheet=1 
    , col_names=TRUE
    , na=c("", ".")
) |> as.data.frame()
print(head(cohort))
print(str(cohort))
# COMMAND ----------
cohort$cod_factor <- factor(cohort$cod
    , levels = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    , labels = c("censored", "ADRD", "Cardiovascular Disease", "Cerebrovascular disease", "Cancer", "Pneumonia", "Chronic Resp Disease", "Genitour. diseases", "Gastroint. diseases", "Injuries", "All Other")
)
cohort$death_post_ndi <- ifelse(cohort$cod == 0, 0, 1)
cohort$sex_factor <- factor(cohort$male
    , levels = c(0, 1)
    , labels = c("Female", "Male")
)
cohort$race4c_factor <- factor(cohort$race4c
    , levels = c(1, 2, 3, 4)
    , labels = c("NH White", "NH Black", "Hispanic", "Other")
)
cohort$ffs_pre_factor <- factor(cohort$ffs_pre
    , levels = c(0, 1)
    , labels = c("MA", "FFS")
)
cohort$dual_pre_factor <- factor(cohort$dual_pre
    , levels = c(0, 1, 99)
    , labels = c("No Dual", "Dual", "Dual Elig NA")
)
cohort$ruca3cat_factor <- factor(cohort$ruca3cat
    , levels = c(1, 2, 3)
    , labels = c("Metropolitan", "Micropolitan", "Small town/Rural")
)
cohort$exposure_factor <- factor(cohort$high_rain_by_wind_tim
    , levels = c(0, 1)
    , labels = c("Unexposed", "Exposed")
)
# COMMAND ----------
tab <- table(cohort$cod, cohort$death_post_ndi, useNA= "ifany")
prop.table(tab, margin = 1) * 100
# COMMAND ----------
print(head(cohort))
print(str(cohort))

# COMMAND ----------
fit_unadj <- coxph(
    Surv(days_follow_up, death_post_ndi) ~ exposure_factor + frailty(zip_year, distribution = "gaussian")
    , data = cohort
)
fit_adj <- coxph(
    Surv(days_follow_up, death_post_ndi) ~ exposure_factor + age + sex_factor + race4c_factor + cfi_score_no_adrd + dual_pre_factor + ffs_pre_factor + ruca3cat_factor + frailty(zip_year, distribution = "gaussian")
    , data = cohort
)
print("Unadjusted Results overall mortality:")
print(summary(fit_unadj))
print("Adjusted Results overall mortality:")
print(summary(fit_adj))
# COMMAND ----------

cod_cat <- c("ADRD", "Cardiovascular Disease", "Cerebrovascular disease", "Cancer", "Pneumonia", "Chronic Resp Disease", "Genitour. diseases", "Gastroint. diseases", "Injuries", "All Other")
for (i in seq_along(cod_cat)) {
    cod=cod_cat[i]
    fg_data <- finegray(Surv(days_follow_up, cod_factor) ~., data=cohort, etype=cod)
    fit_fg_unadj <- coxph(
        Surv(fgstart, fgstop, fgstatus) ~ exposure_factor + frailty(zip_year, distribution = "gaussian")
        , data = fg_data
    )
    fit_fg_adj <- coxph(
        Surv(fgstart, fgstop, fgstatus) ~ exposure_factor + age + sex_factor + race4c_factor + cfi_score_no_adrd + dual_pre_factor + ffs_pre_factor + ruca3cat_factor + frailty(zip_year, distribution = "gaussian")
        , data = fg_data
    )
    print(paste("Unadjusted Results for COD:", cod))
    print(summary(fit_fg_unadj))
    print(paste("Adjusted Results for COD:", cod))
    print(summary(fit_fg_adj))
}

# Databricks notebook source
# /*start-header
################################################################################
# Type of File     : R
#
# Program Name     : 148a_sensitivity_analyses_psmatch.R
#			
# Program Path     : sasCCW\DUA_FOLDER\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 01Sep2026	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Primary analyses for paper - Aim 1
#
# Input files      : all_storms_first_elig_matched
#
# Output file      : 
#
#################################################################################
# end-header*/
library(haven)
library(survival)
library(readxl)
# COMMAND ----------
cohort <- read_excel("PATH/all_storms_first_elig_matched.xlsx"
    , sheet=1 
    , col_names=TRUE
    , na=c("", ".")
) |> as.data.frame()
print(head(cohort))
print(str(cohort))
# COMMAND ----------
cohort$cod_factor <- factor(cohort$cod
    , levels = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    , labels = c("censored", "ADRD", "Cardiovascular Disease", "Cerebrovascular disease", "Cancer", "Pneumonia", "Chronic Resp Disease", "Genitour. diseases", "Gastroint. diseases", "Injuries", "All Other")
)
cohort$death_post_ndi <- ifelse(cohort$cod == 0, 0, 1)
cohort$sex_factor <- factor(cohort$male
    , levels = c(0, 1)
    , labels = c("Female", "Male")
)
cohort$race4c_factor <- factor(cohort$race4c
    , levels = c(1, 2, 3, 4)
    , labels = c("NH White", "NH Black", "Hispanic", "Other")
)
cohort$ffs_pre_factor <- factor(cohort$ffs_pre
    , levels = c(0, 1)
    , labels = c("MA", "FFS")
)
cohort$dual_pre_factor <- factor(cohort$dual_pre
    , levels = c(0, 1, 99)
    , labels = c("No Dual", "Dual", "Dual Elig NA")
)
cohort$ruca3cat_factor <- factor(cohort$ruca3cat
    , levels = c(1, 2, 3)
    , labels = c("Metropolitan", "Micropolitan", "Small town/Rural")
)
cohort$exposure_factor <- factor(cohort$high_rain_by_wind_tim
    , levels = c(0, 1)
    , labels = c("Unexposed", "Exposed")
)
# COMMAND ----------
tab <- table(cohort$cod, cohort$death_post_ndi, useNA= "ifany")
prop.table(tab, margin = 1) * 100
# COMMAND ----------
print(head(cohort))
print(str(cohort))

# COMMAND ----------
fit_unadj <- coxph(
    Surv(days_follow_up, death_post_ndi) ~ exposure_factor + frailty(zip_year, distribution = "gaussian")
    , data = cohort
)
fit_adj <- coxph(
    Surv(days_follow_up, death_post_ndi) ~ exposure_factor + age + sex_factor + race4c_factor + cfi_score_no_adrd + dual_pre_factor + ffs_pre_factor + ruca3cat_factor + frailty(zip_year, distribution = "gaussian")
    , data = cohort
)
print("Unadjusted Results overall mortality:")
print(summary(fit_unadj))
print("Adjusted Results overall mortality:")
print(summary(fit_adj))
# COMMAND ----------

cod_cat <- c("ADRD", "Cardiovascular Disease", "Cerebrovascular disease", "Cancer", "Pneumonia", "Chronic Resp Disease", "Genitour. diseases", "Gastroint. diseases", "Injuries", "All Other")
for (i in seq_along(cod_cat)) {
    cod=cod_cat[i]
    fg_data <- finegray(Surv(days_follow_up, cod_factor) ~., data=cohort, etype=cod)
    fit_fg_unadj <- coxph(
        Surv(fgstart, fgstop, fgstatus) ~ exposure_factor + frailty(zip_year, distribution = "gaussian")
        , data = fg_data
    )
    fit_fg_adj <- coxph(
        Surv(fgstart, fgstop, fgstatus) ~ exposure_factor + age + sex_factor + race4c_factor + cfi_score_no_adrd + dual_pre_factor + ffs_pre_factor + ruca3cat_factor + frailty(zip_year, distribution = "gaussian")
        , data = fg_data
    )
    print(paste("Unadjusted Results for COD:", cod))
    print(summary(fit_fg_unadj))
    print(paste("Adjusted Results for COD:", cod))
    print(summary(fit_fg_adj))
}

# Databricks notebook source
# /*start-header
################################################################################
# Type of File     : R
#
# Program Name     : 148b_sensitivity_analyses_3mo.R
#			
# Program Path     : sasCCW\DUA_FOLDER\code
#
# Programmed By    : Jonathan Martindale
#
# Date Created     : 01Sep2026	
#
# Project Title    : Bell-Davis RF1
#
# Purpose          : Primary analyses for paper - Aim 1
#
# Input files      : all_storms_first_elig_3mo
#
# Output file      : 
#
#################################################################################
# end-header*/
library(haven)
library(survival)
library(readxl)
# COMMAND ----------
cohort <- read_excel("PATH/all_storms_first_elig_3mo.xlsx"
    , sheet=1 
    , col_names=TRUE
    , na=c("", ".")
) |> as.data.frame()
print(head(cohort))
print(str(cohort))
# COMMAND ----------
cohort$cod_factor <- factor(cohort$cod
    , levels = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    , labels = c("censored", "ADRD", "Cardiovascular Disease", "Cerebrovascular disease", "Cancer", "Pneumonia", "Chronic Resp Disease", "Genitour. diseases", "Gastroint. diseases", "Injuries", "All Other")
)
cohort$death_post_ndi <- ifelse(cohort$cod == 0, 0, 1)
cohort$sex_factor <- factor(cohort$male
    , levels = c(0, 1)
    , labels = c("Female", "Male")
)
cohort$race4c_factor <- factor(cohort$race4c
    , levels = c(1, 2, 3, 4)
    , labels = c("NH White", "NH Black", "Hispanic", "Other")
)
cohort$ffs_pre_factor <- factor(cohort$ffs_pre
    , levels = c(0, 1)
    , labels = c("MA", "FFS")
)
cohort$dual_pre_factor <- factor(cohort$dual_pre
    , levels = c(0, 1, 99)
    , labels = c("No Dual", "Dual", "Dual Elig NA")
)
cohort$ruca3cat_factor <- factor(cohort$ruca3cat
    , levels = c(1, 2, 3)
    , labels = c("Metropolitan", "Micropolitan", "Small town/Rural")
)
cohort$exposure_factor <- factor(cohort$high_rain_by_wind_tim
    , levels = c(0, 1)
    , labels = c("Unexposed", "Exposed")
)
# COMMAND ----------
tab <- table(cohort$cod, cohort$death_post_ndi, useNA= "ifany")
prop.table(tab, margin = 1) * 100
# COMMAND ----------
print(head(cohort))
print(str(cohort))
# COMMAND ----------
fit_unadj <- coxph(
    Surv(days_follow_up, death_post_ndi) ~ exposure_factor + frailty(zip_year, distribution = "gaussian")
    , data = cohort
)
fit_adj <- coxph(
    Surv(days_follow_up, death_post_ndi) ~ exposure_factor + age + sex_factor + race4c_factor + cfi_score_no_adrd + dual_pre_factor + ffs_pre_factor + ruca3cat_factor + frailty(zip_year, distribution = "gaussian")
    , data = cohort
)
print("Unadjusted Results overall mortality:")
print(summary(fit_unadj))
print("Adjusted Results overall mortality:")
print(summary(fit_adj))
# COMMAND ----------
cod_cat <- c("ADRD", "Cardiovascular Disease", "Cerebrovascular disease", "Cancer", "Pneumonia", "Chronic Resp Disease", "Genitour. diseases", "Gastroint. diseases", "Injuries", "All Other")
for (i in seq_along(cod_cat)) {
    cod=cod_cat[i]
    fg_data <- finegray(Surv(days_follow_up, cod_factor) ~., data=cohort, etype=cod)
    fit_fg_unadj <- coxph(
        Surv(fgstart, fgstop, fgstatus) ~ exposure_factor + frailty(zip_year, distribution = "gaussian")
        , data = fg_data
    )
    fit_fg_adj <- coxph(
        Surv(fgstart, fgstop, fgstatus) ~ exposure_factor + age + sex_factor + race4c_factor + cfi_score_no_adrd + dual_pre_factor + ffs_pre_factor + ruca3cat_factor + frailty(zip_year, distribution = "gaussian")
        , data = fg_data
    )
    print(paste("Unadjusted Results for COD:", cod))
    print(summary(fit_fg_unadj))
    print(paste("Adjusted Results for COD:", cod))
    print(summary(fit_fg_adj))
}
