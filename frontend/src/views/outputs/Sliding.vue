<template>

<Output
    name="slide_wrNaive_elo"
    title="Naive Win Rates by Elo"
    square
    :path="path" />


<Output
    name="slide_wrNaive_gamelength"
    title="Naive Win Rates by Game Length"
    square
    :path="path" />


<Output
    name="slide_playrate_elo"
    title="Play Rates by Elo"
    square
    :path="path" />

</template>



<script>
import Output from "@/components/Output"
export default {
    props: ["path"],
    components: {
        "Output": Output
    }
}
</script>


<style scoped>
</style>