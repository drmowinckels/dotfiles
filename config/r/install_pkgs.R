if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")

pkgfile <- file.path(dirname(sys.frame(1)$ofile %||% "."), "Rpkgfile")
if (!file.exists(pkgfile)) pkgfile <- "~/.dotfiles/config/r/Rpkgfile"

lines <- readLines(pkgfile)
pkgs <- trimws(lines)
pkgs <- pkgs[nzchar(pkgs) & !startsWith(pkgs, "#")]

pak::pkg_install(pkgs, upgrade = TRUE, ask = FALSE)
