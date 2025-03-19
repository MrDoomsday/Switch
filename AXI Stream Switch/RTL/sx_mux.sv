module sx_mux #(
    parameter   DATA_WIDTH = 8,
                S_DATA_COUNT = 1,
    localparam  ID_WIDTH = $clog2(S_DATA_COUNT)
)(
    input   logic                       clk,
    input   logic                       reset_n,

    // multiple input streams
    input   logic   [S_DATA_COUNT-1:0][DATA_WIDTH-1:0]      s_axis_data_i,
    input   logic   [S_DATA_COUNT-1:0]                      s_axis_last_i,
    input   logic   [S_DATA_COUNT-1:0]                      s_axis_valid_i,
    input   logic   [S_DATA_COUNT-1:0][DATA_WIDTH/8-1:0]    s_axis_keep_i,
    output  logic   [S_DATA_COUNT-1:0]                      s_axis_ready_o,

    // multiple output streams
    output  logic   [DATA_WIDTH-1:0]                        m_axis_data_o,
    output  logic   [ID_WIDTH-1:0]                          m_axis_id_o, // ID интерфейса, с которого пришел пакет
    output  logic                                           m_axis_last_o,
    output  logic                                           m_axis_valid_o,
    output  logic   [DATA_WIDTH/8-1:0]                      m_axis_keep_o,
    input   logic                                           m_axis_ready_i

);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    typedef enum logic {
        SM_GET_GNT, 
        SM_TRANSIT
    } mux_state_t;
    mux_state_t mux_state, mux_state_next;

    logic [S_DATA_COUNT-1:0] arb_req, arb_gnt;
    logic [ID_WIDTH-1:0] arb_gnt_id;
    logic arb_en;

    logic [S_DATA_COUNT-1:0] arb_gnt_reg;
    logic [ID_WIDTH-1:0] arb_gnt_id_reg;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/ 
    pp_arbiter #(
        .WIDTH_REQ(S_DATA_COUNT)
    ) arbiter (
        .clk        ( clk       ),
        .reset_n    ( reset_n   ),
    
        .req_i      ( arb_req   ),
        .en_i       ( arb_en    ),
    
        .gnt_o      ( arb_gnt   ),  // onehot
        .gnt_id_o   ( arb_gnt_id)   // номер gnt'а
    );
/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            mux_state <= SM_GET_GNT;
        end else begin
            mux_state <= mux_state_next;
        end
    end

    always_comb begin
        mux_state_next = mux_state;
        arb_en = 1'b0;

        case(mux_state)
            SM_GET_GNT: begin
                arb_en = 1'b1;
                if(|arb_req) begin
                    mux_state_next = SM_TRANSIT;
                end
            end
            
            SM_TRANSIT: begin
                if(m_axis_ready_i && m_axis_valid_o && m_axis_last_o) begin
                    mux_state_next = SM_GET_GNT;
                end
            end

            default: mux_state_next = SM_GET_GNT;
        endcase
    end


    assign arb_req = s_axis_valid_i;

    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            arb_gnt_reg     <= '0;
            arb_gnt_id_reg  <= '0;
        end else if(arb_en) begin
            arb_gnt_reg     <= arb_gnt;
            arb_gnt_id_reg  <= arb_gnt_id;
        end
    end

    // output axis-interface
    assign m_axis_valid_o = (|(s_axis_valid_i & arb_gnt_reg)) & (mux_state == SM_TRANSIT);
    assign m_axis_last_o = |(s_axis_last_i & arb_gnt_reg);
    assign m_axis_id_o = arb_gnt_id_reg;
    generate
        logic [S_DATA_COUNT-2:0][DATA_WIDTH-1:0] mux_data;
        logic [S_DATA_COUNT-2:0][DATA_WIDTH/8-1:0] mux_keep;
        
        for(genvar i = 0; i < S_DATA_COUNT - 2; i++) begin
            assign mux_data[i] = arb_gnt_reg[i] ? s_axis_data_i[i] : mux_data[i+1];
            assign mux_keep[i] = arb_gnt_reg[i] ? s_axis_keep_i[i] : mux_keep[i+1];
        end
        assign mux_data[S_DATA_COUNT-2] = arb_gnt_reg[S_DATA_COUNT-2] ? s_axis_data_i[S_DATA_COUNT-2] : s_axis_data_i[S_DATA_COUNT-1];
        assign mux_keep[S_DATA_COUNT-2] = arb_gnt_reg[S_DATA_COUNT-2] ? s_axis_keep_i[S_DATA_COUNT-2] : s_axis_keep_i[S_DATA_COUNT-1];
        
        assign m_axis_data_o = mux_data[0];
        assign m_axis_keep_o = mux_keep[0];
    endgenerate
    
    assign s_axis_ready_o = {S_DATA_COUNT{m_axis_ready_i & (mux_state == SM_TRANSIT)}} & arb_gnt_reg;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            ASSERT           ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/



endmodule