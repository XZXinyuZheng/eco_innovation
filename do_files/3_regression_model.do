*****Regression*****
local dir "D:\GU\thesis_data"

cd `dir'

use "data\clean\clean_data.dta", clear

replace size = . if size == 4

recode sector (1 2 3 5 6 7 8 11 13 = 1 "Industry") (4 9 10 12 = 0 "Service"), gen(sector_2)

global y_varlist heating_cooling energy_generation machinery_equipment energy_management vehicles lighting_system energy_efficiency monitor energy_target co2_target

global x_varlist fc f_external state_owned country size sector_2 innovation iso competitor customer cost tax standard

********************************************************************************
**construct denpendent varibale**
********************************************************************************

*****OPTION 1*****

pca $y_varlist

*screeplot

predict pc1, score

*****OPTION 2*****

egen adopt_level = rowtotal($y_varlist)

********************************************************************************
**overall OLS**
********************************************************************************
reg pc1 i.fc, robust
outreg2 using output\table\reg.doc, replace ctitle(Model 1) addtext(Control country, NO)

reg pc1 i.fc i.innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned, robust
outreg2 using output\table\reg.doc, append ctitle(Model 2) addtext(Control country, NO)

reg pc1 i.fc i.innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size, robust
outreg2 using output\table\reg.doc, append ctitle(Model 3) drop(i.country) addtext(Control size, YES, Control sector, NO, Control country, NO)

reg pc1 i.fc i.innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.sector_2, robust
outreg2 using output\table\reg.doc, append ctitle(Model 4) drop(i.country) addtext(Control size, YES, Control sector, YES, Control country, NO)

reg pc1 i.fc i.innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.sector_2 i.country, robust
outreg2 using output\table\reg.doc, append ctitle(Model 5) drop(i.country) addtext(Control size, YES, Control sector, YES, Control country, YES)

********************************************************************************
**OLS by sector**
********************************************************************************
reg pc1 i.fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 0 & size == 1, robust
outreg2 using output\table\reg_sector_size.doc, replace ctitle(Model 1) drop(i.size i.sector i.region i.country) addtext(Control size, YES, Control sector, YES, Control country, YES)

reg pc1 i.fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 0 & size == 2, robust
outreg2 using output\table\reg_sector_size.doc, append ctitle(Model 2) drop(i.size i.sector i.region i.country) addtext(Control size, YES, Control sector, YES, Control country, YES)

reg pc1 i.fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 0 & size == 3, robust
outreg2 using output\table\reg_sector_size.doc, append ctitle(Model 3) drop(i.size i.sector i.region i.country) addtext(Control size, YES, Control sector, YES, Control country, YES)

reg pc1 i.fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 1 & size == 1, robust
outreg2 using output\table\reg_sector_size.doc, append ctitle(Model 4) drop(i.size i.sector i.region i.country) addtext(Control size, YES, Control sector, YES, Control country, YES)

reg pc1 i.fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 1 & size == 2, robust
outreg2 using output\table\reg_sector_size.doc, append ctitle(Model 5) drop(i.size i.sector i.region i.country) addtext(Control size, YES, Control sector, YES, Control country, YES)

reg pc1 i.fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 1 & size == 3, robust
outreg2 using output\table\reg_sector_size.doc, append ctitle(Model 6) drop(i.size i.sector i.region i.country) addtext(Control size, YES, Control sector, YES, Control country, YES)

********************************************************************************
**Robustness check: decompose eco-innovation index**
********************************************************************************
local dir "D:\GU\thesis_data"
* variation in y: decomposite eco-innovation index 
foreach y in $y_varlist {
	reg `y' i.fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 1, robust
	estimates store `y'
}

coefplot $y_varlist, vertical keep(1.fc 2.fc 3.fc 4.fc) yline(0) level(90) ///
rename(fc = "Financial Constraints") ///
p1(label("Heating and cooling improvement")) ///
p2(label("Climate-friendly energy generation")) ///
p3(label("Upgrade machinery equipment")) ///
p4(label("Energy management")) ///
p5(label("Upgrade vehicles")) ///
p6(label("Upgrade lighting system")) ///
p7(label("Improve energy efficiency")) ///
p8(label("Monitor energy consumption")) ///
p9(label("Set energy consumption target")) ///
p10(label("Set CO2 target")) ///
title("The coefficients of financial constraint with 90% of CI" "in regressions of decomposed eco-innovation index in the industry sector", size(4) margin(2)) ///
legend(size(3) region(lcolor(none))) ///
xlabel(, labsize(3)) ylabel(, labsize(3)) ///
plotregion(fcolor(white)) graphregion(fcolor(white))

graph export "`dir'\output\image\robust_y_industry.png", replace

foreach y in $y_varlist {
	reg `y' fc innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.country i.region if sector_2 == 0, robust
	estimates store `y'
}

coefplot $y_varlist, vertical keep(fc) yline(0) level(90) ///
rename(fc = "Financial Constraints") ///
p1(label("Heating and cooling improvement")) ///
p2(label("Climate-friendly energy generation")) ///
p3(label("Upgrade machinery equipment")) ///
p4(label("Energy management")) ///
p5(label("Upgrade vehicles")) ///
p6(label("Upgrade lighting system")) ///
p7(label("Improve energy efficiency")) ///
p8(label("Monitor energy consumption")) ///
p9(label("Set energy consumption target")) ///
p10(label("Set CO2 target")) ///
title("The coefficients of financial constraint with 90% of CI" "in regressions of decomposed eco-innovation index in the service sector", size(4) margin(2)) ///
legend(size(3) region(lcolor(none))) ///
xlabel(, labsize(3)) ylabel(, labsize(3)) ///
plotregion(fcolor(white)) graphregion(fcolor(white))

graph export "`dir'\output\image\robust_y_service.png", replace

********************************************************************************
**Robustness check: different measure of financial constraints**
********************************************************************************
reg f_external i.fc, robust

********************************************************************************
**Robustness check: across countries**
********************************************************************************

********************************************************************************
**Threat to inference**
********************************************************************************







