*****Descriptive Analysis*****

cd "D:\GU\Thesis Data\clean"

use "clean_data.dta", clear

replace size = . if size == 4

recode sector (1 2 3 5 6 7 8 11 13 = 1 "Industry") (4 9 10 12 = 2 "Service"), gen(sector_2)

global y_varlist new_BMGc23a new_BMGc23b new_BMGc23c new_BMGc23d new_BMGc23e new_BMGc23f new_BMGc23g new_BMGc23h new_BMGc23i new_BMGc23j new_BMGc25 

global x_varlist fc f_external state_owned country size sector_2 innovation iso competitor customer cost tax standard

global x_varlist_c f_external state_owned competitor cost

global x_varlist_d fc country size sector_2 iso customer tax standard innovation

******************************
**construct denpendent varibale**
******************************

*****OPTION 1*****

pca $y_varlist

*screeplot

predict pc1, score

*****OPTION 2*****

egen adopt_level = rowtotal($y_varlist)

******************************
**Whether use weights in regression**
******************************

reg pc1 i.fc fc#size fc#sector_2 fc#c.f_external ///
    $x_varlist_c i.country i.size i.sector_2 i.iso i.customer i.tax i.standard ///
	wmedian c.wmedian#fc c.wmedian#fc#size c.wmedian#fc#sector_2 c.wmedian#fc#c.f_external ///
	c.wmedian#c.f_external c.wmedian#c.state_owned c.wmedian#country c.wmedian#size c.wmedian#sector_2 c.wmedian#c.innovation c.wmedian#iso c.wmedian#c.competitor c.wmedian#customer c.wmedian#c.cost c.wmedian#tax c.wmedian#standard

testparm wmedian c.wmedian#fc c.wmedian#fc#size c.wmedian#fc#sector_2 c.wmedian#fc#c.f_external c.wmedian#c.f_external c.wmedian#c.state_owned c.wmedian#country c.wmedian#size c.wmedian#sector_2 c.wmedian#c.innovation c.wmedian#iso c.wmedian#c.competitor c.wmedian#customer c.wmedian#c.cost c.wmedian#tax c.wmedian#standard

* The p-value of the F stat is 0.6630 which is not statistically significant, so I don't use weights in regression analysis

******************************
**OLS**
******************************
reg pc1 i.fc, robust
outreg2 using reg.doc, replace ctitle(Model 1) addtext(Control country, NO)

reg pc1 i.fc i.innovation i.iso, robust
outreg2 using reg.doc, append ctitle(Model 2) addtext(Control country, NO)

reg pc1 i.fc i.innovation i.iso competitor cost i.customer, robust
outreg2 using reg.doc, append ctitle(Model 3) addtext(Control country, NO))

reg pc1 i.fc i.innovation i.iso competitor cost i.customer i.tax i.standard, robust
outreg2 using reg.doc, append ctitle(Model 4) addtext(Control country, NO)

reg pc1 i.fc i.innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned, robust
outreg2 using reg.doc, append ctitle(Model 5) addtext(Control country, NO)

reg pc1 i.fc i.innovation i.iso competitor cost i.customer i.tax i.standard f_external state_owned i.size i.sector_2 i.country, robust
outreg2 using reg.doc, replace ctitle(Model 6) drop(i.country) addtext(Control country, YES)


	
testparm 3.fc 3.fc#size 3.fc#sector_2 3.fc#c.f_external 
