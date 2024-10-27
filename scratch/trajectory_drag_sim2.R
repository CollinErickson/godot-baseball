# Using calculations with drag that matches velo squared drag at the endpoints
# and is linear between.
# It seems to not give a solution.


library(dplyr)
library(ggplot2)

x2 <- 20
d <- .05
v1 <- 40

dt <- 1./600
x <- 0
v <- v1
a <- -d*v1^2
t <- 0
iii <- 0
df <- NULL
while (x < x2) {
  iii <- iii + 1
  if (iii > 1e5) {break}
  print(data.frame(t, x, v, a))
  df <- rbind(df, data.frame(t, x, v, a))
  t <- t + dt
  x <- x + dt*v
  v <- v + dt*a
  a <- -d*v^2

}
df
head(df)
df %>% ggplot(aes(t, x)) + geom_point()
df %>% ggplot(aes(t, v)) + geom_point()
df %>% ggplot(aes(t, a)) + geom_point()
# df$x_calc <- with(df, 0+v1*t+.5*(ac-d*v1^2)*t^2 - d/(6*t2)*(v2^2-v1^2)*t^3) # Don't know t2

ac <- 0
b <- ac - d/2 * v1^2
e <- .5*(ac-d*v1^2)

f1 <- function(v2) {
  v1*(v2-v1)*(b-d/2*v2^2) + e*(v2^2-v1^2) - d/6*(v2^2-v1^2)*(v2-v1)*(b-d/2*v2^2)  -  x2*(b-d/2*v2^2)
}
c(f1(0), f1(v1/2), f1(v1))
curve(f1, 0, v1)

f2 <- function(v2) {
  t2 <- (v2 - v1) / (ac - d*v1^2 -d/2*(v2^2-v1^2))
  Z = v1*t2 + (ac-d*v1^2)/2*t2^2 - d/6*(v2^2 - v1^2)*t2^2 - (x2)
  print(c(t2, Z))
  Z
}
c(f2(0), f2(v1/2), f2(v1))
curve(f2, 0, v1)
