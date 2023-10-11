global dir "D:/GU/thesis_data"

********************************************************************************
**Appending**
********************************************************************************

local file_list : dir "$dir/data/medium" files "*.dta"

tempfile clean_data
save `clean_data', emptyok

foreach i in `file_list' {
	use "$dir/data/medium/`i'", clear
  	keep BMGc23a BMGc23b BMGc23c BMGc23d BMGc23g BMGc23i BMGc25 BMGd6 BMGd7 BMGa4 k30 k3a a1 a2 a4a a6a b2c b8 b8x e2 n2b n2f idstd wmedian h1 h5 BMh1 BMh2 BMh3 k15a k15b d2 BMGb1 a4b a6b a3 a3a n2a n2b n2f b2a b2b
	foreach v in a1 a2 a4a a6a a4b a6b a3 a3a {
		decode `v', gen(`v'_s)
		drop `v'
		rename `v'_s `v' 
	}
	gen sampling_region = a1 + " " + a2
	replace sampling_region = "" if missing(a2)
	gen region = a1 + " " + a3a
	replace region = "" if missing(a3a)
	append using `clean_data', force
	save `clean_data', replace
	}

foreach v in a1 a2 a4a a6a a4b a6b sampling_region region a3 {
		encode `v', gen(`v'_n)
		drop `v'
		rename `v'_n `v' 
	}

********************************************************************************
**recode variables**
********************************************************************************

* dummies
foreach v in BMGc23a BMGc23b BMGc23c BMGc23d BMGc23g BMGc23i BMGc25 BMGd6 BMGd7 BMGa4 h1 h5 BMh1 BMh2 BMh3 {
	recode `v' (1 = 1 "yes") (2 = 0 "No") (else = .), prefix(new_)
}

* financial constraints
gen fc = k30
replace fc = . if inlist(k30, -9, -7, .)
label define fc_label 0 "No" 1 "Minor" 2 "Moderate" 3 "Major" 4 "Very severe"
label values fc fc_label
label variable fc "financial constraints"

* innovation
egen innovation = rowtotal(new_h1 new_h5 new_BMh1 new_BMh2 new_BMh3), m
replace innovation = . if new_h1 == . | new_h5 == . | new_BMh1 == .| new_BMh2 == .| new_BMh3 == .

* ISO
gen iso = 0
replace iso = 1 if regexm(b8x, "900|1400")
replace iso = . if inlist(b8, -9, .)
label define binary_label 1 "Yes" 0 "No"
label values iso binary_label
label variable iso "adopt iso 1900 or iso 14000 series"

* competitor
gen competitor = e2
replace competitor = . if e2 == -9
replace competitor = 10000 if e2 == -4
label variable competitor "the number of competitors"

* cost
foreach i in n2b n2f {
	replace `i' = . if `i' == -9
}
egen cost = rowtotal(n2b n2f)

* sale
replace d2 = . if d2 == -9
rename d2 sale

* cost / sale
gen cost_sale = cost / sale
label variable cost_sale "the ratio of cost over sale"

* sampling size
recode a6a (4 = 1 "Small") (2 = 2 "Medium") (1 8 = 3 "Large") (else = 4 "Unknow"), gen (sampling_size)

* finance from external resource
gen f_external = .
replace f_external = 100 - k3a if k3a != -9
label variable f_external "working capital from external sources"

* owned by government
gen pct_state_owned = b2c
replace pct_state_owned = . if inlist(b2c, -9, .)
label variable pct_state_owned "pct owned by government or state"

gen pct_domestic = b2a
replace pct_domestic = . if inlist(b2a, -9, .)
label variable pct_domestic "pct owned by domestic individuals, companies, or organizations"

gen pct_foreign = b2b
replace pct_foreign = . if inlist(b2b, -9, .)
label variable pct_foreign "pct owned by foreign individuals, companies, or organizations"

rename (new_BMGc23a new_BMGc23b new_BMGc23c new_BMGc23d new_BMGc23g new_BMGc23i new_BMGc25 new_BMGd6 new_BMGd7 new_BMGa4 a1 a4a a3) ///
       (heating_cooling energy_generation machinery_equipment energy_management vehicles lighting_system energy_efficiency tax standard customer country sampling_sector population)

* potential iv: outstanding loan
replace k15a = . if k15a == -9
replace k15b = . if inlist(k15b, -8, -9)
rename (k15a k15b) (amount_loan number_loan) 

