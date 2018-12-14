\name{sparse_mat-class}
\docType{class}

\alias{class:sparse_mat}
\alias{sparse_mat}
\alias{sparse_matc}
\alias{sparse_matr}
\alias{sparse_mat-class}
\alias{sparse_matc-class}
\alias{sparse_matr-class}

\alias{keys,sparse_mat-method}
\alias{keys<-,sparse_mat-method}
\alias{keys<-,sparse_matc-method}
\alias{keys<-,sparse_matr-method}
\alias{tolerance,sparse_mat-method}
\alias{tolerance<-,sparse_mat-method}
\alias{combiner,sparse_mat-method}
\alias{combiner<-,sparse_mat-method}
\alias{datamode<-,sparse_mat-method}

\alias{[,sparse_mat-method}
\alias{[,sparse_mat,ANY,ANY,ANY-method}
\alias{[,sparse_mat,ANY,ANY,NULL-method}
\alias{[,sparse_mat,ANY,missing,ANY-method}
\alias{[,sparse_mat,ANY,missing,NULL-method}
\alias{[,sparse_mat,missing,ANY,ANY-method}
\alias{[,sparse_mat,missing,ANY,NULL-method}
\alias{[,sparse_mat,missing,missing,ANY-method}
\alias{[<-,sparse_mat-method}
\alias{[<-,sparse_mat,ANY,ANY,ANY-method}
\alias{[<-,sparse_mat,ANY,missing,ANY-method}
\alias{[<-,sparse_mat,missing,ANY,ANY-method}
\alias{[<-,sparse_mat,missing,missing,ANY-method}

\alias{t,sparse_matc-method}
\alias{t,sparse_matr-method}

\alias{as.matrix,sparse_mat-method}

\alias{is.sparse}
\alias{as.sparse}

\title{Sparse Matrices}

\description{
    The \code{sparse_mat} class implements sparse matrices, potentially stored out-of-memory. Both compressed-sparse-column (CSC) and compressed-sparse-row (CSR) formats are supported. Non-zero elements are internally represented as key-value pairs.
}

\usage{
## Instance creation
sparse_mat(data, datamode = "double", nrow = 0, ncol = 0,
            rowMaj = FALSE, dimnames = NULL, keys = NULL,
            tolerance = c(abs=0), combiner = "identity", \dots)

# Check if an object is a sparse matrix
is.sparse(x)

# Coerce an object to a sparse matrix
as.sparse(x, \dots)

## Additional methods documented below
}

\arguments{
        \item{data}{Either a length-2 'list' with elements 'keys' and 'values' which provide the halves of the key-value pairs of the non-zero elements, or a data matrix that will be used to initialized the sparse matrix. If a list is given, all 'keys' elements must be \emph{sorted} in increasing order.}

        \item{datamode}{A 'character' vector giving the storage mode of the data in virtual memory. Allowable values are R numeric and logical types ('logical', 'integer', 'numeric') and their C equivalents.}

        \item{nrow}{An optional number giving the total number of rows.}

        \item{ncol}{An optional number giving the total number of columns.}

        \item{keys}{Either NULL or a vector with length equal to the number of rows (for CSC matrices) or the number of columns (for CSR matrices). If NULL, then the 'key' portion of the key-value pairs that make up the non-zero elements are assumed to be row or column indices. If a vector, then they define the how the non-zero elements are matched to rows or columns. The 'key' portion of each non-zero element is matched against this canonical set of keys using binary search. Allowed types for keys are 'integer', 'numeric', and 'character'.}

        \item{rowMaj}{Whether the data should be stored using compressed-sparse-row (CSR) representation (as opposed to compressed-sparse-column (CSC) representation). Defaults to 'FALSE', for efficient access to columns. Set to 'TRUE' for more efficient access to rows instead.}

        \item{dimnames}{The names of the sparse matrix dimensions.}

        \item{tolerance}{For 'numeric' keys, the tolerance used for floating-point equality when determining key matches. The vector should be named. Use 'absolute' to use absolute differences, and 'relative' to use relative differences.}

        \item{combiner}{In the case of collisions when matching keys, how the row- or column-vectors should be combined. Acceptable values are "identity", "min", "max", "sum", and "mean". A user-specified function may also be provided. Using "identity" means collisions result in an error. Using "sum" or "mean" results in binning all matches.}

        \item{x}{An object to check if it is a sparse matrix or coerce to a sparse matrix.}

        \item{\dots}{Additional arguments to be passed to constructor.}
}

\section{Slots}{
    \describe{
        \item{\code{data}:}{This slot stores the information about locations of the data in virtual memory and within the files.}

        \item{\code{datamode}:}{The storage mode of the accessed data when read into R. This should a 'character' vector of length one with value 'integer' or 'numeric'.}

        \item{\code{paths}:}{A 'character' vector of the paths to the files where the data are stored.}

        \item{\code{filemode}:}{The read/write mode of the files where the data are stored. This should be 'r' for read-only access, or 'rw' for read/write access.}

        \item{\code{chunksize}:}{The maximum number of elements which should be loaded into memory at once. Used by methods implementing summary statistics and linear algebra. Ignored when explicitly subsetting the dataset.}

        \item{\code{length}:}{The length of the data.}

        \item{\code{dim}:}{Either 'NULL' for vectors, or an integer vector of length one of more giving the maximal indices in each dimension for matrices and arrays.}

        \item{\code{names}:}{The names of the data elements for vectors.}

        \item{\code{dimnames}:}{Either 'NULL' or the names for the dimensions. If not 'NULL', then this should be a list of character vectors of the length given by 'dim' for each dimension. This is always 'NULL' for vectors.}

        \item{\code{ops}:}{Delayed operations to be applied on atoms.}

        \item{keys}{Either NULL or a vector with length equal to the number of rows (for CSC matrices) or the number of columns (for CSR matrices). If NULL, then the 'key' portion of the key-value pairs that make up the non-zero elements are assumed to be row or column indices. If a vector, then they define the how the non-zero elements are matched to rows or columns. The 'key' portion of each non-zero element is matched against this canonical set of keys using binary search. Allowed types for keys are 'integer', 'numeric', and 'character'.}

        \item{\code{tolerance}:}{For 'numeric' keys, the tolerance used for floating-point equality when determining key matches. An attribute 'type' gives whether 'absolute' or 'relative' differences should be used for the comparison.}

        \item{\code{combiner}:}{This is a function determining how the row- or column-vectors should be combined (or not) when key matching collisions occur.}
    }
}

\section{Warning}{
    If 'data' is given as a length-2 list of key-value pairs, no checking is performed on the validity of the key-value pairs, as this may be a costly operation if the list is stored in virtual memory. Each element of the 'keys' element must be \emph{sorted} in increasing order, or behavior may be unexpected.

    Assigning a new data element to the sparse matrix will always sort the key-value pairs of the row or column into which it was assigned.
}

\section{Extends}{
   \code{\linkS4class{matter}}
}

\section{Creating Objects}{
    \code{sparse_mat} instances can be created through \code{sparse_mat()}.
}

\section{Methods}{
    Standard generic methods:
    \describe{
        \item{\code{x[i, j, ..., drop], x[i, j] <- value}:}{Get or set the elements of the sparse matrix. Use \code{drop = NULL} to return a subset of the same class as the object.}

        \item{\code{cbind(x, ...), rbind(x, ...)}:}{Combine sparse matrices by row or column.}

        \item{\code{t(x)}:}{Transpose a matrix. This is a quick operation which only changes metadata and does not touch the data representation.}
    }
}

\value{
    An object of class \code{\linkS4class{sparse_mat}}.
}

\author{Kylie A. Bemis}

\seealso{
    \code{\linkS4class{matter}}
}

\examples{
keys <- list(
    c(1,4,8,10),
    c(2,3,5),
    c(1,2,7,9))

values <- list(
    rnorm(4),
    rnorm(3),
    rnorm(4))

init1 <- list(keys=keys, values=values)

x <- sparse_mat(init1, nrow=10)
x[]

init2 <- matrix(rbinom(100, 1, 0.2), nrow=10, ncol=10)

y <- sparse_mat(init2, keys=letters[1:10])
y[]
}

\keyword{classes}
\keyword{array}
