module pr_encoder #(
    parameter WIDTH_N = 10,//размер входного вектора request
    parameter AMOUNT_M = 2//максимальное число допустимых одновременных ответов
)(
    input bit clk,
    input bit reset_n,

    input   bit     [WIDTH_N-1:0]                   req_i,
    input   bit                                     req_vld_i,
    output  bit                                     req_rdy_o,

    output  bit     [AMOUNT_M-1:0][WIDTH_N-1:0]     gnt_o,
    output  bit                                     gnt_vld_o,
    input   bit                                     gnt_rdy_i
);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************         DECLARATION         ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    localparam WIDTH_SUM = $clog2(AMOUNT_M+1);//размер сумматора, который будет вести подсчет активных бит с насыщением
    genvar i,j;

    bit                                     ready;    
    bit     [WIDTH_N-1:0][WIDTH_SUM-1:0]    sum_tmp, sum_reg;
    bit                                     sum_vld;
    bit     [WIDTH_N-1:0][AMOUNT_M-1:0]     gnt_next;



    function bit [WIDTH_SUM-1:0] sum_sat(bit [WIDTH_SUM-1:0] a, b);//суммирование с насыщением
        bit [WIDTH_SUM:0] result;
        
        if(AMOUNT_M == 1) begin
            result = a | b;
        end
        else begin
            result = a + b;
            if(result > AMOUNT_M) result[WIDTH_SUM-1:0] = WIDTH_SUM'(AMOUNT_M);
        end

        return result[WIDTH_SUM-1:0];
    endfunction


    function bit [AMOUNT_M-1:0] bin2thermo(bit [WIDTH_SUM-1:0] bin);
        bit [AMOUNT_M-1:0] result;
        result = '1;
        result <<= (AMOUNT_M-bin);
        return result;
    endfunction

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    assign req_rdy_o = ready;

    generate
        //generate saturated_sum
        assign sum_tmp[0] = {{(WIDTH_SUM-1){1'b0}}, req_i[0]};

        for(i = 1; i < WIDTH_N; i++) begin:gen_sat_tmp_sum
            assign sum_tmp[i] = sum_sat(sum_tmp[i-1], {{(WIDTH_SUM-1){1'b0}}, req_i[i]});
        end

        //fixed in register sum
        for(i = 0; i < WIDTH_N; i++) begin:gen_sat_sum
            always_ff @ (posedge clk) begin
                if(ready) sum_reg[i] <= sum_tmp[i];
            end
        end

        always_ff @ (posedge clk or negedge reset_n) begin
            if(!reset_n) sum_vld <= 1'b0;
            else if(ready) sum_vld <= req_vld_i;
        end


        //send output data
        for(i = 0; i < WIDTH_N; i++) begin:gen_gnt_next
            assign gnt_next[i] = bin2thermo(sum_reg[i]);
        end

        for(i = 0; i < AMOUNT_M; i++) begin:gen_gnt
            for(j = 0; j < WIDTH_N; j++) begin:transporation_gnt
                always_ff @ (posedge clk) begin
                    if(ready) gnt_o[i][j] <= gnt_next[j][i];//т.е. делаем транспонирование
                end
            end
        end

        always_ff @ (posedge clk or negedge reset_n) begin
            if(!reset_n) gnt_vld_o <= 1'b0;
            else if(ready) gnt_vld_o <= sum_vld;
        end
    endgenerate


    assign ready = gnt_vld_o & ~gnt_rdy_i ? 1'b0 : 1'b1;


/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            ASSERTION        ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    SVA_CHECK_REQ_VLD: assert property (
        @(posedge clk) disable iff(!reset_n)
        req_vld_i & ~req_rdy_o |-> ##1 req_vld_i
    ) else $display("SVA error: request valid is not stable for disable ready!");

    SVA_CHECK_REQ_DATA: assert property (
        @(posedge clk) disable iff(!reset_n)
        req_vld_i & ~req_rdy_o |-> ##1 $stable(req_i)
    ) else $display("SVA error: request is not stable for disable ready!");

endmodule