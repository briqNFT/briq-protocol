%lang starknet

// The shape contract can hold a contigous range of shapes, referred by an index.
// This increments that initial index.
// Usually 1 because the token 0 generally doesn't exist and this makes things neater.
const INDEX_START = 1

// Contains N + 1 items (where N is the number of shapes) because we need the length of all shapes.
shape_offset_cumulative:
dw 0;
dw 2;
shape_offset_cumulative_end:

shape_data:
dw 863007951083700187368981306005289237711549847714211561473;
dw 3138550867693340381747753528143363976420947510921535684607;
dw 867699793691671751021422106963715347039123285304720490497;
dw 3138550867693340381747753528143363976402500766847826132991;
shape_data_end:

nft_offset_cumulative:
dw 0;
dw 0;
nft_offset_cumulative_end:

nft_data:
nft_data_end:
