
<template>

<div class="col-4 px-0 mx-0 py-1" v-if="data !== null">
    <label class = "px-0 mx-0">
        Civilisation:
    </label>
    <select class="form-select px-0 mx-0" v-model="civ">
        <option 
            v-for="(opt, key) in data" 
            :key="key"
            > 
            {{ key }}
        </option>
    </select>
</div>

<OutputPlotly v-if="data !== null"
    name="civ_wrNaive"
    title="Civilisation v Civilisation Win Rates"
    :data="data[civ]"/>
</template>

<script>
import OutputPlotly from "@/components/OutputPlotly"

export default {
    props: ["path"],
    components: {
        "OutputPlotly": OutputPlotly
    },
    data() {
        return {
            data : null,
            civ: 'Aztecs'
        }
    },
    watch: {
        path: function (val) {
            this.fetchData()
        }
    },
    created() {
        this.fetchData()
    },
    methods: {
        fetchData() {
            let filepath = this.path + "/cvc.json";
            fetch(filepath)
                .then( response => {
                    return response.json()
                })
                .then( jsondata => {
                    this.data = jsondata
                })
        }
    }
}
</script>


<style scoped>
</style>