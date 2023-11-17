# Needs to be run as an admin that has write permissions to /etc/rstudio
# 
# This script when run against any R version will 
# * figure out which compatible BioConductor Version exist
# * get all the URLs for the repositories of BioConductor
# * Add both CRAN and BioConductor 
#       into files in /etc/rstudio/repos/repos-x.y.z.conf
# * add entries into /etc/rstudio/r-versions to define the respective 
#       R version (x.y.z) and point to the repos.conf file  
# * update Rprofile.site with the same repository informations 
# * add renv config into Renviron.site to use 
#       a global cache in $renvdir  
# * install all needed R packages for Workbench to work and add them 
#       in a separate .libPath() ($basepackagedir/x.y.z)
# * create a pak pkg.lock file in $basepackagedir/x.y.z
#       for increased reproducibility
# * auto-detect which OS it is running on and add binary package support
# * uses a packagemanager running at $pmurl 
#       with repositories bioconductor and cran configured and named as such
# * assumes R binaries are installed into /opt/R/x.y.z

# main config parameters

# root folder for global renv cache 
renvdir<-"/scratch/renv"

# base folder site libraries for additional packages 
basepackagedir<-"/opt/rstudio/rver"

# packagemanager URL to be used
pmurl <- "https://packagemanager.posit.co"

# place to create rstudio integration for package repos
rsconfigdir <- "/opt/rstudio/etc/rstudio" 

binaryflag<-""

if(file.exists("/etc/debian_version")) {
    binaryflag <- paste0("__linux__/",system(". /etc/os-release && echo $VERSION_CODENAME", intern = TRUE),"/")
}

if(file.exists("/etc/redhat-release")) {
    binaryflag <- paste0("__linux__/centos",system(". /etc/os-release && echo $VERSION_ID", intern = TRUE),"/")
}

currver <- paste0(R.Version()$major,".",R.Version()$minor)

libdir <- paste0(basepackagedir,"/",currver)

if(dir.exists(libdir)) {unlink(libdir,recursive=TRUE)}
dir.create(libdir,recursive=TRUE)

#directory for temporary packages
pkgtempdir<-tempdir()
.libPaths(pkgtempdir)

install.packages(c("RCurl","pak","BiocManager"),pkgtempdir, repos=paste0(pmurl,"/cran/",binaryflag,"latest"))


currver <- paste0(R.Version()$major,".",R.Version()$minor)
paste("version",currver)

#Start with a starting date for the time-based snapshot 60 days past the R release
releasedate <- as.Date(paste0(R.version$year,"-",R.version$month,"-",R.version$day))
paste("release", releasedate)
 
#Try to figure out if the needed Bioconductor release is older than the most recents
# If yes, use the release date of bioconduct version + 1 as a start date for looking 
# into CRAN snapshots - if no, use the current date
getbiocreleasedate <- function(biocvers){
  biocdata<-read.csv("bioc.txt")
  
  splitbioc<-strsplit(as.character(biocvers),"[.]")[[1]]
  biocversnext<-paste0(splitbioc[1],".",as.integer(splitbioc[2])+1)
  
  repodate<-biocdata$Date[which(biocdata$X.Release==biocversnext)]
  if (identical(repodate,character(0))) repodate<-"latest"

  return(repodate)
}

#Attempt to install packages from snapshot - if snapshot does not exist, decrease day by 1 and try again
getreleasedate <- function(repodate){
  
  repo=paste0(pmurl,"/cran/",binaryflag,repodate)
  paste(repo)
  URLfound=FALSE
  while(!URLfound) {
   if (!RCurl::url.exists(paste0(repo,"/src/contrib/PACKAGES"),useragent="curl/7.39.0 Rcurl/1.95.4.5")) {
	repodate<-as.Date(repodate)-1
        repo=paste0(pmurl,"/cran/",binaryflag,repodate)
   } else {
   URLfound=TRUE
   }
 }
 return(repodate)
}

paste("Configuring Bioconductor")
# Prepare for Bioconductor
options(BioC_mirror = paste0(pmurl,"/bioconductor"))
options(BIOCONDUCTOR_CONFIG_FILE = paste0(pmurl,"/bioconductor/config.yaml"))
sink(paste0("/opt/R/",currver,"/lib/R/etc/Rprofile.site"),append=FALSE)
options(BioC_mirror = paste0(pmurl,"/bioconductor"))
options(BIOCONDUCTOR_CONFIG_FILE = paste0(pmurl,"/bioconductor/config.yaml"))
sink()