* loan / sale
gen amount_loan_sale =  amount_loan / sale
label variable amount_loan_sale "how many times is the loan to annual sale?"

* loss during extreme weather
replace BMGb1 = . if BMGb1 == -9
replace BMGb1 = 0 if BMGb1 == 2
rename BMGb1 loss

* screening size
recode a6b (3 4 = 0 "Small") (2 = 1 "Medium") (1 = 2 "Large"), gen(size)

* screening sector
*recode a4b (1 2 4/8 11/19 22 23 26 28 = 0 "Manufacturing") (3 = 1 "Construction") (9 20 21 27 = 2 "Service") (24 25 = 3 "Transportation") (10 = 4 "IT"), gen(sector)
replace a4b = 24 if a4b == 25
rename a4b sector_specific
recode sector_specific (1 2 4/8 11/19 22 23 26 28 = 0 "Manufacturing") (9 20 21 27 = 1 "Service") (3 10 24 25 = 2 "Others"), gen(sector_simple)

drop BMGc23a BMGc23b BMGc23c BMGc23d BMGc23g BMGc23i BMGc25 BMGd6 BMGd7 BMGa4 k30 k3a a6a b2a b2b b2c b8 b8x e2 n2b n2f h1 h5 BMh1 BMh2 BMh3 new_h1 new_h5 new_BMh1 new_BMh2 new_BMh3 a6b a2 a3a

save "$dir\data\clean\clean_data.dta", replace

********************************************************************************
**check missing value**
********************************************************************************

egen nmcount = rownonmiss($y_varlist $x_varlist)
tab nmcount


*-------------------------------------------------------------------------------
********************************************************************************
*****Descriptive Analysis*****
********************************************************************************
*-------------------------------------------------------------------------------

use "$dir/data/clean/clean_data.dta", clear

gen developed = 0

replace developed = 1 if inlist(country, 6, 7, 14, 16, 24)

drop if developed == 1

********************************************************************************
**sampling weight**
********************************************************************************

gen reweight = .

levelsof country, local(country)

foreach c in `country' {
	sum wmedian if country == `c'
	replace reweight = wmedian / r(sum) if country == `c'
	}
	
replace reweight = reweight * (1/23)

egen strata = group(sampling_region sampling_sector sampling_size)

svyset idstd [pweight = reweight], strata(strata) singleunit(centered)

********************************************************************************
**preprocess for descriptive anaylsis**
********************************************************************************

global y_varlist heating_cooling energy_generation machinery_equipment energy_management vehicles lighting_system energy_efficiency

gen fc_s = .
replace fc_s = 1 if fc == 4
replace fc_s = 0 if inlist(fc, 0, 1, 2, 3)

global x_varlist fc fc_s innovation iso competitor customer cost_sale tax standard f_external size sector_specific country

* drop obs containting at least one missing

egen nmcount = rownonmiss($y_varlist fc innovation iso competitor customer cost_sale tax standard f_external sector_specific size country)

keep if nmcount == 19 

********************************************************************************
**summry table**
********************************************************************************
svy: mean $y_varlist $x_varlist

********************************************************************************
**frequency distribution**
********************************************************************************
/*
foreach n in 0 1 2 3 4 {
	svy: tab sector_simple size if fc == `n'
}

svy: mean $y_varlist fc_s, over(size sector_simple)

svy: mean heating_cooling, over(size sector_simple)

*/

egen upgrade = rowtotal(heating_cooling machinery_equipment lighting_system) // vehicles
egen management = rowtotal(energy_efficiency energy_management)

bysort sector_simple size: correlate fc_s energy_generation vehicles upgrade management [aweight = reweight]

forvalues sector = 0/2 {
	forvalues size = 0/2 {
		foreach y in energy_generation vehicles upgrade management {
			svy: regress `y' fc_s if sector_simple == `sector' & size == `size'
		}
	}
}

********************************************************************************
**correlation among independent variables**
********************************************************************************
svy: sem fc f_external state_owned country size sector_2 innovation iso competitor customer tax standard, standardized

* problem with cost

******************************
**visualization for presentation： do not include in thesis**
******************************

*correlation bewteen dependent and key independent

