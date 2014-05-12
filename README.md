#Viewing graph in the browser, 5 methods

This repository comes along with the blog post http://alexandremasselot.blogspot.com/XXXX
It propose basic code to demonstrate some features of different approaches to display and interact with graphs in the browser.


## Building random graphes
To produce a random graph with 40 nodes and 3 subclusters  of decreasing sizes and serve as input for the various methods.
This will produce files with `/tmp/aa` prefix

 + `/tmp/aa-nodes.tsv` tabular node description;
 + `/tmp/aa-edges.tsv` tabular edge description;
 + `/tmp/aa.json` a json file with nodes and edges arrays;
 + `/tmp/aa.dot` graphviz `dot` formatted;
 + `/tmp/aa-cypher.txt` as a cypher file ready to be imported into neo4j;


    perl perl/build-random-graph.pl /tmp/aa 40 3

## Graphviz

To convert the `.dot` file into an `.svg` one, use the graphviz executable. `/tmp/aa-graphviz.svg` can then be loaded in your browser.

    dot -Tsvg /tmp/aa.dot  >/tmp/aa-graphviz.svg

## neo4j
Simply import the cypher file, either through the web application or the command line

    bin/neo4j-shell -file /tmp/aa-cypher.txt

## cytoscape.js
Not to be mistaken for cytoscapeweb.js, reads the JSON file.

## d3.js
converts json data into d3 force layout ready data.


## sigma.js
Show an example processed by gephi and simply display it with sigma.js


#Author
alexandre.masselot@gmail.com

#License
BSD