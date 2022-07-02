<template>
    <p>
            The following statistics were calculated by only including matches that met the following critera:
    </p>
    <ul>
        <li>Were played on the <strong>{{config.filter.leaderboard}}</strong> leaderboard</li>
        <li>Have a map classification of <strong>{{config.filter.mapclass}}</strong></li>
        <li>The lowest Elo player has an Elo greater than <strong>{{config.filter.elo_limit_lower}}</strong></li>
        <li>The highest Elo player has an Elo smaller than <strong>{{config.filter.elo_limit_upper}}</strong></li>
        <li>Started after <strong>{{ config.period.lower }}</strong></li>
        <li>Started before <strong>{{ config.period.upper }}</strong></li>
        <li>Had a game length longer than <strong>{{ config.filter.length_limit_lower }}</strong> in-game minutes</li>
        <li>Had a game length shorter than <strong>{{ config.filter.length_limit_upper }}</strong> in-game minutes</li>
    </ul>
    <p>
        The only exception is for the "Win rate by Elo" plot in which the lowest Elo requirement is
        relaxed to allow for all matches in which the lowest player had an Elo greater than
        <strong>{{config.filter.elo_limit_lower_slide}}</strong>.
    </p>
</template>



<script>
export default {
    props: ["path", "config"]
}
</script>


<style scoped>
</style>