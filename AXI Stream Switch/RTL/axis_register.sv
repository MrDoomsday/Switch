module axis_register #(
    parameter   PIPE_CNT = 2,
    parameter   T_DATA_WIDTH = 8,
                T_USER_WIDTH = 10,
                T_ID_WIDTH = 8
)(
    input bit clk,
    input bit reset_n,

    //input stream
    input   bit   [T_ID_WIDTH-1:0]          s_id_i,
    input   bit   [T_DATA_WIDTH-1:0]        s_data_i,
    input   bit   [T_USER_WIDTH-1:0]        s_user_i,//user signal
    input   bit                             s_last_i ,
    input   bit                             s_valid_i,
    output  bit                             s_ready_o,

    //output stream
    output  bit   [T_ID_WIDTH-1:0]          m_id_o,
    output  bit   [T_DATA_WIDTH-1:0]        m_data_o,
    output  bit   [T_USER_WIDTH-1:0]        m_user_o,//user signal
    output  bit                             m_last_o,
    output  bit                             m_valid_o,
    input   bit                             m_ready_i
);



/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
generate
    genvar i;

    if(PIPE_CNT == 0) begin
        assign m_id_o   = s_id_i;
        assign m_data_o = s_data_i;
        assign m_user_o = s_user_i;
        assign m_last_o = s_last_i;
        assign m_valid_o = s_valid_i;
        assign s_ready_o = m_ready_i;
    end
    else if(PIPE_CNT == 1) begin

        bit                             s_ready_reg;
        bit     [T_ID_WIDTH-1:0]        s_id_reg;
        bit     [T_DATA_WIDTH-1:0]      s_data_reg;
        bit     [T_USER_WIDTH-1:0]      s_user_reg;
        bit                             s_last_reg;
        bit                             s_valid_reg;


        assign s_ready_o = s_ready_reg;

        always_ff @ (posedge clk or negedge reset_n) begin
            if(!reset_n) begin
                s_ready_reg <= 1'b1;
                s_valid_reg <= 1'b0;
            end
            else begin
                if(s_ready_reg && s_valid_i) begin//помещаем данные в буферный регистр  
                    s_ready_reg <= 1'b0;
                    s_valid_reg <= 1'b1;
                end
                else if(m_ready_i && m_valid_o) begin
                    s_ready_reg <= 1'b1;
                    s_valid_reg <= 1'b0;
                end
            end
        end

        always_ff @ (posedge clk) begin
            if(s_ready_reg && s_valid_i) begin
                s_id_reg    <= s_id_i;
                s_data_reg  <= s_data_i;
                s_user_reg  <= s_user_i;
                s_last_reg  <= s_last_i;
            end
        end

        //assigned output signal
        assign m_id_o   = s_id_reg;
        assign m_data_o = s_data_reg;
        assign m_user_o = s_user_reg;
        assign m_last_o = s_last_reg;
        assign m_valid_o = s_valid_reg;
    end
    else if(PIPE_CNT > 1) begin
        bit     [$clog2(PIPE_CNT):0]    credit_words;//количество кредитов (слов, которые накопитель может принять)
        bit                             pipe_ready      [PIPE_CNT-1:0];
        bit     [T_ID_WIDTH-1:0]        pipe_id         [PIPE_CNT-1:0];
        bit     [T_DATA_WIDTH-1:0]      pipe_data       [PIPE_CNT-1:0];
        bit     [T_USER_WIDTH-1:0]      pipe_user       [PIPE_CNT-1:0];
        bit                             pipe_last       [PIPE_CNT-1:0];
        bit                             pipe_valid      [PIPE_CNT-1:0];

        bit                             put_pipe, get_pipe;

        //credit counter
        assign put_pipe = s_valid_i & s_ready_o;
        assign get_pipe = m_valid_o & m_ready_i;

        always_ff @ (posedge clk or negedge reset_n) begin
            if(!reset_n) begin
                credit_words <= PIPE_CNT;
                s_ready_o <= 1'b1;
            end
            else begin
                if(put_pipe && !get_pipe) begin
                    credit_words <= credit_words - 1;
                end
                else if(!put_pipe && get_pipe) begin
                    credit_words <= credit_words + 1;
                end

                if(credit_words == 1 && put_pipe && !get_pipe) begin
                    s_ready_o <= 1'b0;
                end
                else if(credit_words == 0 && get_pipe) begin
                    s_ready_o <= 1'b1;
                end
            end
        end

    //first pipeline
        assign pipe_ready[0] = pipe_valid[0] ? pipe_ready[1] : s_valid_i & s_ready_o;

        always_ff @ (posedge clk) begin
            if(pipe_ready[0]) begin
                pipe_valid[0]   <= s_valid_i & s_ready_o;
                pipe_id[0]      <= s_id_i;
                pipe_data[0]    <= s_data_i;
                pipe_user[0]    <= s_user_i;
                pipe_last[0]    <= s_last_i;
            end
        end

    //sequence pipelines
        for(i = PIPE_CNT-2; i > 0; i--) begin:pipe_reg
            assign pipe_ready[i] = pipe_valid[i] ? pipe_ready[i+1] : pipe_valid[i-1];

            always_ff @ (posedge clk) begin
                if(pipe_ready[i]) begin
                    pipe_valid[i]   <= pipe_valid[i-1];
                    pipe_id[i]      <= pipe_id[i-1];
                    pipe_data[i]    <= pipe_data[i-1];
                    pipe_user[i]    <= pipe_user[i-1];
                    pipe_last[i]    <= pipe_last[i-1];
                end
            end
        end

    //last pipeline
        // assign pipe_ready[PIPE_CNT-1] = pipe_valid[PIPE_CNT-1] & m_ready_i | ~pipe_valid[PIPE_CNT-1] & pipe_valid[PIPE_CNT-2];
        assign pipe_ready[PIPE_CNT-1] = pipe_valid[PIPE_CNT-1] ? m_ready_i : pipe_valid[PIPE_CNT-2];//более компактная запись мультиплексора, получившегося строчкой выше
            
        always_ff @ (posedge clk or negedge reset_n) begin
            if(!reset_n) pipe_valid[PIPE_CNT-1] <= 1'b0;
            else if(pipe_ready[PIPE_CNT-1]) pipe_valid[PIPE_CNT-1] <= pipe_valid[PIPE_CNT-2];
        end

        always_ff @ (posedge clk) begin
            if(pipe_ready[PIPE_CNT-1]) begin
                pipe_id[PIPE_CNT-1]     <= pipe_id[PIPE_CNT-2];
                pipe_data[PIPE_CNT-1]   <= pipe_data[PIPE_CNT-2];
                pipe_user[PIPE_CNT-1]   <= pipe_user[PIPE_CNT-2];
                pipe_last[PIPE_CNT-1]   <= pipe_last[PIPE_CNT-2];
            end
        end


    //assigned output
        assign m_id_o       =   pipe_id[PIPE_CNT-1];
        assign m_data_o     =   pipe_data[PIPE_CNT-1];
        assign m_user_o     =   pipe_user[PIPE_CNT-1];
        assign m_last_o     =   pipe_last[PIPE_CNT-1];
        assign m_valid_o    =   pipe_valid[PIPE_CNT-1];
    end

endgenerate



endmodule