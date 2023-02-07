********************
**setup**
********************
cd "D:\GU\thesis_data"

********************
**select variables**
********************

*** Y
* BMGc23a - BMGc23j: whether adopt a measures (energy-related: a, b, c, d, g, i)
* BMGc25: whether adopt a measure to improve energy efficiency
* BMGc26: Whether these measures are self-developed
* BMGa1: stratefic objectives
* BMGa2: manager
* BMGc1: monitor energy consumption
* BMGc3: external audit energy consumption (too much missing)
* BMGc4: monior water
* BMGc6: external audit water
* BMGc7: whether emit co2
* BMGc8, BMGc10: monitor and external audit co2 (too much missing)
* BMGc16: energy consumption target
* BMGc18: co2 emissions target
* BMGc22: manager responsible for energy consumption, co2, and pollutants (too much missing)

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

*** Survey: stratification
* wmedian
* a2: region - strata

*** Potential IV
* c9a, c9b: power outage loss in % or absolute value
* d6: loss of exports due to theft
* d7: loss of exports due to breakag or spoilage
* d10: loss of inports due to theft
* d11: loss of inports due to breakag or spoilage
* i3, i4a, i4b: loss as a result of theft, robbery, vandalism, arson, internet hacking or fraudulent internet transactions
* k1c: percentage of the value of total annual purchases of material inputs or services was purchased on credit

********************
**append variables**
********************

***preprocess unmatched variables***

*use "Montenegro-2019-full-data.dta", clear
*destring BMGa12, replace ignore(" Vd000Vd ")
*save "Montenegro-2019-full-data.dta", replace

***prefix before appending***

* Jordan
use "data\raw\Jordan-2019-full-data.dta", clear

label define A6A_N 1 "Small" 2 "Medium" 3 "Large" 4 "Small and Medium" 5 "Medium and Large" 6 "Small, Medium and Large"
label values a6a A6A_N

save "data\medium\Jordan-2019-full-data.dta", replace

* Georgia
use "data\raw\Georgia-2019-full-data.dta", clear

replace a6a = 1 if a6a == . & strata == 51
replace a6a = 2 if a6a == . & strata == 18

replace a4a = 2 if a4a == . & strata == 51
replace a4a = 5 if a4a == . & strata == 18

save "data\medium\Georgia-2019-full-data.dta", replace

* Cyprus
use "data\raw\Cyprus-2019-full-data.dta", clear

label define A6A_N 1 "Small" 2 "Medium" 3 "Large" 4 "Very Large"
label values a6a A6A_N

save "data\medium\Cyprus-2019-full-data.dta", replace

* Other
foreach c in Albania Bosnia-and-Herzegovina Bulgaria Croatia Estonia North-Macedonia Kazakhstan Kosovo Kyrgyz-Republic Latvia Lithuania Mongolia Montenegro Romania Serbia Slovenia Tajikistan Ukraine Uzbekistan Azerbaijan Morocco Moldova West-Bank-and-Gaza Lebanon {
	cd "D:\GU\thesis_data\data\raw"
	use "`c'-2019-full-data.dta", clear
	cd "D:\GU\thesis_data\data\medium"
	save "`c'-2019-full-data.dta", replace
}