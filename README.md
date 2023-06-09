# pak-singularity-example

## Introduction

This repo aims at showing an example on how to seamlessly set up a Singularity/Apptainer container for RStudio Workbench with a defined set of R package pre-installed. The `r-session-complete` container as provided by Posit is used as a baseline, but then all R versions removed and a defined set of R versions installed. For each of those R versions bespoke repository settings are configured (time-based snapshots, Bioconductor as CRAN repository integration, user of public package manager). For package installation `pak` is being used (https://pak.r-lib.org/). `pak` not only allows for parallel package installations but also can extract system dependencies so that the installation of the same can be fully automated. 

## How to use this repository

1. Make sure `singularity/apptainer` is installed
2. Identify a folder where you have ample storage available (>10 GB)

If the folder identified in the last step is `/scratch/data/tmp`, then run 

```
singularity build -B /scratch/data/tmp:/tmp r-sif4.sif r-session-complete.sdef
```   

## Additional information

The singularity recipe shared here is an advanced and more scalable version of the corresponding recipe shared in https://github.com/sol-eng/singularity-rstudio.  
