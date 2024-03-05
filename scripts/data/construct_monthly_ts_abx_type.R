# The function of this script file is to construct monthly time series for the
# types of antibiotics.
# The output will be a collection of ts objects for each antibiotic identified
# by its name, and scaled by the average monthly enrollees per 1,000,000
# enrollees.

# Loading functions and packages ####
R <- list.files(path = "./R", pattern = "*.R", full.names = TRUE) #nolint
sapply(R, source, .GlobalEnv)

# Creating data sub-directory ####
if (!dir.exists("./data/")) {
  dir.create("./data/")
}

# Importing data ####
load(file = "./data-raw/all_abx_dates.RData")
load(file = "./data-raw/antibiotic_ndc_groupings.RData")
load(file = "./data-raw/total_enroll.RData")

# Construct time series for antibiotics ####

## Give NDC numbers names in RX data ####
antibiotic_ndc_groups_new <- subset(
  x = antibiotic_ndc_groups_new,
  select = c(ndcnum, name, roads)
)

### Removing duplicated NDCs ####
antibiotic_ndc_groups_new <- dplyr::filter(
  .data = antibiotic_ndc_groups_new,
  !duplicated(ndcnum)
)

### Removing non-antibiotics from RX dates ####
rx_dates <- dplyr::filter(
  .data = rx_dates,
  ndcnum %in% antibiotic_ndc_groups_new$ndcnum
)

### Removing NDCs not found in RX data ####
rx_ndc <- unique(rx_dates$ndcnum)
antibiotic_ndc_groups_new <- dplyr::filter(
  .data = antibiotic_ndc_groups_new,
  ndcnum %in% rx_ndc
)

### Simplfying the names for converting to antibiotic names to tgenames of the
# elements of a list ####
antibiotic_ndc_groups_new$name <- gsub(
  pattern = " ",
  replacement = "_",
  x = antibiotic_ndc_groups_new$name,
  fixed = TRUE
)
antibiotic_ndc_groups_new$name <- gsub(
  pattern = "[[:punct:]]",
  replacement = "_",
  x = antibiotic_ndc_groups_new$name
)

### Splitting NDC data in to a list based on name ####
antibiotic_ndc_groups_new <- split(
  x = antibiotic_ndc_groups_new,
  f = factor(antibiotic_ndc_groups_new$name)
)

### Merging the RX dates data with NDC data ####
dc <- parallel::detectCores()
cl <- parallel::makeCluster(dc - 1)
parallel::clusterExport(cl = cl, varlist = ls(envir = .GlobalEnv))
abx_tmp <- parallel::parLapply(
  cl = cl,
  X = antibiotic_ndc_groups_new,
  fun = function(x) {
    #### Pulling NDCs from NDC data ####
    ndc <- unique(x$ndcnum)
    #### Filtering RX dates data to include NDCs of interest ####
    ndc_rx <- dplyr::filter(.data = rx_dates, ndcnum %in% ndc)
    #### Expanding antibiotics data to match RX data ####
    ndc_count <- ndc_rx |> dplyr::count(ndcnum)
    x <- merge(
      x = x,
      y = ndc_count,
      by = "ndcnum",
      all.y = TRUE
    )
    x <- lapply(
      X = seq_len(nrow(x)),
      FUN = function(j) {
        xx <- x[j, ]
        data.frame(
          ndcnum = rep(xx$ndcnum, times = xx$n),
          name = rep(xx$name, times = xx$n),
          roads = rep(xx$roads, times = xx$n)
        )
      }
    )
    x <- dplyr::bind_rows(x)

    #### Merging RX dates data and NDC data ####
    ndc_rx <- ndc_rx[order(ndc_rx$ndcnum), ]
    x <- x[order(x$ndcnum), ]
    ndc_rx <- dplyr::bind_cols(
      ndc_rx,
      subset(x, select = c(name, roads))
    )
    ndc_rx <- dplyr::select(
      .data = ndc_rx,
      enrolid, name, roads, svcdate, daysupp
    )
    #### Output data ####
    return(ndc_rx)
  }
)

## Finding date of service ####
parallel::clusterExport(cl = cl, varlist = ls(envir = .GlobalEnv))
origin_date <- as.Date(x = "1970-01-01", format = "%Y-%m-%d")
abx_tmp <- parallel::parLapply(
  cl = cl,
  X = abx_tmp,
  function(x) {
    x$svcdate <- as.Date(x = x$svcdate, origin = origin_date)
    return(x)
  }
)

