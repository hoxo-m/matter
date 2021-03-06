

#### Define matter<virtual matrix> classes for virtual data ####
## -------------------------------------------------------------

setClass("virtual_mat",
	slots = c(
		index = "list_OR_NULL",
		transpose = "logical"),
	prototype = prototype(
		datamode = make_datamode(c("virtual", "numeric"), type="R"),
		dim = c(0L,0L),
		dimnames = NULL,
		index = NULL,
		transpose = FALSE),
	contains = c("matter_vt", "VIRTUAL"),
	validity = function(object) {
		errors <- NULL
		if ( is.null(object@dim) )
			errors <- c(errors, "virtual matrix must have non-NULL 'dim'")
		if ( length(object@dim) != 2 )
			errors <- c(errors, "virtual matrix must have 'dim' of length 2")
		if ( prod(object@dim) != object@length )
			errors <- c(errors, paste0("dims [product ", prod(object@dim),
				"] do not match the length of array [", object@length, "]"))
		if ( is.null(errors) ) TRUE else errors
	})

setClass("virtual_matc",
	prototype = prototype(
		data = list(),
		datamode = make_datamode(c("virtual", "numeric"), type="R"),
		paths = character(),
		filemode = make_filemode(),
		chunksize = 1e6L,
		length = 0,
		dim = c(0L,0L),
		names = NULL,
		dimnames = NULL,
		ops = NULL,
		index = NULL,
		transpose = FALSE),
	contains = "virtual_mat",
	validity = function(object) {
		errors <- NULL
		if ( is.null(dim(object@data[[1]])) ) {
			if ( length(unique(sapply(object@data, length))) != 1 )
				errors <- c(errors, "elements of 'data' must have the same length")
		} else {
			if ( length(unique(sapply(object@data, nrow))) != 1 )
				errors <- c(errors, "elements of 'data' must have the same number of rows")
		}
		if ( is.null(errors) ) TRUE else errors
	})

setClass("virtual_matr",
	prototype = prototype(
		data = list(),
		datamode = make_datamode(c("virtual", "numeric"), type="R"),
		paths = character(),
		filemode = make_filemode(),
		chunksize = 1e6L,
		length = 0,
		dim = c(0L,0L),
		names = NULL,
		dimnames = NULL,
		ops = NULL,
		index = NULL,
		transpose = FALSE),
	contains = "virtual_mat",
	validity = function(object) {
		errors <- NULL
		if ( is.null(dim(object@data[[1]])) ) {
			if ( length(unique(sapply(object@data, length))) != 1 )
				errors <- c(errors, "elements of 'data' must have the same length")
		} else {
			if ( length(unique(sapply(object@data, ncol))) != 1 )
				errors <- c(errors, "elements of 'data' must have the same number of columns")
		}
		if ( is.null(errors) ) TRUE else errors
	})

virtual_mat <- function(data, datamode = "double", rowMaj = FALSE,
						dimnames = NULL, index = NULL, transpose = FALSE,
						chunksize = getOption("matter.default.chunksize"), ...) {
	if ( !is.list(data) )
		data <- list(data)
	if ( missing(datamode) ) {
		if ( is.atomic(data[[1]]) )
			datamode <- typeof(data[[1]])
		if ( is.matter(data[[1]]) )
			datamode <- datamode(data[[1]])
	}
	datamode <- as.character(make_datamode(datamode, type="R"))
	if ( rowMaj ) {
		mclass <- "virtual_matr"
		if ( !is.null(dim(data[[1]])) ) {
			nrow <- sum(sapply(data, nrow))
			ncol <- ncol(data[[1]])
		} else {
			nrow <- length(data)
			ncol <- length(data[[1]])
		}
	} else {
		mclass <- "virtual_matc"
		if ( !is.null(dim(data[[1]])) ) {
			nrow <- nrow(data[[1]])
			ncol <- sum(sapply(data, ncol))
		} else {
			nrow <- length(data[[1]])
			ncol <- length(data)
		}
	}
	if ( datamode[1] != "virtual" )
		datamode <- make_datamode(c("virtual", datamode), type="R")
	x <- new(mclass,
		data=data,
		datamode=datamode,
		paths=character(),
		filemode=make_filemode(),
		chunksize=as.integer(chunksize),
		length=as.numeric(prod(c(nrow, ncol))),
		dim=as.integer(c(nrow, ncol)),
		names=NULL,
		dimnames=dimnames,
		ops=NULL,
		index=index)
	if ( isTRUE(transpose) )
		x <- t(x)
	x
}

