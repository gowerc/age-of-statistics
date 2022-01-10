

<template>
    <h2>Main Stats Page</h2>
    
    
    <Selector 
        :setRoute="setRoute" 
        :list="filters"
        name="filter"
    />
    
    <Selector 
        :setRoute="setRoute" 
        :list="dates"
        name="date"
    />
    
    <Selector 
        :setRoute="setRoute" 
        :list="filters"
        name="filter"
    />

    <router-view v-slot="slotProps">
        <keep-alive max="6">
            <component :is="slotProps.Component" :path="path"></component>
        </keep-alive>
    </router-view>
</template>


<script>
    import manifest from '@/assets/manifest.json'
    import Selector from '@/components/Selector'

    export default {
        data(){
            return {
                filter: "",
                date: "",
                game: ""
            }
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
                    manifest[this.$route.query.game].default.version
                ].join('/');
            },
            filters(){
                let game = this.$route.query.game
                if(!game) {
                    return ""
                }
                return manifest[game].filters
            },
            dates(){
                let game = this.$route.query.game
                if(!game) {
                    return ""
                }
                return manifest[game].dates
            },
            games(){
                manifest.games
            }
        },
        methods: {
            setRoute(obj, defaults = false){
                let replacement = {
                    ...this.$route.query,
                    ...obj
                }
                if(defaults) {
                    replacement.date = manifest[replacement.game].default.date
                    replacement.filter = manifest[replacement.game].default.date
                }
                this.$router.replace({query: replacement});
            },
            ensureValidURL(){
                if(
                    !this.$route.query.game |
                    !this.$route.query.date |
                    !this.$route.query.filter 
                ) {
                    this.setRoute({game: "aoe2"}, true)
                }
            }
        },
        created(){
            this.ensureValidURL()
        },
        beforeUpdate() {
            this.ensureValidURL()
        },
        components: {
            "Selector": Selector
        }
    }
</script>
