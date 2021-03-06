\name{combiner}
\docType{methods}

\alias{combiner}
\alias{combiner<-}

\title{Get or Set combiner for an Object}

\description{
    This is a generic function for getting or setting the 'combiner' for an object with values to combine.
}

\usage{
combiner(object)

combiner(object) <- value
}

\arguments{
    \item{object}{An object with a combiner.}
    
    \item{value}{The value to set the combiner.}
}

\author{Kylie A. Bemis}

\seealso{
    \code{\linkS4class{sparse_mat}}
}

\examples{
x <- sparse_mat(diag(10))
combiner(x)
combiner(x) <- "sum"
x[]
}

\keyword{utilities}
