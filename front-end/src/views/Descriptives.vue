<template>
  <h3>Distribution of Matches Played by Patch</h3>
  img class="img-cohort img-standard" src="{{ path }}/dist_patch.png"

  <h3>Distribution of Matches Played by Map</h3>
  img class="img-cohort img-standard" src="{{ path }}/dist_map.png"
    
  <h3>Distribution of Matches Played by Map (Normalised)</h3>
  img class="img-cohort img-standard" src="{{ path }}/dist_map_normal.png"

  <h3>Distribution of Matches Played by Game Length</h3>
  img class="img-cohort img-standard" src="{{ path }}/dist_gamelength.png"

  <h3>Distribution of Matches Played by Mean Team Elo </h3>
  img class="img-cohort img-standard" src="{{ path }}/dist_elo.png"

  <h3>Play Rate by Civilisation</h3>
  img class="img-cohort img-standard" src="{{ path }}/civ_playrate.png"
</template>


<script>
export default {
    props: ["path"],
}
</script>


<style scoped>
</style>