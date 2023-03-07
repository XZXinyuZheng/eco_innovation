*****Regression*****
********************************************************************************
**setup**
********************************************************************************

global dir "D:\GU\thesis_data"

cd "$dir"

use "$dir\data\clean\clean_data.dta", clear

*replace size = . if size == 4

*recode sector (1 2 3 5 6 7 8 11 13 = 1 "Manufacturing") (4 9 10 12 = 0 "Service"), gen(sector2)

*recode sector (1 2 4/8 11/19 22 23 26 28 = 0 "Manufacturing") (3 = 1 "Construction") (9 20 21 27 = 2 "Service") (24 25 = 3 "Transportation") (10 = 4 "IT"), gen(sector3)

/*
	   decode country, gen(country_string)
	   drop country
	   encode country_string, gen(country)
	   drop country_string
*/

gen fc_s = .
replace fc_s = 1 if fc == 4
replace fc_s = 0 if inlist(fc, 0, 1, 2, 3)

gen fc_ms = .
replace fc_ms = 1 if inlist(fc, 3, 4)
replace fc_ms = 0 if inlist(fc, 0, 1, 2)

/*
	   gen fc_mms = .
	   replace fc_mms = 1 if inlist(fc, 2, 3, 4)
	   replace fc_mms = 0 if inlist(fc, 0, 1)

	   gen fc_mmms = .
	   replace fc_mmms = 1 if inlist(fc, 1, 2, 3, 4)
	   replace fc_mmms = 0 if inlist(fc, 0)
*/

gen competitor_log = log(competitor + 1)

gen cost_sale_log = log(cost_sale)

global y_varlist heating_cooling energy_generation machinery_equipment energy_management vehicles lighting_system energy_efficiency

global c_varlist innovation i.iso competitor_log i.customer cost_sale_log i.tax i.standard f_external

*egen nmcount = rownonmiss($y_varlist fc innovation iso competitor_log customer cost_sale tax standard f_external sector_specific size country)
*tab nmcount
*drop if nmcount < 19
* Question:  electricity fee is zero? competitor is zero?

********************************************************************************
**sampling weight**
********************************************************************************

gen reweight = .

levelsof country, local(country)

foreach c in `country' {
	sum wmedian if country == `c'
	replace reweight = wmedian / r(sum) if country == `c'
}

replace reweight = reweight * (1/27)

egen strata = group(region sector size)

svyset idstd [pweight = reweight], strata(strata) singleunit(centered)

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
**OLS: very sever**
********************************************************************************

reg pc1 i.fc_s $c_varlist i.size, robust
outreg2 using output\table\severe.doc, replace keep(i.fc_s) addtext(Control variables, Yes, Sector FE, No, Country FE, No) adjr2 nocons

reg pc1 i.fc_s $c_varlist i.size i.sector2, robust
outreg2 using output\table\severe.doc, append keep(i.fc_s) addtext(Control variables, Yes, Sector FE, Yes, Country FE, No) adjr2 nocons

*reg pc1 i.fc_s $c_varlist i.size i.sector2 i.region, robust
*outreg2 using output\table\severe.doc, append ctitle(pc1) drop(i.size i.sector2 i.region) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, NO)

reg pc1 i.fc_s $c_varlist i.size i.sector2 i.country, robust
outreg2 using output\table\severe.doc, append keep(i.fc_s) addtext(Control variables, Yes, Sector FE, Yes, Country FE, Yes) adjr2 nocons


********************************************************************************
**OLS by sector: very severe**
********************************************************************************

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		reg pc1 i.fc_s $c_varlist i.country if sector2 == `sector' & size == `size', robust
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\severe_sector_size.doc, replace ctitle("PC1", "`sector'|`size'") keep(i.fc_s) addtext(Control variables, Yes, Country FE, Yes) adjr2 nocons
		} 
		else {
			outreg2 using output\table\severe_sector_size.doc, append ctitle("PC1", "`sector'|`size'") keep(i.fc_s) addtext(Control variables, Yes, Country FE, Yes) adjr2 nocons
		}
	}
}

