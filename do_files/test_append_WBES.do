*** setup ***
cd "D:\GU\Thesis Data"

***preprocess before appending***

use "Romania-2019-full-data.dta", clear
labdtch panel contractor a24
save "Romania-2019-full-data.dta", replace

use "Morocco-2019-full-data.dta", clear
labdtch CNg4a CNg4b CNl1a CNl1b BMwstrict BMwmedian BMwweak
save "Morocco-2019-full-data.dta", replace

use "Lebanon-2019-full-data.dta", clear
labdtch panel
save "Lebanon-2019-full-data.dta", replace

foreach i in Albania Bosnia-and-Herzegovina Bulgaria Croatia Cyprus Estonia North-Macedonia Kazakhstan Kosovo Kyrgyz-Republic Latvia Lithuania Mongolia Montenegro Romania Serbia Slovenia Tajikistan Ukraine Uzbekistan Azerbaijan Georgia Jordan West-Bank-and-Gaza {  
	use "`i'-2019-full-data.dta", clear
	labdtch gdpr2
	save "`i'-2019-full-data.dta", replace
}

foreach i in Albania Bosnia-and-Herzegovina Bulgaria Croatia Cyprus Estonia North-Macedonia Kazakhstan Kosovo Kyrgyz-Republic Latvia Lithuania Mongolia Montenegro Romania Serbia Slovenia Tajikistan Ukraine Uzbekistan Azerbaijan Georgia Jordan West-Bank-and-Gaza Morocco Moldova {  
	use "`i'-2019-full-data.dta", clear
	labdtch BMGa12
	save "`i'-2019-full-data.dta", replace
}

***append***
global country_list Albania Bosnia-and-Herzegovina Bulgaria Croatia Cyprus Estonia North-Macedonia Kazakhstan Kosovo Kyrgyz-Republic Latvia Lithuania Mongolia Montenegro Romania Serbia Slovenia Tajikistan Ukraine Uzbekistan Azerbaijan Georgia Jordan Morocco Moldova West-Bank-and-Gaza Lebanon

tempfile clean_data
save `clean_data', emptyok

foreach i in $country_list {  
	use "`i'-2019-full-data.dta", clear
	* detach ghost labels
	qui labdtch idstd id a6c a12 a13 a14d a14m a14y a14h a14min a20y a20m a20d BMj1_impartial_pos BMj1_transparent_pos BMj1_voice_pos BMj2_impartial_pos BMj2_transparent_pos BMj2_voice_pos BMj3_parliament_pos BMj3_natgov_pos BMj3_locgov_pos j30_taxrate_pos j30_taxadmin_pos j30_permit_pos j30_instability_pos j30_corruption_pos j30_courts_pos j30_safety_pos j30_health_pos j30_environment_pos m1a_finance_pos m1a_land_pos m1a_permit_pos m1a_corruption_pos m1a_courts_pos m1a_crime_pos m1a_trade_pos m1a_electricity_pos m1a_workforce_pos m1a_labor_pos m1a_instability_pos m1a_informal_pos m1a_taxadmin_pos m1a_taxrate_pos m1a_transport_pos a15d a15m a15y a15h a15min a19h a19m BMGa14gd BMGa14gd BMGa14gm BMGa14gy BMGa14gh BMGa14gmin BMGa15gd BMGa15gm BMGa15gy BMGa15gh BMGa15gmin d1a2 wstrict wmedian wweak strata
	qui ds, has(vallabel)
	foreach v in `r(varlist)' {
		decode `v', gen(`v'_s)
		drop `v'
	}
	append using `clean_data', force
	save `clean_data', replace
}

ds, has(type string)
foreach v in `r(varlist)' {
		encode `v', gen(n_`v')
		drop `v'
		rename n_`v' `v' 
	}