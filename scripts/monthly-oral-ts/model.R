# The function of this script file is model the oral time series using a
# state-space model proposed by Shumway and Stoffer, and modified by Bengsston
# and Cavanaugh.

# As of 2024-03-26, the standardized log-transformed oral times series will
# modeled as the hope is to compare the incidence of the oral times series
# to the incidence of the influenza time series.

# Loading functions and packages ####
R <- list.files(path = "./R", pattern = "*.R", full.names = TRUE) #nolint
sapply(R, source, .GlobalEnv)

# Creating data sub-directory ####
if (!dir.exists("./outputs/monthly-oral-ts")) {
  dir.create("./outputs/monthly-oral-ts/")
}

# Import data ####
oral_ts_trans <- readRDS(file = "./data/monthly_oral_ts_trans.rds")

# Modeling the observed series into the latent processes for each abx ####

## Defining observation equation design matrix ####
a <- cbind(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

## Defining the design matrix for the state equation
phi <- diag(0, length(a))
phi[1, 1] <- 1
phi[2, ] <- c(0, rep(-1, 11))
w <- which(a == 0)[1]
for (k in seq(w, nrow(phi))) {
  phi[k, (k - 1)] <- 1
}

## Creating model fits ####
models <- vector(mode = "list", length = length(oral_ts_trans))
names(models) <- names(oral_ts_trans)
pb <- utils::txtProgressBar(
  min = 0, max = length(models), style = 3, initial =  "\n"
)
for (j in seq_along(models)) {
  ### Fitting models
  models[[j]] <- tryCatch(
    expr = {
      res <- ss(
        y = oral_ts_trans[[j]],
        a = a,
        phi = phi,
        theta0 = c(0.05, 0.05),
        mu0 = rep(0, 12),
        sigma0 = diag(1, 12),
        control = list(),
        auto = TRUE
      )
    }, warning = function(w) {
      paste(w)
    }, error = function(e) {
      paste(e)
    }, finally = {
      res
    }
  )

  ### Updating progress bar
  utils::setTxtProgressBar(pb, j)
  if (j == length(models)) {
    close(pb)
    cat("\n")
  }
}

## Re-fit models that have negative variance estimates ####

### Determining problematic model fits ####
test <- sapply(
  X = models,
  FUN = function(x) {
    u <- x$u
    check <- all(u$estimate >= 0)
    return(check)
  }
)

print(test <- test[!test])

### Re-fitting models ####

#### cefaclor ####
models$cefaclor <- ss(
  y = oral_ts_trans$cefaclor,
  a = a,
  phi = phi,
  theta0 = c(0.05, 0.005),
  mu0 = rep(0, 12),
  sigma0 = diag(1, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)

#### cefuroxime ####
models$cefuroxime <- ss(
  y = oral_ts_trans$cefuroxime,
  a = a,
  phi = phi,
  theta0 = c(0.05, 0.005),
  mu0 = rep(0, 12),
  sigma0 = diag(0.25, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)

#### cephalexin ####
models$cephalexin <- ss(
  y = oral_ts_trans$cephalexin,
  a = a,
  phi = phi,
  theta0 = c(0.005, 0.0005),
  mu0 = rep(0, 12),
  sigma0 = diag(0.25, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)

#### clindamycin ####
models$clindamycin <- ss(
  y = oral_ts_trans$clindamycin,
  a = a,
  phi = phi,
  theta0 = c(0.0005, 0.005),
  mu0 = rep(0, 12),
  sigma0 = diag(1, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)

#### doxycycline ####
models$doxycycline <- ss(
  y = oral_ts_trans$doxycycline,
  a = a,
  phi = phi,
  theta0 = c(1, 0.0005),
  mu0 = rep(0, 12),
  sigma0 = diag(1, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)
models$doxycycline$u

#### ofloxacin ####
models$ofloxacin <- ss(
  y = oral_ts_trans$ofloxacin,
  a = a,
  phi = phi,
  theta0 = c(0.0005, 0.005),
  mu0 = rep(0, 12),
  sigma0 = diag(1, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)

#### sulfamethoxazole_trimethoprim ####
models$sulfamethoxazole_trimethoprim <- ss(
  y = oral_ts_trans$sulfamethoxazole_trimethoprim,
  a = a,
  phi = phi,
  theta0 = c(0.0005, 0.0005),
  mu0 = rep(0, 12),
  sigma0 = diag(0.25, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)
models$sulfamethoxazole_trimethoprim$u

#### tetracycline ####
models$tetracycline <- ss(
  y = oral_ts_trans$tetracycline,
  a = a,
  phi = phi,
  theta0 = c(0.05, 0.005),
  mu0 = rep(0, 12),
  sigma0 = diag(0.25, 12),
  control = list(trace = 1, REPORT = 1, maxit = 100),
  auto = TRUE
)

# Exporting model fits ####
saveRDS(
  object = models,
  file = "./outputs/monthly-oral-ts/models.rds"
)