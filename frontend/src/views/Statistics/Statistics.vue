

<template>


<div class="container pb-2 px-0 mx-0">
    <div class="row justify-content-evenly align-items-center px-0 mx-0">
        <StatSelector
            :update-route="updateRoute"
            :list="periods"
            name="period"
        />
        <StatSelector
            :update-route="updateRoute"
            :list="filters"
            name="filter"
        />
    </div>
</div>


<TabBar :tabs="this.tabs"/>

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
import StatSelector from '@/components/StatSelector'
import TabBar from '@/components/TabBar'


let object_subset = function (obj, arr) {
    let result = {}
    arr.map( e => result[e] = obj[e])
    return result;
}



export default {
    data() {
        return {
            tabs: [
                {id: 'criteria', desc: "Criteria"},
                {id: 'descriptives', desc:"Descriptives"},
                {id: 'winrates', desc:"Win Rates"},
                {id: 'individual', desc:"Individual Civs"},
                {id: 'sliding', desc:"Sliding Window"},
                {id: 'experimental', desc: "Experimental"}
            ]
        }
    },
    components: {
        "StatSelector": StatSelector,
        "TabBar": TabBar,
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
            if (!config || !this.is_valid_period()) {
                return null;
            }
            return object_subset(
                config.filters,
                config.periods[this.current_period].filters
            )
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
        
        current_config() {
            let is_valid_url = this.ensureValidURL()
            if (!is_valid_url || !this.current_period || !this.current_filter) {
                return null;
            }
            let result = {
                "period": config.periods[this.current_period],
                "filter": config.filters[this.current_filter]
            }
            return result
        }
    },
    
    beforeUpdate() {
        this.ensureValidURL()
    },

    created() {
        this.ensureValidURL()
    },
    
    methods: {
        
        updateRoute(obj, go_to_default){
            let replacement = {
                ...this.$route.query,
                ...obj
            }
            if (go_to_default) {
                replacement.period = config.default.periods
                replacement.filter = config.default.filters
            }
            this.$router.replace({query: replacement});
        },


        is_valid_period() {
            if (!this.$route.query.period) {
                return false
            }
            if (!(this.$route.query.period in config.periods)) {
                return false
            }
            return true;
        },

        is_valid_filter() {
            if (!this.is_valid_period()){
                return false
            }
            let period = config.periods[this.$route.query.period]
            if (!this.$route.query.filter) {
                return false
            }
            if (!period.filters.includes(this.$route.query.filter)) {
                return false
            }
            return true
        },

        ensureValidURL() {

            if (!this.is_valid_period()){
                this.updateRoute({}, true)
                return false
            }

            if (!this.is_valid_filter()) {
                return false
            }

            return true
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
