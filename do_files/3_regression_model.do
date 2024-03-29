*****Regression*****

********************************************************************************
**setup**
********************************************************************************

global dir "D:\GU\thesis_data"

cd "$dir"

use "$dir\data\clean\clean_data.dta", clear

set scheme sj

gen developed = 0

replace developed = 1 if inlist(country, 6, 7, 14, 16, 24)

drop if developed == 1

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

egen nmcount = rownonmiss($y_varlist fc innovation iso competitor_log customer cost_sale tax standard f_external sector_specific size country)
*tab nmcount
*drop if nmcount < 19
* Question:  electricity fee is zero? competitor is zero?

********************************************************************************
**construct denpendent varibale**
********************************************************************************

*****OPTION 1*****

pca $y_varlist

*screeplot

predict pc1, score

*****OPTION 2*****

*egen adopt_level = rowtotal($y_varlist)

********************************************************************************
**OLS: very sever**
********************************************************************************

reg pc1 i.fc_s $c_varlist i.size, robust
outreg2 using output\table\severe.doc, replace addtext(Control variables, Yes, Sector FE, No, Country FE, No) adjr2 nocons

reg pc1 i.fc_s $c_varlist i.size i.sector_simple, robust
outreg2 using output\table\severe.doc, append addtext(Control variables, Yes, Sector FE, Yes, Country FE, No) adjr2 nocons

*reg pc1 i.fc_s $c_varlist i.size i.sector2 i.region, robust
*outreg2 using output\table\severe.doc, append ctitle(pc1) drop(i.size i.sector2 i.region) addtext(Control size, YES, Control sector, YES, Control region, YES, Control country, NO)

reg pc1 i.fc_s $c_varlist i.size i.sector_simple i.country, robust
outreg2 using output\table\severe.doc, append addtext(Control variables, Yes, Sector FE, Yes, Country FE, Yes) adjr2 nocons


********************************************************************************
**OLS by sector: very severe**
********************************************************************************

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		reg pc1 i.fc_s $c_varlist i.country if sector_simple == `sector' & size == `size', robust
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
		reg pc1 fc $c_varlist i.country if sector_simple == `sector' & size == `size', robust
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\fc_sector_size.doc, replace ctitle("PC1", "`sector'|`size'") keep(fc) addtext(Control variables, Yes, Country FE, Yes) adjr2 nocons
		} 
		else {
			outreg2 using output\table\fc_sector_size.doc, append ctitle("PC1", "`sector'|`size'") keep(fc) addtext(Control variables, Yes, Country FE, Yes) adjr2 nocons
		}
	}
}

********************************************************************************
**Threat to inference: IV**
********************************************************************************
*heating_cooling energy_generation machinery_equipment energy_management vehicles lighting_system energy_efficiency

***OPTION 1: financial constraints***
bysort region sector_specific: egen iv1 = mean(fc)

/*
***OPTION 2: external funds: SECTOR LEVEL FINANCE FROM EXTERNAL SOURCES CORRELATE TO PC1
bysort country region: egen iv2 = mean(f_external)

***OPTION 3: outstanding loads: NO FEW OBSERVATIONS, BIAS
bysort country sector: egen iv3 = mean(amount_loan)
gen iv3_log = log(iv3)

bysort country sector: egen iv4 = mean(number_load)
gen iv4_log = log(iv4)

* 2sls regressions
ivregress 2sls pc1 $c_varlist i.size i.country i.sector_simple (fc_s = iv1), first vce(robust) // do not include sector, region, and country fixed effects as they will control for iv3
*/

* very severe: by sector2 and size
forvalues sector = 0/2 {
	forvalues size = 0/2 {
		ivregress 2sls pc1 $c_varlist i.country (fc_s = iv1) if sector_simple == `sector' & size == `size', first vce(robust)
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\iv_severe_sector_size.doc, replace ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc_s) nocons
		} 
		else {
			outreg2 using output\table\iv_severe_sector_size.doc, append ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc_s) nocons
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
		ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if sector_simple == `sector' & size == `size', first vce(robust)
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\iv_fc_sector_size.doc, replace ctitle("`sector'|`size'") addtext(Control variables, Yes,, Control country, Yes) keep(fc) nocons
		} 
		else {
			outreg2 using output\table\iv_fc_sector_size.doc, append ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc) nocons
		}
	}
}

********************************************************************************
**Robustness check: decompose eco-innovation index**
********************************************************************************

* for very severe financial constraints: decomposite eco-innovation index 

egen upgrade = rowtotal(heating_cooling machinery_equipment lighting_system) // vehicles
egen management = rowtotal(energy_efficiency energy_management)