# Make sure BiocManager is loaded - needed to determine BioConductor Version
library(BiocManager,lib.loc=pkgtempdir,quietly=TRUE,verbose=FALSE)

# Version of BioConductor as given by BiocManager (can also be manually set)
biocvers <- BiocManager::version()

paste("Defining repos and setting them up in repos.conf as well as Rprofile.site")
# Bioconductor Repositories
r<-BiocManager::repositories(version=biocvers)

paste("Determining compatible CRAN snapshot")
biocreleasedate <- getbiocreleasedate(biocvers)
if (identical(biocreleasedate,"latest")) {
    releasedate <- "latest" 
} else {
  releasedate <- getreleasedate(biocreleasedate)
}


#Final CRAN snapsot URL
repo=paste0(pmurl,"/cran/",binaryflag,releasedate)
options(repos=c(CRAN=repo))

paste("CRAN Snapshot selected", repo)

# enforce CRAN is set to our snapshot 
r["CRAN"]<-repo

# Make sure CRAN is listed as first repository (rsconnect deployments will start
# searching for packages in repos in the order they are listed in options()$repos
# until it finds the package
# With CRAN being the most frequenly use repo, having CRAN listed first saves 
# a lot of time
nr=length(r)
r<-c(r[nr],r[1:nr-1])

system(paste0("mkdir -p ",rsconfigdir,"/repos"))
filename=paste0(rsconfigdir,"/repos/repos-",currver,".conf")
sink(filename)
for (i in names(r)) {cat(noquote(paste0(i,"=",r[i],"\n"))) }
sink()

x<-unlist(strsplit(R.home(),"[/]"))
r_home<-paste0(x[2:length(x)-2],"/",collapse="")

sink(paste0(rsconfigdir,"/r-versions"), append=TRUE)
cat("\n")
cat(paste0("Path: ",r_home,"\n"))
cat(paste0("Label: R","\n"))
cat(paste0("Repo: ",filename,"\n"))
cat(paste0("Script: /opt/R/",currver,"/lib/R/etc/ldpaths \n"))
cat("\n")
sink()

sink(paste0("/opt/R/",currver,"/lib/R/etc/Rprofile.site"),append=FALSE)
if ( currver < "4.1.0" ) {
  cat('.env = new.env()\n')
}
cat('local({\n')
cat('r<-options()$repos\n')
for (line in names(r)) {
   cat(paste0('r["',line,'"]="',r[line],'"\n'))
}
cat('options(repos=r)\n') 

options(BioC_mirror = paste0(pmurl,"/bioconductor"))
options(BIOCONDUCTOR_CONFIG_FILE = paste0(pmurl,"/bioconductor/config.yaml"))

libdir <- paste0(basepackagedir,"/",currver)
cat(paste0('.libPaths(c(.libPaths(),"',libdir,'"))\n'))
if ( currver < "4.1.0" ) {
cat('}, envir = .env)\n')
cat('attach(.env)\n')
} else {
cat('})\n')
}
sink()

# Install customer provided CRAN and Bioconductor packages
paste("Installing packages for CRAN and Bioconductor")

packages_needed=c(readLines("r-packages-bioconductor.txt"),
                readLines("r-packages-cran.txt"))

# Let's filter out any installed base and recommended packages 
available_packages=as.data.frame(available.packages())
baserec_packages=available_packages$Package[which(!is.na(available_packages$Priority))]
baserecinst_packages=baserec_packages[baserec_packages %in% as.data.frame(installed.packages())$Package]

packages_selected=packages_needed[!packages_needed %in% baserecinst_packages]

options(Ncpus=4)
pak::pkg_install(packages_selected,lib=libdir)
paste("Creating lock file for further reproducibility")
pak::lockfile_create(packages_selected,lockfile=paste0(libdir,"/pkg.lock"))

paste("Setting up global renv cache")
sink(paste0("/opt/R/",currver,"/lib/R/etc/Renviron.site"), append=TRUE)
  cat("RENV_PATHS_PREFIX_AUTO=TRUE\n")
  cat(paste0("RENV_PATHS_CACHE=", renvdir, "\n"))
  cat(paste0("RENV_PATHS_SANDBOX=", renvdir, "/sandbox\n"))
sink()

