# data-raw

This sub-directory will never have its contents tracked by Git, as it contains the raw data obtained from MarketScan. Generally, this data will be provided to myself, D. Erik Boonstra, by Aaron Miller, my co-investigator. Below are descriptions of the data received with descriptions of the variables within each data.

## `all_abx_dates.RData`

contains 688,234,200 observations and 7 variables that are associated with prescriptions for MarketScan enrollees using National Drug Code (NDC) directory to label specific drugs.

- `enrolid`: `integer64` unique enrolle identification number for identifying patients. This is stored as 64-bit integers, so the [`bit64`](https://cran.r-project.org/web/packages/bit64/index.html) *R* package is needed to view these values properly
- `ndcnum`: `chr` drug code to identify unique medications, which will serve as the primary linking variable to the `antibiotic_ndc_groupings` data set
- `svcdate`: `int` the date of service (i.e., when the antibiotic was dispensed)
- `daysupp`: `int` number of days supplied
- `metqty`: `num` metric quantity dispensed without regard to packaging format
- `refill`: `int` indicator if the prescription was a refill
- `qty`: `int` number of prescriptions filled

## `antibiotic_ndc_groupings.RData`

contains 24,958 observations and 6 variables that are associated with labeling the National Drug Codes (NDC) for antibiotics.

- `ndcnum`: `chr` drug code to identify unique medications, which will serve as the primary linking variable to the `all_abx_dates` data set
- `name`: `chr` name for the type of antibiotic
- `gennme`: `chr` the generic name for the medication
- `prodname`: `chr` the brand name for the medication
- `roads`: `chr` route of admission (i.e., injection, oral, etc)
- `class`: `chr` a broad class of antibiotics

## `total_enroll.RData`

contains 7,670 observations and 2 variables that are associated with the daily enrollment of individuals in MarketScan.

- `date`: `num` date associated with the total enrollment in MarketScan represented as the number of days from 1970-01-01
- `total_enroll`: `num` the number of individuals that were enrolled in MarketScan

## `monthly_incidence.RData`

contains 25,410 observations and 11 variables that are associated with the monthly antibiotic useage.

- `year`: `num` year that an antibiotic was prescribed
- `month`: `num` month that an antibiotic was prescribed
- `name`: `chr` name for the type of antibiotic
- `roads`: `chr` route of admission (i.e., injection, oral, etc)
- `n_enrollees`: `int` number of distinct enrollees who received the antibiotic
- `n_prescriptions`: `int` number of distinct prescriptions
- `n_daysupp`: `int` total number of days supplied (across all enrollees)
- `mean_enroll`: `num` mean number of enrollees for the month given the year
- `inc_enroll`: `num` incidence of enrollees prescribed an antibiotic (per 100,000 enrollees)
- `inc_prescription`: `num` incidence of distinct prescriptions (per 100,000 enrollees)
- `inc_daysupp`: `num` incidence of days supplied (per 100,000 enrollees)

## `daily_incidence.RData`

contains 500,831 observations and 10 variables that are associated with the daily antibiotic useage.

- `date`: `num` date associated with an antibiotic being prescribed represented as the number of days from 1970-01-01
- `name`: `chr` name for the type of antibiotic
- `roads`: `chr` route of admission (i.e., injection, oral, etc)
- `n_enrollees`: `int` number of distinct enrollees who received the antibiotic
- `n_prescriptions`: `int` number of distinct prescriptions
- `n_daysupp`: `int` total number of days supplied (across all enrollees)
- `total_enroll`: `num` total number of enrollees for the date of interest
- `inc_enroll`: `num` incidence of enrollees prescribed an antibiotic (per 100,000 enrollees)
- `inc_prescription`: `num` incidence of distinct prescriptions (per 100,000 enrollees)
- `inc_daysupp`: `num` incidence of days supplied (per 100,000 enrollees)