forvalues s = 0/2 {
	local model_ind_`s'
	local model_ser_`s'
	local model_oth_`s'
	foreach y in energy_generation vehicles upgrade management {
		* Manufacturing
		reg `y' i.fc_s $c_varlist i.country if sector_simple == 0 & size == `s', robust
		*ivregress 2sls `y' $c_varlist i.country (fc_ms = iv1) if sector2 == 1 & size == `s', first vce(robust)
		estimates store `y'_ind_`s'
		local model_ind_`s' `model_ind_`s'' `y'_ind_`s'
		
		* Service
		reg `y' i.fc_s $c_varlist i.country if sector_simple == 1 & size == `s', robust
		*ivregress 2sls `y' $c_varlist i.country (fc_ms = iv1) if sector2 == 0 & size == `s', first vce(robust)
		estimates store `y'_ser_`s'
		local model_ser_`s' `model_ser_`s'' `y'_ser_`s'
		
		* Other sector
		reg `y' i.fc_s $c_varlist i.country if sector_simple == 2 & size == `s', robust
		estimates store `y'_oth_`s'
		local model_oth_`s' `model_oth_`s'' `y'_oth_`s'
	}
}

coefplot `model_ind_0', bylabel(Manufacturing | Small) ///
	|| `model_ind_1', bylabel(Manufacturing| Medium) ///
	|| `model_ind_2', bylabel(Manufacturing| Large) ///
	|| `model_ser_0', bylabel(Service | Small) ///
	|| `model_ser_1', bylabel(Service | Medium) ///
	|| `model_ser_2', bylabel(Service | Large) ///
	|| `model_oth_0', bylabel(Other | Small) ///
	|| `model_oth_1', bylabel(Other | Medium) ///
	|| `model_oth_2', bylabel(Other | Large) ///
	||, keep(1.fc_s) xline(0) level(90) ylabel(none) ///
	p1(label("Climate-friendly energy generation")) ///
	p2(label("Upgrade vehicles")) ///
	p3(label("Upgrade heating and cooling system, machinery and equipment, lighting system")) ///
	p4(label("Energy management and energy efficiency improving")) ///
	subtitle(, size(3)) ///
	legend(size(3) region(lcolor(none)) row(4)) ///
	xtitle("The development and adoption index", size(3)) ///
	ytitle("Very severe financial constraint", size(3)) ///
	xlabel(, labsize(3))
	
		*byopts(title("The coefficients of financial constraint with 90% of CI" "in regressions of decomposed the development and adoption index", size(3) margin(2))) ///

graph export "$dir\output\image\robust_y_decompose.png", replace

sum $y_varlist if sector_simple == 0 & size == 2 & fc_s == 0

forvalues s = 0/2 {
	local model_con_`s'
	local model_it_`s'
	local model_tran_`s'
	foreach y in energy_generation vehicles upgrade management {
		* construction
		reg `y' i.fc_s $c_varlist i.country if sector_simple == 2 & sector_specific == 3 & size == `s', robust
		estimates store `y'_con_`s'
		local model_con_`s' `model_con_`s'' `y'_con_`s'
		
		* IT
		reg `y' i.fc_s $c_varlist i.country if sector_simple == 2 & sector_specific == 10 & size == `s', robust
		estimates store `y'_it_`s'
		local model_it_`s' `model_it_`s'' `y'_it_`s'
		
		* Transportation
		reg `y' i.fc_s $c_varlist i.country if sector_simple == 2 & sector_specific == 24 & size == `s', robust
		estimates store `y'_tran_`s'
		local model_tran_`s' `model_tran_`s'' `y'_tran_`s'
	}
}

coefplot `model_con_0', bylabel(Construction | Small) ///
	|| `model_con_1', bylabel(Construction| Medium) ///
	|| `model_con_2', bylabel(Construction| Large) ///
	|| `model_tran_0', bylabel(Transportation | Small) ///
	|| `model_tran_1', bylabel(Transportation| Medium) ///
	|| `model_tran_2', bylabel(Transportation | Large) ///
	||, keep(1.fc_s) xline(0) level(90) ylabel(none) ///
	p1(label("Climate-friendly energy generation")) ///
	p2(label("Upgrade vehicles")) ///
	p3(label("Upgrade heating and cooling system, machinery and equipment, lighting system")) ///
	p4(label("Energy management and energy efficiency improving")) ///
	subtitle(, size(3)) ///
	byopts(xrescale) ///
	legend(size(3) region(lcolor(none)) row(4)) ///
	xtitle("The development and adoption index", size(3)) ///
	ytitle("Very severe financial constraint", size(3)) ///
	xlabel(, labsize(3))
	
	/*	|| `model_it_0', bylabel(IT | Small) ///
	|| `model_it_1', bylabel(IT | Medium) ///
	|| `model_it_2', bylabel(IT| Large) ///
	*/
	
	*title("The coefficients of financial constraint with 90% of CI" "in regressions of decomposed the development and adoption index in other sectors", size(3) margin(2))

	graph export "$dir\output\image\robust_y_decompose_other_sector_fc_s.png", replace
	
