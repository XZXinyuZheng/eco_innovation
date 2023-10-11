*****Descriptive Analysis*****

cd "D:\GU\thesis_data"

use "data\clean\clean_data.dta", clear

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
	
	graph export "output\image\fc_`y'.png", replace
	 
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

graph export "output\image\correlation.png", replace