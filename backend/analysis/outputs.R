
# TODO



# Play Rate by Civilisation
pr <- data_pr(matchmeta = matchmeta, players = players_all)
om$add_output(
    output = plot_pr(pr),
    id = "civ_playrate"
)






# Slide - Naive Win Rates by Elo
om$add_output(
    output = plot_slide_wr_elo(matchmeta = matchmeta_slice, players = players_all),
    id = "slide_wrNaive_elo",
    style = "square"
)



# Slide -  Naive Win Rates by Game Length
om$add_output(
    output = plot_slide_wr_gamelength(matchmeta = matchmeta, players = players_all),
    id = "slide_wrNaive_gamelength",
    style = "square"
)


# Slide - Play rate by Elo
om$add_output(
    output = plot_slide_pr_elo(matchmeta = matchmeta, players = players_all),
    id = "slide_playrate_elo",
    style = "square"
)




# Civilisation v Civilisation Win Rates
# cvc_plots <- plot_cvc(wr_avg_coef)
# for (civ in names(cvc_plots)) {
#     om$add_output(
#         output = cvc_plots[[civ]],
#         id = glue("cvc_wrNaive_{civ}", civ = civ)
#     )
# }



# Distribution of Players Highest Picked Civilisation's Play Rate
om$add_output(
    output = plot_pr_civ1(matchmeta, players_all, lower_limit = 20),
    id = "dist_civpick"
)





# Estimating how Overrated or Underrated each Civilisation is
p_wr_ewr <- plot_wr_ewr(wr_naive, pr)

om$add_output(
    output = p_wr_ewr[[1]],
    id = "civ_ewr_owr_diff"
)

om$add_output(
    output = p_wr_ewr[[2]],
    id = "civ_ewr_owr"
)