forvalues s = 0/2 {
	local model_con_`s'
	local model_it_`s'
	local model_tran_`s'
	foreach y in energy_generation vehicles upgrade management {
		* construction
		reg `y' fc $c_varlist i.country if sector_simple == 2 & sector_specific == 3 & size == `s', robust
		estimates store `y'_con_`s'
		local model_con_`s' `model_con_`s'' `y'_con_`s'
		
		* IT
		reg `y' fc $c_varlist i.country if sector_simple == 2 & sector_specific == 10 & size == `s', robust
		estimates store `y'_it_`s'
		local model_it_`s' `model_it_`s'' `y'_it_`s'
		
		* Transportation
		reg `y' fc $c_varlist i.country if sector_simple == 2 & sector_specific == 24 & size == `s', robust
		estimates store `y'_tran_`s'
		local model_tran_`s' `model_tran_`s'' `y'_tran_`s'
	}
}

coefplot `model_con_0', bylabel(Construction | Small) ///
	|| `model_con_1', bylabel(Construction| Medium) ///
	|| `model_con_2', bylabel(Construction| Large) ///
	|| `model_tran_0', bylabel(Transportation | Small) ///
	|| `model_tran_1', bylabel(Transportation| Medium) ///
	|| `model_tran_2', bylabel(Transportation | Large) ///
	||, keep(fc) xline(0) level(90) ylabel(none) ///
	p1(label("Climate-friendly energy generation")) ///
	p2(label("Upgrade vehicles")) ///
	p3(label("Upgrade heating and cooling system, machinery and equipment, lighting system")) ///
	p4(label("Energy management and energy efficiency improving")) ///
	subtitle(, size(3)) ///
	byopts(xrescale) ///
	legend(size(3) region(lcolor(none)) row(4)) ///
	xtitle("The development and adoption index", size(3)) ///
	ytitle("Financial constraint score", size(3)) ///
	xlabel(, labsize(3))
	
	/*	|| `model_it_0', bylabel(IT | Small) ///
	|| `model_it_1', bylabel(IT | Medium) ///
	|| `model_it_2', bylabel(IT| Large) ///
	*/

	graph export "$dir\output\image\robust_y_decompose_other_sector_fc.png", replace

********************************************************************************
**Understand why large manumacturing firms are significant**
********************************************************************************
/*
eststo clear

levelsof sector_specific if sector_simple == 0, local(sector)

*bysort sector_specific size: egen count = count(country)
*replace count = . if nmcount < 19

forvalue i = 0/2 {
	foreach s in `sector' {
		dis as error `s'
		qui count if sector_specific == `s' & size == `i'
        local n = r(N)
        if `n' >= 30 {
			rename * *_`i'_`s'
			eststo reg_`i'_`s': reg pc1 i.fc_s $c_varlist i.country if sector_specific == `s' & size == `i', robust
			rename *_`i'_`s' *
		}
		
	}
} 

coefplot reg_0_*, bylabel(Small) ///
|| reg_1_*, bylabel(Medium) drop(1.fc_s_1_11) ///
|| reg_2_*, bylabel(Large) drop(1.fc_s_2_26) ///
||, keep(1.fc_s_*) xline(0) level(90) byopts(xrescale cols(3)) legend(off) ///
	xtitle("Very Severe Financial Constraints", size(2)) ///
	title("The coefficients of financial constraint with 90% of CI by sector", size(3) margin(2)) ///
	xlabel(, labsize(2)) ///
	plotregion(fcolor(white)) graphregion(fcolor(white))

	*drop(1.fc_s_2_26) drop(1.fc_s_1_11)
*/
********************************************************************************

* Foreign investment

gen if_state_owned = 0
replace if_state_owned = 1 if pct_state_owned != 0

gen if_foreign_owned = 0
replace if_foreign_owned = 1 if pct_foreign > 50

gen external = 0
replace external =1 if f_external != 0

