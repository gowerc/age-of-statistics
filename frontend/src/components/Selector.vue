



<template>
    <select
        :class="['form-select', 'px-0', 'mr-0']"
        @click="$emit('update:modelValue', $event.target.value)"
        v-model="selected">
        <option v-if = "show_blank" selected="true">
        </option>
        <option 
            v-for="(opt, key) in list" 
            :key="key"
            :value="key"
            :selected="key===selected"> 
            {{ opt.label }}
        </option>
    </select>
</template>


<script>
export default {
    props: ["list", "default"],
    emits: ["update:modelValue"],
    data() {
        return {
            selected: ""
        }
    },
    computed: {
        show_blank() {
            if (!this.list || !this.selected) {
                return true
            }
            return !(this.selected in this.list)
        }
    },
    created() {
        this.selected = this.default
    },
    methods: {
        toTitleCase(str) {
            return str.replace(
                /\w\S*/g,
                function(txt) {
                    return txt.charAt(0).toUpperCase() +
                        txt.substr(1).toLowerCase();
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
        width: 100%;
        max-width: 340px;
        min-width: 160px;
        font-size: calc(100% - 3px);
    }
    
    .right {
        margin-right: 0;
        margin-left: auto;
    }
    
    .left {
        margin-left: 0;
        margin-right: auto;
    }

</style>