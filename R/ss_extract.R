# The function of this script is to extract the trend, seasonal, and anomaly and
# error components based on the observed series and state-space modeling.

# Creating extractation function ####
ss_extract <- function(data, object) {

  # Parameter checking ####
  if (class(data) != "ts") {
    stop("data must be a ts object.")
  }

  if (class(object) != "ss") {
    stop("object must be a ss object produced by ss.")
  }

  # Pulling latent processes ####
  ## Observed
  obs <- stats::ts(
    data = c(data),
    start = stats::tsp(data)[1],
    freq = stats::tsp(data)[3]
  )
  ## Trend
  tsm <- stats::ts(
    object$ks$Xs[1, , ], start = stats::tsp(data)[1], freq = stats::tsp(data)[3]
  )
  ### Standard error
  tsm_se <- sqrt(object$ks$Ps[1, 1, ])
  ## Seasonal
  ssm <- stats::ts(
    object$ks$Xs[2, , ], start = stats::tsp(data)[1], freq = stats::tsp(data)[3]
  )
  ### Standard error
  ssm_se <- sqrt(object$ks$Ps[2, 2, ])
  ## Anomaly and error
  asm <- stats::ts(
    c(data - tsm - ssm), start = stats::tsp(data)[1], freq = stats::tsp(data)[3]
  )

  # Returning object ####
  return(
    structure(
      .Data = list(
        obs = obs,
        tsm = tsm,
        tsm_se = tsm_se,
        ssm = ssm,
        ssm_se = ssm_se,
        asm = asm
      ),
      class = "ss.extract"
    )
  )
}

## Creating a plotting function ####
plot.ss.extract <- function(
  data, confidence_band = FALSE, alpha = 0.05,
  ylim = c(-3, 3), ylab = "Incidence", xlab = "Time",
  main = "", oma = c(2, 2, 0, 0)
) {

  # Parameter checking ####
  if (class(data) != "ss.extract") {
    stop("data must be a ss.extract object produced by signal_extract")
  }

  # Plotting ####
  graphics::par(mfrow = c(4, 1), oma = oma)
  crit_val <- stats::qnorm(p = 1 - (alpha / 2))
  ## Observations
  astsa::tsplot(
    x = data$obs, main = "Observed series", ylab = "", xlab = "", ylim = ylim
  )
  ## Trend
  astsa::tsplot(
    x = data$tsm, main = "Trend component", ylab = "", xlab = "", ylim = ylim
  )
  if (confidence_band) {
    xx <- c(stats::time(data$tsm), rev(stats::time(data$tsm)))
    yy <- c(
      data$tsm - (crit_val * data$tsm_se),
      rev(data$tsm + (crit_val * data$tsm_se))
    )
    graphics::polygon(
      x = xx, y = yy,
      border = NA,
      col = grDevices::gray(level = 0.5, alpha = 0.3)
    )
  }
  ## Seasonal
  astsa::tsplot(
    x = data$ssm, main = "Seasonal component", ylab = "", xlab = "", ylim = ylim
  )
  if (confidence_band) {
    xx <- c(stats::time(data$ssm), rev(stats::time(data$ssm)))
    yy <- c(
      data$ssm - (crit_val * data$ssm_se),
      rev(data$ssm + (crit_val * data$ssm_se))
    )
    graphics::polygon(
      x = xx, y = yy,
      border = NA,
      col = grDevices::gray(level = 0.5, alpha = 0.3)
    )
  }
  ## Anomaly and error
  astsa::tsplot(
    x = data$asm, main = "Local component", ylab = "", xlab = ""
  )
  ## Adding axis labels
  graphics::mtext(text = ylab, side = 2, outer = TRUE, cex = 1, las = 0)
  graphics::mtext(text = xlab, side = 1, outer = TRUE, cex = 1)
  if (oma[3] > 0) {
    graphics::mtext(text = main, side = 3, outer = TRUE, cex = 1)
  }
  par(mfrow = c(1, 1))
}