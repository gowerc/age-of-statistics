<template>
    <p>
        This cohort was built by only including matches that met the following critera:
    </p>
    <ul>
        <li>Were played on the <strong>{{meta.leaderboard}}</strong> leaderboard</li>
        <li>Have a map classification of <strong>{{meta.mapclass}}</strong></li>
        <li>The lowest Elo player has an Elo greater than <strong>{{meta.elo_limit_lower}}</strong></li>
        <li>Started after <strong>{{meta.start_limit_lower}}</strong></li>
        <li>Started before <strong>{{meta.start_limit_upper}}</strong></li>
        <li>Had a game length longer than <strong>{{meta.length_limit_lower}}</strong> in-game minutes</li>
        <li>Had a game length shorter than <strong>{{meta.length_limit_upper}}</strong> in-game minutes</li>
        {% if meta.rm_single_pick %}
        <li>Contains no players who played the same civ more than 40&#65130;</li>
        {% endif %}
    </ul>
    <p>
        The only exception is for the "Win rate by Elo" plot in which the lowest Elo requirement is
        relaxed to allow for all matches in which the lowest player had an Elo greater than
        <strong>{{meta.elo_limit_lower_slide}}</strong>.
    </p>
</template>



<script>
export default {
    props: ["path"],
}
</script>


<style scoped>
</style>