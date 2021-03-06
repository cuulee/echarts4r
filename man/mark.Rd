% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mark.R
\name{e_mark_point}
\alias{e_mark_point}
\alias{e_mark_line}
\title{Mark point}
\usage{
e_mark_point(e, serie = NULL, data = NULL, ...)

e_mark_line(e, serie = NULL, data = NULL, ...)
}
\arguments{
\item{e}{An \code{echarts4r} object as returned by \code{\link{e_charts}}.}

\item{serie}{Serie to mark on, defaults to last added.}

\item{data}{Placement.}

\item{...}{Any other option to pass to \code{bar} or \code{line} char types.}
}
\description{
Mark points and lines.
}
\examples{
max <- list(
  name = "Max",
  type = "max"
)

min <- list(
  name = "Min",
  type = "min"
)

avg <- list(
  type = "average",
  name = "AVG"
)

USArrests \%>\% 
  e_charts(Murder) \%>\% 
  e_line(Rape) \%>\% 
  e_mark_point(data = max) \%>\% 
  e_mark_point(data = min) \%>\% 
  e_mark_line(data = avg)

}