setMethod("describe_for_display", "virtual_mat", function(x) {
	desc1 <- paste0("<", x@dim[[1]], " row, ", x@dim[[2]], " column> ", class(x))
	desc2 <- paste0("virtual ", x@datamode[2], " matrix")
	paste0(desc1, " :: ", desc2)
})

setMethod("preview_for_display", "virtual_mat", function(x) preview_matrix(x))

setAs("ANY", "virtual_matc",
	function(from) virtual_mat(from, dimnames=dimnames(from), rowMaj=FALSE))

setAs("ANY", "virtual_matr",
	function(from) virtual_mat(from, dimnames=dimnames(from), rowMaj=TRUE))

setAs("matrix", "virtual_mat",
	function(from) virtual_mat(from, datamode=typeof(from), dimnames=dimnames(from)))

setAs("array", "virtual_mat",
	function(from) virtual_mat(as.matrix(from), datamode=typeof(from), dimnames=dimnames(from)))

as.virtual <- function(x, ...) as(x, "virtual_mat")

is.virtual <- function(x) is(x, "virtual_mat")

setAs("virtual_mat", "matrix", function(from) from[])

setMethod("as.matrix", "virtual_mat", function(x) as(x, "matrix"))

getVirtualMatrixElements <- function(x, i, j, drop=TRUE) {
	if ( is.null(i) ) {
		if ( is.null(x@index[[1]]) ) {
			rows <- seq_len(dim(x)[1])
		} else {
			rows <- x@index[[1]]
		}
	} else {
		if ( is.logical(i) )
			i <- logical2index(x, i, 1)
		if ( is.character(i) )
			i <- dimnames2index(x, i, 1)
		if ( is.null(x@index[[1]]) ) {
			rows <- i
		} else {
			rows <- x@index[[1]][i]
		}
	}
	if ( is.null(j) ) {
		if ( is.null(x@index[[2]]) ) {
			cols <- seq_len(dim(x)[2])
		} else {
			cols <- x@index[[2]]
		}
	} else {
		if ( is.logical(j) )
			j <- logical2index(x, j, 2)
		if ( is.character(j) )
			j <- dimnames2index(x, j, 2)
		if ( is.null(x@index[[2]]) ) {
			cols <- j
		} else {
			cols <- x@index[[2]][j]
		}
	}
	nrow <- length(rows)
	ncol <- length(cols)
	if ( x@transpose ) {
		t.rows <- rows
		t.cols <- cols
		rows <- t.cols
		cols <- t.rows
	}
	vmode <- as.character(x@datamode[2])
	init <- as.vector(NA, mode=vmode)
	y <- matrix(init, nrow=nrow, ncol=ncol)
	if ( is(x, "virtual_matc") ) {
		if ( !is.null(dim(x@data[[1]])) ) {
			colranges <- c(0, cumsum(sapply(x@data, ncol)))
			wh <- findInterval(cols, colranges, left.open=TRUE)
		}
		for ( jj in seq_along(cols) ) {
			if ( !is.null(dim(x@data[[1]])) ) {
				e <- wh[jj]
				vals <- x@data[[e]][rows, cols[jj] - colranges[e]]
			} else {
				vals <- x@data[[cols[jj]]][rows]
			}
			if ( x@transpose ) {
				y[jj,] <- as.vector(vals, mode=vmode)
			} else {
				y[,jj] <- as.vector(vals, mode=vmode)
			}
		}
	} else if ( is(x, "virtual_matr") ) {
		if ( !is.null(dim(x@data[[1]])) ) {
			rowranges <- c(0, cumsum(sapply(x@data, nrow)))
			wh <- findInterval(rows, rowranges, left.open=TRUE)
		}
		for ( ii in seq_along(rows) ) {
			if ( !is.null(dim(x@data[[1]])) ) {
				e <- wh[ii]
				vals <- x@data[[e]][rows[ii] - rowranges[e], cols]
			} else {
				vals <- x@data[[rows[ii]]][cols]
			}
			if ( x@transpose ) {
				y[,ii] <- as.vector(vals, mode=vmode)
			} else {
				y[ii,] <- as.vector(vals, mode=vmode)
			}
		}
	}
	if ( !is.null(dimnames(x)) )
		dimnames(y) <- dimnames(x)
	if ( drop ) 
		y <- drop(y)
	y
}

