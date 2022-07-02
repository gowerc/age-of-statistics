<template>

    <TabBar :tabs="this.tabs"/>

    <router-view v-slot="slotProps">
        <keep-alive max="6">
                <component :is="slotProps.Component"/>
        </keep-alive>
    </router-view>

</template>




<script>
import TabBar from "@/components/TabBar"
export default {
    data() {
        return {
            tabs: [
                {id: 'timetrends', desc: "Time Trends"},
                {id: 'elodist', desc:"Elo Distributions"}
            ]
        }
    },
    components: {
        "TabBar": TabBar
    }
}
</script>

