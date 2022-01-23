<template>

<div class="d-flex align-items-start flex-column main-page">
    <div class="p-0 m-0  mb-3"  style="width:100%">
        <Navbar />
    </div>
    <div class="content mb-auto mx-auto px-3">
        <router-view />
    </div>
    <div class="p-0 m-0 mt-3" style="width:100%">
        <Footer />
    </div>
</div>
</template>



<script>
import 'bootstrap'
import 'bootstrap/dist/css/bootstrap.min.css'
import "bootstrap-icons/font/bootstrap-icons.css";
import "@/assets/styles.css"
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
export default {
    components: {
        "Navbar": Navbar,
        "Footer" : Footer
    }
}
</script>



<style scoped>

.content {
    max-width: 940px;
    width: min(940px, 100%); 
    margin-left: auto;
    margin-right: auto;
}
.main-page {
    min-height: 100vh;
}
</style>
