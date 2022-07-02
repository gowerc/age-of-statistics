<template>

<Output
    name="dist_civpick"
    title="Distribution of Players Highest Picked Civilisation's Play Rate"
    :path="path" />


<p>
    For this plot we calculate the play rate of each players most played civ 
    (i.e. if I used Franks for 60% of my games, Mayans for 30% and Britains for 10%
    I would get a value of 60). We then categories the counts into brackets of 10
    (i.e. 0-10, 10-20, etc) and count how many are in each bracket. The idea is this
    should give some indication of how many people are playing random vs how many are
    1-civ pickers.
</p>



<Output
    name="civ_dendro"
    title="Hierarchical Clustering Dendrogram"
    :path="path" />

<p>
    This output attempts to highlight civilisations that are "similar" based upon
    their win rates vs other civilisations. The algorithm works by recursively
    grouping civilisations (or groups of civilisations) that are the most similar
    to each other until there is only 1 group. The lower down on the y-axis that
    civilisations are grouped indicates a higher degree of similarity whilst
    civilisations that are grouped higher up on the y-axis indicates a lower degree
    of similarity. That is to say that if two civilisations are linked together low
    down on the y-axis it means that they tend to win and lose against the same
    civilisations.
</p>


<Output
    name="civ_ewr_owr_diff"
    title="Estimating how Overrated or Underrated each Civilisation is"
    :path="path" />

<p>
    This plot attempts to answer the question of "how overrated / underrated is each
    civilisation" (credit to SOTL for proposing this idea).
    
    In order to try and quantify this, play rates are normalised using a box-cox
    transformation and then a robust linear regression is fitted and used to estimate
    what the expected win rate should be for each civilisation.
    
    The idea is that play rates could be used as a surrogate to indicate what
    people's expectations of each civilisation are; that is, civilisations with
    high play rates are those that people think will do well whilst civilisations
    with low play rates are those that people think will do badly. The plot above 
    shows the difference between the expected win rate and the observed win rate with
    the plot below showing the observed win rates vs the expected win rates.
</p>


<Output
    name="civ_ewr_owr"
    :path="path" />
    
<p>
    It must stress that these plots should be interpreted with a massive grain of
    salt. The fundamental assumption that play rates predict win rates is a strong
    one (for example I main Vietnamese despite knowing they perform below average).
    Likewise pick rates heavily bias win rates due to interactions with the Elo
    system as well as peoples skill/familiarity with the civ. These are biases that
    the model can’t account for and to which the results are most susceptible to as
    it is intrinsically the extremes that we are most likely to be interested in.
    This is all to say that these results should be regarded more as an informal
    conversation starter rather than as an exact science / analysis.
</p>
</template>



<script>
import Output from "@/components/Output"
export default {
    props: ["path", "config"],
    components: {
        "Output": Output
    }
}
</script>


<style scoped>
</style>