getVirtualMatrixRows <- function(x, i, drop=TRUE) {
	getVirtualMatrixElements(x, i, NULL, drop=drop)
}

getVirtualMatrixCols <- function(x, j, drop=TRUE) {
	getVirtualMatrixElements(x, NULL, j, drop=drop)	
}

getVirtualMatrix <- function(x) {
	getVirtualMatrixElements(x, NULL, NULL, drop=FALSE)
}

subVirtualMatrix <- function(x, i, j) {
	if ( is.logical(i) )
		i <- logical2index(x, i, 1)
	if ( is.character(i) )
		i <- dimnames2index(x, i, 1)
	if ( is.logical(j) )
		j <- logical2index(x, j, 2)
	if ( is.character(j) )
		j <- dimnames2index(x, j, 2)
	if ( !is.null(i) ) {
		if ( any(i > x@dim[1]) )
			stop("subscript out of bounds")
		if ( is.null(x@index[[1]]) ) {
			x@index <- list(i, x@index[[2]])
		} else {
			x@index[[1]] <- x@index[[1]][j]
		}
		x@dim[1] <- length(i)
		if ( !is.null(dimnames(x)) )
			x@dimnames[[1]] <- x@dimnames[[1]][i]
	}
	if ( !is.null(j) ) {
		if ( any(j > x@dim[2]) )
			stop("subscript out of bounds")
		if ( is.null(x@index[[2]]) ) {
			x@index <- list(x@index[[1]], j)
		} else {
			x@index[[2]] <- x@index[[2]][j]
		}
		x@dim[2] <- length(j)
		if ( !is.null(dimnames(x)) )
			x@dimnames[[2]] <- x@dimnames[[2]][j]
	}
	x@length <- as.numeric(prod(x@dim))
	if ( validObject(x) )
		x
}

subVirtualMatrixRows <- function(x, i) {
	subVirtualMatrix(x, i, NULL)
}

subVirtualMatrixCols <- function(x, j) {
	subVirtualMatrix(x, NULL, j)	
}

setMethod("[",
	c(x = "virtual_mat", i = "ANY", j = "ANY", drop = "ANY"),
	function(x, i, j, ..., drop) {
		narg <- nargs() - 1 - !missing(drop)
		if ( !missing(i) && narg == 1 )
			stop("linear indexing not supported")
		if ( narg > 1 && narg != length(dim(x)) )
			stop("incorrect number of dimensions")
		if ( !missing(i) && is.null(i) )
			i <- integer(0)
		if ( !missing(j) && is.null(j) )
			j <- integer(0)
		if ( !missing(i) && !missing(j) ) {
			getVirtualMatrixElements(x, i, j, drop)
		} else if ( !missing(i) ) {
			getVirtualMatrixRows(x, i, drop)
		} else if ( !missing(j) ) {
			getVirtualMatrixCols(x, j, drop)
		} else {
			getVirtualMatrix(x)
		}
	})

