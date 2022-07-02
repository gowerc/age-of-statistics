
<template>

<div class="col-4 px-0 mx-0 py-1" v-if="cvc">
    <label class = "px-0 mx-0">
        Civilisation:
    </label>
    <select class="form-select px-0 mx-0" v-model="civ">
        <option 
            v-for="(opt, key) in cvc" 
            :key="key"
            > 
            {{ key }}
        </option>
    </select>
</div>

<OutputWR v-if="cvc !== null"
    name="civ_wrNaive"
    title="Civilisation v Civilisation Win Rates"
    :data="cvc[civ]"/>

<OutputWrElo v-if="wr_elo !== null"
    name="civ_wr_elo"
    title="Naive Win Rates by Elo"
    :data="wr_elo[civ]"/>


</template>

<script>
import OutputWR from "@/components/OutputWR"
import OutputWrElo from "@/components/OutputWrElo"


export default {
    props: ["path", "config"],
    components: {
        "OutputWR": OutputWR,
        "OutputWrElo": OutputWrElo
    },
    data() {
        return {
            cvc : null,
            wr_elo: null,
            civ: 'Aztecs'
        }
    },
    watch: {
        path: function (val) {
            this.updateData()
        }
    },
    created() {
        this.updateData()
    },
    methods: {
        updateData() {
            this.fetchData("cvc", "cvc.json")
            this.fetchData("wr_elo", "slide_WR_ELO.json")
        },
        fetchData(id, file) {
            let filepath = this.path + "/" + file;
            fetch(filepath)
                .then( response => {
                    return response.json()
                })
                .then( jsondata => {
                    this[id] = jsondata
                })
        }
    }
}
</script>


<style scoped>
</style>