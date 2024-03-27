# The function of this script file is to extract the latent processes from
# the modeled disease series. This script file is based on model.R

# As of 2024-03-26, the standardized log-transformed oral times series will
# modeled as the hope is to compare the incidence of the oral times series
# to the incidence of the influenza time series.

# Loading functions and packages ####
R <- list.files(path = "./R", pattern = "*.R", full.names = TRUE) #nolint
sapply(R, source, .GlobalEnv)

# Importing data ####
oral_ts_trans <- readRDS(file = "./data/monthly_oral_ts_trans.rds")

# Importing models ####
models <- readRDS(file = "./outputs/monthly-oral-ts/models.rds")

# Extracting latent processes ####
extract <- vector(mode = "list", length = length(oral_ts_trans))
names(extract) <- names(oral_ts_trans)
for (j in seq_along(extract)) {
  extract[[j]] <- ss_extract(data = oral_ts_trans[[j]], object = models[[j]])
}

# Exporting model fits ####
saveRDS(
  object = extract,
  file = "./outputs/monthly-oral-ts/extract.rds"
)