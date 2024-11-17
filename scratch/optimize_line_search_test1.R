# Bisect line search
opt <- function(f, x0, max_iter, delta=1e-4, step0=1, eps=1e-12) {
  d <- length(x0)
  fx0 <- f(x0)
  if (abs(fx0) < eps) {
    return(list(x0, fx0))
  }
  x1 <- x0
  fx1 <- fx0
  cat('Start:', x1, fx1, "\n")
  for (j in 1:5) {
    cat("Starting round j:", j, x1, fx1, "\n")
    # Starting at x1, estimate gradient
    fdelta <- rep(0, d)
    grad <- rep(0, d)
    for (i in 1:d) {
      xi <- x1
      xi[i] <- x1[i] + delta
      fdelta[i] <- f(xi)
      # print(c(x1, xi, fdelta))
      grad[i] <- (fdelta[i] - fx1) / delta
    }
    cat('grad:', grad, '\n')

    # Now we have direction
    x2 <- x1 - step0 * grad
    fx2 <- f(x2)
    cat('Have x2:', x2, fx2, grad, x1, fx1, "\n")

    if (fx2 < fx1) {
      # Keep going in that direction same distance
      x3 <- x2 + (x2 - x1)
      fx3 <- f(x3)
      # Next time be more confident
      step0 <- step0 * 2
    } else {
      # Went too far, put halfway
      x3 <- x2
      fx3 <- fx2
      x2 <- (x1 + x3) / 2
      fx2 <- f(x2)
      # Next time be less confident
      step0 <- step0 / 2
    }

    # Do bisect/extend steps
    for (k in 1:5) {
      # browser()
      cat("\t\tStarting k:", k, x1, x2, x3, fx1, fx2, fx3, "\n")
      if (fx2 < fx1 && fx2 < fx3) {
        # print('case 1')
        # Case 1: min is in middle (2 ways)
        # Put new point in larger gap
        if (veclength(x2-x1) > veclength(x3-x2)) {
          # New point between x1/x2
          x4 <- (x1+x2) / 2
          fx4 <- f(x4)
          if (fx4 < fx2) {
            # Get rid of x3
            x3 <- x2
            fx3 <- fx2
            x2 <- x4
            fx2 <- fx4
          } else {
            # Get rid of x1
            x1 <- x4
            fx1 <- fx4
          }
        } else {
          # New point between x2/x3
          x4 <- (x2+x3)/2
          fx4 <- f(x4)
          if (fx4 < fx2) {
            # Get rid of x1
            x1 <- x2
            fx1 <- fx2
            x2 <- x4
            fx2 <- fx4
          } else {
            # Get rid of x3
            x3 <- x4
            fx3 <- fx4
          }
        }
      } else if (fx2 < fx1 && fx3 < fx2) {
        print('case 2')
        # Case 2: decreasing (1 way)
        x4 <- x3 + (x3 - x1)
        fx4 <- f(x4)
        # No matter what happens, replace x1 with x4
        x1 <- x2
        fx1 <- fx2
        x2 <- x3
        fx2 <- fx3
        x3 <- x4
        fx3 <- fx4
      } else if (fx2 > fx1 && fx3 > fx2){
        # Case 3: increasing (1 way)
        # Replace x1 with point further back
        print('case 3')
        x3 <- x2
        fx3 <- fx2
        x2 <- x1
        fx2 <- fx1
        x1 <- x2 - (x3 - x2)
        fx1 <- f(x1)
        cat("Case 3 result", x1, x2, x3, fx1, fx2, fx3, "\n")

      } else if (fx2 > fx1 && fx2 > fx3) {
        # Case 4: max is in the middle (2 ways)
        break
        # x4 <- (x1+x2)/2
        # fx4 <- f(x4)
        # x3 <- x4
        # fx3 <- fx4
        # x2 <- x4
        # fx2 <- fx4
      } else {
        cat("No case for", x1, x2, x3, fx1, fx2, fx3, "\n")
      }

      # # x3 <- (x1 + x3) / 2
      # x2 <- x1 + (x3-x1) / 2^k
      # fx2 <- f(x2)
      # # cat("\t\tk:", k, x2, fx2, "\n")
      # if (fx2 < fx1) {
      #   # Get ready for next iter
      #   x1 <- x2
      #   fx1 <- fx2
      #   break
      # }

    } # end k

    # Set point to start at next time
    if (fx2 < fx1) {
      x1 <- x2
      fx1 <- fx2
    } else if (fx3 < fx1) {
      x1 <- x3
      fx3 <- fx3
    }
    cat('End j:', j, min(fx1, fx2, fx3), "\n")
  } # End j

}
veclength <- function(x) {
  sqrt(sum(x*x))
}

# opt(function(x) {x}, 1)
# opt(function(x) {x^2}, 1)
# opt(function(x) {sin(x)}, 1)
opt(function(x) {sin(x[1]) + abs(x[2])^2}, c(1,2))
