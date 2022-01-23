<template>
    <p>
        The following statistics were calculated by only including matches that met the following critera:
    </p>
    <ul>
        <li>Were played on the <strong>{{meta_filter.leaderboard}}</strong> leaderboard</li>
        <li>Have a map classification of <strong>{{meta_filter.mapclass}}</strong></li>
        <li>The lowest Elo player has an Elo greater than <strong>{{meta_filter.elo_limit_lower}}</strong></li>
        <li>Started after <strong>{{ meta_period.lower }}</strong></li>
        <li>Started before <strong>{{ meta_period.upper }}</strong></li>
        <li>Had a game length longer than <strong>{{ meta_filter.length_limit_lower }}</strong> in-game minutes</li>
        <li>Had a game length shorter than <strong>{{ meta_filter.length_limit_upper }}</strong> in-game minutes</li>



        <li v-if="meta_filter.rm_single_pick">
            Contains no players who played the same civ more than <strong>40&#65130;</strong>
        </li>

    </ul>
    <p>
        The only exception is for the "Win rate by Elo" plot in which the lowest Elo requirement is
        relaxed to allow for all matches in which the lowest player had an Elo greater than
        <strong>{{meta_filter.elo_limit_lower_slide}}</strong>.
    </p>
</template>



<script>
import config from "@/assets/config.json"

export default {
    props: ["path"],
    computed: {
        meta_filter() {
            let query = this.$route.query
            return config[query.game].filters[query.filter]
        },
        meta_period() {
            let query = this.$route.query
            return config[query.game].periods[query.period]
        }
    }
}
</script>


<style scoped>
</style>