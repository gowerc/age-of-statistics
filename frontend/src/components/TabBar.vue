


<template>
  <nav class="nav nav-pills flex-column flex-sm-row mb-4">
    <router-link
      v-for="tab in this.tabs"
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
    props: ["tabs"],
    computed: {
        lastUrl(){
            return this.$route.path.split("/").at(-1)
        }
    }
}
</script>







<style scoped>

a:link { text-decoration: none; }
a:visited { text-decoration: none; }
a:hover { text-decoration: none; }
a:active { text-decoration: none; }
    
    
.tab-box.active {
    border-bottom: 1.5px solid #212529;
}

.tab-box {
    color: inherit;
    margin-right: auto;
    margin-left: auto;
    font-weight: 600;
}
a.tab-box:hover { 
    color: inherit; 
}
</style>
