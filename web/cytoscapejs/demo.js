$(loadCy = function () {

    function cyOptions(graph) {
        return {
            showOverlay: false,
            minZoom: 0.5,
            maxZoom: 2,
            layout: {
                name: 'arbor',
                fit: true,
                maxSimulationTime: 15000
            },
            style: cytoscape.stylesheet()
                .selector('node')
                .css({
                    'content': 'data(id)',
                    'font-family': 'helvetica',
                    'font-size': 14,
                    'text-outline-width': 3,
                    'text-outline-color': '#eee',
                    'text-valign': 'center',
                    'color': 'black',
                    'width': 'mapData(size, 0, 100, 20, 60)',
                    'height': 'mapData(size, 0, 100, 20, 60)',
                    'background-color': 'data(category)',
                    'background-opacity': 0.5,
                    'border-color': '#fff'
                })
                .selector(':selected')
                .css({
                    'background-color': '#000',
                    'target-arrow-color': '#000',
                    'text-outline-color': '#000',
                    color: 'white'
                })
                .selector('edge')
                .css({
                    'width': 2,
                    'target-arrow-shape': 'triangle',
                    'line-color': 'mapData(rate, 0,100, blue, red)'

                }),

            elements: graph,

            ready: function () {
                cy = this;
            }

        };
    }

    $.getJSON('../data/aa.json', function (graph) {
        //restructure the graph to fit cytoscape
        var cyGraph = {
            nodes: _.map(graph.nodes, function (n) {
                return {data: n};
            }),
            edges: _.map(graph.edges, function (e) {
                return {data: {source: e.from, target: e.to, rate: e.rate}};
            })
        };
        $('#graph').cytoscape(cyOptions(cyGraph));

    });


})
;