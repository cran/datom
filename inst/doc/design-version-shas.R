## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment  = "#>",
  eval     = FALSE
)

## ----eval = TRUE--------------------------------------------------------------
library(datom)

clean <- data.frame(
  id    = 1:3,
  score = c(1.5, 2.5, 3.5),
  grp   = factor(c("x", "y", "x")),
  day   = as.Date(c("2026-01-01", "2026-01-02", "2026-01-03"))
)
datom_check_hashable(clean)

## ----eval = TRUE--------------------------------------------------------------
messy <- data.frame(id = 1:2)
messy$notes <- list(c("a", "b"), "c")
messy$z <- c(1 + 2i, 3 + 4i)

report <- datom_check_hashable(messy)
report[report$status == "unsupported", c("column", "class")]

## ----eval = TRUE, echo = FALSE------------------------------------------------
one_col <- function(value) {
  d <- data.frame(placeholder = rep(NA, max(1L, length(value))))
  d$col <- value
  d["placeholder"] <- NULL
  d
}

# One fixture per recourse case. datom dispatches on the class tag, so a bare
# structure() carrying the class is enough to render the advice for the
# package-specific cases without taking a dependency on sf / units / zoo.
fixtures <- list(
  as.POSIXlt("2026-01-01", tz = "UTC"),
  structure(list(1, 2), class = "sfc"),
  list(data.frame(a = 1), data.frame(a = 2)),
  list(1:2, letters[1:2]),
  structure(c(1, 2), class = "units"),
  structure(c(2026.0, 2026.1), class = "yearmon"),
  c(1 + 2i, 3 + 4i),
  as.raw(1:2),
  structure(1:2, class = "myclass")
)

report <- do.call(rbind, lapply(fixtures, function(v) {
  suppressMessages(datom_check_hashable(one_col(v)))
}))

knitr::kable(
  data.frame(Column_class = report$class, Recourse = report$recourse),
  col.names = c("Column class", "Recourse")
)

## -----------------------------------------------------------------------------
# dm <- readRDS("dm.rds")
# datom_write(conn, data = dm, name = "dm")

## ----eval = TRUE--------------------------------------------------------------
.Machine$sizeof.longdouble   # 8 means long double == double

