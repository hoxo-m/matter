\name{delayed-ops}
\docType{methods}

\alias{Arith,matter_vec,numeric-method}
\alias{Arith,numeric,matter_vec-method}
\alias{Arith,matter_vec,matter_vec-method}

\alias{Arith,numeric,matter_matc-method}
\alias{Arith,matter_matc,numeric-method}
\alias{Arith,matter_matc,matter_matc-method}

\alias{Arith,numeric,matter_matr-method}
\alias{Arith,matter_matr,numeric-method}
\alias{Arith,matter_matr,matter_matr-method}

\alias{Arith,matter_arr,matter_arr-method}
\alias{Arith,matter_arr,numeric-method}
\alias{Arith,numeric,matter_arr-method}

\alias{Compare,matter_vec,raw-method}
\alias{Compare,matter_vec,numeric-method}
\alias{Compare,raw,matter_vec-method}
\alias{Compare,numeric,matter_vec-method}
\alias{Compare,matter_vec,matter_vec-method}

\alias{Compare,raw,matter_matc-method}
\alias{Compare,numeric,matter_matc-method}
\alias{Compare,matter_matc,raw-method}
\alias{Compare,matter_matc,numeric-method}
\alias{Compare,matter_matc,matter_matc-method}

\alias{Compare,raw,matter_matr-method}
\alias{Compare,numeric,matter_matr-method}
\alias{Compare,matter_matr,raw-method}
\alias{Compare,matter_matr,numeric-method}
\alias{Compare,matter_matr,matter_matr-method}

\alias{Compare,matter_arr,raw-method}
\alias{Compare,matter_arr,numeric-method}
\alias{Compare,raw,matter_arr-method}
\alias{Compare,numeric,matter_arr-method}
\alias{Compare,matter_arr,matter_arr-method}

\alias{exp,matter_vec-method}
\alias{exp,matter_mat-method}
\alias{exp,matter_arr-method}

\alias{log,matter_vec-method}
\alias{log,matter_matc-method}
\alias{log,matter_matr-method}
\alias{log,matter_arr-method}
\alias{log,matter_vec,numeric-method}
\alias{log,matter_matc,numeric-method}
\alias{log,matter_matr,numeric-method}
\alias{log,matter_arr,numeric-method}

\alias{log2,matter_vec-method}
\alias{log2,matter_mat-method}
\alias{log2,matter_arr-method}

\alias{log10,matter_vec-method}
\alias{log10,matter_mat-method}
\alias{log10,matter_arr-method}


\title{Delayed Operations on ``matter'' Objects}

\description{
    Some arithmetic operations are available as delayed operations on \code{\linkS4class{matter}} objects. With these operations, no data is changed on disk, and the operation is only executed when elements of the object are actually accessed.
}

\details{
    Currently the following operations are supported:

    `Arith': `+', `-', `*', `/', `^'

    `Compare': `==', `>', `<', `!=', `<=', `>='

    `Math': `exp', `log', `log2', `log10'

    Delayed operations are applied at the C++ layer immediately after the elements are read from disk. This means that operations that are implemented in C and/or C++ for efficiency (such as summary statistics) will also reflect the execution of the delayed operations.
}

\value{
    A new \code{\linkS4class{matter}} object with the registered delayed operation. Data on disk is not modified; only object metadata is changed.
}

\author{Kylie A. Bemis}

\seealso{
    \code{\link[methods]{Arith}},
    \code{\link[methods]{Compare}},
    \code{\link[methods]{Math}}
}

\examples{
x <- matter(1:100)
y <- 2 * x + 1

x[1:10]
y[1:10]

mean(x)
mean(y)
}

\keyword{methods}
\keyword{arith}
