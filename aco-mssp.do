clear all
import excel using "...\Exhibit 1.xlsx", firstrow

*exclude ACOs that did not successfully report on quality in 2013 b/c of incomplete quality data
*drop if SuccessfullyReportedQuality == "No - 2013"

*exclude Golden Life Accountable Care Organization
*drop if ACONameLBNorDBAifapplica == "Golden Life Accountable Care Organization (ACO)"

*Variable construction
*Fixing SharedSavingsResults -> converting to string
gen SharedSavingsResults_num = 3 if SharedSavingsResults == "Earned $"
replace SharedSavingsResults_num = 2 if SharedSavingsResults == "Neutral"
replace SharedSavingsResults_num = 1 if SharedSavingsResults == "Lost $"
capture label drop ssrlab
label define ssrlab 1 "Lost $" 2 "Neutral" 3 "Earned $"
label value SharedSavingsResults_num ssrlab

*Fixing Track -> converting to string
gen Track_num = 1 if Track == "Track1"
replace Track_num = 2 if Track == "Track2 "

*log transfoming PCB and MSR

gen logpcb = log(PerCapitaBenchmark)
graph box logpcb, by(GeneratedSavingsGSRMSR)

gen logmsr = log(MSRcalculatedTrack2adjust)
graph box logmsr, by(GeneratedSavingsGSRMSR)

log using "...\Table_1.statalog", replace text

tab AgreementStartDate GeneratedSavingsGSRMSR, nocol chi2

tab Track GeneratedSavingsGSRMSR, nocol chi2

*Used chi2 because not normal

tab TotalAssignedBeneficiaryCateg GeneratedSavingsGSRMSR, nocol chi2

tab PerCapitaBenchmarkCategory GeneratedSavingsGSRMSR, nocol chi2

*Per capita benchmark continuous analysis

histogram PerCapitaBenchmark
ttest PerCapitaBenchmark, by(GeneratedSavingsGSRMSR)
anova PerCapitaBenchmark GeneratedSavingsGSRMSR

tab PerCapitaTotalExpendituresCa GeneratedSavingsGSRMSR, nocol chi2

tab SharedSavingsResults_num GeneratedSavingsGSRMSR, nocol exact

tab SuccessfullyReportedQuality GeneratedSavingsGSRMSR, nocol exact

*final quality score - of those who successfully reported quality, was there a significant difference in terms of final quality score between those who generated savings or not

histogram FinalQualityScore if SuccessfullyReportedQuality=="Yes"

ttest FinalQualityScore if SuccessfullyReportedQuality=="Yes", by(GeneratedSavingsGSRMSR)

anova  FinalQualityScore GeneratedSavingsGSRMSR  if SuccessfullyReportedQuality=="Yes"

*new variable for quality score

univar FinalQualityScore

xtile qualitycat = FinalQualityScore, nquantiles(4)

tab qualitycat GeneratedSavingsGSRMSR, chi2

gen quality_cat = FinalQualityScore
recode quality_cat (min/0.669 = 1) (0.67/0.749 =2) (0.75/0.7999 =3) (0.80/0.919 =4)
capture label drop age_catlab
label define quality_catlab 1 "26%-66%" 2 "67%-74%" 3 "75%-79%" 4 "80%-91%"
label value quality_cat quality_catlab

tab quality_cat GeneratedSavingsGSRMSR, col chi2

univar FinalQualityScore if GeneratedSavingsGSRMSR==1
univar FinalQualityScore if GeneratedSavingsGSRMSR==0

*Regression #1

logistic GeneratedSavingsGSRMSR logpcb 

logistic GeneratedSavingsGSRMSR logpcb i.AgreementStartDate TotalAssignedBeneficiaries PerCapitaExpenditures i.SharedSavingsResults_num

logistic GeneratedSavingsGSRMSR logpcb i.AgreementStartDate TotalAssignedBeneficiaries PerCapitaExpenditures

*Regression #1 - final model

logistic GeneratedSavingsGSRMSR logpcb i.AgreementStartDate TotalAssignedBeneficiaries

*Regression #2

logistic GeneratedSavingsGSRMSR logmsr i.AgreementStartDate TotalAssignedBeneficiaries PerCapitaExpenditures i.SharedSavingsResults_num

logistic GeneratedSavingsGSRMSR logmsr i.AgreementStartDate TotalAssignedBeneficiaries PerCapitaExpenditures

*Regression #2 - final model

logistic GeneratedSavingsGSRMSR logmsr TotalAssignedBeneficiaries PerCapitaExpenditures

*Regression #3

logistic GeneratedSavingsGSRMSR FinalQualityScore i.AgreementStartDate TotalAssignedBeneficiaries PerCapitaExpenditures i.SharedSavingsResults_num

*Regression #3 - final model

logistic GeneratedSavingsGSRMSR FinalQualityScore TotalAssignedBeneficiaries PerCapitaExpenditures



log close

*reconstructed initial regressions:
*logistic GeneratedSavingsGSRMSR logpcb logmsr

*logistic GeneratedSavingsGSRMSR logpcb i.Track_num

*logistic GeneratedSavingsGSRMSR FinalQualityScore
