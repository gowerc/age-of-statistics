



<template>
<div style = 'display: none' :class = "name">invisible</div>
<img :class="['img-output', 'img-square', name]" v-show="is_valid" >
</template>



<script>


import Plotly from 'plotly.js-dist';


const pearson_correlation = (x, y) => {
    let sumX = 0,
        sumY = 0,
        sumXY = 0,
        sumX2 = 0,
        sumY2 = 0;

    if (x.length !== y.length) {
        throw 'x and y are of different lengths';
    }

    const n = x.length

    x.forEach((xi, index) => {
        const yi = y[index];
        sumX += xi;
        sumY += yi;
        sumXY += xi * yi;
        sumX2 += xi * xi;
        sumY2 += yi * yi;
    })

    const numerator = n * sumXY - sumX * sumY
    const denominator = Math.sqrt(
        ( n * sumX2 - sumX * sumX) *
        ( n * sumY2 - sumY * sumY)
    )
    return numerator / denominator;
};



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

            let yrange = [Math.min(...values_y), Math.max(...values_y)]
            let scaling = 0.05
            
            yrange[0] = yrange[0] - (yrange[1] - yrange[0]) * scaling
            yrange[1] = yrange[1] + (yrange[1] - yrange[0]) * scaling

            let xrange = [Math.min(...values_x), Math.max(...values_x)]
            xrange[0] = xrange[0] - (xrange[1] - xrange[0]) * scaling
            xrange[1] = xrange[1] + (xrange[1] - xrange[0]) * scaling

            // Misc options
            let config = {
                displayModeBar: false, // hide the zoom bar.
                staticPlot: true,      // Remove interactivity
                displaylogo: false,    // Remove plotly logo
                responsive: true       // Make plot responsive
            };

            // Axis defintitions
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

            // Diagonal reference line
            var ref_diag = {
                type: 'scatter',
                x: [0, 100],
                y: [0, 100],
                mode: 'lines',
                showlegend: false,
                line: {
                    color: 'rgba(0, 0, 255, 0.6)',
                    width: 7,
                    dash: 'solid',
                }
            }

            // X-axis reference line
            var ref_x = {
                type: 'scatter',
                x: [0, 100],
                y: [50, 50],
                mode: 'lines',
                showlegend: false,
                line: {
                    color: 'rgba(255, 0, 0, 0.6)',
                    width: 7,
                    dash: 'solid',
                }
            }

            // Y-axis reference line
            var ref_y = {
                type: 'scatter',
                x: [50, 50],
                y: [ 0, 100],
                mode: 'lines',
                showlegend: false,
                line: {
                    color: 'rgba(255, 0, 0, 0.6)',
                    width: 7,
                    dash: 'solid',
                }
            }

            let corr = pearson_correlation(values_x, values_y);
            corr = Math.round(corr * 1000) / 1000;

            let pearson_text = {
                x: [Math.min(...values_x) ],
                y: [Math.max(...values_y) ],
                mode: 'text',
                showlegend: false,
                text: ["Pearson's Correlation = " + corr ],
                textposition: 'bottom-right',
                type: 'scatter',
                textfont: { size: 18 },
            };

            var data = [ref_x, ref_y, ref_diag, pearson_text, core];
            
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












