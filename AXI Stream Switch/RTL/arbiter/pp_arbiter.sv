/*
    В данном модуле реализован Ping-Pong арбитр из статьи:
    Generating fast logic circuits for m-select n-port Round Robin Arbitration
    DOI: 10.1109/VLSI-SoC.2013.6673286
*/
module pp_arbiter #(
    parameter WIDTH_REQ = 8,
    localparam WIDTH_ID = $clog2(WIDTH_REQ) // размер указателя на REQUEST
) (
    input   logic   clk,
    input   logic   reset_n,

    input   logic   [WIDTH_REQ-1:0]     req_i,
    input                               en_i,    

    output  logic   [WIDTH_REQ-1:0]     gnt_o, // onehot
    output  logic   [WIDTH_ID-1:0]      gnt_id_o // номер gnt'а
);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    /*
        Преобразование входного вектора в термокодированный (ThermoCode)
    */
    function logic [WIDTH_REQ-1:0] get_tc(logic [WIDTH_REQ-1:0] in);
        logic [WIDTH_REQ-1:0] result;
        result[0] = in[0];
        for(int unsigned i = 1; i < WIDTH_REQ; i++) begin
            result[i] = in[i] | result[i-1];
        end
        return result;
    endfunction

    /*
        Поиск первого активного бита в термокодированном векторе (Edge Detector)
    */
    function logic [WIDTH_REQ-1:0] get_ed(logic [WIDTH_REQ-1:0] in);
        logic [WIDTH_REQ-1:0] result;
        result[0] = in[0];
        for(int unsigned i = 1; i < WIDTH_REQ; i++) begin
            result[i] = in[i] ^ in[i-1];
        end
        return result;
    endfunction

    logic   [WIDTH_REQ-1:0] head_ptr, head_ptr_next;
    logic   [WIDTH_REQ-1:0] tc, tc_mask, tc_mux;
    logic   [WIDTH_REQ-1:0] id_mask [WIDTH_ID-1:0];

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            head_ptr <= '0;
        end else begin
            head_ptr <= head_ptr_next;
        end
    end

    assign tc = get_tc(req_i);
    assign tc_mask = get_tc(req_i & head_ptr);
    assign tc_mux = tc_mask[WIDTH_REQ-1] ? tc_mask : tc;

    assign head_ptr_next = en_i ? {tc_mux[WIDTH_REQ-2:0], 1'b0} : head_ptr; // сдвиг вправо

    // generate grant signal
    assign gnt_o = get_ed(tc_mux);

    // generate id grant signal
    generate
        for(genvar i = 0; i < WIDTH_ID; i++) begin: rows
            for(genvar j = 0; j < WIDTH_REQ; j++) begin: columns
                assign id_mask[i][j] = (j >> i) & 1'b1;
            end
            assign gnt_id_o[i] = |(gnt_o & id_mask[i]);
        end
    endgenerate

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            ASSERT           ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    SVA_CHECK_GNT_ONEHOT: assert property (
        @(posedge clk) disable iff(!reset_n)
        gnt_o > 0 |-> $onehot(gnt_o)
    ) else $error("More than two GRANT received simultaneously");

    generate
        for(genvar i = 0; i < WIDTH_REQ; i++) begin:sva_check
            SVA_CHECK_REQ_GNT: assert property (
                @(posedge clk) disable iff(!reset_n)
                en_i & req_i[i] |-> ##[0:$] gnt_o[i]
            ) else $error("GRANT signal was not received");
            
            CVA_CHECK_ID_GNT: assert property (
                @(posedge clk) disable iff(!reset_n)
                gnt_o[i] |-> gnt_id_o == i
            ) else $error("The acknowledgement identifier number does not match the active bit number in the acknowledgement vector");
        end
    endgenerate

endmodule