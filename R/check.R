#' Check package
#'
#' @export
#' @note Updated 2021-01-07.
#'
#' @param path `character(1)`.
#'   Directory path to package.
#' @param cran `logical(1)`.
#'   Perform additional CRAN submission checks.
#'
#' @return `TRUE` on success, otherwise error.
#'
#' @examples
#' ## > check()
check <- function(path = ".", cran = FALSE) {
    stopifnot(
        requireNamespace("desc", quietly = TRUE),
        isTRUE(dir.exists(path))
    )
    path <- normalizePath(path, mustWork = TRUE)
    descFile <- file.path(path, "DESCRIPTION")
    keys <- desc::desc_get(keys = c("Package", "biocViews"), file = descFile)
    pkgName <- keys[["Package"]]
    message(sprintf("Checking '%s' package at '%s'.", pkgName, path))
    message("Checking for lints with 'lint_package()'.")
    lints <- lint_package(path = path)
    if (length(lints) > 0L) {
        print(lints)
        stop(sprintf(
            fmt = "Package failed lintr checks. %d %s detected.",
            length(lints),
            ngettext(n = length(lints), msg1 = "lint", msg2 = "lints")
        ))
    }
    ## Note that URL checks are automatic in R 4.1.
    if (requireNamespace("urlchecker", quietly = TRUE)) {
        message("Checking URLs with 'urlchecker::url_check()'.")
        urlchecker::url_check(path = path)
    }
    message("Running package checks with 'rcmdcheck()'.")
    rcmdcheck(path = path, cran = cran)
    ## Only run BiocCheck if we detect "biocViews" in DESCRIPTION and when the
    ## directory name is identical to the package name. BiocCheck currently
    ## errors on directory names that differ from the package name.
    ok <- all(
        !is.na(keys[["biocViews"]]),
        identical(pkgName, basename(path))
    )
    if (isTRUE(ok)) {
        message("Running additional Bioconductor checks with 'BiocCheck()'.")
        BiocCheck(package = path)
    }
    invisible(TRUE)
}
