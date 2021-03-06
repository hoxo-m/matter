
#### Define matter<array> class for array-like data ####
## -------------------------------------------------------

setClass("matter_arr",
	slots = c(data = "atoms"),
	prototype = prototype(
		data = new("atoms"),
		datamode = make_datamode("numeric", type="R"),
		paths = character(),
		filemode = make_filemode("r"),
		chunksize = 1e6L,
		length = 0,
		dim = 0L,
		names = NULL,
		dimnames = NULL,
		ops = NULL),
	contains = "matter",
	validity = function(object) {
		errors <- NULL
		if ( is.null(object@dim) )
			errors <- c(errors, "array must have non-NULL 'dim'")
		if ( prod(object@dim) != object@length )
			errors <- c(errors, paste0("dims [product ", prod(object@dim),
				"] do not match the length of array [", object@length, "]"))
		if ( is.null(errors) ) TRUE else errors
	})

matter_arr <- function(data, datamode = "double", paths = NULL,
					filemode = ifelse(all(file.exists(paths)), "r", "rw"),
					offset = 0, extent = prod(dim), dim = 0, dimnames = NULL,
					chunksize = getOption("matter.default.chunksize"), ...)
{
	if ( !missing(data) ) {
		if ( missing(datamode) )
			datamode <- typeof(data)
		if ( missing(dim) ) {
			if ( !is.array(data) ) {
				stop("data is not an array")
			} else {
				dim <- dim(data)
			}
		}
	}
	if ( all(dim == 0) && all(extent == 0) )
		return(new("matter_arr"))
	if ( length(offset) != length(extent) )
		stop("length of 'offset' [", length(offset), "] ",
			"must equal length of 'extent' [", length(extent), "]")
	if ( length(datamode) != length(extent) )
		datamode <- rep(datamode, length.out=length(extent))
	if ( is.null(paths) )
		paths <- tempfile(tmpdir=getOption("matter.dump.dir"), fileext=".bin")
	paths <- normalizePath(paths, mustWork=FALSE)
	if ( !file.exists(paths) ) {
		if ( missing(data) )
			data <- vector(as.character(widest_datamode(datamode)), length=1)
		filemode <- force(filemode)
		result <- file.create(paths)
		if ( !all(result) )
			stop("error creating file(s)")
	} else if ( !missing(data) && missing(filemode) ) {
		warning("file already exists")
	}
	if ( length(paths) != length(extent) )
		paths <- rep(paths, length.out=length(extent))
	x <- new("matter_arr",
		data=atoms(
			group_id=rep.int(1L, length(extent)),
			source_id=as.integer(factor(paths)),
			datamode=as.integer(make_datamode(datamode, type="C")),
			offset=as.numeric(offset),
			extent=as.numeric(extent)),
		datamode=widest_datamode(datamode),
		paths=levels(factor(paths)),
		filemode=make_filemode(filemode),
		chunksize=as.integer(chunksize),
		length=as.numeric(prod(dim)),
		dim=as.integer(dim),
		names=NULL,
		dimnames=dimnames,
		ops=NULL, ...)
	if ( !missing(data) )
		x[] <- data
	x
}

setMethod("describe_for_display", "matter_arr", function(x) {
	desc1 <- paste0("<", paste0(x@dim, collapse=" x "), " dim> ", class(x))
	desc2 <- paste0("out-of-memory ", x@datamode, " array")
	paste0(desc1, " :: ", desc2)
})

setMethod("preview_for_display", "matter_arr", function(x) {
	if ( length(dim(x)) < 2L ) {
		preview_vector(x)
	} else if ( length(dim(x)) == 2L ) {
		preview_matrix(x)
	} else if ( length(dim(x)) > 2L ) {
		preview_Nd_array(x)
	} else {
		stop("ill-formed array dimensions")
	}
})

setAs("array", "matter_arr", function(from) matter_arr(from, dimnames=dimnames(from)))

