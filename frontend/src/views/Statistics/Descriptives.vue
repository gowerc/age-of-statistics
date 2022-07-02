<template>

<Output
    name="dist_patch"
    title="Distribution of Matches Played by Patch"
    :path="path" />

<Output
    name="dist_map"
    title="Distribution of Matches Played by Map"
    :path="path" />

<Output
    name="dist_map_normal"
    title="Distribution of Matches Played by Map (Normalised)"
    :path="path" />

<Output
    name="dist_gamelength"
    title="Distribution of Matches Played by Game Length"
    :path="path" />

<Output
    name="dist_elo"
    title="Distribution of Matches Played by Mean Team Elo"
    :path="path" />

<Output
    name="civ_playrate"
    title="Play Rate by Civilisation"
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