global dir "D:/GU/thesis_data"

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
* a4b: screening sector 
* a6b: screening firm size
* b2a, b2c, b2d: percentage of this firm is owned by domestic, foreign, and government or state
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
* a4a: sampling sector
* a6a: sampling firm size (0: l1: firm size - # of employees)

*** IV
* c9a, c9b: power outage loss in % or absolute value (NO)
* d6: loss of exports due to theft (NO)
* d7: loss of exports due to breakag or spoilage (NO)
* d10: loss of inports due to theft (NO)
* d11: loss of inports due to breakag or spoilage (NO)
* i3, i4a, i4b: loss as a result of theft, robbery, vandalism, arson, internet hacking or fraudulent internet transactions (NO)
* k1c: percentage of the value of total annual purchases of material inputs or services was purchased on credit
* k2c: percentage of the value of total annual purchases of material inputs or services was sold on credit
* k15a, k15b: outstanding balance of all open lines of credit and loans held by this establishment
* a3x: city/town/village
* a3a: screening region
* a3: population

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