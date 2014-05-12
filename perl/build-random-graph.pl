#!/usr/bin/env perl
use strict;
use List::Util qw/shuffle/;
use List::MoreUtils qw/any firstval distinct/;
use Hash::Merge qw/merge/;
use Text::Lorem;
use JSON;
use Data::Dumper;

#name can be any file prefix
die "usage $0 name nbNodes nbSubgraphes" unless 3==@ARGV;
my ($name, $nbNodes, $nbSubgraphes) = @ARGV;

#lorem factory
my $lorem = Text::Lorem->new();

#build some decreasing random sizes for subgraphes
my $subFact  = 0.3;
my $remNodes = $nbNodes;
my $i        = $nbSubgraphes;

my @graphSizes;
while($remNodes>0 && $i>1){
    my $s = int((0.3+rand(0.4))*$remNodes)+1;
    push @graphSizes, $s;
    $remNodes-=$s;
    $i--;
}
push @graphSizes, $remNodes if $remNodes>0;

my ($offsetNode, $offsetEdge) = (0, 0);
my %graph=(
    nodes => [],
    edges => []
);
foreach my $i (0..$#graphSizes){
    my $n = $graphSizes[$i];
    my ($lNodes, $lEdges) = randomGraph($n, $offsetNode, $offsetEdge, {cluster=>"c_$i"});
    $offsetNode+=$n;
    $offsetEdge += scalar(@$lEdges);
    push @{$graph{nodes}}, @$lNodes;
    push @{$graph{edges}}, @$lEdges;
}

saveJSON(\%graph, $name);
saveTSV(\%graph, $name);
saveGraphviz(\%graph, $name);
saveCypher(\%graph, $name);

=head2 randomGraph
Entry point to build one random connected cluster. It will draw random edges with low prob and higher for a sub cluster
=cut
sub randomGraph{
    my($graphSize, $offsetNode, $offsetEdge, $commonProps)=@_;

    my $pConnLow = 1.0/$graphSize;
    my $pConnHigh = 0.4;
    my @categories=qw/red green blue magenta cyan/;
    my @types=qw/X Y/;

    my @nodes =  map {
        my $i = $_+$offsetNode;
        merge({         id          => "n_$i",
            category    => $categories[rand(@categories)],
            type        => $types[rand(@types)],
            size        => 1*rand(100),
            description => $lorem->sentences(1)
       }, $commonProps);
    } 0..($graphSize-1);

    my %highlyConnected;
    if($graphSize>10){
        $highlyConnected{$_}=1 foreach ((shuffle(map {$_->{id}} @nodes))[0..5]);
    }


    my @edges;
    foreach my $nodeA (@nodes){
        my $cptEdges;
        foreach my $nodeB (@nodes){
            my ($idA, $idB) = ($nodeA->{id}, $nodeB->{id});
            next if $idB eq $idA;

            if(rand()<$pConnLow || ($highlyConnected{$idA} && $highlyConnected{$idB} && rand()<$pConnHigh)){
                $cptEdges++;
                push @edges, randomEdge("e_$offsetEdge", $idA, $idB, $commonProps);
                $offsetEdge++;
            }
        }
    }

    connectGraph(\@nodes, \@edges, $offsetEdge, $commonProps);
#    use Data::Dumper;
#    warn Dumper(\@nodes);
#    warn Dumper(\@edges);
    (\@nodes, \@edges);
}

#build a random edge, based on nodes id
sub randomEdge{
    my($id, $na, $nb, $commonProps)=@_;
    merge({
        id          => $id,
        from        => $na,
        to          => $nb,
        probability => rand(),
        rate        => 100*rand()
    }, $commonProps);
}

#ensure the graph is connex
#that's for sure a suboptimal implementation, but, who cares here...
sub connectGraph{
    my( $nodes, $edges, $offsetEdge, $commonProps) =@_;

    my @subgraphes;
    my %nodeCheck;
    $nodeCheck{$_->{id}}=1 foreach(@$nodes);
    foreach my $e (@$edges){
        my $from = $e->{from};
        my $to = $e->{to};
        my $g = firstval {$_->{$from} || $_->{$to} } @subgraphes;
        if(!defined $g){
            $g={};
            push @subgraphes, $g;
        }
        $g->{$from}=1;
        $g->{$to}=1;
        delete $nodeCheck{$from};
        delete $nodeCheck{$to};

        #reduce subgraphes
        my @redgs = grep {$_ != $g && ( $_->{$from} || $_->{$to})} @subgraphes;
        next unless @redgs;
        foreach my $delg (@redgs){
            $g->{$_}=1 foreach keys %$delg;
            delete $delg->{$_} foreach keys %$delg;
        }
    }
    @subgraphes = grep {scalar %$_} @subgraphes;
    push @subgraphes, {$_=>1} foreach keys %nodeCheck;
    if (@subgraphes == 1){
        return;
    }
    foreach (0..($#subgraphes-1)){
        my %sg0 = %{ $subgraphes[$_]};
        my %sg1 = %{ $subgraphes[$_+1]};
        delete $sg0{$_} foreach keys %sg1;
        delete $sg1{$_} foreach keys %sg0;

        push @$edges, randomEdge("e_$offsetEdge", (keys %sg0)[0], (keys %sg1)[0], $commonProps);
        $offsetEdge++;
    }
    connectGraph($nodes, $edges, $offsetEdge, $commonProps);
}


#save one name-nodes.tsv and one names-edges.tsv files
sub saveTSV{
    my ($graph, $name)=@_;

    foreach my $entity (qw/nodes edges/){
        open my $FD, '>', "$name-$entity.tsv";
        my @cols = sort keys %{$graph->{$entity}[0]};
        print $FD join("\t", @cols)."\n";
        foreach (@{$graph->{$entity}}){
            print $FD join("\t", @$_{@cols})."\n";
        }
        close $FD;
    }
}

=head2 saveGraphviz
To be imported into graphviz
=cut
sub saveGraphviz{
    my ($graph, $name)=@_;
    open my $FD, '>', "$name.dot";
    print $FD <<EOT;
graph random{
  node [
    style=filled,
    fontsize=25
       ];
EOT
    foreach (@{$graph->{nodes}}){
        my $r=0.5+$_->{size}/100;
        print $FD "$_->{id} [color=$_->{category},width=$r,height=$r,tooltip=\"$_->{description}\",href=\"http://www.graphviz.org\"]\n"
    }
    foreach (@{$graph->{edges}}){
        print $FD "$_->{from} -- $_->{to} [label=$_->{id}]\n"
    }

    print $FD "}\n";

    close $FD;
}

=head2 saveCypher
To be imported into a neo4j database
=cut
sub saveCypher{
    my ($graph, $name)=@_;
    open my $FD, '>', "$name-cypher.txt";
    foreach (@{$graph->{nodes}}){
        my $r=0.5+$_->{size}/100;
        print $FD "CREATE ($_->{id}:MyNode {description:'$_->{description}', category:'$_->{category}', cluster:'$_->{cluster}', size:$_->{size}})\n";
    }
    foreach (@{$graph->{edges}}){
        print $FD "CREATE  ($_->{from})-[:MyLink {rate:$_->{rate}}]->($_->{to})\n"
    }
    print $FD ";\n";

    close $FD;
}

=head2 saveJSON
Simply dumps the graph in a JSON form
=cut
sub saveJSON{
    my ($graph, $name)=@_;
    open my $FD, '>', "$name.json";
    my $json = JSON->new->allow_nonref;

    my $jsStr = $json->pretty->encode( $graph );
    print $FD $jsStr;

    close $FD;
}