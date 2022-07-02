



<template>
<div style = 'display: none' :class = "name">invisible</div>
<img :class="['img-output', 'img-square', name]" v-show="is_valid" >
</template>



<script>


import Plotly from 'plotly.js-dist';


export default {
    props: {
        "name": String,
        "title": String,
        "data_x": Object,
        "data_y": Object
    },
    methods: {
        create_plot(data_x, data_y) {

            if (!this.is_valid) {
                return
            }

            let get_random_value = function(arr) {
                return arr[Math.floor(Math.random() * arr.length)]
            }
            
            let values_x = []
            let values_y = []
            let values_civ = []
            let civ_positions = []

            Object.keys(data_x).map((e) => {
                if (Object.keys(data_y).includes(e)) {
                    values_x.push(data_x[e]["est"])
                    values_y.push(data_y[e]["est"])
                    values_civ.push(e)
                    civ_positions.push(get_random_value(
                        [
                            "top", "bottom", "left", "right",
                            "bottom left", "bottom right",
                            "top right", "top left"
                        ]
                    ))
                }
            });

            let yrange = [
                Math.min(...values_y) * 0.98,
                Math.max(...values_y) * 1.02
            ]

            let xrange = [
                Math.min(...values_x) * 0.98,
                Math.max(...values_x) * 1.02
            ]

            let config = {
                displayModeBar: false, // hide the zoom bar.
                staticPlot: true,      // Remove interactivity
                displaylogo: false,    // Remove plotly logo
                responsive: true       // Make plot responsive
            };

            // Main data points + error bars
            var core = {
                x: values_x,
                y: values_y,
                showlegend: false,
                mode: 'markers+text',
                marker: {
                    size: 10,
                    color: "#000000",
                },
                type: 'scatter',
                text: values_civ,
                textfont: { size: 18 },
                textposition: civ_positions,
            }

            let layout = {
                xaxis: {
                    zeroline: false,
                    linecolor: 'black',
                    linewidth: 0.4,
                    mirror: true,
                    tickfont: { size: 18 },
                    title: {
                        text: "Win Rate (%)",
                        font: {
                            size: 25
                        }
                    },
                    ticks: 'outside',
                    range: xrange
                },
                yaxis: {
                    zeroline: false,
                    linecolor: 'black',
                    linewidth: 0.4,
                    mirror: true,
                    tickfont: { size: 18 },
                    title: {
                        text: "Win Rate (%)",
                        font: {
                            size: 25
                        }
                    },
                    ticks: 'outside',
                    range: yrange
                },
                margin: {
                    b: 250,
                    t: 10,
                }
            };

            // X-axis reference line
            var line_med = {
                type: 'scatter',
                x: [-10, 9000, 50, 50],
                y: [50, 50, -100, 100],
                mode: 'lines',
                showlegend: false,
                line: {
                    color: 'rgba(255, 0, 0, 0.8)',
                    width: 7,
                    dash: 'solid',
                }
            }

            var data = [line_med, core];
            
            let div = document.querySelector('div.' + this.name);
                        
            Plotly.newPlot(div, data, layout, config)
                .then((gd) => {
                    return Plotly.toImage(
                        gd,
                        { format: 'png', width: 1800, height: 1000, scale: 3 }
                    )
                })
                .then((url) => {
                    let img = document.querySelector('img.' + this.name);
                    img.setAttribute("src", url);
                })
        }

    },
    computed: {
        is_valid() {
            return !(Object.keys(this.data_x).length === 0 || Object.keys(this.data_y).length === 0)
        }
    },
    updated() { 
        this.create_plot(this.data_x, this.data_y)
    },
    mounted() {
        this.create_plot(this.data_x, this.data_y)
    }

}

</script>



<style scoped>
.img-standard {
    max-height: 500px;
}

.img-square {
    max-height: 1000px;
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


</style>