********************************************************************************
**Robustness check of OLS by sector: major and very severe**
********************************************************************************

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		reg pc1 i.fc_ms $c_varlist i.country if sector2 == `sector' & size == `size', robust
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\major_severe_sector_size.doc, replace ctitle("PC1", "`sector'|`size'") keep(i.fc_ms) addtext(Control variables, Yes, Country FE, Yes) adjr2 nocons
		} 
		else {
			outreg2 using output\table\major_severe_sector_size.doc, append ctitle("PC1", "`sector'|`size'") keep(i.fc_ms) addtext(Control variables, Yes, Country FE, Yes) adjr2 nocons
		}
	}
}

********************************************************************************
**Threat to inference: IV**
********************************************************************************
*heating_cooling energy_generation machinery_equipment energy_management vehicles lighting_system energy_efficiency

***OPTION 1: financial constraints***
bysort region sector: egen iv1 = mean(fc)

***OPTION 2: external funds: SECTOR LEVEL FINANCE FROM EXTERNAL SOURCES CORRELATE TO PC1
bysort country region: egen iv2 = mean(f_external)

***OPTION 3: outstanding loads: NO FEW OBSERVATIONS, BIAS
bysort country sector: egen iv3 = mean(amount_loan)
gen iv3_log = log(iv3)

bysort country sector: egen iv4 = mean(number_load)
gen iv4_log = log(iv4)

* 2sls regressions
ivregress 2sls pc1 $c_varlist i.size i.country i.sector2 (fc_s = iv1), first vce(robust) // do not include sector, region, and country fixed effects as they will control for iv3

* very severe: by sector2 and size
forvalues sector = 0/2 {
	forvalues size = 0/2 {
		ivregress 2sls pc1 $c_varlist i.country (fc_s = iv1) if sector2 == `sector' & size == `size', first vce(robust)
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\iv_severe_sector_size.doc, replace ctitle("PC1", "`sector'|`size'") addtext(Control country, YES) keep(fc_s) nocons
		} 
		else {
			outreg2 using output\table\iv_severe_sector_size.doc, append ctitle("PC1", "`sector'|`size'") addtext(Control country, YES) keep(fc_s) nocons
		}
	}
}

/*
	   forvalues sector = 0/4 {
	   forvalues size = 0/2 {
	   *ivregress 2sls pc1 $c_varlist i.country (fc_s = iv1) if sector3 == `sector' & size == `size', first vce(robust)
	   regress pc1 fc_s $c_varlist i.country if sector3 == `sector' & size == `size', robust
	   if `sector' == 0 & `size' == 0 {
	   outreg2 using output\table\iv_severe_sector_size.doc, replace ctitle("PC1", "`sector'|`size'") addtext(Control country, YES) keep(fc_s) nocons
	   } 
	   else {
	   outreg2 using output\table\iv_severe_sector_size.doc, append ctitle("PC1", "`sector'|`size'") addtext(Control country, YES) keep(fc_s) nocons
	   }
	   }
	   }

	   forvalues i = 1/7 {
	   local y: word `i' of $y_varlist
	   ivregress 2sls `y' $c_varlist i.size i.country (fc_s = iv1) if sector3 == 1, first vce(robust)
	   if `i' == 1 {
	   outreg2 using output\table\iv_severe_sector_size.doc, replace ctitle("PC1", "`sector'") addtext(Control country, YES) keep(fc_s) nocons
	   } 
	   else {
	   outreg2 using output\table\iv_severe_sector_size.doc, append ctitle("PC1", "`sector'") addtext(Control country, YES) keep(fc_s) nocons
	   }
	   }
*/

