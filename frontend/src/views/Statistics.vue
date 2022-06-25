

<template>


<div class="container pb-2 px-0 mx-0">
    <div class="row justify-content-evenly align-items-center px-0 mx-0">
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
        <div v-if="current_config">
            <component
                :is="slotProps.Component"
                :path="path"
                :config="current_config"
            />
        </div>
    </keep-alive>
</router-view>
</template>


<script>
import config from '@/components/json/config.json'
import Selector from '@/components/Selector'
import StatsPageLinks from '@/components/StatsPageLinks'




export default {
    components: {
        "Selector": Selector,
        "StatsPageLinks": StatsPageLinks,
    },
    computed: {
        path(){ 
            return [
                "/outputs",
                this.$route.query.period,
                this.$route.query.filter
            ].join('/');
        },
        
        filters(){
            if (!config) {
                return null;
            }
            return config.filters
        },
        
        periods(){
            if (!config) {
                return null;
            }
            return config.periods
        },
        
        current_filter(){
            return this.$route.query.filter
        },
        
        current_period(){
            return this.$route.query.period
        },
        
        current_config(){
            if (!config || !this.current_period || !this.current_filter) {
                return null;
            }
            
            if (!(this.current_period in config.periods)) {
                this.ensureValidURL(true)
                return null
            }
            
            if (!(this.current_filter in config.filters)) {
                this.ensureValidURL(true)
                return null
            }
            
            return {
                "period": config.periods[this.current_period],
                "filter": config.filters[this.current_filter]
            }
        }
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
                replacement.period = config.default.periods
                replacement.filter = config.default.filters
            }
            
            this.$router.replace({query: replacement});
        },
        
        ensureValidURL(force = false){
            if(
                !this.$route.query.period ||
                !this.$route.query.filter ||
                force
            ) {
                return this.updateRoute({}, true)
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