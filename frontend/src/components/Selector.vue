<template>
<div class="col-md-5 px-0 mx-0 py-1">
    <label class = "px-0 mx-0">
        {{ toTitleCase(name) }}:&nbsp;
    </label>
    <select
        class="form-select px-0 mx-0"
        @change="onChange($event)">
        <option v-if = "show_blank" selected="true"></option>
        <option 
            v-for="(opt, key) in list" 
            :key="key"
            :value="key"
            :selected="key===val"> 
            {{ opt.label }}
        </option>
    </select>
</div>



</template>


<script>
export default {
    props: ["updateRoute", "list", "name"],
    computed: {
        val() {
            return this.$route.query[this.name]
        },
        show_blank() {
            if (!this.val || !this.list) {
                return true
            }
            return !(this.val in this.list)
        }
    },
    methods: {
        onChange(e){
            let obj = {}
            obj[this.name] = e.target.value
            this.updateRoute(obj)
        },
        toTitleCase(str) {
            return str.replace(
                /\w\S*/g,
                function(txt) {
                    return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
                }
            )
        }
    }
}
</script>


<style scoped>

.selection {
    display: inline-block;
}

select {
    display: inline-block;
    width: calc(100% - 4.2rem);
    max-width: 340px;
    min-width: 160px;
    font-size: calc(100% - 3px);
}




label {
    width: 3.6rem
}

</style>