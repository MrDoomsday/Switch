module stream_xbar #(
    parameter   DATA_WIDTH = 8,
                S_DATA_COUNT = 10,
                M_DATA_COUNT = 10,
    localparam  ID_WIDTH = $clog2(S_DATA_COUNT),
                DEST_WIDTH = $clog2(M_DATA_COUNT)
)(
    input   logic                       clk,
    input   logic                       reset_n,

    // multiple input streams
    input   logic   [DATA_WIDTH-1:0]        s_axis_data_i   [S_DATA_COUNT-1:0],
    input   logic   [DEST_WIDTH-1:0]        s_axis_dest_i   [S_DATA_COUNT-1:0],
    input   logic   [DATA_WIDTH/8-1:0]      s_axis_keep_i   [S_DATA_COUNT-1:0],
    input   logic   [S_DATA_COUNT-1:0]      s_axis_last_i,
    input   logic   [S_DATA_COUNT-1:0]      s_axis_valid_i,
    output  logic   [S_DATA_COUNT-1:0]      s_axis_ready_o,

    // multiple output streams
    output  logic   [DATA_WIDTH-1:0]        m_axis_data_o   [M_DATA_COUNT-1:0],
    output  logic   [ID_WIDTH-1:0]          m_axis_id_o     [M_DATA_COUNT-1:0],
    output  logic   [DATA_WIDTH/8-1:0]      m_axis_keep_o   [M_DATA_COUNT-1:0],
    output  logic   [M_DATA_COUNT-1:0]      m_axis_last_o,
    output  logic   [M_DATA_COUNT-1:0]      m_axis_valid_o,
    input   logic   [M_DATA_COUNT-1:0]      m_axis_ready_i
);