setMethod("[",
	c(x = "virtual_mat", i = "ANY", j = "ANY", drop = "NULL"),
	function(x, i, j, ..., drop) {
		narg <- nargs() - 1 - !missing(drop)
		if ( !missing(i) && narg == 1 )
			stop("linear indexing not supported")
		if ( narg > 1 && narg != length(dim(x)) )
			stop("incorrect number of dimensions")
		if ( !missing(i) && is.null(i) )
			i <- integer(0)
		if ( !missing(j) && is.null(j) )
			j <- integer(0)
		if ( !missing(i) && !missing(j) ) {
			subVirtualMatrix(x, i, j)
		} else if ( !missing(i) ) {
			subVirtualMatrixRows(x, i)
		} else if ( !missing(j) ) {
			subVirtualMatrixCols(x, j)
		} else {
			x
		}
	})

# combine by rows

setMethod("combine_by_rows", c("virtual_matr", "virtual_matr"),
	function(x, y, ...)
{
	if ( ncol(x) != ncol(y) )
		stop("number of columns of matrices must match")
	if ( !is.null(x@ops) || !is.null(y@ops) )
		warning("dropping delayed operations")
	xi <- x@index
	yi <- y@index
	comformable_cols <- is.null(xi[[2]]) && is.null(yi[[2]])
	is_transposed <- x@transpose || y@transpose
	if ( comformable_cols && !is_transposed ) {
		if ( is.null(xi[[1]]) && is.null(yi[[1]]) ) {
			index <- NULL
		} else {
			if ( is.null(xi[[1]]) )
				xi[[1]] <- seq_len(nrow(x))
			if ( is.null(yi[[1]]) ) {
				yi[[1]] <- seq_len(nrow(y)) + nrow(x)
			} else {
				yi[[1]] <- yi[[1]] + nrow(x)
			}
			index <- list(c(xi[[1]], yi[[1]]), NULL)
		}
		new(class(x),
			data=c(x@data, y@data),
			datamode=x@datamode,
			paths=x@paths,
			filemode=x@filemode,
			length=x@length + y@length,
			dim=c(x@dim[1] + y@dim[1], x@dim[2]),
			names=NULL,
			dimnames=combine_rownames(x,y),
			ops=NULL,
			index=index,
			transpose=FALSE)
	} else {
		callNextMethod()
	}
})

setMethod("combine_by_rows", c("virtual_mat", "virtual_mat"),
	function(x, y, ...)
{
	if ( ncol(x) != ncol(y) )
		stop("number of columns of matrices must match")
	if ( !is.null(x@ops) || !is.null(y@ops) )
		warning("dropping delayed operations")
	new("virtual_matr",
		data=list(x, y),
		datamode=x@datamode,
		paths=x@paths,
		filemode=x@filemode,
		length=x@length + y@length,
		dim=c(x@dim[1] + y@dim[1], x@dim[2]),
		names=NULL,
		dimnames=combine_rownames(x,y),
		ops=NULL,
		index=NULL,
		transpose=FALSE)
})

setMethod("combine_by_rows", c("virtual_mat", "ANY"),
	function(x, y, ...) combine_by_rows(x, as(y, "virtual_matr")))

setMethod("combine_by_rows", c("ANY", "virtual_mat"),
	function(x, y, ...) combine_by_rows(as(x, "virtual_matr"), y))

setMethod("combine_by_rows", c("matter", "matter"),
	function(x, y, ...)
{
	combine_by_rows(as(x, "virtual_matr"), as(y, "virtual_matr"))
})

# combine by cols

