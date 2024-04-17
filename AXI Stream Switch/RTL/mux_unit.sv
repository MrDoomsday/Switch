module mux_unit #(
    parameter   T_DATA_WIDTH = 8, 
                S_DATA_COUNT = 8,//число входов мультиплексора
                M_DATA_COUNT = 3,//число выходов коммутатора 
    localparam  T_ID___WIDTH = $clog2(S_DATA_COUNT),//квартус стандарт едишн не понимает данного колдунства
    //parameter   T_ID___WIDTH = $clog2(S_DATA_COUNT),
                T_DEST_WIDTH = $clog2(M_DATA_COUNT),
    parameter   NUM_CHANNEL = 0 //номер выходного канала, задается модулем внешнего уровня
)(
    input     logic clk,
    input     logic reset_n,

// multiple input streams
    input     logic   [S_DATA_COUNT-1:0][T_DATA_WIDTH-1:0]  s_data_i,
    input     logic   [S_DATA_COUNT-1:0][T_DEST_WIDTH-1:0]  s_dest_i,
    input     logic   [S_DATA_COUNT-1:0]                    s_last_i ,
    input     logic   [S_DATA_COUNT-1:0]                    s_valid_i,
    output    logic   [S_DATA_COUNT-1:0]                    s_ready_o,

// multiple output streams
    output    logic   [T_DATA_WIDTH-1:0]  m_data_o  ,
    output    logic   [T_ID___WIDTH-1:0]  m_id_o    ,
    output    logic                       m_last_o  ,
    output    logic                       m_valid_o ,
    input     logic                       m_ready_i

);



/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    localparam SIZE_POINTER = T_ID___WIDTH;//число бит, которых достаточно для указания номера входа
    genvar i;

    typedef struct packed {
        logic   [T_DATA_WIDTH-1:0]  data;
        logic   [T_DEST_WIDTH-1:0]  dest;
        logic                       last;
        logic                       valid;
    } stream;

    stream [S_DATA_COUNT-1:0]       st_chk_vld;
    stream [S_DATA_COUNT-1:0]       st_pipe;
    logic  [S_DATA_COUNT-1:0]       pkt_process;//какой-то пакет находится в обработке - активен начиная от первого до последнего слова пакета

    logic     [S_DATA_COUNT-1:0]    req_next;
    logic     [S_DATA_COUNT-1:0]    req;
    logic     [S_DATA_COUNT-1:0]    req_ack;//подтверждение запроса

    logic     [S_DATA_COUNT-1:0]    gnt;
    logic     [SIZE_POINTER-1:0]    gnt_id;
    logic                           gnt_vld;
    logic                           gnt_rdy;

    enum bit [1:0] {
        IDLE,   //режим простоя
        TRANSIT //режим передачи пакетов
    } state, state_next;

    bit [SIZE_POINTER-1:0] active_channel, active_channel_next;
    logic ready_master;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    irr_arbiter #(
        .WIDTH_REQ(S_DATA_COUNT)
    ) irr_arbiter_inst (
        .clk        (clk        ),
        .reset_n    (reset_n    ),

        .req_i      (req        ),
        .req_ack_o  (req_ack    ),

        .gnt_o      (gnt        ),
        .gnt_id_o   (gnt_id     ),
        .gnt_vld_o  (gnt_vld    ),
        .gnt_rdy_i  (gnt_rdy    )
    );