foreach y in $y_varlist {
	graph hbox fc [pw = reweight], ///
     over(`y', label(labsize(2))) ///
     over(size, label(labsize(2))) ///
	 over(sector_2, label(labsize(2))) ///
     ytitle("`y'", size(2)) ///
     title("{bf}Correlation between eco-innovation and financial constraints", pos(11) size(2)) ///
	 subtitle("{bf}by firm size and sector", pos(11) size(2)) ///
	 xsize(5) ysize(7) ///
	 legend(rows(1) symysize(2) symxsize(2) size(2)) ///
	 nooutsides ///
	 graphregion(fcolor(white))
	
	graph export "$dir/output/image/fc_`y'.png", replace
	 
   *graph hbox y [pw = reweight], ///
   *  over(fc, label(labsize(2.5))) ///
   *  over(sector_2, label(labsize(2.5))) ///
   *  ytitle("Component1", size(2.25)) ///
   *  title("{bf}Correlation between eco-innovation and financial constraints by sector", pos(11) size(2.5)) ///
   *  scheme(white_w3d)
}


*correlation bewteen dependent and all independent

  * Only change names of variable in local var_corr. 
  * The code will hopefully do the rest of the work without any hitch
  local var_corr $x_varlist
  local countn : word count `var_corr'
  
  * Use correlation command
  qui pwcorr `var_corr'
  matrix C = r(C)
  local rnames : rownames C
  
  * Now to generate a dataset from the Correlation Matrix
  clear
   
   * For no diagonal and total count
   local tot_rows : display `countn' * `countn'
   set obs `tot_rows'
   
   generate corrname1 = ""
   generate corrname2 = ""
   generate y = .
   generate x = .
   generate corr = .
   generate abs_corr = .
   
   local row = 1
   local y = 1
   local rowname = 2
    
   foreach name of local var_corr {
    forvalues i = `rowname'/`countn' { 
     local a : word `i' of `var_corr'
     replace corrname1 = "`name'" in `row'
     replace corrname2 = "`a'" in `row'
     replace y = `y' in `row'
     replace x = `i' in `row'
     replace corr = round(C[`i',`y'], .01) in `row'
     replace abs_corr = abs(C[`i',`y']) in `row'
     
     local ++row
     
    }
    
    local rowname = `rowname' + 1
    local y = `y' + 1
   
   }
   
  drop if missing(corrname1)
  replace abs_corr = 0.1 if abs_corr < 0.1 & abs_corr > 0.04
  
  colorpalette HCL pinkgreen, n(10) nograph intensity(0.65)
  *colorpalette CET CBD1, n(10) nograph //Color Blind Friendly option
  generate colorname = ""
  local col = 1
  forvalues colrange = -1(0.2)0.8 {
   replace colorname = "`r(p`col')'" if corr >= `colrange' & corr < `=`colrange' + 0.2'
   replace colorname = "`r(p10)'" if corr == 1
   local ++col
  } 
  
  
  * Plotting
  * Saving the plotting code in a local 
  forvalues i = 1/`=_N' {
  
   local slist "`slist' (scatteri `=y[`i']' `=x[`i']' "`: display %3.2f corr[`i']'", mlabposition(0) msize(`=abs_corr[`i']*15') mcolor("`=colorname[`i']'"))"
  
  }
  
  
  * Gather Y axis labels
  labmask y, val(corrname1)
  labmask x, val(corrname2)
  
  levelsof y, local(yl)
  foreach l of local yl {
   local ylab "`ylab' `l'  `" "`:lab (y) `l''" "'" 
   
  } 

  * Gather X Axis labels
  levelsof x, local(xl)
  foreach l of local xl {
   local xlab "`xlab' `l'  `" "`:lab (x) `l''" "'" 
   
  }  
  
  * Plot all the above saved lolcas
  twoway `slist', title("Correlogram of Continuous Variables", size(3) pos(11)) ///
    xlabel(`xlab', labsize(2.5)) ylabel(`ylab', labsize(2.5)) ///
    xscale(range(1.75 )) yscale(range(0.75 )) ///
    ytitle("") xtitle("") ///
    legend(off) ///
    aspect(1) ///
    scheme(white_tableau)

graph export "$dir/output/image/correlation.png", replace


*-------------------------------------------------------------------------------
********************************************************************************
*****Regression*****
********************************************************************************
*-------------------------------------------------------------------------------

**setup**
cd "$dir"

use "data/clean/clean_data.dta", clear

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
