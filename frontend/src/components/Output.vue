<template>
<h3 v-if="title">
    <a :name="name" :href="'#' + name">
        {{ title }}
    </a>
</h3>
<img 
    :class="['img-output', {'img-square': square, 'img-standard': !square}]"
    :src="path + '/' + name + '.png'">
</template>



<script>
export default {
    props: {
        square: {
            type: Boolean,
            default: false
        },
        name: String,
        title: String,
        path: String
    }
}
</script>



<style scoped>
.img-standard {
    max-height: 500px;
}

.img-square {
    max-height: 650px;
}

.img-output {
    max-width: 100%;
    display: block;
    margin-right: auto;
    margin-left: auto;
    margin-top: 25px;
    margin-bottom: 50px;
    border: 0;
    width: auto;
    height: auto;
}

a:link { text-decoration: none; }
a:visited { text-decoration: none; }
a:hover { text-decoration: none; }
a:active { text-decoration: none; }
a { color: inherit; }
</style>