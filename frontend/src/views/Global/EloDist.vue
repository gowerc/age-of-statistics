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

</template>


<script>
import Output from "@/components/Output"
export default {
    components: {
        "Output": Output
    }
}
</script>