* fc: by sector2 and size
forvalues sector = 0/2 {
	forvalues size = 0/2 {
		ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if sector2 == `sector' & size == `size', first vce(robust)
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\iv_fc_sector_size.doc, replace ctitle("PC1", "`sector'|`size'") addtext(Control country, YES) keep(fc) nocons
		} 
		else {
			outreg2 using output\table\iv_fc_sector_size.doc, append ctitle("PC1", "`sector'|`size'") addtext(Control country, YES) keep(fc) nocons
		}
	}
}

********************************************************************************
**Robustness check: decompose eco-innovation index**
********************************************************************************

/* very severe
	   reg heating_cooling i.fc_s $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg.doc, replace ctitle(Model 1) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg energy_generation i.fc_s $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg.doc, append ctitle(Model 2) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg machinery_equipment i.fc_s $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg.doc, append ctitle(Model 3) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg energy_management i.fc_s $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg.doc, append ctitle(Model 4) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg vehicles i.fc_s $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg.doc, append ctitle(Model 5) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg lighting_system i.fc_s $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg.doc, append ctitle(Model 6) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg energy_efficiency i.fc_s $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg.doc, append ctitle(Model 7) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)
*/

/* major and very severe
	   reg heating_cooling i.fc_ms $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg_major_severe.doc, replace ctitle(Model 1) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg energy_generation i.fc_ms $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg_major_severe.doc, append ctitle(Model 2) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg machinery_equipment i.fc_ms $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg_major_severe.doc, append ctitle(Model 3) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg energy_management i.fc_ms $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg_major_severe.doc, append ctitle(Model 4) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg vehicles i.fc_ms $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg_major_severe.doc, append ctitle(Model 5) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg lighting_system i.fc_ms $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg_major_severe.doc, append ctitle(Model 6) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)

	   reg energy_efficiency i.fc_ms $c_varlist i.size i.sector_2 i.region i.country, robust
	   outreg2 using output\table\reg_major_severe.doc, append ctitle(Model 7) drop(i.size i.sector_2 i.region i.country) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, YES)
*/

* for very severe financial constraints: decomposite eco-innovation index 

egen upgrade = rowtotal(heating_cooling machinery_equipment lighting_system vehicles)
egen management = rowtotal(energy_efficiency energy_management)

forvalues s = 0/2 {
	local model_ind_`s'
	local model_ser_`s'
	foreach y in energy_generation upgrade management {
		reg `y' i.fc_s $c_varlist i.country if sector2 == 0 & size == `s', robust
		*ivregress 2sls `y' $c_varlist i.country (fc_ms = iv1) if sector2 == 1 & size == `s', first vce(robust)
		estimates store `y'_ind_`s'
		local model_ind_`s' `model_ind_`s'' `y'_ind_`s'
		reg `y' i.fc_s $c_varlist i.country if sector2 == 1 & size == `s', robust
		*ivregress 2sls `y' $c_varlist i.country (fc_ms = iv1) if sector2 == 0 & size == `s', first vce(robust)
		estimates store `y'_ser_`s'
		local model_ser_`s' `model_ser_`s'' `y'_ser_`s'
	}
}

coefplot `model_ind_0', bylabel(Industry | Small) ///
	|| `model_ind_1', bylabel(Industry | Medium) ///
	|| `model_ind_2', bylabel(Industry | Large) ///
	|| `model_ser_0', bylabel(Service | Small) ///
	|| `model_ser_1', bylabel(Service | Medium) ///
	|| `model_ser_2', bylabel(Service | Large) ///
	||, keep(1.fc_s) xline(0) level(90) ///
	rename(1.fc_s = "Very severe") ///
	p1(label("Climate-friendly energy generation")) ///
	p2(label("Upgrade heating and cooling system, machinery and equipment, lighting system, and vehicles")) ///
	p3(label("Energy management and energy efficiency improving")) ///
	byopts(title("The coefficients of financial constraint with 90% of CI" "in regressions of decomposed eco-innovation index", size(4) margin(2))) ///
	legend(size(3) region(lcolor(none)) row(3)) ///
	xlabel(, labsize(3)) ylabel(, labsize(3)) ///
	plotregion(fcolor(white)) graphregion(fcolor(white))

