# pak-singularity-example

## Introduction

This repo aims at showing an example on how to seamlessly set up a Singularity/Apptainer container for RStudio Workbench with a defined set of R package pre-installed. The `r-session-complete` container as provided by Posit is used as a baseline, but then all R versions removed and a defined set of R versions installed. For each of those R versions bespoke repository settings are configured (time-based snapshots, Bioconductor as CRAN repository integration, user of public package manager). For package installation `pak` is being used (https://pak.r-lib.org/). `pak` not only allows for parallel package installations but also can extract system dependencies so that the installation of the same can be fully automated. 

## How to use this repository (and additional background information)

1. Make sure `singularity/apptainer` is installed
2. Make sure you use local disk space if possible 
3. Total disk storage consumed for the build process is close to 80 GB so make sure you have ample space available, especially in `/tmp`
4. `pak` is running in parallel and will at any given time use all the available cores. The more cores you have, the faster you can build your container - provided you are not maxing out the I/O capabilities of your local storage
5. `pak` is using a local package cache. Mounting them externally is very helpful when debugging and you don't want to re-download all the 700+ R packages again for each R version. (`-B` option)
6. `BiocFileCache` seems to be having some issues in Bioconductor 3.18 - This is now installed from github to prevent some strange db errors
7. Package `DOSE` depends on `HPO.db` and `MPO.db` - both packages lead to `AnnotationDBI` cache corruption. I am using a special release from the maintainers straight from github
8. The infrastructure code to setup R and install package is only using `pak::create_lockfile()` and `pak::install_lockfile()` - the latter will automatically install system deps if needed. 
9. As input we use 
 * `r-packages-bioconductor.txt`
 * `r-packages-cran.txt`
 * `r-packages-github.txt`


A typical command on how to build the singularity image is

```
mkdir -p /tmp/cache
singularity build -B /tmp/cache:/root/.cache r-session-complete.sif r-session-complete.sdef
```   

## Additional information

The singularity recipe shared here is an advanced and more scalable version of the corresponding recipe shared in https://github.com/sol-eng/singularity-rstudio.  
