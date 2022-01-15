


<template>
  <nav class="nav nav-pills flex-column flex-md-row mb-4">
    <router-link
      v-for="tab in tabs"
      :key="tab"
      :class="[
        'flex-sm-fill', 
        'text-center', 
        'tab-box', 
        { active: lastUrl === tab.id }
      ]"
      :to="{ path: tab.id, query: $route.query}"
      href="#"
    >
      {{ tab.desc }}
    </router-link>
  </nav>
</template>


<script>
export default {
    data() {
        return {
            tabs: [
                {id: 'descriptives', desc:"Descriptives"},
                {id: 'winrates', desc:"Win-Rates"}
            ]
        }
    },
    computed: {
        lastUrl(){
            return this.$route.path.split("/").at(-1)
        }
    }
}
</script>
   
