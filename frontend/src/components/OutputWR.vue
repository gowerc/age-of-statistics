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


function get_sort_index(toSort) {
    let hold = [];
    toSort.map((v, i) => {
        hold.push([v,i])
    })
    hold.sort(function(left, right) {
        return left[0] > right[0] ? -1 : 1;
    });
    var sortIndices = [];
    hold.map(e => {
        sortIndices.push(e[1]);
    })
  return sortIndices;
}


function sort_by_index(arr, idx) {
    return idx.map(e => {
        return arr[e]
    })
}


export default {
    props: {
        name: String,
        title: String,
        data: Object
    },
    methods: {
        create_plot(cvc) {

            let civs = cvc.map(a => a.civ);
            let wr = cvc.map(a => a.wr);
            let uci = cvc.map(a => a.uci);
            let lci = cvc.map(a => a.lci);
            let uci_adj = cvc.map(a => a.uci - a.wr);
            let lci_adj = cvc.map(a => a.wr - a.lci);


            let idx = get_sort_index(wr);
            civs = sort_by_index(civs, idx);
            wr = sort_by_index(wr, idx);
            uci = sort_by_index(uci, idx);
            lci = sort_by_index(lci, idx);
            uci_adj = sort_by_index(uci_adj, idx);
            lci_adj = sort_by_index(lci_adj, idx);
            
            let civ_index = Array.from({length: wr.length}, (e, i)=> i)
            
            let yrange = [
                Math.min(...lci) * 0.95,
                Math.max(...uci) * 1.05
            ]
            
            let xrange = [
                Math.min(...civ_index) - 1,
                Math.max(...civ_index) + 1
            ]

            let footnotes = [
                `Filter: ${this.$route.query.filter}, Period: ${this.$route.query.period}<br>`,
                ...footnotes_all.civ_wrNaive
            ].join('').replaceAll("<br/>", "<br>")
            
            let layout = {
                xaxis: {
                    zeroline: false,
                    linecolor: 'black',
                    linewidth: 0.4,
                    mirror: true,
                    ticks: 'outside',
                    range: xrange,
                    tickvals: civ_index,
                    ticktext: civs,
                    tickangle: -50,
                    tickfont: { size: 20 }
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
                x: [-10, 60],
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
                x: [-10, 60, null, -10, 60],
                y: [45, 45, null, 55, 55],
                mode: 'lines',
                showlegend: false,
                line: {
                color: 'rgba(0, 0, 255, 0.5)',
                width: 7,
                dash: 'dash'
                }
            }
            
            // Main data points + error bars
            var core = {
                x: civ_index,
                y: wr,
                showlegend: false,
                mode: 'markers',
                marker: {
                    size: 10,
                    color: "#000000",
                },
                error_y: {
                    type: 'data',
                    symmetric: false,
                    array: uci_adj,
                    arrayminus: lci_adj,
                    color: '#000000',
                    thickness: 8,
                    width: 5,
                    opacity: 1
                },
                type: 'scatter'
            }
            
            var data = [line_med, line_bound, core];
            
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