


<template>

<h3>
    <a href="#civcross">
        Civilisation Naive Win Rates Cross-Comparison
    </a>
</h3>

<div class="row">
    <strong>Y-Axis:</strong>
</div>
<div class="ms-3">
    <div class="row">
        <span class="align-middle">
            Period:
        </span>

        <div class="col-md-5 col-10">
            <Selector 
                :list="config.periods"
                :default="y_period"
                v-model="y_period"
                />
        </div>
        
        <div class="break"></div>
        
        <span class="align-middle">
            Filter:
        </span>
        
        <div class="col-md-5 col-10">
            <Selector
                :list="y_filtersObj"
                :default="y_filter"
                v-model="y_filter"
                />
        </div>
    </div>
</div>

<div class="row">
    <strong>X-Axis:</strong>
</div>

<div class="ms-3">
    <div class="row">
        
        <span class="align-middle">
            Period:
        </span>

        <div class="col-md-5 col-10">
            <Selector 
                :list="config.periods"
                :default="x_period"
                v-model="x_period"
                />
        </div>
        
        <div class="break"></div>
        
        <span class="align-middle">
            Filter:
        </span>
        
        <div class="col-md-5 col-10">
            <Selector
                :list="x_filtersObj"
                :default="x_filter"
                v-model="x_filter"
                />
        </div>
    </div>
</div>


<OutputCross 
    name="civcross"
    :data_x="data_x"
    :data_y="data_y"
    />

</template>



<script>
import config from '@/components/json/config.json'
import Selector from '@/components/Selector'
import OutputCross from '@/components/OutputCross'

let object_subset = function (obj, arr) {
    let result = {}
    arr.map( e => result[e] = obj[e])
    return result;
}

export default {
    data() {
        return {
            config: config,
            y_period: config.default.periods,
            y_filter: config.default.filters,
            x_period: config.default.periods,
            x_filter: config.default.filters,
            data_x: {},
            data_y: {}
        }
    },
    computed: {
        y_filtersObj() {
            return this.get_filterObj(this.y_period)
        },
        x_filtersObj() {
            return this.get_filterObj(this.x_period)
        }
    },
    components: {
        "OutputCross": OutputCross,
        "Selector": Selector
    },
    watch: {
        x_period() { this.updateX() },
        x_filter() { this.updateX() },
        y_period() { this.updateY() },
        y_filter() { this.updateY() }
    },
    mounted() {
        this.updateX()
        this.updateY()
    },
    methods: {
        get_filterObj(period) {
            if (!period) {
                return undefined
            }
            return object_subset(
                config.filters,
                config.periods[period].filters
            )
        },
        is_valid_selection(period, filter) {
            if (!(period in config.periods)) {
                return false
            }
            let periodObj = config.periods[period]
            if (!periodObj.filters.includes(filter)) {
                return false
            }
            return true
        },
        updateX() { this.updateData("data_x", this.x_period, this.x_filter) },
        updateY() { this.updateData("data_y", this.y_period, this.y_filter) },
        updateData(id, period, filter) {
            if (!this.is_valid_selection(period, filter)) {
                this[id] = {}
                return
            }
            let filepath = `/outputs/${period}/${ filter }/wr_naive.json`;
            fetch(filepath)
                .then(response => {
                    return response.json()
                })
                .then( jsondata => {
                    this[id] = jsondata
                })
        }
    }
}

</script>

<style scoped>

div {
    align-items: center;
}


span {
    margin: 0px;
    padding: 0px;
    width: 50px;
    display: inline;
}


/* Wider than 768 */ 
@media (min-width: 768px) {
    .break {
        display: none;
    }
}

/* Narrower than 768 */ 
@media (max-width: 768px) {}


a:link { text-decoration: none; }
a:visited { text-decoration: none; }
a:hover { text-decoration: none; }
a:active { text-decoration: none; }
a { color: inherit; }

strong { padding: 0px;}
</style>



