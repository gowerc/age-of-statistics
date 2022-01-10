
<template>
    <h3>Naive Win Rates by Civilisation</h3>
    img class="img-cohort img-standard" src="{{path}}/civ_wrNaive.png"

    <h3>Naive Win Rates vs Play Rate</h3>
    img class="img-cohort img-standard" src="{{path}}/civ_wrNaive_playrate.png"

    <h3>Averaged Win Rates by Civilisation</h3>
    img class="img-cohort img-standard" src="{{path}}/civ_wrAvg.png"

    <h3>Averaged Win Rates vs Play Rate</h3>
    img class="img-cohort img-standard" src="{{path}}/civ_wrAvg_playrate.png"
</template>

<script>
export default {
    props: ["path"],
}
</script>


<style scoped>
</style>