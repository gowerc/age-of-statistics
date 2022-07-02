<template>

    <Output
        name="global_elo_time_NPLAYER"
        title="Total Number of Unique Active Players per Day"
        path="/outputs/global" />


    <Output
        name="global_elo_time_NGAME"
        title="Total Number of Games Played per Day"
        path="/outputs/global" />


    <Output
        name="global_elo_time_AVG"
        title="Mean Elo of Unique Active Players per Day"
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