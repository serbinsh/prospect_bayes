##' Process MCMC results.

library(coda)

##' @name get.results
##' @title Load MCMC chains
##' @details {
##' Load all MCMC chains from a given folder, of a given species, into a single MCMC list object.
##' Optionally applies burn-in and thinning.
##' }

##' @param path Folder containing run results (e.g. run_results/testfolder/)
##' @param burnin Burn-in amount; i.e. remove the first 'n' values (default = 0)
##' @param thin Thinning interval; i.e. keep only every 'nth' value (default = 1)
##' @param species Name of species to load. Must exactly match species tag in filename. "All" (default) loads all species.
##' @return Returns 'mcmc.list' object of all loaded chains.
##' @export
##' 
##' @author Alexey Shiklomanov

get.results <- function(path, burnin=0, thin=1, species="All"){
        flist <- list.files(path)
        if(species != "All") flist <- flist[grep(species, flist)]
        flist <- flist[which(nchar(flist) > 5)]
        species.list <- unique(gsub("(.*)_[0-9][.][0-9]+_.*", "\\1", flist))
        
        relist <- c("none", "plot", "leaf")
        
        for (species in species.list){
                for (re in relist){
                        fset <- flist[grep(sprintf("%s_.*_%s_.*", species, re), flist)]
                        print(fset)
                        if(length(fset) > 0){
                                speclist <- lapply(fset, function(x) read.csv(paste(path, x, sep=''), 
                                                                              header=TRUE))
                                min.spec <- min(sapply(speclist, nrow))
                                samples <- seq(burnin, min.spec, by=thin)
                                speclist <- lapply(speclist, "[", samples,,drop=FALSE)
                                speclist <- lapply(speclist, mcmc)
                                assign(sprintf("%s.%s.l", species, re), mcmc.list(speclist), envir = .GlobalEnv)
                        }
                }
        }
}

##' @name chain.plots
##' @title Plot individual chains
##' @details {
##' Interactive chain by chain plot of mcmc.list objects. Individual chains can be selected for removal as they appear.
##' For each question, enter '1' for 'Yes' and '0' for 'No'.
##' }

##' @param mcmclist 'mcmc.list' object from which chains will be extracted.
##' @return Returns 'mcmc.list' object with 'bad' chains removed.
##' @export
##' 
##' @author Alexey Shiklomanov

chain.plots <- function(mcmclist){
        plot(mcmclist)
        t1 <- readline("View details? : ")
        if(t1 == 1){
                l.m <- length(mcmclist)
                out <- NULL
                for (i in 1:l.m){
                        plot(mcmclist[[i]])
                        t2 <- readline("Discard? ")
                        if(t2 == 1){
                                out <- c(out, i)
                        }
                }
                if(length(out) > 0) {
                        return(mcmclist[-out])
                } else {
                        return(mcmclist)
                }
        } else {
                return(mcmclist)
        }
        
}

##' @name sumtab
##' @title Summary table for MCMC chains
##' @details {
##' Produce summary table containing mean and confidence interval width for a given set of chains.
##' }

##' @param m 'mcmc.list' object from which chains will be extracted.
##' @return Returns matrix of means and confidence interval widths.
##' @export
##' 
##' @author Alexey Shiklomanov

sumtab <- function(m) {
        s <- summary(m)
        means <- s$statistics[,1]
        ci <- s$quantiles[,5] - s$quantiles[,1]
        out <- rbind(means, ci)
        return(out)
}
