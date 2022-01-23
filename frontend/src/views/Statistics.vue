

<template>


<div class="container pb-2 px-0 mx-0">
    <div class="row justify-content-evenly align-items-center px-0 mx-0">
        <Selector
            :update-route="updateRoute"
            :list="games"
            name="game"
        />
        <Selector
            :update-route="updateRoute"
            :list="periods"
            name="period"
        />
        <Selector
            :update-route="updateRoute"
            :list="filters"
            name="filter"
        />
    </div>
</div>


<StatsPageLinks />

<router-view v-slot="slotProps">
    <keep-alive max="6">
        <div v-if="path">
            <component
                :is="slotProps.Component"
                :path="path"
            />
        </div>
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
                "/outputs",
                this.$route.query.game,
                config[this.$route.query.game].default.version,
                this.$route.query.period,
                this.$route.query.filter
            ].join('/');
        },
        filters(){
            let game = this.$route.query.game
            if(!game) {
                return ""
            }
            return config[game].filters
        },
        periods(){
            let game = this.$route.query.game
            if(!game) {
                return ""
            }
            return config[game].periods
        },
        games(){
            return config
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
                replacement.period = config[replacement.game].default.periods
                replacement.filter = config[replacement.game].default.filters
            }
            this.$router.replace({query: replacement});
        },
        ensureValidURL(){
            if(
                !this.$route.query.game |
                !this.$route.query.period |
                !this.$route.query.filter 
            ) {
                this.updateRoute({game: "aoe2"}, true)
            }
        }
    }
}
</script>


<style scoped>
.container {
    width: 100%;
    max-width: inherit;
}
</style>