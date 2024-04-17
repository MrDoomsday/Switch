/*
    В данном модуле реализован арбитр Index-based Round Robin (IRR) из статьи:
    DOI: 10.1109/ISVLSI.2015.27
    Судя по всему он он отличается высокой скоростью работы
*/
module irr_arbiter #(
    parameter WIDTH_REQ = 8,
    parameter SIZE_POINTER = $clog2(WIDTH_REQ)//размер указателя на REQUEST
) (
    input   bit     clk,
    input   bit     reset_n,

    input   bit     [WIDTH_REQ-1:0]         req_i,
    output  bit     [WIDTH_REQ-1:0]         req_ack_o,//подтверждение запроса

    output  bit     [WIDTH_REQ-1:0]         gnt_o,
    output  bit     [SIZE_POINTER-1:0]      gnt_id_o,
    output  bit                             gnt_vld_o,
    input   bit                             gnt_rdy_i
    /*
        Подключаемый модуль информирует о необходимости приостановить выдачу grant'ов
        Следует отметить, что в момент gnt_rdy_i = 0 сигналы gnt_o, gnt_id_o, gnt_vld_o могут изменяться
    */
);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    genvar i;
    localparam NOT_FULL_BUS = 2**SIZE_POINTER > WIDTH_REQ;//определяет, что используется не кратное степени двойки число входов request

    bit any_r;
    bit [WIDTH_REQ-1:0][SIZE_POINTER-1:0] sub_mux_data_i0, sub_mux_data_i1, sub_mux_data_o;//данный мультиплексор отвечает за поиск номера активного request'а
    bit [WIDTH_REQ-1:0] sub_mux_sel;

    bit [WIDTH_REQ-1:0][SIZE_POINTER-1:0] mp_in;
    bit [SIZE_POINTER-1:0] mp_out;
    bit [SIZE_POINTER-1:0] mp_sel;

    bit [SIZE_POINTER-1:0] point, point_next;//указывает на текущий приоритетный request
    

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    assign any_r = |req_i;

    generate
        //generate sub_mux - нужны для конвертирования адреса request'а 
        for(i = 0; i < WIDTH_REQ; i++) begin: gen_sub_mux
            irr_arbiter_mux #(
                .AMOUNT_IN  (2),
                .WIDTH_DATA (SIZE_POINTER)
            ) sub_mux_inst (
                .mux_in_i   ({sub_mux_data_i1[i], sub_mux_data_i0[i]}),
                .mux_sel_i  (sub_mux_sel[i]),
                .mux_out_o  (sub_mux_data_o[i])
            );

            if(i == 0) begin
                assign sub_mux_sel[i] = ~(~req_i[0] & any_r);
            end
            else begin
                assign sub_mux_sel[i] = req_i[i];
            end

            assign sub_mux_data_i1[i] = SIZE_POINTER'(i);

            if(i == WIDTH_REQ - 1) begin
                assign sub_mux_data_i0[i] = sub_mux_data_o[0];
            end
            else begin
                assign sub_mux_data_i0[i] = sub_mux_data_o[i+1];
            end
        end

        //мультиплексор приоритетов - динамически меняет приоритет обрабатываемых request'ов
        irr_arbiter_mux #(
            .AMOUNT_IN  (WIDTH_REQ),
            .WIDTH_DATA (SIZE_POINTER)
        ) mux_mp (
            .mux_in_i   (mp_in),
            .mux_sel_i  (mp_sel),
            .mux_out_o  (mp_out)
        );

        assign mp_in = sub_mux_data_o;
        assign mp_sel = point;

        assign point_next = NOT_FULL_BUS ? ((mp_out >= WIDTH_REQ - 1) ? {SIZE_POINTER{1'b0}} : (mp_out + SIZE_POINTER'(1'h1))) : (mp_out + SIZE_POINTER'(1'h1));

        always_ff @ (posedge clk or negedge reset_n) begin
            if(!reset_n) point <= 'h0;
            else if(any_r && gnt_rdy_i) point <= point_next;
        end

        //generate grant
        assign gnt_vld_o = any_r;
        assign gnt_id_o = mp_out;

        for(i = 0; i < WIDTH_REQ; i++) begin: gen_grant
            assign req_ack_o[i] = gnt_rdy_i & req_i[i] & gnt_o[i];
            
            if(i == 0) begin
                assign gnt_o[i] = any_r & (mp_out == i);
            end
            else begin
                assign gnt_o[i] = (mp_out == i);
            end
        end
    endgenerate

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            ASSERT           ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    SVA_CHECK_GNT_ONEHOT: assert property (
        @(posedge clk) disable iff(!reset_n)
        gnt_vld_o |-> $onehot(gnt_o)
    ) else $error("SVA error: More than two GRANT received simultaneously");

    SVA_CHECK_ID: assert property (
        @(posedge clk) disable iff(!reset_n)
        gnt_vld_o |-> gnt_o[gnt_id_o]
    ) else $error("SVA error: ID doesn't match GRANT");

    generate
        for(i = 0; i < WIDTH_REQ; i++) begin:sva_check
            SVA_CHECK_ACK: assert property (
                @(posedge clk) disable iff(!reset_n)
                req_i[i] |-> ##[0:$] req_ack_o[i]
            ) else $error("SVA error: ACK signal was not received");

            SVA_CHECK_EMPTY_ACK: assert property (
                @(posedge clk) disable iff(!reset_n)
                req_ack_o[i] |-> req_i[i]
            ) else $error("SVA error: ACK signal came before request");

            SVA_CHECK_GRANT: assert property (
                @(posedge clk) disable iff(!reset_n)
                gnt_vld_o & gnt_o[i] |-> req_i[i]
            ) else $error("SVA error: GRANT signal doesn't match request");

            SVA_CHECK_REQ_GNT: assert property (
                @(posedge clk) disable iff(!reset_n)
                req_i[i] |-> ##[0:$] gnt_o[i] & gnt_vld_o
            ) else $error("SVA error: GRANT signal was not received");
        end
    endgenerate

endmodule