#' @importFrom stats ftable addmargins
{}


#' @rdname tinytests
#' @param object a tinytests object
#' @return For \code{summary} an \code{\link{ftable}} object
#' @export
summary.tinytests <- function(object, ...){
  
  expect <- sapply(object, function(x) as.character(attr(x,"call")[[1]]) )
  expect <- sub("expect_", "", expect)
  result <- factor(ifelse(sapply(object, isTRUE), "passes","fails")
            , levels=c("passes","fails"))
  file   <- sapply(object, function(x) attr(x,"file"))
  file   <- basename(file)
  tab <- table(file=file,expect=expect, result=result)

  hdr <- sprintf("tinytests object with %d results, %d passing, %d failing"
    , length(object), sum(result=="passing"), sum(result=="failing"))
  cat(hdr,"\n\n")
  stats::ftable(stats::addmargins(tab, 2:3))
}   

#' Tinytests object
#'
#' An object of class \code{tinytests} (note: plural) results
#' from running multiple tests from script. E.g. by running
#' \code{\link{run_test_file}}.
#'
#'
#' @aliases tinytests
#'
#' @param i an index
#' @param x a \code{tinytests} object 
#'
#' @return For \code{[.tinytests} another, smaller \code{tinytests} object.
#'
#' @export
#' @rdname tinytests
`[.tinytests` <- function(x,i){
   structure(unclass(x)[i], class="tinytests")
}

#' @param passes \code{[logical]} Toggle: print passing tests?
#' @param limit \code{[numeric]} Max number of results to print
#' @param nlong \code{[numeric]} First \code{nlong} results are printed in long format.
#' @param ... passed to \code{\link{format.tinytest}}
#'
#' @section Details:
#'
#' By default, the first 3 failing test results are printed in long form,
#' the next 7 failing test results are printed in short form and all other 
#' failing tests are not printed. These defaults can be changed by passing options
#' to  \code{print.tinytest}, or by setting one or more of the following general
#' options:
#' \itemize{
#' \item{\code{tt.pr.passes} Set to \code{TRUE} to print output of non-failing tests.}
#' \item{\code{tt.pr.limit} Max number of results to print (e.g. \code{Inf})}
#' \item{\code{tt.pr.nlong} The number of results to print in long format (e.g. \code{Inf}).}
#' }
#'
#' For example, set \code{options(tt.pr.limit=Inf)} to print all test results.
#' 
#' @rdname tinytests 
#' @export
print.tinytests <- function(x
  , passes=getOption("tt.pr.passes", FALSE)
  , limit =getOption("tt.pr.limit",  7)
  , nlong =getOption("tt.pr.nlong",  3),...){

  ntst  <- length(x)
  ifail <- if (ntst > 0) sapply(x, isFALSE) else logical(0)
  
  if (!passes){
    x <- x[ifail]
    if ( length(x) == 0 ){
      cat(sprintf("All ok (%d results)\n", ntst))
      return(invisible(NULL))
    }
  }
  limit <- min(length(x), limit)
  nlong <- min(nlong, limit)
  nshort <- max(limit - nlong,0)
  x <- x[seq_len(limit)]
  type <- c( rep("long",nlong)
           , rep("short",nshort) )

  str <- sapply(seq_along(x), function(i) format.tinytest(x[[i]], type=type[i]))  
  cat(paste0(str,"\n"), "\n")
  if (ntst > length(str)){
    cat(sprintf("Showing %d out of %d test results; %d tests failed\n"
        , length(x), ntst, sum(ifail)))
  } 
}


#' @return For \code{as.data.frame.} a data frame.
#' @family test-files
#'
#' @examples
#' # create a test file in tempdir
#' tests <- "
#' addOne <- function(x) x + 2
#'
#' expect_true(addOne(0) > 0)
#' expect_equal(2, addOne(1))
#' "
#' testfile <- tempfile(pattern="test_", fileext=".R")
#' write(tests, testfile)
#' 
#' # extract testdir
#' testdir <- dirname(testfile)
#' # run all files starting with 'test' in testdir
#' out <- run_test_dir(testdir)
#' #
#' # print results
#' print(out)
#' summary(out)
#' dat <- as.data.frame(out)
#' out[1]
#' 
#' @rdname tinytests
#' @export
as.data.frame.tinytests <- function(x, ...){
  L <- lapply(x, attributes)
  data.frame(
      result = sapply(x, isTRUE)
    , call   = sapply(L, function(y) gsub(" +"," ",paste0(capture.output(print(y$call)),collapse=" ")) )
    , diff   = sapply(L, `[[`, "diff")
    , short  = sapply(L, `[[`, "short")
    , file   = sapply(L, `[[`, "file")
    , first  = sapply(L, `[[`, "fst")
    , last   = sapply(L, `[[`, "lst")
    , stringsAsFactors=FALSE
  )
}


