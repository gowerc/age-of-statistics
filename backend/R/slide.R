


get_slide_smoothed <- function(CIV, dat) {
    dat2 <- dat %>%
        filter(civ == CIV)

    # fit GAM model
    lci_m <- mgcv::gam(lci ~ s(y), data = dat2)
    med_m <- mgcv::gam(est ~ s(y), data = dat2)
    uci_m <- mgcv::gam(uci ~ s(y), data = dat2)

    pdat <- tibble(
        y = dat2$y,
        civ = dat2$civ,
        lci = predict(lci_m, newdata = data.frame(y = y)),
        med = predict(med_m, newdata = data.frame(y = y)),
        uci = predict(uci_m, newdata = data.frame(y = y)),
    )
    return(pdat)
}



get_cluster <- function(n) {
    cl <- parallel::makeCluster(n)
    parallel::clusterEvalQ(cl, {
        library(dplyr)
        library(lubridate)
        devtools::load_all()
    })
    return(cl)
}