as.matter_arr <- function(x) as(x, "matter_arr")

setReplaceMethod("dim", "matter_arr", function(x, value) {
	if ( is.null(value) ) {
		as(x, "matter_vec")
	} else {
		callNextMethod()
	}
})

getArray <- function(x) {
	y <- .Call("C_getVector", x, PACKAGE="matter")
	dim(y) <- dim(x)
	if ( !is.null(dimnames(x)) )
		dimnames(y) <- dimnames(x)
	y
}

setArray <- function(x, value) {
	if ( length(x) %% length(value) != 0 )
		warning("number of items to replace is not ",
			"a multiple of replacement length")
	if ( length(value) != 1 )
		value <- rep(value, length.out=length(x))
	if ( is.logical(value) )
		value <- as.integer(value)
	if ( is.character(value) )
		value <- as.double(value)
	.Call("C_setVector", x, value, PACKAGE="matter")
	if ( validObject(x) )
		invisible(x)
}

getArrayElements <- function(x, ind, drop) {
	for ( k in seq_along(ind) ) {
		if ( is.numeric(ind[[k]]) ) {
			next
		} else if ( is.logical(ind[[k]]) ) {
			ind[[k]] <- logical2index(x, ind[[k]])
		} else if ( is.character(ind[[k]]) ) {
			ind[[k]] <- names2index(x, ind[[k]])
		} else if ( is.null(ind[[k]]) ) {
			ind[[k]] <- seq_len(dim(x)[k])
		}
	}
	dims <- sapply(ind, length)
	if ( any( dims == 0) ) {
		y <- array(vector(mode=as.character(datamode(x))), dim=dims)
	} else {
		i <- linearInd(ind, dim(x))
		y <- .Call("C_getVectorElements", x, i - 1, PACKAGE="matter")
		dim(y) <- sapply(ind, length)
	}
	if ( !is.null(dimnames(x)) )
		dimnames(y) <- mapply(function(dnm, i) dnm[i], dimnames(x), ind)
	if ( drop )
		y <- drop(y)
	y	
}

setArrayElements <- function(x, ind, value) {
	for ( i in seq_along(ind) )
		if ( is.logical(ind[i]) )
			ind[i] <- logical2index(x, ind[i])
	for ( i in seq_along(ind) )
		if ( is.character(ind[i]) )
			ind[i] <- names2index(x, ind[i])
	i <- linearInd(ind, dim(x))
	if ( length(x) %% length(value) != 0 )
		warning("number of items to replace is not ",
			"a multiple of replacement length")
	if ( length(value) != 1 )
		value <- rep(value, length.out=length(i))
	if ( is.logical(value) )
		value <- as.integer(value)
	if ( is.character(value) )
		value <- as.double(value)
	.Call("C_setVectorElements", x, i - 1, value, PACKAGE="matter")
	if ( validObject(x) )
		invisible(x)	
}

