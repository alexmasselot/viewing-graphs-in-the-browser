$(function () {
    var width = 960,
        height = 800;


    var force = d3.layout.force()
        .charge(-150)
        .size([width, height]);

    var svg = d3.select("#graph").append("svg")
        .attr("width", width)
        .attr("height", height);

    d3.json("../data/aa.json", function (error, graph) {
        //build a node map (so we can link the edges to the node objects)
        var nodes = {};
        _.each(graph.nodes, function (n) {
            nodes[n.id] = n;
        })
        var links = graph.edges.map(function (e) {
            return _.extend(e, {source: nodes[e.from], target: nodes[e.to]});
        });

        force
            .nodes(_.values(nodes))
            .links(links)
            .start();

        var link = svg.selectAll(".link")
            .data(links)
            .enter().append("line")
            .attr("class", "link");

        var node = svg.selectAll(".node")
            .data(graph.nodes)
            .enter().append("circle")
            .attr("class", "node")
            .attr("r", function(d){
                return 4+ d.size/10;
            })
            .style("fill", function (d) {
                return d.category;
            })
            .call(force.drag);

        node.append("title")
            .text(function (d) {
                return d.description;
            });

        force.on("tick", function () {
            link.attr("x1", function(d) { return d.source.x; })
                .attr("y1", function(d) { return d.source.y; })
                .attr("x2", function(d) { return d.target.x; })
                .attr("y2", function(d) { return d.target.y; });

            node.attr("cx", function(d) { return d.x; })
                .attr("cy", function(d) { return d.y; });
        });
    });
});