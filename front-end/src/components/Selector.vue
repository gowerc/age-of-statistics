
<template>
    <div class="demo">
        <select @change="update" class="form-control" v-model="val">
            <option disabled value="">Please select one</option>
            <option 
                v-for="(opt, key) in list" 
                :key="key"
                :value="key"
            > 
                {{opt.name}}
            </option>
        </select>
    </div>
</template>


<script>
export default {
    props: ["setRoute", "list", "name"],
    data() {
        return {
            val : ""
        }
    },
    methods: {
        update(){
            let obj = {}
            obj[this.name] = this.val
            this.setRoute(obj)
        }
    }
}
</script>