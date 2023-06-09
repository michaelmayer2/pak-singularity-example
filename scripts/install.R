options(Ncpus=4)

currver <- paste0(R.Version()$major,".",R.Version()$minor)
paste("version",currver)

libdir <- paste0("/opt/rstudio/rver/",currver)

repos<-readLines(paste0("/tmp/repos-",currver))

tmpdir<-tempdir()

install.packages(c("rjson","RCurl","BiocManager","bitops","remotes","pkgsearch","pkgdepends","pkgcache","distro"),tmpdir)
.libPaths(tmpdir)
library(RCurl)
library(rjson)
remotes::install_github("michaelmayer2/pak@e2a3c95f",lib=tmpdir)
pak:::create_dev_lib()

.libPaths(tmpdir)
library(rjson)
Sys.setenv("PKGCACHE_HTTP_VERSION" = "2")
library(pak)
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

paste("XXX :",currver,": Installing github packages")
remotes::install_github('davidsjoberg/ggsankey@3e171a8',lib=libdir)
remotes::install_github('Mikata-Project/ggthemr@f04aca6',lib=libdir)
remotes::install_github('federicomarini/pcaExplorer@4a87c29',lib=libdir, dependencies = TRUE)
remotes::install_github('federicomarini/ideal@6a0b6df',lib=libdir, dependencies = TRUE)
remotes::install_github('cellgeni/sceasy@0cfc0e3',lib=libdir)
