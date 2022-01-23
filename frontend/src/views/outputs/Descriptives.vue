<template>
    <h3>
        <a name="dist_patch" href="#dist_patch">
            Distribution of Matches Played by Patch
        </a>
    </h3>
    <img 
        class="img-output img-standard" 
        :src="path + '/dist_patch.png'">

    <h3>
        <a name="dist_map" href="#dist_map">
            Distribution of Matches Played by Map
        </a>
    </h3>
    <img 
        class="img-output img-standard" 
        :src="path + '/dist_map.png'" >


    <h3>
        <a name="dist_map_normal" href="#dist_map_normal">
            Distribution of Matches Played by Map (Normalised)
        </a>
    </h3>
    <img 
        class="img-output img-standard" 
        :src="path + '/dist_map_normal.png'">


    <h3>
        <a name="dist_gamelength" href="#dist_gamelength">
            Distribution of Matches Played by Game Length
        </a>
    </h3>
    <img 
        class="img-output img-standard" 
        :src="path + '/dist_gamelength.png'">


    <h3>
        <a name="dist_elo" href="#dist_elo">
            Distribution of Matches Played by Mean Team Elo
        </a>
    </h3>
    <img 
        class="img-output img-standard" 
        :src="path + '/dist_elo.png'">


    <h3>
        <a name="civ_playrate" href="#civ_playrate">
            Play Rate by Civilisation
        </a>
    </h3>
    <img 
        class="img-output img-standard"
        :src="path + '/civ_playrate.png'">

</template>


<script>
export default {
    props: ["path"],
}
</script>


<style scoped>
a:link { text-decoration: none; }
a:visited { text-decoration: none; }
a:hover { text-decoration: none; }
a:active { text-decoration: none; }
a { color: inherit; }
</style>