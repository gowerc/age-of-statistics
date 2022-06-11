
<template>

<Output
    name="civ_wrNaive"
    title="Naive Win Rates by Civilisation"
    :path="path" />

<Output
    name="civ_wrNaive_playrate"
    title="Naive Win Rates vs Play Rate"
    :path="path" />


<Output
    name="civ_wr_rank"
    title="Naive Win Rates (Ranked) by Civilisation"
    :path="path" />

<Output
    name="civ_wrAvg"
    title="Averaged Win Rates by Civilisation"
    :path="path" />

<Output
    name="civ_wrAvg_playrate"
    title="Averaged Win Rates vs Play Rate"
    :path="path" />

</template>

<script>
import Output from "@/components/Output"
export default {
    props: ["path", "config"],
    components: {
        "Output": Output
    }
}
</script>


<style scoped>
</style>