## Removing data, where days supplied is less than 0 ####
parallel::clusterExport(cl = cl, varlist = ls(envir = .GlobalEnv))
abx_tmp <- parallel::parLapply(
  cl = cl,
  X = abx_tmp,
  fun = function(x) {
    x <- subset(x = x, subset = daysupp >= 0)
    return(x)
  }
)

## Finding raw counts ####
parallel::clusterExport(cl = cl, varlist = ls(envir = .GlobalEnv))
abx_long <- parallel::parLapply(
  cl = cl,
  X = abx_tmp,
  fun = function(x) {
    ### For every antibiotic name we do the following ####
    tmp <- vector(mode = "list", length = nrow(x))
    for (j in seq_len(nrow(x))) {
      #### Expanding every row by service date and number of days of supply ####
      xx <- x[j, ]
      xx$enddate <- xx$svcdate + xx$daysupp
      all_dates <- seq(from = xx$svcdate, to = xx$enddate, by = 1)
      long <- data.frame(
        enrolid = rep(xx$enrolid, times = length(all_dates)),
        name = rep(xx$name, times = length(all_dates)),
        date = all_dates
      )
      #### Calculating raw count by year and month ####
      long$month <- as.numeric(format(long[[j]]$date, format = "%m"))
      long$year <- as.numeric(format(long[[j]]$date, format = "%Y"))
      tmp[[j]] <- long |>
        dplyr::group_by(name, year, month) |>
        dplyr::tally() |>
        dplyr::rename(rx_count = n) |>
        dplyr::ungroup()
    }
    ### Outputting based on antibiotic name ####
    out <- dplyr::bind_rows(tmp)
    return(out)
  }
)
abx <- dplyr::bind_rows(abx_long)

## Finding total prescription count for each month ####
abx <- abx_long |>
  dplyr::group_by(name, year, month) |>
  dplyr::summarise(total_rx_count = sum(rx_count)) |>
  dplyr::ungroup() |>
  dplyr::arrange(name, year, month)

## Creating a reference object for merging ####
## This will be all the possible combination of name, year, and months.
all_combinations <- expand.grid(
  name = unique(abx$name),
  year = unique(abx$year),
  month = 1:12
)
all_combinations <- all_combinations |>
  dplyr::arrange(name, year, month)

## Merging monthly prescription count with reference data ###
abx <- merge(
  x = abx,
  y = all_combinations,
  by = c("name", "year", "month"),
  all.y = TRUE
)

## Replacing missing values with zero ####
## This is being done because a missing value occurs if a certain antibiotic
## was not dispensed for a given month.
abx$total_rx_count <- ifelse(
  test = is.na(abx$total_rx_count),
  yes = 0,
  no = abx$total_rx_count
)

## Scaling raw monthly counts by average monthly enrollees ####

### Cleaning up enrollment daily data to monthly data ####

#### Transforming numeric date to date variable ####
total_enroll$date <- as.Date(x = total_enroll$date, origin = origin_date)

#### Calculating average monthly enrollment #####
total_enroll$month <- as.numeric(format(total_enroll$date, format = "%m"))
total_enroll$year <- as.numeric(format(total_enroll$date, format = "%Y"))
monthly_enroll <- aggregate(
  x = total_enroll ~ month + year,
  data = total_enroll,
  FUN = mean
)
colnames(monthly_enroll) <- c("month", "year", "avg_monthly_enroll")

### Scaling raw monthly counts by monthly enrollment ####
### Per 1,000,000 enrollees
abx <- merge(
  x = abx,
  y = monthly_enroll,
  by = c("month", "year"),
  all.x = TRUE
)
abx$rate_rx_use <- with(
  data = abx,
  expr = {
    (total_rx_count * 1000000) / avg_monthly_enroll
  }
)

### Dropping unwanting variables ####
abx <- subset(
  x = abx,
  select = c(name, year, month, rate_rx_use)
)

### Re-arrange data ####
abx <- abx[order(abx$name, abx$year, abx$month), ]
rownames(abx) <- NULL

## Constructing ts objects ####
abx_ts <- split(x = abx, f = factor(abx$name))
abx_ts <- lapply(
  X = abx_ts,
  FUN = function(x) {
    x <- x[order(x$year, x$month), ]
    min_year <- min(x$year)
    x <- subset(x = x, select = rate_rx_use)
    x <- stats::ts(
      data = x,
      start = c(min_year, 1),
      frequency = 12
    )
    return(x)
  }
)

## Saving ts objects ####
saveRDS(object = abx_ts, file = "./data/monthly_ts_abx_type.rds")