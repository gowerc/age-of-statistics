<template>
    <h3>Naive Win Rates by Elo</h3>
    <img class="img-cohort img-square" src="outputs/cohort_{{meta.id}}/slide_wrNaive_elo_{{build_id}}.png">

    <h3>Naive Win Rates by Game Length</h3>
    <img class="img-cohort img-square" src="outputs/cohort_{{meta.id}}/slide_wrNaive_gamelength_{{build_id}}.png">


    <h3>Play Rates by Elo</h3>
    <img class="img-cohort img-square" src="outputs/cohort_{{meta.id}}/slide_playrate_elo_{{build_id}}.png">
</template>



<script>
export default {
    props: ["path"],
}
</script>


<style scoped>
</style>