setMethod("[",
	c(x = "matter_arr", i = "ANY", j = "ANY", drop = "ANY"),
	function(x, i, j, ..., drop = TRUE) {
		if ( !missing(drop) && is.null(drop) )
			stop("endomorphic subsetting not supported")
		narg <- nargs() - 1 - !missing(drop)
		if ( missing(i) && missing(j) && narg == 1 ) {
			return(getArray(x))
		} else if ( !missing(i) && narg == 1 ) {
			return(as(x, "matter_vec")[i])
		} else if ( narg > 1 && narg != length(dim(x)) ) {
			stop("incorrect number of dimensions")
		}
		ind <- list()
		call <- as.list(match.call(expand.dots=TRUE))[-c(1,2)]
		call$drop <- NULL
		if ( "i" %in% names(call) ) {
			wh <- which(names(call) == "i")
			i <- eval(call[[wh]])
			if ( is.null(i) )
				i <- integer(0)
			ind[[1]] <- i
			call <- call[-wh]
		} else if ( length(dim(x)) >= 1 ) {
			ind[[1]] <- seq_len(dim(x)[1])
		}
		if ( "j" %in% names(call) ) {
			wh <- which(names(call) == "j")
			j <- eval(call[[wh]])
			if ( is.null(j) )
				j <- integer(0)
			ind[[2]] <- j
			call <- call[-wh]
		} else if ( length(dim(x)) >= 2 ) {
			ind[[2]] <- seq_len(dim(x)[2])
		}
		ind <- c(ind, call)
		names(ind) <- names(dim)
		for ( k in seq_along(ind) ) {
			if ( is.vector(ind[[k]]) || is.null(ind[[k]]) ) {
				next
			} else if ( is.name(ind[[k]]) && nchar(ind[[k]]) == 0 ) {
				ind[[k]] <- seq_len(dim(x)[k])
			} else if ( is.name(ind[[k]]) && nchar(ind[[k]]) > 0 ) {
				ind[[k]] <- eval(ind[[k]])
			} else if ( is.call(ind[[k]]) ) {
				ind[[k]] <- eval(ind[[k]])
			}
		}
		getArrayElements(x, ind, drop)
})

setReplaceMethod("[",
	c(x = "matter_arr", i = "ANY", j = "ANY", value = "ANY"),
	function(x, i, j, ..., value) {
		dots <- match.call(expand.dots=FALSE)$...
		narg <- nargs() - 2
		if ( !missing(i) && narg == 1 ) {
			y <- as(x, "matter_vec")
			y[i] <- value
			return(x)
		}
		if ( narg > 1 && narg != length(dim(x)) )
			stop("incorrect number of dimensions")
		if ( missing(i) && missing(j) && length(dots) == 0 )
			return(setArray(x, value))
		if ( missing(i) && length(dim(x)) >= 1 ) {
			i <- seq_len(dim(x)[1])
		} else if ( missing(i) ) {
			stop("subscript out of bounds")
		}
		if ( length(dim(x)) == 1 && missing(j) )
			return(setArrayElements(x, list(i), value))
		if ( missing(j) && length(dim(x)) >= 2 ) {
			j <- seq_len(dim(x)[2])
		} else if ( missing(j) ) {
			stop("subscript out of bounds")
		}
		ind <- c(list(i), list(j), dots)
		for ( k in seq_along(ind) ) {
			if ( is.vector(ind[[k]]) ) {
				next
			} else if ( is.null(ind[[k]])) {
				ind[[k]] <- integer(0)
			} else if ( is.name(ind[[k]]) && nchar(ind[[k]]) == 0 ) {
				ind[[k]] <- seq_len(dim(x)[k])
			} else if ( is.name(ind[[k]]) && nchar(ind[[k]]) > 0 ) {
				ind[[k]] <- eval(ind[[k]])
			} else if ( is.call(ind[[k]]) ) {
				ind[[k]] <- eval(ind[[k]])
			}
		}
		dims <- sapply(ind, length)
		if ( any( dims == 0L) ) {
			x
		} else {
			setArrayElements(x, ind, value)
		}
})


#### Delayed operations on 'matter_arr' ####
## ----------------------------------------

# Arith

setMethod("Arith", c("matter_arr", "matter_arr"),
	function(e1, e2) {
		if ( all(dim(e1) == dim(e2)) ) {
			register_op(e1, NULL, e2, .Generic)
		} else {
			stop("array dims must match exactly for delayed operation")
		}
})

setMethod("Arith", c("matter_arr", "numeric"),
	function(e1, e2) {
		if ( check_comformable_lengths(e1, e2) ) {
			e1 <- register_op(e1, NULL, e2, .Generic)
			if ( datamode(e1)[1] != "numeric" && typeof(e2) == "double" )
				datamode(e1) <- "numeric"
			e1
		}
})

