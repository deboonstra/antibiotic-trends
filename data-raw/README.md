# data-raw

This sub-directory will never have its contents tracked by Git, as it contains the raw data obtained from MarketScan. Generally, this data will be provided to myself, D. Erik Boonstra, by Aaron Miller, my co-investigator. Below are descriptions of the data received with descriptions of the variables within each data.

`all_abx_dates.RData`

- `enrolid`: `integer64` unique enrolle identification number for identifying patients. This is stored as 64-bit integers, so the [`bit64`](https://cran.r-project.org/web/packages/bit64/index.html) *R* package is needed to view these values properly
- `ndcnum`: `chr` drug code to identify unique medications, which will serve as the primary linking variable to the `antibiotic_ndc_groupings` data set
- `svcdate`: `int` the date of service (i.e., when the antibiotic was dispensed)
- `daysupp`: `int` number of days supplied
- `metqty`: `num` metric quantity dispensed without regard to packaging format
- `refill`: `int` indicator if the prescription was a refill
- `qty`: `int` number of prescriptions filled

`antibiotic_ndc_groupings.RData`

- `ndcnum`: `char` drug code to identify unique medications, which will serve as the primary linking variable to the `all_abx_dates` data set
- `name`: `char` name for the type of antibiotic
- `gennme`: `char` the generic name for the medication
- `prodname`: `char` the brand name for the medication
- `roads`: `char` route of admission (i.e., injection, oral, etc)
- `class`: `char` a broad class of antibiotics

`total_enroll.RData`