graph export "$dir\output\image\robust_y_decompose.png", replace

********************************************************************************
**Understand why large manumacturing firms are significant**
********************************************************************************

levelsof sector_specific, local(sector)

*bysort sector_specific size: egen count = count(country)
*replace count = . if nmcount < 19


forvalue i = 0/2 {
	foreach s in `sector' {
		qui count if sector_specific == `s' & size == `i'
        local n = r(N)
        if `n' >= 30 {
			rename * *_`i'_`s'
			eststo reg_`i'_`s': reg pc1 i.fc_s $c_varlist i.size i.country if sector_specific == `s' & size == `i', robust
			rename *_`i'_`s' *
			*estimates store model_`s'
		}
	}
} 

coefplot reg_2_* ///
, keep(1.fc_s_*) drop(1.fc_s_2_26) sort xline(0) level(90) legend(off) byopts(xrescale) ///
	xtitle("Very Severe Financial Constraints", size(2)) ///
	title("The coefficients of financial constraint with 90% of CI by sector", size(3) margin(2)) ///
	xlabel(, labsize(2)) ///
	plotregion(fcolor(white)) graphregion(fcolor(white))

	*drop(1.fc_s_2_26) drop(1.fc_s_1_11)

********************************************************************************
**Robustness check: across countries**
********************************************************************************
levelsof country, local(country)

foreach c in `country' {
	rename * *_`c'
	eststo reg_`c': reg pc1 i.fc_s $c_varlist i.size i.sector2 if country == `c', robust
	rename *_`c' *
	*estimates store model_`c'
}

coefplot reg_*, ///
	keep(1.fc_s_*) sort xline(0) level(90) legend(off) ///
	xtitle("Very Severe Financial Constraints", size(2)) ///
	title("The coefficients of financial constraint with 90% of CI by country", size(3) margin(2)) ///
	xlabel(, labsize(2)) ///
	coeflabels(1.fc_s_1 = "Albania" 1.fc_s_2 = "Azerbaijan" 1.fc_s_3 = "Bosnia and Herzegovina" 1.fc_s_4 = "Bulgaria" 1.fc_s_5 = "Croatia" 1.fc_s_6 = "Cyprus" 1.fc_s_7 = "Estonia" 1.fc_s_8 = "Georgia" 1.fc_s_9 = "Jordan" 1.fc_s_10 = "Kazakhstan" 1.fc_s_11 = "Kosovo" 1.fc_s_12 = "Kyrgyz Republic" 1.fc_s_13 = "Latvia" 1.fc_s_14 = "Lebanon" 1.fc_s_15 = "Lithuania" 1.fc_s_16 = "Macedonia, FYR" 1.fc_s_17 = "Moldova" 1.fc_s_18 = "Mongolia" 1.fc_s_19 = "Montenegro" 1.fc_s_20 = "Morocco" 1.fc_s_21 = "Romania" 1.fc_s_22 = "Serbia" 1.fc_s_23 = "Slovenia" 1.fc_s_24 = "Tajikistan" 1.fc_s_25 = "Ukraine" 1.fc_s_26= "Uzbekistan" 1.fc_s_27 = "West Bank and Gaza", labsize(2)) ///
	plotregion(fcolor(white)) graphregion(fcolor(white))