/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/


    //входные сигналы коммутатора, прошедшие через модуль с регистрами axis_register
    logic   [S_DATA_COUNT-1:0][DATA_WIDTH-1:0]      s_data_reg;
    logic   [S_DATA_COUNT-1:0][DATA_WIDTH/8-1:0]    s_keep_reg;
    logic   [S_DATA_COUNT-1:0][DEST_WIDTH-1:0]      s_dest_reg;
    logic   [S_DATA_COUNT-1:0]                      s_last_reg;
    logic   [S_DATA_COUNT-1:0]                      s_valid_reg;
    logic   [S_DATA_COUNT-1:0]                      s_ready_reg;


    logic   [S_DATA_COUNT-1:0][M_DATA_COUNT-1:0]  s_mux_ready_crossbar;

    logic   [M_DATA_COUNT-1:0][S_DATA_COUNT-1:0][DATA_WIDTH-1:0]    s_mux_axis_data;
    logic   [M_DATA_COUNT-1:0][S_DATA_COUNT-1:0]                    s_mux_axis_last;
    logic   [M_DATA_COUNT-1:0][S_DATA_COUNT-1:0]                    s_mux_axis_valid;
    logic   [M_DATA_COUNT-1:0][S_DATA_COUNT-1:0][DATA_WIDTH/8-1:0]  s_mux_axis_keep;
    logic   [M_DATA_COUNT-1:0][S_DATA_COUNT-1:0]                    s_mux_axis_ready;
    

    // multiple output streams
    logic   [M_DATA_COUNT-1:0][DATA_WIDTH-1:0]      m_mux_axis_data;
    logic   [M_DATA_COUNT-1:0][ID_WIDTH-1:0]        m_mux_axis_id; // ID интерфейса, с которого пришел пакет
    logic   [M_DATA_COUNT-1:0]                      m_mux_axis_last;
    logic   [M_DATA_COUNT-1:0]                      m_mux_axis_valid;
    logic   [M_DATA_COUNT-1:0][DATA_WIDTH/8-1:0]    m_mux_axis_keep;
    logic   [M_DATA_COUNT-1:0]                      m_mux_axis_ready;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            INSTANCE         ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    // input buffer
    generate
        for(genvar i = 0; i < S_DATA_COUNT; i++) begin:gen_axis_skid
            sx_axis_skid #(
                .DATA_WIDTH ( DATA_WIDTH ),
                .ID_WIDTH   ( 1 ),
                .DEST_WIDTH ( DEST_WIDTH )
            ) s_axis_skid (
                .clk                ( clk               ),
                .reset_n            ( reset_n           ),

                //input stream
                .s_axis_tdata_i     ( s_axis_data_i[i]  ),
                .s_axis_tvalid_i    ( s_axis_valid_i[i] ),
                .s_axis_tlast_i     ( s_axis_last_i[i]  ),
                .s_axis_tkeep_i     ( s_axis_keep_i[i]  ),
                .s_axis_tid_i       ('0), 
                .s_axis_tdest_i     ( s_axis_dest_i[i]  ),
                .s_axis_tready_o    ( s_axis_ready_o[i] ),

                //output stream
                .m_axis_tdata_o     ( s_data_reg[i]     ),
                .m_axis_tvalid_o    ( s_valid_reg[i]    ),
                .m_axis_tlast_o     ( s_last_reg[i]     ),
                .m_axis_tkeep_o     ( s_keep_reg[i]     ), 
                .m_axis_tid_o       (), 
                .m_axis_tdest_o     ( s_dest_reg[i]     ),
                .m_axis_tready_i    ( s_ready_reg[i]    )
            );
        
            assign s_ready_reg[i] = (s_dest_reg[i] < M_DATA_COUNT) ? s_mux_ready_crossbar[i][s_dest_reg[i]] : 1'b1;
        end

    // crossbar
        for(genvar i = 0; i < M_DATA_COUNT; i++) begin: crossbar
            assign s_mux_axis_data[i] = s_data_reg;
            assign s_mux_axis_last[i] = s_last_reg;
            assign s_mux_axis_keep[i] = s_keep_reg;
            for(genvar j = 0; j < S_DATA_COUNT; j++) begin
                assign s_mux_axis_valid[i][j] = s_valid_reg[j] & (s_dest_reg[j] == j);
                assign s_mux_ready_crossbar[j][i] = s_mux_axis_ready[i][j];
            end
        end

    // output
        for(genvar i = 0; i < M_DATA_COUNT; i++) begin:gen_mux_unit
            sx_mux # (
                .DATA_WIDTH     ( DATA_WIDTH   ),
                .S_DATA_COUNT   ( S_DATA_COUNT )
            ) mux (
                .clk            ( clk                   ),
                .reset_n        ( reset_n               ),
                
                .s_axis_data_i  ( s_mux_axis_data[i]    ),
                .s_axis_last_i  ( s_mux_axis_last[i]    ),
                .s_axis_valid_i ( s_mux_axis_valid[i]   ),
                .s_axis_keep_i  ( s_mux_axis_keep[i]    ),
                .s_axis_ready_o ( s_mux_axis_ready[i]   ),

                .m_axis_data_o  ( m_mux_axis_data[i]    ),
                .m_axis_id_o    ( m_mux_axis_id[i]      ),
                .m_axis_last_o  ( m_mux_axis_last[i]    ),
                .m_axis_valid_o ( m_mux_axis_valid[i]   ),
                .m_axis_keep_o  ( m_mux_axis_keep[i]    ),
                .m_axis_ready_i ( m_mux_axis_ready[i]   )
            );

            sx_axis_skid #(
                .DATA_WIDTH ( DATA_WIDTH ),
                .ID_WIDTH   ( ID_WIDTH ),
                .DEST_WIDTH ( 1 )
            ) s_axis_skid (
                .clk                ( clk                   ),
                .reset_n            ( reset_n               ),

                //input stream
                .s_axis_tdata_i     ( m_mux_axis_data[i]    ),
                .s_axis_tvalid_i    ( m_mux_axis_valid[i]   ),
                .s_axis_tlast_i     ( m_mux_axis_last[i]    ),
                .s_axis_tkeep_i     ( m_mux_axis_keep[i]    ),
                .s_axis_tid_i       ( m_mux_axis_id[i]      ), 
                .s_axis_tdest_i     ( 1'b0                  ),
                .s_axis_tready_o    ( m_mux_axis_ready[i]   ),

                //output stream
                .m_axis_tdata_o     ( m_axis_data_o[i]      ),
                .m_axis_tvalid_o    ( m_axis_valid_o[i]     ),
                .m_axis_tlast_o     ( m_axis_last_o[i]      ),
                .m_axis_tkeep_o     ( m_axis_keep_o[i]      ), 
                .m_axis_tid_o       ( m_axis_id_o[i]), 
                .m_axis_tdest_o     (),
                .m_axis_tready_i    ( m_axis_ready_i[i]     )
            );
        end
    endgenerate

endmodule