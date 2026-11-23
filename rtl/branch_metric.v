module branch_metric (
    input wire [1:0] i_pair,

    output wire [1:0] o_bm00,
    output wire [1:0] o_bm01,
    output wire [1:0] o_bm10,
    output wire [1:0] o_bm11
);

    wire r1 = i_pair[1];
    wire r0 = i_pair[0];
    wire x = r1 ^ r0;

    assign o_bm00 = {r1 & r0, x};
    assign o_bm01 = {r1 & ~r0, ~x};
    assign o_bm10 = {~r1 & r0, ~x};
    assign o_bm11 = {~r1 & ~r0, x};

endmodule