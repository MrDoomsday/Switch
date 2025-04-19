`include "tb_interface.sv"
`include "packet.sv"
`include "configuration.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "agent.sv"
`include "scoreboard.sv"
`include "environment.sv"
`include "test.sv"

module switch_tb();

    localparam S_DATA_COUNT = 10;
    localparam M_DATA_COUNT = 10;
    localparam DATA_WIDTH = 64;
    localparam ID_WIDTH = $clog2(S_DATA_COUNT);
    localparam DEST_WIDTH = $clog2(M_DATA_COUNT);
    localparam USER_WIDTH = 1;


    logic   clk;
    logic   reset_n;


    logic   [DATA_WIDTH-1:0]        s_axis_data_i   [S_DATA_COUNT-1:0];
    logic   [DEST_WIDTH-1:0]        s_axis_dest_i   [S_DATA_COUNT-1:0];
    logic   [DATA_WIDTH/8-1:0]      s_axis_keep_i   [S_DATA_COUNT-1:0];
    logic   [S_DATA_COUNT-1:0]      s_axis_last_i;
    logic   [S_DATA_COUNT-1:0]      s_axis_valid_i;
    logic   [S_DATA_COUNT-1:0]      s_axis_ready_o;

    logic   [DATA_WIDTH-1:0]        m_axis_data_o   [M_DATA_COUNT-1:0];
    logic   [ID_WIDTH-1:0]          m_axis_id_o     [M_DATA_COUNT-1:0];
    logic   [DATA_WIDTH/8-1:0]      m_axis_keep_o   [M_DATA_COUNT-1:0];
    logic   [M_DATA_COUNT-1:0]      m_axis_last_o;
    logic   [M_DATA_COUNT-1:0]      m_axis_valid_o;
    logic   [M_DATA_COUNT-1:0]      m_axis_ready_i;

    if_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) s_intf [S_DATA_COUNT-1:0] (clk, reset_n);

    if_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) m_intf [M_DATA_COUNT-1:0] (clk, reset_n);

    test #(
        .S_DATA_COUNT   (S_DATA_COUNT),
        .M_DATA_COUNT   (M_DATA_COUNT),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .DEST_WIDTH     (DEST_WIDTH),
        .USER_WIDTH     (USER_WIDTH)
    ) test_n;


    generate 
        for(genvar i = 0; i < S_DATA_COUNT; i++) begin
            assign s_axis_data_i[i]     = s_intf[i].data;
            assign s_axis_dest_i[i]     = s_intf[i].dest;
            assign s_axis_keep_i[i]     = s_intf[i].keep;
            assign s_axis_last_i[i]     = s_intf[i].last;
            assign s_axis_valid_i[i]    = s_intf[i].valid;
            assign s_intf[i].ready      = s_axis_ready_o[i];
        end
        for (genvar i = 0; i < M_DATA_COUNT; i++) begin
            assign m_intf[i].data = m_axis_data_o[i];
            assign m_intf[i].id = m_axis_id_o[i];
            assign m_intf[i].keep = m_axis_keep_o[i];
            assign m_intf[i].last = m_axis_last_o[i];
            assign m_intf[i].valid = m_axis_valid_o[i];
            assign m_axis_ready_i[i] = m_intf[i].ready;
            //unused ports
            assign m_intf[i].dest = '0;
            assign m_intf[i].user = '0;
        end
    endgenerate

    stream_xbar # (
        .DATA_WIDTH     (DATA_WIDTH),
        .S_DATA_COUNT   (S_DATA_COUNT),
        .M_DATA_COUNT   (M_DATA_COUNT)
    ) DUT (
        .clk            (clk),
        .reset_n        (reset_n),
        
        .s_axis_data_i  (s_axis_data_i),
        .s_axis_dest_i  (s_axis_dest_i),
        .s_axis_last_i  (s_axis_last_i),
        .s_axis_valid_i (s_axis_valid_i),
        .s_axis_keep_i  (s_axis_keep_i),
        .s_axis_ready_o (s_axis_ready_o),

        .m_axis_data_o  (m_axis_data_o),
        .m_axis_id_o    (m_axis_id_o),
        .m_axis_last_o  (m_axis_last_o),
        .m_axis_valid_o (m_axis_valid_o),
        .m_axis_keep_o  (m_axis_keep_o),
        .m_axis_ready_i (m_axis_ready_i)
    );


    always begin
        clk <= 1'b0;
        #10;
        clk <= 1'b1;
        #10;
    end


    task gen_reset();
        reset_n <= 1'b0;
        repeat(10) @(posedge clk);
        reset_n <= 1'b1;
    endtask

    initial begin
        test_n = new(
            s_intf,
            m_intf
        );

        fork
            test_n.run();
            gen_reset();
        join
    end


endmodule