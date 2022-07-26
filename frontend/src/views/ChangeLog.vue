


<template>

    <h2>Change Log</h2>


    <hr>
    <h4>2022-July-26</h4>
    <ul>
        <li>
            Fixed bug that meant the "RM, Solo, All, >1700" filter was identical to the
            "RM, Solo, Open, >1700" filter. Thank you @Lepigozzus
        </li>
        <li>
            Fixed bug that meant the civilisation vs civilisation plots were sorted in the wrong
            order
        </li>
    </ul>





    <hr>
    <h4>2022-July-25</h4>
    <ul>
        <li>
            Updated most recent period to include matches up to 22nd July 2022
        </li>
        <li>
            <strong>Breaking</strong> - Found and fixed a critical bug that meant that the
            "averaged win rates", "civilisation v civilisation win rates" and
            "hierarchical clustering" outputs were highly inaccurate.
            I apologies for any inconvenience caused to anyone who may have previously used or
            relied upon these outputs
        </li>
        <li>
            Added new filters for Nomad (both solo and team) to the most recent period
        </li>
        <li>
            Updated the highest Elo filter to only include matches for >1700 Elo
            (was previously >1600)
        </li>
        <li>
            Added a new "all maps" filter for the >1700 Elo group
        </li>
        <li>
            Updated filters for team games to use the new Elo scores (centred on 1000)
        </li>
        <li>
            Retrofitted the new Elo calculation to historic games. Removed team games that occurred
            between the 14th and 15th July due to inaccuracies in the data of when the conversion was
            applied
        </li>
        <li>
            Reduced the arbitrary reference lines on team win rate plots from +/-5% to +/-3%
            to better represent expected normal ranges for team games
        </li>
        <li>
            Added new output "Median Number of Matches Played per Player by Elo Percentile" 
            to the Global Statistics page 
        </li>
        <li>
            Updated the output title "Distribution of Matches Played by Mean Team Elo" to
            "Distribution of Matches Played by Mean Match Elo" to better represent the output 
        </li>
        <li>
            Changed methodology for how averaged win rates and their confidence intervals are
            calculated; mostly impacts team games, see methodology tab for details
        </li>
        <li>
            Increased minimum time cut-off for closed maps from 6 minutes to 9 minutes
        </li>
    </ul>






    <hr>
    <h4>2022-July-05</h4>
    <ul>
        <li>
            Added Pearson correlation coefficient to the cross-civilisation plots (thank you @Spirit Of The Law)
        </li>
        <li>
            Added absolute-mean-difference figure to the naive win rate plots (thank you @Spirit Of The Law)
        </li>
    </ul>





    <hr>
    <h4>2022-July-02</h4>
    <ul>
        <li>
            Updated most recent period to include matches up to 30th June 2022
        </li>
        <li>
            Added in new page + outputs for game level statistics
            (unique players over time, Elo distributions, etc)
        </li>
        <li>
            Added in new page for comparing civilisation naive win rates across different
            periods & filters
        </li>
        <li>
            Added new filters for 900-1100 Elo players
        </li>
        <li>
            Have applied the "no-civ-pick" derivation directly to all 1v1 leaderboard
            filters.
        </li>
        <li>
            Have removed the specific "no-civ-pick" filters as they are now
            redundant
        </li>
        <li>
            Have updated the "no-civ-pick" derivation to be based on a rolling window 
            where a match is now removed if any players in the match have picked 
            the same civ for more than 70% of their last 40 games. Matches in which 
            a player has played less than 20 games are not removed.
        </li>
    </ul>






    <hr>
    <h4>2022-June-26</h4>
    <ul>
        <li>Updated most recent period to include matches up to 23rd June 2022</li>
        <li>Added new output "Bradley-Terry Score by Civilisation" to the "Win Rates" tab</li>
        <li>Added new output "Bradley-Terry Score vs Play Rate" to the "Win Rates" tab</li>
        <li>Added methodology documentation for Bradley-Terry Models</li>
        <li>Switched the win-rate to be on the y-axis for win-rate vs play-rate plots (thank you @PlumpDucklin)</li>
        <li>
            Added new filters "RM, Solo, Nomad, >1200" and "RM, Team, Nomad, >1800" to the
            "20Nov2021 - 26Apr2022" period (will add to latest period once there is enough data)
        </li>
        <li>
            Updated the period labels to indicate the main balence changes that were made for
            the given period
        </li>
    </ul>








    <hr>
    <h4>2022-June-11</h4>
    <ul>
        <li>Updated most recent "period" to include matches up to 9th June 2022</li>
        <li>Added new output "Naive Win Rates (Ranked) by Civilisation" to the "Win Rates" tab</li>
        <li>Added new output "Naive Win Rates by Game Length (Greater Than)" to the "Sliding Window" tab</li>
        <li>Improved model notation in "Methods" page (thank you @Alanocallaghan)</li>
    </ul>






    <hr>
    <h4>2022-May-22</h4>
    <ul>
        <li>Updated most recent "period" to include matches up to 21st May 2022</li>
        <li>Added WR vs Elo to the individual civilisation panel</li>
        <li>Removed the "game" selection as I no longer plan to support games other than aoe2</li>
        <li>Added a change log</li>
    </ul>






    <hr>
    <h4>2022-May-19</h4>
    <ul>
        <li>Updated most recent "period" to include matches up to 17th   May 2022</li>
        <li>Included new section for “individual civilisation” win rates</li>
        <li>Changed team games to be >1800 Elo</li>
        <li>Reduced "pro" category down to >1600 (will go back to >1700 once I have enough data)</li>
        <li>Removed EW due to a lack of data (will return if I get enough data in the future)</li>
    </ul>
    
    <hr>
    <h4>Pre-2022-May-19</h4>
    <ul>
        <li>I didn't keep a log... :(</li>
    </ul>

</template>




<style scoped>

</style>