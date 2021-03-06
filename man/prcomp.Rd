\name{prcomp}
\docType{methods}

\alias{prcomp}
\alias{prcomp,matter_mat-method}

\title{Principal Components Analysis for ``matter'' Matrices}

\description{
    This method allows computation of a truncated principal components analysis of a \code{\linkS4class{matter_mat}} matrix using the implicitly restarted Lanczos method \code{\link[irlba]{irlba}}.
}

\usage{
\S4method{prcomp}{matter_mat}(x, n = 3, retx = TRUE, center = TRUE, scale. = FALSE, \dots)
}

\arguments{
    \item{x}{A \code{\linkS4class{matter}} matrix.}

    \item{n}{The number of principal componenets to return, must be less than \code{min(dim(x))}.}

    \item{retx}{A logical value indicating whether the rotated variables should be returned.}

    \item{center}{A logical value indicating whether the variables should be shifted to be zero-centered, or a centering vector of length equal to the number of columns of \code{x}. The centering is performed implicitly and does not change the out-of-memory data in \code{x}.}

    \item{scale.}{A logical value indicating whether the variables should be scaled to have unit variance, or a scaling vector of length equal to the number of columns of \code{x}. The scaling is performed implicitly and does not change the out-of-memory data in \code{x}.}

    \item{\dots}{Additional options passed to \code{\link[irlba]{irlba}}.}
}

\value{
	An object of class `prcomp'. See \code{?\link[stats]{prcomp}} for details.
}

\note{
	The 'tol' truncation argument found in the default \code{\link[stats]{prcomp}} method is not supported. In place of the truncation tolerance in the original function, the argument \code{n} explicitly gives the number of principal components to return. A warning is generated if the argument 'tol' is used.
}

\author{Kylie A. Bemis}

\seealso{
    \code{\link[biglm]{bigglm}}
}

\examples{
set.seed(1)

x <- matter_mat(rnorm(1000), nrow=100, ncol=10)

prcomp(x)
}

\keyword{multivariate}
