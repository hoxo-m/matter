
#### Define matter<virtual> class for virtual matter objects ####
## --------------------------------------------------------------

setClass("matter_vt",
	slots = c(data = "list"),
	contains = c("matter", "VIRTUAL"),
	prototype = prototype(
		data = list(),
		datamode = make_datamode("virtual", type="R"),
		filemode = make_filemode(),
		dim = 0L,
		dimnames = NULL),
	validity = function(object) {
		errors <- NULL
		if ( !"virtual" %in% object@datamode )
			errors <- c(errors, "'datamode' must include 'virtual'")
		if ( is.null(errors) ) TRUE else errors
	})

setReplaceMethod("datamode", "matter_vt", function(x, value) {
	x@data <- lapply(x@data, function(a) {
		if ( is.matter(a) )
			datamode(a) <- value
		a
	})
	if ( value[1] != "virtual" )
		x@datamode <- make_datamode(c("virtual", value), type="R")
	if ( validObject(x) )
		x
})

setReplaceMethod("paths", "matter_vt", function(x, value) {
	x@data <- lapply(x@data, function(a) {
		if ( is.matter(a) )
			paths(a) <- value
		a
	})
	callNextMethod(x, value)
})

setReplaceMethod("filemode", "matter_vt", function(x, value) {
	x@data <- lapply(x@data, function(a) {
		if ( is.matter(a) )
			filemode(a) <- value
		a
	})
	callNextMethod(x, value)
})

setReplaceMethod("readonly", "matter_vt", function(x, value) {
	x@data <- lapply(x@data, function(a) {
		if ( is.matter(a) )
			readonly(a) <- value
		a
	})
	callNextMethod(x, value)
})

setReplaceMethod("chunksize", "matter_vt", function(x, value) {
	x@data <- lapply(x@data, function(a) {
		if ( is.matter(a) )
			chunksize(a) <- value
		a
	})
	callNextMethod(x, value)
})
