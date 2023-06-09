options(Ncpus=4)

currver <- paste0(R.Version()$major,".",R.Version()$minor)
paste("version",currver)

libdir <- paste0("/opt/rstudio/rver/",currver)

repos<-readLines(paste0("/tmp/repos-",currver))

tmpdir<-tempdir()

install.packages(c("rjson","RCurl","BiocManager","bitops","remotes","pkgsearch","pkgdepends","pkgcache","distro"),tmpdir,repos="https://packagemanager.rstudio.com/cran/__linux__/jammy/2023-06-08/")
.libPaths(tmpdir)
library(RCurl)
library(rjson)

paste("XXX :",currver,": remotes::install_github")
remotes::install_github("michaelmayer2/pak@b95f2238",lib=tmpdir)

.libPaths(tmpdir)
library(rjson)
Sys.setenv("PKGCACHE_HTTP_VERSION" = "2")
library(pak)

paste("XXX :",currver,": pak:::create_dev_lib()")
pak:::create_dev_lib()

jsondata<-fromJSON(file="https://raw.githubusercontent.com/rstudio/rstudio/main/src/cpp/session/resources/dependencies/r-packages.json")

pnames<-c()
for (feature in jsondata$features) { pnames<-unique(c(pnames,feature$packages)) }
avpack<-available.packages()

# Install all packages needed for RSW integration
packages<-pnames[pnames %in% avpack]

## Install all OS dependencies
## Install OS dependencies for cran packages 
paste("XXX :",currver,": Installing RStudio packages system deps")
system(pkg_system_requirements(packages, "ubuntu", "22.04"))

## Install packages 
paste("XXX :",currver,": Installing RStudio packages")
pkg_install(packages,lib=libdir)

# Install customer provided CRAN and Bioconductor packages
## Read package list for bioconductor and cran
bc_packages = readLines("/r-packages-bioconductor.txt")
cran_packages = readLines("/r-packages-cran.txt")

## Install OS dependencies for cran packages 
paste("XXX :",currver,": Installing CRAN packages system deps")
system(pkg_system_requirements(cran_packages, "ubuntu", "22.04"))

detach("package:pak", unload=TRUE)
## Install OS dependencies for cran packages
Sys.setenv(RSPM_REPO_ID=4)
Sys.setenv(REQ_URL_EXT=paste0("&bioc_version=",BiocManager::version()))
library(pak)
paste("XXX :",currver,": Installing BioC packages system deps")
system(pkg_system_requirements(bc_packages, "ubuntu", "22.04"))

## Install packages
paste("XXX :",currver,": Installing CRAN packages")
pkg_install(cran_packages,lib=libdir) 
paste("XXX :",currver,": Installing BioC packages")
pkg_install(bc_packages,lib=libdir)

.libPaths(c(libdir, .libPaths()))
paste("XXX :",currver,": Installing github packages")
pkg_install(c('davidsjoberg/ggsankey@3e171a8',
	      'Mikata-Project/ggthemr@f04aca6',
	      'federicomarini/pcaExplorer@4a87c29',
	      'federicomarini/ideal@6a0b6df',
	      'cellgeni/sceasy@0cfc0e3'),lib=libdir)