setMethod("Arith", c("numeric", "matter_arr"),
	function(e1, e2) {
		if ( check_comformable_lengths(e1, e2) ) {
			e2 <- register_op(e2, e1, NULL, .Generic)
			if ( datamode(e2)[1] != "numeric" && typeof(e1) == "double" )
				datamode(e2) <- "numeric"
			e2
		}
})

# Compare

setMethod("Compare", c("matter_arr", "matter_arr"),
	function(e1, e2) {
		if ( all(dim(e1) == dim(e2)) ) {
			register_op(e1, NULL, e2, .Generic)
			if ( datamode(e1)[1] != "logical" )
				datamode(e1) <- "logical"
			e1
		} else {
			stop("array dims must match exactly for delayed operation")
		}
})

setMethod("Compare", c("matter_arr", "raw"),
	function(e1, e2) {
		if ( check_comformable_lengths(e1, e2) ) {
			e1 <- register_op(e1, NULL, e2, .Generic)
			if ( datamode(e1)[1] != "logical" )
				datamode(e1) <- "logical"
			e1
		}
})

setMethod("Compare", c("raw", "matter_arr"),
	function(e1, e2) {
		if ( check_comformable_lengths(e1, e2) ) {
			e2 <- register_op(e2, e1, NULL, .Generic)
			if ( datamode(e2)[1] != "logical" )
				datamode(e2) <- "logical"
			e2
		}
})

setMethod("Compare", c("matter_arr", "numeric"),
	function(e1, e2) {
		if ( check_comformable_lengths(e1, e2) ) {
			e1 <- register_op(e1, NULL, e2, .Generic)
			if ( datamode(e1)[1] != "logical" )
				datamode(e1) <- "logical"
			e1
		}
})

setMethod("Compare", c("numeric", "matter_arr"),
	function(e1, e2) {
		if ( check_comformable_lengths(e1, e2) ) {
			e2 <- register_op(e2, e1, NULL, .Generic)
			if ( datamode(e2)[1] != "logical" )
				datamode(e2) <- "logical"
			e2
		}
})

# Logic

setMethod("Logic", c("matter_arr", "matter_arr"),
	function(e1, e2) {
		if ( datamode(e1) != "logical" || datamode(e2) != "logical" )
			warning("datamode is not logical")
		if ( all(dim(e1) == dim(e2)) ) {
			register_op(e1, NULL, e2, .Generic)
			if ( datamode(e1) != "logical" )
				datamode(e1) <- "logical"
			e1
		} else {
			stop("array dims must match exactly for delayed operation")
		}
})

setMethod("Logic", c("matter_arr", "logical"),
	function(e1, e2) {
		if ( datamode(e1) != "logical" )
			warning("datamode is not logical")
		if ( check_comformable_lengths(e1, e2) ) {
			e1 <- register_op(e1, NULL, e2, .Generic)
			if ( datamode(e1) != "logical" )
				datamode(e1) <- "logical"
			e1
		}
})

setMethod("Logic", c("logical", "matter_arr"),
	function(e1, e2) {
		if ( datamode(e2) != "logical" )
			warning("datamode is not logical")
		if ( check_comformable_lengths(e1, e2) ) {
			e2 <- register_op(e2, e1, NULL, .Generic)
			if ( datamode(e2)[1] != "logical" )
				datamode(e2) <- "logical"
			e2
		}
})

# Math

setMethod("exp", "matter_arr",
	function(x) {
		x <- register_op(x, NULL, NULL, "^")
		if ( datamode(x) != "numeric" )
			datamode(x) <- "numeric"
		x
})

setMethod("log", "matter_arr",
	function(x, base) {
		if ( missing(base) ) {
			x <- register_op(x, NULL, NULL, "log")
		} else if ( check_comformable_lengths(x, base) ) {
			x <- register_op(x, base, NULL, "log")
		}
		if ( datamode(x) != "numeric" )
			datamode(x) <- "numeric"
		x
})

setMethod("log2", "matter_arr", function(x) log(x, base=2))

setMethod("log10", "matter_arr", function(x) log(x, base=10))

