# The function of this script file is to use state-space model to model the
# latent components of the observed series: trend, seasonal, and anomaly and
# error components of series based on the analysis performed by Shumway and
# Stoffer in 6.10. However, we made some adjustments:
# 1. The design matrix for the state equation has dimensions related to the A
# matrix in the observational equation.
# 2. We are using a random walk to model the trend component
# 3. We forced the trend variance to be equivalent to the seasonal variance.
ss <- function(
  y, a, phi, theta0, mu0, sigma0,
  var_ratio = 1, control = list(trace = 1, REPORT = 1), auto = FALSE
) {

  # Checking parameters ####
  if (!("ts" %in% class(y))) {
    stop("y must be a stats::ts object.")
  }

  if (dim(phi)[1] != dim(phi)[2]) {
    stop("phi must be square.")
  }

  if (dim(sigma0)[1] != dim(sigma0)[2]) {
    stop("sigma0 must be square.")
  }

  if (length(a) != dim(phi)[1]) {
    stop("a and phi are not conformable.")
  }

  if (length(mu0) != dim(phi)[1]) {
    stop("mu0 and phi are not conformable.")
  }

  if (dim(sigma0)[1] != dim(phi)[1]) {
    stop("sigma0 and phi are not conformable.")
  }

  if (!is.numeric(var_ratio)) {
    stop("var_ratio must be numeric.")
  }

  if (class(control) != "list") {
    stop("control must be a list.")
  }

  if (!is.logical(auto)) {
    stop("auto must be a logical.")
  }

  # Definining likelihood for structural model ####
  # presented by Shumway and Stoffer in chapter 6 example 10.
  likelihood <- function(theta, y, a, phi, mu0, sigma0, var_ratio) {

    # Defining the variances for the trend and seasonal components
    # Forcing the trend variance to be based on the seasonal variance
    sq <- diag(0, length(a))
    sq[1, 1] <- theta[1] / var_ratio
    sq[2, 2] <- theta[1]

    # Defining the variance of the observational equation
    sr <- theta[2]

    # Filtering series
    kf <- astsa::Kfilter(
      y = y, A = a, mu0 = mu0, Sigma0 = sigma0, Phi = phi, sQ = sq, sR = sr
    )

    # Returning likelihood
    return(kf$like)
  }

  # Estimation ####
  est <- stats::optim(
    par = theta0, fn = likelihood, gr = NULL,
    y = y, a = a, phi = phi, mu0 = mu0, sigma0 = sigma0, var_ratio = var_ratio,
    method = "BFGS", hessian = TRUE, control = control
  )
  u <- data.frame(estimate = est$par, se = sqrt(diag(solve(est$hessian))))
  rownames(u) <- c("sigw2", "sigv")

  # Smoothing ####
  sq <- diag(0, length(a))
  sq[1, 1] <- u$estimate[1] / var_ratio
  sq[2, 2] <- u$estimate[1]
  sr <- u$estimate[2]
  ks <- astsa::Ksmooth(
    y = y, A = a, mu0 = mu0, Sigma0 = sigma0, Phi = phi, sQ = sq, sR = sr
  )

  # Return estimates
  if (!auto) {
    cat("\nu = estimates\ntrend = ks$Xs[1, , ] and seasonal = ks$Xs[2, , ]\n")
  }
  out <- structure(
    .Data = list(u = u, ks = ks, convergence = est$convergence),
    class = "ss"
  )
  return(out)
}