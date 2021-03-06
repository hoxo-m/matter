\name{matter_list-class}
\docType{class}

\alias{class:matter_list}
\alias{matter_list}
\alias{matter_list-class}

\alias{dim,matter_list-method}
\alias{lengths,matter_list-method}

\alias{[,matter_list-method}
\alias{[,matter_list,ANY,missing,ANY-method}
\alias{[,matter_list,ANY,missing,NULL-method}
\alias{[<-,matter_list-method}
\alias{[<-,matter_list,ANY,missing,ANY-method}

\alias{[[,matter_list,ANY,ANY-method}
\alias{[[<-,matter_list,ANY,ANY-method}

\alias{$,matter_list-method}
\alias{$<-,matter_list-method}

\alias{combine,matter_list,ANY-method}

\alias{as.list,matter_list-method}

\title{Out-of-Memory Lists of Vectors}

\description{
    The \code{matter_list} class implements out-of-memory lists.
}

\usage{
## Instance creation
matter_list(data, datamode = "double", paths = NULL,
            filemode = ifelse(all(file.exists(paths)), "r", "rw"),
            offset = c(0, cumsum(sizeof(datamode) * extent)[-length(extent)]),
            extent = lengths, lengths = 0, names = NULL, dimnames = NULL,
            chunksize = getOption("matter.default.chunksize"), \dots)

## Additional methods documented below
}

\arguments{
        \item{data}{An optional data list which will be initially written to the data in virtual memory if provided.}

        \item{datamode}{A 'character' vector giving the storage mode of the data in virtual memory. Allowable values are the C types ('char', 'uchar', short', 'ushort', 'int', 'uint', 'long', 'ulong', 'float') and their R equivalents ('raw', 'logical', 'integer', 'numeric'). See \code{?datatypes} for details.}

        \item{paths}{A 'character' vector of the paths to the files where the data are stored. If 'NULL', then a temporary file is created using \code{\link{tempfile}}.}

        \item{filemode}{The read/write mode of the files where the data are stored. This should be 'r' for read-only access, or 'rw' for read/write access.}

        \item{offset}{A vector giving the offsets in number of bytes from the beginning of each file in 'paths', specifying the start of the data to be accessed for each file.}

        \item{extent}{A vector giving the length of the data for each file in 'paths', specifying the number of elements of size 'datamode' to be accessed from each file.}

        \item{lengths}{A vector giving the length of each element of the list.}

        \item{names}{The names of the data elements.}

        \item{dimnames}{The names of the data elements' data elements.}

        \item{chunksize}{The (suggested) maximum number of elements which should be accessed at once by summary functions and linear algebra. Ignored when explicitly subsetting the dataset.}

        \item{\dots}{Additional arguments to be passed to constructor.}
}

\section{Slots}{
    \describe{
        \item{\code{data}:}{This slot stores the information about locations of the data in virtual memory and within the files.}

        \item{\code{datamode}:}{The storage mode of the \emph{accessed} data when read into R. This is a 'character' vector of with possible values 'raw', 'logical', 'integer', 'numeric', or 'virtual'.}

        \item{\code{paths}:}{A 'character' vector of the paths to the files where the data are stored.}

        \item{\code{filemode}:}{The read/write mode of the files where the data are stored. This should be 'r' for read-only access, or 'rw' for read/write access.}

        \item{\code{chunksize}:}{The maximum number of elements which should be loaded into memory at once. Used by methods implementing summary statistics and linear algebra. Ignored when explicitly subsetting the dataset.}

        \item{\code{length}:}{The length of the data.}

        \item{\code{dim}:}{Either 'NULL' for vectors, or an integer vector of length one of more giving the maximal indices in each dimension for matrices and arrays.}

        \item{\code{names}:}{The names of the data elements for vectors.}

        \item{\code{dimnames}:}{Either 'NULL' or the names for the dimensions. If not 'NULL', then this should be a list of character vectors of the length given by 'dim' for each dimension. This is always 'NULL' for vectors.}

        \item{\code{ops}:}{Delayed operations to be applied on atoms.}
    }
}

\section{Extends}{
   \code{\linkS4class{matter}}
}

\section{Creating Objects}{
    \code{matter_list} instances can be created through \code{matter_list()} or \code{matter()}.
}

\section{Methods}{
    Standard generic methods:
    \describe{
        \item{\code{x[[i]], x[[i]] <- value}:}{Get or set a single element of the list.}

        \item{\code{x[[i, j]]}:}{Get the \code{j}th sub-elements of the \code{i}th element of the list.}

        \item{\code{x[i], x[i] <- value}:}{Get or set the \code{i}th elements of the list.}

        \item{\code{lengths(x)}:}{Get the lengths of all elements in the list.}
    }
}

\value{
    An object of class \code{\linkS4class{matter_list}}.
}

\author{Kylie A. Bemis}

\seealso{
    \code{\linkS4class{matter}}
}

\examples{
x <- matter_list(list(c(TRUE,FALSE), 1:5, c(1.11, 2.22, 3.33)), lengths=c(2,5,3))
x[]
x[1]
x[[1]]

x[[3,1]]
x[[2,1:3]]
}

\keyword{classes}
\keyword{array}
\keyword{IO}
