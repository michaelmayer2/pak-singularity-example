currver <- paste0(R.Version()$major,".",R.Version()$minor)

libdir <- paste0("/opt/rstudio/rver/",currver)

#Install missing BiocManager packages from the list
bc_packages = readLines("/r-packages-bioconductor.txt")
BiocManager::install(bc_packages[!(bc_packages %in% installed.packages()[ , "Package"])],dependencies = TRUE)

#Install missing CRAN packages from the list
cran_packages = readLines("/r-packages-cran.txt")
install.packages(cran_packages[!(cran_packages %in% installed.packages()[ , "Package"])], dependencies = TRUE, repos='https://cran.rstudio.com', libdir)

#### Additional packages
devtools::install_github('davidsjoberg/ggsankey')
devtools::install_github('Mikata-Project/ggthemr')
devtools::install_github('federicomarini/pcaExplorer', dependencies = TRUE)
devtools::install_github('federicomarini/ideal', dependencies = TRUE)
devtools::install_github('cellgeni/sceasy')