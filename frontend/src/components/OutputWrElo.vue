<template>
<h3 v-if="title">
    <a :name="name" :href="'#' + name">
        {{ title }}
    </a>
</h3>
<div style = 'display: none' :class = "name">invisible</div>
<img :class="['img-output', 'img-standard', name]" >
</template>



<script>
import Plotly from 'plotly.js-dist';
import footnotes_all from '@/components/json/footnotes.json'


export default {
    props: {
        name: String,
        title: String,
        data: Object
    },
    methods: {
        create_plot(cvc) {

            let elo = cvc.elo;
            let med = cvc.med;
            let uci = cvc.uci;
            let lci = cvc.lci;
            
            
            let uci_adj = uci.map(function(item, index) {
                return item - med[index];
            })
            
            let lci_adj = med.map(function(item, index) {
                return item - lci[index];
            })
            
                        
            let yrange = [
                Math.min(...lci, 45) * 0.95,
                Math.max(...uci, 55) * 1.05
            ]
            
            let xrange = [
                Math.min(...elo) * 0.99,
                Math.max(...elo) * 1.01
            ]

            let footnotes = [
                `Filter: ${this.$route.query.filter}, Period: ${this.$route.query.period}<br>`,
                ...footnotes_all.slide_wrNaive_elo
            ].join('').replaceAll("<br/>", "<br>")
            
            let layout = {
                xaxis: {
                    zeroline: false,
                    linecolor: 'black',
                    linewidth: 0.4,
                    mirror: true,
                    ticks: 'outside',
                    range: xrange,
                    tickangle: 0,
                    tickfont: { size: 20 },
                    title: {
                        text: "Elo",
                        font: {
                            size: 25
                        }
                    }
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
                annotations: [{
                    text: footnotes,
                    font: {
                        size: 17,
                        color: 'rgba(0,0,0, 1)',
                    },
                    showarrow: false,
                    align: 'left',
                    x: 0,
                    y: -0.29,
                    xref: 'paper',
                    yref: 'paper',
                }],
                margin: {
                    b: 250,
                    t: 10,
                }
            };
            
            let config = {
                displayModeBar: false, // hide the zoom bar.
                staticPlot: true,      // Remove interactivity
                displaylogo: false,    // Remove plotly logo
                responsive: true       // Make plot responsive
            };
            
            
            // Solid Red reference line
            var line_med = {
                type: 'scatter',
                x: xrange,
                y: [50, 50],
                mode: 'lines',
                showlegend: false,
                line: {
                    color: 'rgba(255, 0, 0, 0.8)',
                    width: 7,
                    dash: 'solid',
                }
            }
            
            // Dashed Blue reference lines
            var line_bound = {
                type: 'scatter',
                x: [...xrange, null, ...xrange],
                y: [45, 45, null, 55, 55],
                mode: 'lines',
                showlegend: false,
                line: {
                    color: 'rgba(0, 0, 255, 0.5)',
                    width: 7,
                    dash: 'dash'
                }
            }
            
            let elo_rev = [...elo].reverse()
            let lci_rev = [...lci].reverse()
            
            
            var error_ribbon = {
                x: [...elo, ...elo_rev], 
                y: [...uci, ...lci_rev], 
                fill: "toself", 
                fillcolor: "rgba(231,107,243,0.4)", 
                line: {color: "transparent"}, 
                name: "Fair", 
                showlegend: false, 
                type: "scatter"
            };
            
            // Main data points + error bars
            var core = {
                x: elo,
                y: med,
                showlegend: false,
                mode: 'lines',
                line: {
                    color: 'rgb(0, 0, 0)',
                    width: 10
                },
                type: 'scatter'
            }
            
            var data = [line_med, line_bound, error_ribbon, core];
            
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
    updated() { 
        this.create_plot(this.data)
    },
    mounted() {
        this.create_plot(this.data)
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