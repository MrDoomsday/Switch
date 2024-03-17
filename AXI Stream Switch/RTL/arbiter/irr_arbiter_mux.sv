module irr_arbiter_mux #(
    parameter AMOUNT_IN = 10,
    parameter WIDTH_DATA = 32
)(
    input   bit     [AMOUNT_IN-1:0][WIDTH_DATA-1:0]     mux_in_i,
    input   bit     [$clog2(AMOUNT_IN)-1:0]             mux_sel_i,
    output  bit     [WIDTH_DATA-1:0]                    mux_out_o
);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    assign mux_out_o = mux_in_i[mux_sel_i];
endmodule