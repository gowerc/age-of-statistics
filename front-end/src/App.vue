<template>
    <Navbar/>
    <router-view></router-view>
</template>



<script>
import 'bootstrap'
import 'bootstrap/dist/css/bootstrap.min.css'
import "bootstrap-icons/font/bootstrap-icons.css";
import Navbar from '@/components/Navbar'
export default {
    components: {
        "Navbar": Navbar
    }
}
</script>



<style>
</style>

