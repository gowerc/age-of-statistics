<template>

    <h2>Methods</h2>

    <hr>

    <h3>Confidence Intervals and why they are Important</h3>

    <p>
        A common critique you will hear when talking about any statistic is "you can't trust that value,
        the sample size is too small!". A natural question is then "well how big should the sample size
        be?" or the equivalent question of "how much should I trust this statistic given the sample size".
        This is where confidence intervals come in.
        
        A key thing to realise is that when we create statistics, like win rates, what we are creating
        are estimates of some true unknown value. Confidence intervals can thus be thought of as the range
        of values in which the true value is likely to be found in i.e. there is a 95% chance that the
        true value for the win rate exists within this band. Throughout these documents the 95% confidence
        intervals are presented as error bars around the point estimates. More generally speaking, the
        wider the confidence interval is the less trust we should have in the estimate whilst the narrower
        the confidence interval is the more trust we should have in the estimate.
            
        Please note that my above description of confidence intervals isn't technically correct in that
        if you repeated it to a statistician they will probably roll their eyes at you or lecture you.
        That being said it is good enough to give an intuitive sense of what confidence intervals
        represent and how to interpret them. If you want a more accurate description please see
        <a 
        href="https://www.census.gov/programs-surveys/saipe/guidance/confidence-intervals.html"
        >here</a>.
    </p>

    <h3>Naive Win Rates</h3>
    
    <p>
        Whenever something is indicated as being a "Naive win rate" it means that it has been calculated
        by fitting a logistic regression model to each civ's match data independently, i.e.:
            
        $$
            \displaylines{
            Y_{ij} \sim Bin(1, p_{ij}) \\
            p_{ij} = \text{logistic}(\beta_i +  \beta_d d_{j})
            }
        $$
            
        Where:
            
        <ul>
            <li>
                \(Y_{ij}\) is 1 if civilisation \(i\) won its \(j\)'th match
            </li>
            <li>
                \(\beta_i\) is civilisation \(i\)'s logit win rate
            </li>
            <li>
                \(d_j\) is the difference in mean Elo between team 1 and team 2 in match \(j\)
            </li>
            <li>
                \(\beta_d\) is the importance of the difference in mean Elo between team 1 and team 2 in match \(j\)
            </li>
        </ul>
            
        All mirror matchups are excluded.
            
        It is referred to as the "naive win rate" as it doesn't take into account the civilisation play
        rates and thus more represents the civilisations win rate against the most played civilisations.
    </p>


    <h3>Averaged Win Rates</h3>

    <p>
        Averaged win rates are calculated by taking the average across all civilisation v civilisation win
        rates. I.e The Aztec win rate is calculated by taking the mean of their win rate vs Berbers,
        Britons, Bulgarians, etc, separately. This statistic can be thought of as the win rate if your
        opponent was picking their civilisation at random.

        For 1v1's each civilisation v civilisation win rate is calculated using the "naive" method
        mentioned above. For team games though the win rates are calculated by fitting a logistic
        regression that derives the probability of winning as the average across each pairwise
        civilisation match-up.  For example, let's say in match \(j\) that team 1 had civilisations A, B
        and C whilst team 2 had civilisations X, Y and Z. The model fitted would then be:

        $$
            \displaylines{
                Y_{j} \sim Bin(1, p_{j}) \\
                p_j = \text{logistic}
                \left(\frac{
                \beta_{AX} + \beta_{AY} + \beta_{AZ} + 
                \beta_{BX} + \beta_{BY} + \beta_{BZ} + 
                \beta_{CX} + \beta_{CY} + \beta_{CZ}
                }{9} +  \beta_d d_{j}\right)
            }
        $$

        Where:

        <ul>
            <li>
                \(Y_j\) = 1 if team 1 won or 0 if team 2 won
            </li>
            <li>
                \(\beta_{mn}\) is civilisation \(m\)'s win rate against civilisation \(n\)
            </li>
            <li>
                \(d_j\) is the difference in mean Elo between team 1 and team 2
            </li>
            <li>
                \(\beta_d\) is the importance of the difference in mean Elo between team 1 and team 2 in match \(j\)
            </li>
        </ul>

        Please note that a major limitation of this formulation is that it doesn't allow for any
        interaction effects. I.e. it doesn't account for the fact that some civilisation pairings
        are stronger together than if they were to be considered independently (think a team of all
        cavalry civilisation vs a team of both archer and cavalry civilisation).
        
        In all cases, a small Laplace smoother was added to avoid issues associated with certainty
        bias from low civilisation v civilisation sample sizes (most notably in the Empire Wars data).
        This will mean that the confidence intervals are very marginally underestimated and biased
        towards 50%; realistically however this should be negligible.
    </p>


     <h3>Bradley–Terry Modeling</h3>

    <p>
        A Bradley-Terry model works by assuming that each civilisation has a latent (i.e. hidden/unknown) performance score.
        The model then states that the probability of one civilisation beating another can be calculated based upon
        the difference between the two civilisation's performance scores.
        In particular it is assumed that the probability of civilisation \(i\) beating
        civilisation \(j\) in match\(k\) is defined as:
    </p>

    <p>
        $$
            \frac{1}{1+e^{-\lambda_{ijk}}}
        $$
    </p>
    <p>
        where:
        <ul>
            <li>
                \(  \lambda_{ijk} = X_i - X_j + D_k \)
            </li>
            <li>
                \(X_i\) is the performance score for civilisation \(i\)
            </li>
            <li>
                \(X_j\) is the performance score for civilisation \(j\)
            </li>
            <li>
                \(D_k\)  is the difference in Elo rating between the two players in match \(k\)
            </li>
        </ul>
    </p>
    <p>
        For the maths of the model to work a reference civilisation needs to be defined.
        In this instance the Vikings were chosen to be the reference civilisation; this choice is
        arbitrary and makes no difference to the results.
        This means that the performance score of the Vikings is fixed at 0 and all other civilisations
        performance scores represent the difference from Vikings.
    </p>
    <p>
        The best way to interpret the performance scores is to plug them back into the above formula.
        For example, let’s say civilisation A has a score of \(0.24\)  whilst civilisation B has a
        score of \(-0.13\).
        Then, using the above formula assuming no difference in Elo between the two players, results in: 
        $$
            \frac{1}{1+e^{-(0.24 - (-0.13))}} = \frac{1}{1+e^{-0.37}} = 0.591
        $$
    </p>
    <p>
        That is to say the model predicts that, given there is no difference in Elo between the two players,
        there is a 59.1% chance that civilisation A would beat civilisation B in a 1v1 game on Arabia.
        For reference, the following table provides a mapping from the difference in performance score
        to the expected win percentage:
    </p>
    <table class="table" style="width: auto !important; margin-left: auto; margin-right: auto;">
    <thead>
    <tr>
    <th style="text-align:center;">
    Difference in Performance Score
    </th>
    <th style="text-align:center;">
    Expected Win Percentage
    </th>
    </tr>
    </thead>
    <tbody>
    <tr>
    <td style="text-align:center;">
    0.4
    </td>
    <td style="text-align:center;">
    59.87%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    0.3
    </td>
    <td style="text-align:center;">
    57.44%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    0.2
    </td>
    <td style="text-align:center;">
    54.98%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    0.1
    </td>
    <td style="text-align:center;">
    52.5%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    0.0
    </td>
    <td style="text-align:center;">
    50%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    -0.1
    </td>
    <td style="text-align:center;">
    47.5%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    -0.2
    </td>
    <td style="text-align:center;">
    45.02%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    -0.3
    </td>
    <td style="text-align:center;">
    42.56%
    </td>
    </tr>
    <tr>
    <td style="text-align:center;">
    -0.4
    </td>
    <td style="text-align:center;">
    40.13%
    </td>
    </tr>
    </tbody>
    </table>
    <p>
        Note that an obvious limitation to this type of model is that it assumes linearity in the
        performance scores.
        That is to say that it assumes that if civilisation A beats civilisation B and civilisation
        B beats civilisation C then civilisation A should also beat civilisation C.
        Obviously it is clear this logic does not hold in AOE2 where civilisation superiority is
        multifaceted.
        Regardless, the model still gives us a good estimate of the teams <em>average</em> performance
        and provides a more stable estimate for team games than the "averaged win rates" estimate.
    </p>
    <h3>Removing Single Civilisation Players</h3>

    <p>
        In filters for 1v1 leaderboards (both Empire Wars and Random Map) matches consisting of
        players who are deemed to be single civilisation pickers are excluded. This is determined
        by looking at the last 40 games the player has had before each match and seeing if over
        70% of them have been played with the same civilisation. If the player has less then 20 
        matches prior to the match then they are included regardless. 
        
        The reason for this is that single civilisation pickers can heavily bias win rates; please
        see the following
        [article](https://www.reddit.com/r/aoe2/comments/pl4jpz/a_brief_look_at_the_impact_of_civ_picking_on_win/) 
        to get a better understanding of the issue. Ideally the cutoff point would be lowered to
        something more like 30-40% however we need to balance this issue against the loss in sample 
        size that we take from removing these matches. 
    </p>
</template>

<script>
export default {
    mounted() {
        if(window.MathJax){
            window.MathJax.typeset()
        }
    }
}
</script>
