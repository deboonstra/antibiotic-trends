# The function of this script file is create a function that standardized a
# numeric vector x.
std <- function(x) {
  if (!is.numeric(x)) {
    stop("x must be numeric.")
  }

  # Standardizing x
  x <- (x - mean(x)) / stats::sd(x)

  # Return standardized value
  return(x)
}