module sx_axis_skid #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned ID_WIDTH = 32,
    parameter int unsigned DEST_WIDTH = 32,
    localparam KEEP_WIDTH = DATA_WIDTH/8
) (
    input       logic                       clk,
    input       logic                       reset_n,


    input       logic   [DATA_WIDTH-1:0]    s_axis_tdata_i,
    input       logic                       s_axis_tvalid_i,
    input       logic                       s_axis_tlast_i,
    input       logic   [KEEP_WIDTH-1:0]    s_axis_tkeep_i,
    input       logic   [ID_WIDTH-1:0]      s_axis_tid_i, 
    input       logic   [DEST_WIDTH-1:0]    s_axis_tdest_i,
    output      logic                       s_axis_tready_o,


    output      logic   [DATA_WIDTH-1:0]    m_axis_tdata_o,
    output      logic                       m_axis_tvalid_o,
    output      logic                       m_axis_tlast_o,
    output      logic   [KEEP_WIDTH-1:0]    m_axis_tkeep_o, 
    output      logic   [ID_WIDTH-1:0]      m_axis_tid_o, 
    output      logic   [DEST_WIDTH-1:0]    m_axis_tdest_o,
    input       logic                       m_axis_tready_i

);


/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    logic                       s_ready_reg;
    logic                       s_ready_early;

    //промежуточный накопитель
    logic   [DATA_WIDTH-1:0]    store_tdata;
    logic                       store_tvalid, store_tvalid_next;
    logic                       store_tlast;
    logic   [KEEP_WIDTH-1:0]    store_tkeep; 
    logic   [ID_WIDTH-1:0]      store_tid;
    logic   [DEST_WIDTH-1:0]    store_tdest;

    //выходной регистр
    logic   [DATA_WIDTH-1:0]    m_axis_tdata_reg;
    logic                       m_axis_tvalid_reg, m_axis_tvalid_reg_next;
    logic                       m_axis_tlast_reg;
    logic   [KEEP_WIDTH-1:0]    m_axis_tkeep_reg; 
    logic   [ID_WIDTH-1:0]      m_axis_tid_reg;
    logic   [DEST_WIDTH-1:0]    m_axis_tdest_reg;

    logic                       transfer_in2out, 
                                transfer_in2store, 
                                transfer_store2out;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    assign s_axis_tready_o = s_ready_reg;
    // m_axis_trdy_i - сдвигает конвейер независимо от его содержимого, в любом случае освобождается регистр store
    // !store_tvalid & (!s_axis_tvalid_i | !m_axis_tvalid_reg) - если накопитель пустой и: на входе отсутствуют валидные данные или регистр на выходе не содержит данных
    assign s_ready_early = m_axis_tready_i | !store_tvalid & (!s_axis_tvalid_i | !m_axis_tvalid_reg);

    always_comb begin
        store_tvalid_next = store_tvalid;
        m_axis_tvalid_reg_next = m_axis_tvalid_reg;

        transfer_in2out = 1'b0;
        transfer_in2store = 1'b0;
        transfer_store2out = 1'b0;

        //s_ready_early = s_ready_reg;

        //если вход готов принимать данные
        if(s_axis_tready_o) begin
            //если следующий модуль готов принимать данные или выходной регистр пустой 
            if(m_axis_tready_i || !m_axis_tvalid_reg) begin
                //s_ready_early = 1'b1;
                m_axis_tvalid_reg_next = s_axis_tvalid_i;
                transfer_in2out = 1'b1;
            end
            //если следующий модуль не готов принимать данные и выходной регистр не пустой - загружаем в накопитель
            else begin
                //s_ready_early = !s_axis_tvalid_i;
                store_tvalid_next = s_axis_tvalid_i;
                transfer_in2store = 1'b1;
            end
        end
        else if(m_axis_tready_i) begin
            //s_ready_early = 1'b1;
            store_tvalid_next = 1'b0;
            m_axis_tvalid_reg_next = store_tvalid;
            transfer_store2out = 1'b1;
        end
    end

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            s_ready_reg     <=  1'b1;
            store_tvalid    <=  1'b0;
            m_axis_tvalid_reg    <=  1'b0;
        end
        else begin
            s_ready_reg     <=  s_ready_early;
            store_tvalid    <=  store_tvalid_next;
            m_axis_tvalid_reg    <=  m_axis_tvalid_reg_next;
        end
    end



    always_ff @ (posedge clk) begin
        if(transfer_in2store) begin
            store_tdata     <=  s_axis_tdata_i;
            store_tlast     <=  s_axis_tlast_i;
            store_tkeep     <=  s_axis_tkeep_i;
            store_tid       <=  s_axis_tid_i;
            store_tdest     <=  s_axis_tdest_i;
        end

        if(transfer_in2out) begin
            m_axis_tdata_reg     <=  s_axis_tdata_i;
            m_axis_tlast_reg     <=  s_axis_tlast_i;
            m_axis_tkeep_reg     <=  s_axis_tkeep_i;
            m_axis_tid_reg       <=  s_axis_tid_i;
            m_axis_tdest_reg     <=  s_axis_tdest_i;
        end
        else if(transfer_store2out) begin
            m_axis_tdata_reg     <=  store_tdata;
            m_axis_tlast_reg     <=  store_tlast;
            m_axis_tkeep_reg     <=  store_tkeep;
            m_axis_tid_reg       <=  store_tid;
            m_axis_tdest_reg     <=  store_tdest;
        end
    end


    assign m_axis_tdata_o    = m_axis_tdata_reg;
    assign m_axis_tvalid_o   = m_axis_tvalid_reg;
    assign m_axis_tlast_o    = m_axis_tlast_reg;
    assign m_axis_tkeep_o    = m_axis_tkeep_reg;
    assign m_axis_tid_o      = m_axis_tid_reg;
    assign m_axis_tdest_o    = m_axis_tdest_reg;

endmodule