foreach size in 0 2 {
	reg pc1 fc $c_varlist i.country if external == 0 & sector_simple == 0 & size == `size', robust
	outreg2 using output\table\foreign_owned_`size'.doc, replace ctitle("`foreign-owned'") addtext(Control variables, Yes, Country FE, Yes) keep(fc) nocons

	reg pc1 fc $c_varlist i.country if external == 1 & sector_simple == 0 & size == `size', robust
	outreg2 using output\table\foreign_owned_`size'.doc, append ctitle("`foreign-owned'") addtext(Control variables, Yes, Country FE, Yes) keep(fc) nocons

	ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if external == 0 & sector_simple == 0 & size == `size', first vce(robust)
	outreg2 using output\table\foreign_owned_`size'.doc, append ctitle("`foreign-owned'") addtext(Control variables, Yes, Country FE, Yes) keep(fc) nocons

	ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if external == 1 & sector_simple == 0 & size == `size', first vce(robust)
	outreg2 using output\table\foreign_owned_`size'.doc, append ctitle("`foreign-owned'") addtext(Control variables, Yes, Country FE, Yes) keep(fc) nocons
}

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		*reg pc1 fc $c_varlist if country_co2target ==1 & sector_simple == `sector' & size == `size', robust
		qui ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if if_foreign_owned == 1 & sector_simple == `sector' & size == `size', first vce(robust)
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\state_owned_sector_size.doc, replace ctitle("`sector'|`size'") addtext(Control variables, Yes,, Control country, Yes) keep(fc) nocons
		} 
		else {
			outreg2 using output\table\state_owned_sector_size.doc, append ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc) nocons
		}
	}
}

********************************************************************************
/* By income level
gen country_income = 0 // Tajikistan
replace country_income = 1 if inlist(country, 17, 25, 26, 12, 18, 20, 27) 
replace country_income = 2 if inlist(country, 3, 22, 19, 11, 1, 16, 4, 8, 2, 10, 14, 9) 
replace country_income = 3 if inlist(country, 5, 23, 21, 15, 13, 7, 6) 
*/

* By status of net-zero carbon emissions targets
cap drop country_co2target
gen country_co2target = 0 // 1 2 3 8 10 12 13 17 18 19 20 21 23 25 27 28
*replace country_co2target = 1 if inlist(country, 4) // discussion
*replace country_co2target = 2 if inlist(country, 7, 11) // declaration and pledge
replace country_co2target = 1 if inlist(country, 5, 6, 9, 14, 15, 16, 22, 24, 26) // in policy documentation

eststo clear

*levelsof country, local(country)
*set varabbrev off

/*
forvalues c = 0/1 {
	forvalues size = 0/2 {
		dis as error `c'
		rename * *_`c'
		eststo reg_`size'_`c': reg pc1 i.fc_s $c_varlist if sector_simple == 0 & size == `size' & country_co2target == `c', robust
		rename *_`c' *	
	}
}

coefplot reg_0_*, bylabel(Small) ///
|| reg_1_*, bylabel(Medium) ///
|| reg_2_*, bylabel(Large) ///
||, keep(1.fc_s_*) xline(0) level(90) ///
	p1(label("No net-zero emission targets / in discussion / declaration or pledge")) ///
	p2(label("In policy documentation")) ///
	byopts(cols(3) title("The coefficients of financial constraint with 90% of CI for manufacturing firms" "by the status of countries' net-zero emissions progress", size(4) margin(2))) ///
	legend(size(3) region(lcolor(none)) row(2)) ///
	ylabel(none)

graph export "$dir\output\image\manufacturing_by_co2target_country.png", replace	

*/
********************************************************************************
*version2

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		*reg pc1 fc_s $c_varlist if country_co2target ==1 & sector_simple == `sector' & size == `size', robust
		ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if country_co2target == 1 & sector_simple == `sector' & size == `size', first vce(robust)
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\policy_sector_size.doc, replace ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc) nocons
		} 
		else {
			outreg2 using output\table\policy_sector_size.doc, append ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc) nocons
		}
	}
}

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		*reg pc1 fc $c_varlist if country_co2target ==1 & sector_simple == `sector' & size == `size', robust
		ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if country_co2target ==0 & sector_simple == `sector' & size == `size', first vce(robust)
		if `sector' == 0 & `size' == 0 {
			outreg2 using output\table\no_policy_sector_size.doc, replace ctitle("`sector'|`size'") addtext(Control variables, Yes,, Control country, Yes) keep(fc) nocons
		} 
		else {
			outreg2 using output\table\no_policy_sector_size.doc, append ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc) nocons
		}
	}
}

