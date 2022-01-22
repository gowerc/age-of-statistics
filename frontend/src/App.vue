<template>
  <Navbar />
  <div class="content">
    <router-view />
  </div>
</template>



<script>
import 'bootstrap'
import 'bootstrap/dist/css/bootstrap.min.css'
import "bootstrap-icons/font/bootstrap-icons.css";
import "@/assets/styles.css"
import Navbar from '@/components/Navbar'
export default {
    components: {
        "Navbar": Navbar
    }
}
</script>



<style scoped>
.content {
    max-width: 940px;
    width: min(940px, 100vw); 
    margin-left: auto;
    margin-right: auto;
}
</style>
