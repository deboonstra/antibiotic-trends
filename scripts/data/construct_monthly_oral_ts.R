# The function of this script file is to contstruct a collection of time series
# (ts) objects based on monthly incidence, where the route of admission for the
# antibiotics is oral

# Loading functions and packages ####
R <- list.files(path = "./R", pattern = "*.R", full.names = TRUE) #nolint
sapply(R, source, .GlobalEnv)

# Creating data sub-directory ####
if (!dir.exists("./data/")) {
  dir.create("./data/")
}

# Importing data ####
load(file = "./data-raw/monthly_incidence.RData")

# Obtaining all the oral antibiotics ####
# with non-zero monthly incidence for all months

## Filtering out non-oral antibiotics ####
oral <- subset(x = monthly_incidence, subset = roads == "Oral")

## Filtering out the antibiotics that do NOT have non-zero incidence ####
## for all months during the observational window

### Calculating the maximum number of observations ####
total_obs <- with(
  data = oral,
  expr = {
    length(min(year):max(year)) * 12
  }
)

### Determining the number of observations for each antibiotic ####
no_obs <- dplyr::count(x = oral, name)

### Filtering out anitbiotics ####
all_obs_abx <- c(subset(x = no_obs, subset = n == total_obs)$name)
oral <- subset(x = oral, subset = name %in% all_obs_abx)

## Organizing observations based antibiotic names ####

### Ordering observations ####
### by name, year, and month
oral <- dplyr::arrange(.data = oral, name, year, month)

### Making antibiotic names into variable names ####
oral$name <- tolower(oral$name)
oral$name <- gsub(
  pattern = "[[:punct:]]",
  replacement = "_",
  x = oral$name,
  perl = TRUE
)

# Creating time series (ts) objects for each antibiotic by name ####
# These objects will be based on the inc_prescription variable as
# it provides the incidence for prescriptions taken each month.

## Creating a basis list based on antibiotic names ####
oral_ts <- split(x = oral, f = factor(oral$name))

## Setting the time series object parameters ####
min_year <- min(oral$year) # minimum year
min_month <- min(oral$month)
freq <- 12L # frequency of time series

## Creating ts objects ####
oral_ts <- lapply(
  X = oral_ts,
  FUN = function(x) {
    x <- x[order(x$year, x$month), ]
    x <- x$inc_prescriptions
    x <- stats::ts(
      data = x,
      start = c(min_year, min_month),
      frequency = freq
    )
    return(x)
  }
)

## Creating a standardized log-transformed version of the time series ####
oral_ts_trans <- lapply(
  X = oral_ts,
  FUN = function(x) {
    x <- log(x) # log-transformed
    x <- std(x) # standardized
    return(x)
  }
)
# Exporting data ####

## Oral time series ####
saveRDS(
  object = oral_ts,
  file = "./data/monthly_oral_ts.rds"
)

## Standardized log-transformed oral time series ####
saveRDS(
  object = oral_ts_trans,
  file = "./data/monthly_oral_ts_trans.rds"
)