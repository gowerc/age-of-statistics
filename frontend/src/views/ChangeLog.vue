


<template>

    <h2>Change Log</h2>
    
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