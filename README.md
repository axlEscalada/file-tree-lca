# Find first file ancestor between two files

## Algorithm implementation
For this excercise I treat the filesystem like a N-ary tree so, I used an euler tour algorithm to generate a path of nodes between the first file (or node) 
and the second file. With this algorithm I ensure that the lowest number between the first appearance of two nodes is the common path.
The time complexity for this algorithm is O(N).

I also used a sparse table taking as input the euler tour array, with this algorithm I can query the findFile function any time having a time complexity of O(N).
The complexity of building this sparse table is O(N log n).

Together then this algorithms form an LCA algorithm.

## Build and test
Zig version: `0.12.0-dev.1831+90a19f741`

For testing run:
`zig test src/tests.zig`

For build and executable run:
`zig build`

