local dir "D:\GU\thesis_data\"

********************************************************************************
**select variables**
********************************************************************************

*** Y
* BMGc23a - BMGc23j: whether adopt a measures (energy-related: a, b, c, d, g, i)
* BMGc25: whether adopt a measure to improve energy efficiency
* BMGc1: monitor energy consumption (maybe not part of eco-innovation)
* BMGc3: external audit energy consumption (too much missing)
* BMGc8, BMGc10: monitor and external audit co2 (too much missing)
* BMGc16: energy consumption target (maybe not part of eco-innovation)
* BMGc18: co2 emissions target (maybe not part of eco-innovation)
* BMGc22: manager responsible for energy consumption, co2, and pollutants (too much missing)
* (BMGc7: whether emit co2)
* (BMGc26: Whether these measures are self-developed)

*** Key X
* k30: the level of financial obstacles
* k3a, k3bc, k3e, k3f: % of working capital financed from ...

*** Covariats
* a1: countries
* a4a: sector - manufactoring, retail, and other service
* a6a: firm size (0: l1: firm size - # of employees)
* b2c: percentage of this firm is owned by government or state
* h8 - h9: whether and how much spend on R&D
* h1, h5, BMh1, BMh2, Bmh3: innovation
* b8 - b8x: Recognized quality certification
* e2: competitors
* n2e, n2b, n2f: costs on materials, electricity and fuel
* n2P: total sale cost
* d2: total sale
* BMGc27: the main reason no measures were adopted (uncertainty)
* BMGd6 - BMGd7: whether subject to tax and standards
* BMd1a, BMd1b: expected sale next year
* BMGa4: whether customers require environmental certifications or adherence to standards
* b7a, b4, b4a: female management

*** Survey： Stratification
* wmedian
* a2: region - strata

*** IV
* c9a, c9b: power outage loss in % or absolute value
* d6: loss of exports due to theft
* d7: loss of exports due to breakag or spoilage
* d10: loss of inports due to theft
* d11: loss of inports due to breakag or spoilage
* i3, i4a, i4b: loss as a result of theft, robbery, vandalism, arson, internet hacking or fraudulent internet transactions
* k1c: percentage of the value of total annual purchases of material inputs or services was purchased on credit

********************************************************************************
**Appending**
********************************************************************************

cd "`dir'data\medium"

tempfile clean_data
save `clean_data', emptyok

foreach i in Albania Bosnia-and-Herzegovina Bulgaria Croatia Cyprus Estonia North-Macedonia Kazakhstan Kosovo Kyrgyz-Republic Latvia Lithuania Mongolia Montenegro Romania Serbia Slovenia Tajikistan Ukraine Uzbekistan Azerbaijan Georgia Jordan Morocco Moldova West-Bank-and-Gaza Lebanon {
	use "`i'-2019-full-data.dta", clear
	keep BMGc23a BMGc23b BMGc23c BMGc23d BMGc23g BMGc23i BMGc25 BMGc1 BMGc16 BMGc18 BMGd6 BMGd7 BMGa4 k30 k3a a1 a2 a4a a6a b2c b8 b8x e2 n2b n2f idstd wmedian h1 h5 BMh1 BMh2 BMh3 i3 i4a i4b k1c
	foreach v in a2 a4a a6a {
		decode `v', gen(`v'_s)
		drop `v'
		rename `v'_s `v' 
	}
	append using `clean_data', force
	save `clean_data', replace
}

foreach v in a2 a4a a6a {
		encode `v', gen(`v'_n)
		drop `v'
		rename `v'_n `v' 
	}

********************************************************************************
**recode variables**
********************************************************************************

* dummies
foreach v in BMGc23a BMGc23b BMGc23c BMGc23d BMGc23g BMGc23i BMGc25 BMGc1 BMGc16 BMGc18 BMGd6 BMGd7 BMGa4 h1 h5 BMh1 BMh2 BMh3 {
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

* size
recode a6a (4 = 1 "Small") (2 = 2 "Medium") (1 8 = 3 "Large") (else = 4 "Unknow"), gen (size)

* finance from external resource
gen f_external = .
replace f_external = 100 - k3a if k3a != -9
label variable f_external "working capital from external sources"

* owned by government
gen state_owned = b2c
replace state_owned = . if inlist(b2c, -9, .)
label variable state_owned "pct owned by government or state"

rename new_BMGc23a heating_cooling
rename new_BMGc23b energy_generation
rename new_BMGc23c machinery_equipment
rename new_BMGc23d energy_management
rename new_BMGc23g vehicles
rename new_BMGc23i lighting_system
rename new_BMGc25 energy_efficiency
rename new_BMGc1 monitor
rename new_BMGc16 energy_target
rename new_BMGc18 co2_target
rename new_BMGd6 tax
rename new_BMGd7 standard
rename new_BMGa4 customer
rename a1 country
rename a2 region
rename a4a sector

gen loss = .
replace loss = i4a if i3 == 1
replace loss = 0 if i3 == 0

drop BMGc23a BMGc23b BMGc23c BMGc23d BMGc23g BMGc23i BMGc25 BMGc1 BMGc16 BMGc18 BMGd6 BMGd7 BMGa4 k30 k3a a6a b2c b8 b8x e2 n2b n2f h1 h5 BMh1 BMh2 BMh3 i3 i4a i4b k1c new_h1 new_h5 new_BMh1 new_BMh2 new_BMh3

save "`dir'data\clean\clean_data.dta", replace

********************************************************************************
**check missing value**
********************************************************************************

egen nmcount = rownonmiss($y_varlist $x_varlist)
tab nmcount