setMethod("combine_by_cols", c("virtual_matc", "virtual_matc"),
	function(x, y, ...)
{
	if ( nrow(x) != nrow(y) )
		stop("number of rows of matrices must match")
	if ( !is.null(x@ops) || !is.null(y@ops) )
		warning("dropping delayed operations")
	xi <- x@index
	yi <- y@index
	comformable_rows <- is.null(xi[[1]]) && is.null(yi[[1]])
	is_transposed <- x@transpose || y@transpose
	if ( comformable_rows && !is_transposed ) {
		if ( is.null(xi[[2]]) && is.null(yi[[2]]) ) {
			index <- NULL
		} else {
			if ( is.null(xi[[2]]) )
				xi[[2]] <- seq_len(ncol(x))
			if ( is.null(yi[[2]]) ) {
				yi[[2]] <- seq_len(ncol(y)) + ncol(x)
			} else {
				yi[[2]] <- yi[[2]] + ncol(x)
			}
			index <- list(NULL, c(xi[[2]], yi[[2]]))
		}
		new(class(x),
			data=c(x@data, y@data),
			datamode=x@datamode,
			paths=x@paths,
			filemode=x@filemode,
			length=x@length + y@length,
			dim=c(x@dim[1], x@dim[2] + y@dim[2]),
			names=NULL,
			dimnames=combine_colnames(x,y),
			ops=NULL,
			index=index,
			transpose=FALSE)
	} else {
		callNextMethod()
	}
})

setMethod("combine_by_cols", c("virtual_mat", "virtual_mat"),
	function(x, y, ...)
{
	if ( nrow(x) != nrow(y) )
		stop("number of rows of matrices must match")
	if ( !is.null(x@ops) || !is.null(y@ops) )
		warning("dropping delayed operations")
	new("virtual_matc",
		data=list(x, y),
		datamode=x@datamode,
		paths=x@paths,
		filemode=x@filemode,
		length=x@length + y@length,
		dim=c(x@dim[1], x@dim[2] + y@dim[2]),
		names=NULL,
		dimnames=combine_colnames(x,y),
		ops=NULL,
		index=NULL,
		transpose=FALSE)
})

setMethod("combine_by_cols", c("virtual_mat", "ANY"),
	function(x, y, ...) combine_by_cols(x, as(y, "virtual_matc")))

setMethod("combine_by_cols", c("ANY", "virtual_mat"),
	function(x, y, ...) combine_by_cols(as(x, "virtual_matc"), y))

setMethod("combine_by_cols", c("matter", "matter"),
	function(x, y, ...)
{
	combine_by_cols(as(x, "virtual_matc"), as(y, "virtual_matc"))
})

# transpose

setMethod("t", "virtual_mat", function(x)
{
	x@dim <- rev(x@dim)
	x@dimnames <- rev(x@dimnames)
	x@index <- rev(x@index)
	x@transpose <- !x@transpose
	if ( validObject(x) )
		x
})

#### Matrix multiplication for virtual matter objects ####
## ------------------------------------------------------

rightMatrixMult <- function(x, y, useOuter = FALSE) {
	ret <- matrix(0, nrow=nrow(x), ncol=ncol(y))
	if ( useOuter ) {
		for ( i in 1:ncol(x) )
			ret <- ret + outer(x[,i], y[i,])
	} else {
		for ( i in 1:nrow(x) )
			ret[i,] <- x[i,,drop=FALSE] %*% y
	}
	ret
}

leftMatrixMult <- function(x, y, useOuter = FALSE) {
	ret <- matrix(0, nrow=nrow(x), ncol=ncol(y))
	if ( useOuter ) {
		for ( i in 1:nrow(y) )
			ret <- ret + outer(x[,i], y[i,])
	} else {
		for ( i in 1:ncol(y) )
			ret[,i] <- x %*% y[,i,drop=FALSE]
	}
	ret
}

# matrix x matrix

setMethod("%*%", c("virtual_matc", "matrix"), function(x, y)
{
	rightMatrixMult(x, y, useOuter=TRUE)
})

setMethod("%*%", c("virtual_matr", "matrix"), function(x, y)
{
	rightMatrixMult(x, y, useOuter=FALSE)
})

setMethod("%*%", c("matrix", "virtual_matc"), function(x, y)
{
	leftMatrixMult(x, y, useOuter=FALSE)
})

setMethod("%*%", c("matrix", "virtual_matr"), function(x, y)
{
	leftMatrixMult(x, y, useOuter=TRUE)
})