/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    generate
        for(i = 0; i < S_DATA_COUNT; i++) begin: gen_pipe
            //определение принадлежности входящего пакета данному модулю
            always_comb begin:gen_vld
                st_chk_vld[i].data     = s_data_i[i];
                st_chk_vld[i].dest     = s_dest_i[i];
                st_chk_vld[i].last     = s_last_i[i];
                /*
                *   мы должны принимать только тот пакет, который соответствует номеру текущего выходного канала
                *   вышестоящий модуль присваивает номер канала параметром NUM_CHANNEL в шапке модуля
                */
                st_chk_vld[i].valid    = s_valid_i[i] & (s_dest_i[i] == T_DEST_WIDTH'(NUM_CHANNEL));
            end

            //фиксация входных данных в регистр с генерацией request'а
            always_ff @ (posedge clk or negedge reset_n) begin
                if(!reset_n) st_pipe[i].valid <= 1'b0;
                else if(s_ready_o[i]) st_pipe[i].valid <= st_chk_vld[i].valid;
            end


            always_ff @ (posedge clk) begin
                if(s_ready_o[i]) begin
                    st_pipe[i].data <= st_chk_vld[i].data;
                    st_pipe[i].dest <= st_chk_vld[i].dest;
                    st_pipe[i].last <= st_chk_vld[i].last;
                end
            end

            always_ff @ (posedge clk or negedge reset_n) begin
                if(!reset_n) pkt_process[i] <= 1'b0;
                /*пакет может приходить любой длины, в том числе и однословный*/                
                else if(pkt_process[i]) begin
                    // сбрасываем только в случае получения последнего слова в пакете
                    // но учитываем, что после последнего слова может сразу идти другой пакет
                    pkt_process[i] <= st_pipe[i].valid & s_ready_o[i] & st_pipe[i].last ? st_chk_vld[i].valid : 1'b1;
                end
                else begin
                    pkt_process[i] <= st_chk_vld[i].valid & s_ready_o[i];
                end
            end

            assign req_next[i] =    st_chk_vld[i].valid & s_ready_o[i] & ~pkt_process[i] | //если пришел старт пакета - выставляем запрос на обслуживание
                                    st_chk_vld[i].valid & s_ready_o[i] & pkt_process[i] & st_pipe[i].valid & st_pipe[i].last;//если следующий пакет приходит сразу после предыдущего

            always_ff @ (posedge clk or negedge reset_n) begin
                if(!reset_n) req[i] <= 1'b0;
                else if(req[i]) begin
                    req[i] <= req_ack[i] ? req_next[i] : 1'b1;//если получено подтверждение от арбитра, то обновляем request
                end
                else begin
                    req[i] <= req_next[i];
                end
            end
        end
    endgenerate


    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) state <= IDLE;
        else state <= state_next;
    end

    always_comb begin
        state_next = state;
        gnt_rdy = 1'b0;
        active_channel_next = active_channel;

        for(int j = 0; j < S_DATA_COUNT; j++) begin
            s_ready_o[j] = ~st_pipe[j].valid;
        end

        case(state)
            IDLE: begin
                gnt_rdy = 1'b1;
                if(gnt_vld) begin
                    active_channel_next = gnt_id;
                    state_next = TRANSIT;
                end
            end

            TRANSIT: begin
                gnt_rdy = 1'b0;
                s_ready_o[active_channel] = ready_master;

                if(ready_master && st_pipe[active_channel].valid && st_pipe[active_channel].last) begin
                    if(gnt_vld) begin//если вдруг в арбитре висит запрос
                        gnt_rdy = 1'b1;
                        active_channel_next = gnt_id;
                        state_next = TRANSIT;//в таком случае мы остаемся в этом же состоянии, но обновляем номер активного канала
                    end
                    else begin
                        state_next = IDLE;
                    end
                end
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            active_channel <= {SIZE_POINTER{1'b0}};
        end
        else begin
            active_channel <= active_channel_next;
        end
    end


    //выходной интерфейс
    assign ready_master = ~(m_valid_o & ~m_ready_i);
    
    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) m_valid_o <= 1'b0;
        else if(ready_master) begin
            m_valid_o <= (state == TRANSIT) & st_pipe[active_channel].valid;
        end
    end

    always_ff @ (posedge clk) begin
        if(ready_master) begin
            m_data_o    <= st_pipe[active_channel].data;
            m_id_o      <= active_channel;//отправляем номер текущего обработанного канала
            m_last_o    <= st_pipe[active_channel].last;
        end
    end

endmodule