x1 <- 0
x2 <- 60
v1 <- 30*3
dt <- 1/30/10
a <- 0
k <- 40
p <- 0

t <- 0
x <- 0
v <- v1
df <- NULL
while (x < x2) {
  if (p == 0) {
    a <- -k
  } else if (p == 1) {
    a <- -x*v
  } else if (p == 2) {
    a <- -x*v^2
  }
  t <- t + dt
  x <- x + dt*v
  v <- v + dt*a
  df <- rbind(df, data.frame(t=t, x=x, v=v))
}
print(df)
plot(df$t, df$x)
plot(df$t, df$v)




x2 <- 60/3
y2 <- -3
s1 <- 40
g <- 10.6
a <- .25*g^2
b <- g*y2-s1^2
c <- x2^2+y2^2
t2 <- (-b - sqrt(b^2-4*a*c)) / (2*a)
t <- sqrt(t2)
vy1 <- (y2 + .5*g*t2) / t
vx1 <- x2/t
c(vx1, vy1, t)

xxx <- 0
ttt <- 0
yyy <- 0
vyyy <- vy1
deltat <- 1e-3
while (ttt < t) {
  ttt <- ttt + deltat
  xxx <- xxx + vx1*deltat
  vyyy <- vyyy -g*deltat
  yyy <- yyy + vyyy*deltat - .5*g*deltat^2
  # yyy <- vy1*ttt + -.5*g*ttt^2
}
c(ttt, xxx, yyy)


x <- 1
y <- 2
z <- 20
sz_z <- .6
vx <- 4.10156
vy <- .5622
vz <- -39.785
g <- 9.8*1.09361
dt <- 1e-3
while(z > sz_z) {
  x <- x +dt*vx
  y <- y +dt*vy
  z <- z +dt*vz
  vy <- vy - g*dt

}
c(x, y, z)