********************************************************************************
* more supervision: ttest by size

gen large = 0
replace large = 1 if size == 2

estpost ttest standard tax if sector_simple == 0, by(large)
esttab using output\table\ttest.doc, replace wide nonumber mtitle("diff.")

********************************************************************************
*by costs of fuel and electricity

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		*preserve
		*keep if sector_simple == `sector' & size == `size'
		cap drop high_cost
		gen high_cost = 1
		qui sum cost, d
		replace high_cost = 0 if cost < `r(p90)'
		reg pc1 fc_s $c_varlist i.country if high_cost == 1 & sector_simple == `sector' & size == `size', robust
		*qui ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if high_cost == 1 & sector_simple == `sector' & size == `size', first vce(robust)
		if  `sector' == 0 & `size' == 0 {
			outreg2 using output\table\high_cost_by_sector_size.doc, replace ctitle("`sector'|`size'") addtext(Control variables, Yes,, Control country, Yes) keep(fc_s) nocons
		} 
		else {
			outreg2 using output\table\high_cost_by_sector_size.doc, append ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc_s) nocons
		}
		*restore
	}
}

graph box cost, over(sector_simple) over(size) nooutside

********************************************************************************
**Robustness check: across countries**
********************************************************************************

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

	
	/*	qui count if sector_simple == 0 & size == 1 & country == `c'
	local n = r(N)
	if `n' >= 30 {
		rename * *_`c'
		eststo reg_`c': reg pc1 i.fc_s $c_varlist if sector_simple == 0 & size == 1 & country == `c', robust
		rename *_`c' *
	}
	
	coefplot reg_*, keep(1.fc_s_*) sort xline(0) level(90) legend(size(1) cols(5)) legend(off) ///
	xtitle("Very Severe Financial Constraints", size(2)) ///
	title("The coefficients of financial constraint with 90% of CI by country", size(3) margin(2)) ///
	xlabel(, labsize(2)) ///
	coeflabels(1.fc_s_1 = "Albania" 1.fc_s_2 = "Azerbaijan" 1.fc_s_3 = "Bosnia and Herzegovina" 1.fc_s_4 = "Bulgaria" 1.fc_s_5 = "Croatia" 1.fc_s_6 = "Cyprus" 1.fc_s_7 = "Estonia" 1.fc_s_8 = "Georgia" 1.fc_s_9 = "Jordan" 1.fc_s_10 = "Kazakhstan" 1.fc_s_11 = "Kosovo" 1.fc_s_12 = "Kyrgyz Republic" 1.fc_s_13 = "Latvia" 1.fc_s_14 = "Lebanon" 1.fc_s_15 = "Lithuania" 1.fc_s_16 = "Macedonia, FYR" 1.fc_s_17 = "Moldova" 1.fc_s_18 = "Mongolia" 1.fc_s_19 = "Montenegro" 1.fc_s_20 = "Morocco" 1.fc_s_21 = "Romania" 1.fc_s_22 = "Serbia" 1.fc_s_23 = "Slovenia" 1.fc_s_24 = "Tajikistan" 1.fc_s_25 = "Ukraine" 1.fc_s_26= "Uzbekistan" 1.fc_s_27 = "West Bank and Gaza", labsize(2)) ///
	plotregion(fcolor(white)) graphregion(fcolor(white))
	*/

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

********************************************************************************

estpost ttest innovation if size != 1 & nmcount == 19, by(size)
esttab using output\table\ttest_innovation.doc, replace wide nonumber mtitle("diff.")

estpost ttest innovation if size != 0 & nmcount == 19, by(size)
esttab using output\table\ttest_innovation.doc, replace wide nonumber mtitle("diff.")

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		*preserve
		*keep if sector_simple == `sector' & size == `size'
		cap drop high_inno
		gen high_inno = 1
		qui sum innovation, d
		replace high_inno = 0 if innovation < `r(p75)'
		*reg pc1 fc_s $c_varlist i.country if inno == 1 & sector_simple == `sector' & size == `size', robust
		qui ivregress 2sls pc1 $c_varlist i.country (fc = iv1) if high_inno == 0 & sector_simple == `sector' & size == `size', first vce(robust)
		if  `sector' == 0 & `size' == 0 {
			outreg2 using output\table\test.doc, replace ctitle("`sector'|`size'") addtext(Control variables, Yes,, Control country, Yes) keep(fc) nocons
		} 
		else {
			outreg2 using output\table\test.doc, append ctitle("`sector'|`size'") addtext(Control variables, Yes, Control country, Yes) keep(fc) nocons
		}
		*restore
	}
}