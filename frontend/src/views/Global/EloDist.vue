<template>


<Output
    name="global_elo_dist_solo"
    title="Distribution of 1v1 Random Map Leaderboard Elo"
    path="/outputs/global" />

<Output
    name="global_elo_dist_team"
    title="Distribution of Team Random Map Leaderboard Elo"
    path="/outputs/global" />

<Output
    name="global_elo_dist_solo_ew"
    title="Distribution of 1v1 Empire Wars Leaderboard Elo"
    path="/outputs/global" />



<Output
    name="global_elo_games_SOLO"
    title="Median Number of Matches Played per Player by Elo Percentile in the 1v1 Random Map Leaderboard"
    path="/outputs/global" />

<Output
    name="global_elo_games_TEAM"
    title="Median Number of Matches Played per Player by Elo Percentile in the Team Random Map Leaderboard"
    path="/outputs/global" />

<Output
    name="global_elo_games_SOLO_EW"
    title="Median Number of Matches Played per Player by Elo Percentile in the 1v1 Empire Wars Leaderboard"
    path="/outputs/global" />

</template>


<script>
import Output from "@/components/Output"
export default {
    components: {
        "Output": Output
    }
}
</script>