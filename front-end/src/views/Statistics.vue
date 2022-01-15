

<template>
  <h2>Main Stats Page</h2>
    
  <div>
    <h3>Game:</h3>
    <Selector
      :update-route="updateRoute"
      :list="games"
      name="game"
    />
  </div>
    
  <div>
    <h3>Date:</h3>
    <Selector
      :update-route="updateRoute"
      :list="dates"
      name="date"
    />
  </div>
    
  <div>
    <h3>Filter:</h3>
    <Selector
      :update-route="updateRoute"
      :list="filters"
      name="filter"
    />
  </div>
    
    
    
    

    
  <StatsPageLinks />

  <router-view v-slot="slotProps">
    <keep-alive max="6">
      <component
        :is="slotProps.Component"
        :path="path"
      />
    </keep-alive>
  </router-view>
</template>


<script>
    import config from '@/assets/config.json'
    import Selector from '@/components/Selector'
    import StatsPageLinks from '@/components/StatsPageLinks'

    export default {
        components: {
            "Selector": Selector,
            "StatsPageLinks": StatsPageLinks
        },
        computed: {
            path(){ 
                let game = this.$route.query.game
                if(!game) {
                    return ""
                }
                return [
                    "@assets",
                    this.$route.query.game,
                    this.$route.query.date,
                    this.$route.query.filter,
                    config[this.$route.query.game].default.version
                ].join('/');
            },
            filters(){
                let game = this.$route.query.game
                if(!game) {
                    return ""
                }
                return config[game].filters
            },
            dates(){
                let game = this.$route.query.game
                if(!game) {
                    return ""
                }
                return config[game].dates
            },
            games(){
                return config.games
            }
        },
        created(){
            this.ensureValidURL()
        },
        beforeUpdate() {
            this.ensureValidURL()
        },
        methods: {
            updateRoute(obj, defaults = false){
                let replacement = {
                    ...this.$route.query,
                    ...obj
                }
                if(defaults) {
                    replacement.date = config[replacement.game].default.date
                    replacement.filter = config[replacement.game].default.filter
                }
                this.$router.replace({query: replacement});
            },
            ensureValidURL(){
                if(
                    !this.$route.query.game |
                    !this.$route.query.date |
                    !this.$route.query.filter 
                ) {
                    this.updateRoute({game: "aoe2"}, true)
                }
            }
        }
    }
</script>


<style scoped>
    h3 {
        display: inline;
    }
</style>