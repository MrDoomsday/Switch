interface if_axis #(
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
)(
    input logic clk,
    input logic reset_n
);

    logic   [DATA_WIDTH-1:0]    data;
    logic   [ID_WIDTH-1:0]      id;
    logic   [DEST_WIDTH-1:0]    dest;
    logic   [USER_WIDTH-1:0]    user;
    logic   [DATA_WIDTH/8-1:0]  keep;
    logic                       last;
    logic                       valid;
    logic                       ready;


    SVA_CHECK_VLD_STABLE: assert property(
        @(posedge clk) disable iff (!reset_n)
        valid & ~ready |-> ##1 valid
    ) else $error("Valid signal is unstable during zero ready"); 

    SVA_CHECK_OTHERS_STABLE: assert property(
        @(posedge clk) disable iff (!reset_n)
        valid & ~ready |-> ##1 {data, id, dest, user, keep, last} == $past({data, id, dest, user, keep, last})
    ) else $error("AXI interface signals are unstable when there is no ready signal"); 

endinterface