/*
	   p1(label("Albania")) ///
	   p2(label("Azerbaijan")) ///
	   p3(label("Bosnia and Herzegovina")) ///
	   p4(label("Bulgaria")) ///
	   p5(label("Croatia")) ///
	   p6(label("Cyprus")) ///
	   p7(label("Estonia")) ///
	   p8(label("Georgia")) ///
	   p9(label("Jordan")) ///
	   p10(label("Kazakhstan")) ///
	   p11(label("Kosovo")) ///
	   p12(label("Kyrgyz Republic")) ///
	   p13(label("Latvia")) ///
	   p14(label("Lebanon")) ///
	   p15(label("Lithuania")) ///
	   p16(label("Macedonia, FYR")) ///
	   p17(label("Moldova")) ///
	   p18(label("Mongolia")) ///
	   p19(label("Montenegro")) ///
	   p20(label("Morocco")) ///
	   p21(label("Romania")) ///
	   p22(label("Serbia")) ///
	   p23(label("Slovenia")) ///
	   p24(label("Tajikistan")) ///
	   p25(label("Ukraine")) ///
	   p26(label("Uzbekistan")) ///
	   p27(label("West Bank and Gaza")) ///
	   legend(size(2) region(lcolor(none)) col(5)) ///
*/

graph export "$dir\output\image\robust_by_country.png", replace

********************************************************************************
**Policy Implication**
********************************************************************************

* for all levels of financial constraints: decomposite eco-innovation index 

forvalues s = 1/3 {
	local fc_models_`s'
	foreach y in $y_varlist {
		reg `y' i.fc $c_varlist i.country if sector_2 == 1 & size == `s', robust
		estimates store fc_`y'_`s'
		local fc_models_`s' `fc_models_`s'' fc_`y'_`s'
	}
}

coefplot `fc_models_1', bylabel(Small) ///
	|| `fc_models_2', bylabel(Medium) ///
	|| `fc_models_3', bylabel(Large) ///
	||, vertical keep(1.fc 2.fc 3.fc 4.fc) yline(0) level(90) ///
	rename(fc = "Financial Constraints") ///
	p1(label("Heating and cooling improvement")) ///
	p2(label("Climate-friendly energy generation")) ///
	p3(label("Upgrade machinery equipment")) ///
	p4(label("Energy management")) ///
	p5(label("Upgrade vehicles")) ///
	p6(label("Upgrade lighting system")) ///
	p7(label("Improve energy efficiency")) ///
	byopts(title("The coefficients of financial constraint with 90% of CI" "in regressions of decomposed eco-innovation index in the industry sector", size(3) margin(2))) ///
	legend(size(2) region(lcolor(none)) row(3)) ///
	xlabel(, labsize(2)) ylabel(, labsize(2)) ///
	plotregion(fcolor(white)) graphregion(fcolor(white))

graph export "$dir\output\image\robust_y_industry.png", replace


forvalues s = 1/3 {
	local fc_models_`s'
	foreach y in $y_varlist {
		reg `y' i.fc $c_varlist i.country if sector_2 == 0 & size == `s', robust
		estimates store fc_`y'_`s'
		local fc_models_`s' `fc_models_`s'' fc_`y'_`s'
	}
}

coefplot `fc_models_1', bylabel(Small) ///
	|| `fc_models_2', bylabel(Medium) ///
	|| `fc_models_3', bylabel(Large) ///
	||, keep(1.fc 2.fc 3.fc 4.fc) yline(0) level(90) ///
	rename(fc = "Financial Constraints") ///
	p1(label("Heating and cooling improvement")) ///
	p2(label("Climate-friendly energy generation")) ///
	p3(label("Upgrade machinery equipment")) ///
	p4(label("Energy management")) ///
	p5(label("Upgrade vehicles")) ///
	p6(label("Upgrade lighting system")) ///
	p7(label("Improve energy efficiency")) ///
	byopts(title("The coefficients of financial constraint with 90% of CI" "in regressions of decomposed eco-innovation index in the service sector", size(3) margin(2))) ///
	legend(size(2) region(lcolor(none)) row(3)) ///
	xlabel(, labsize(2)) ylabel(, labsize(2)) ///
	plotregion(fcolor(white)) graphregion(fcolor(white))

graph export "$dir\output\image\robust_y_service.png", replace




