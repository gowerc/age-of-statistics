<template>
  <select
    class="form-control w-50"
    @change="onChange($event)"
  >
    <option 
      v-for="(opt, key) in list" 
      :key="key"
      :value="key"
      :selected="key===val"
    > 
      {{ opt.name }}
    </option>
  </select>
</template>


<script>
export default {
    props: ["updateRoute", "list", "name"],
    computed: {
        val() {
            return this.$route.query[this.name]
        }
    },
    methods: {
        onChange(e){
            let obj = {}
            obj[this.name] = e.target.value
            this.updateRoute(obj)
        }
    }
}
</script>


<style scoped>
    select {
        max-width: "200px";
    }
    .form-control {
        width:auto;
        display:inline-block;
    }
</style>