class test #(
    parameter S_DATA_COUNT = 8,
    parameter M_DATA_COUNT = 8,
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
);

    virtual if_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) vif_s_axis [S_DATA_COUNT-1:0];

    virtual if_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) vif_m_axis [M_DATA_COUNT-1:0];

    environment #(
        .S_DATA_COUNT   (S_DATA_COUNT),
        .M_DATA_COUNT   (M_DATA_COUNT),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .DEST_WIDTH     (DEST_WIDTH),
        .USER_WIDTH     (USER_WIDTH)
    ) env;

    configuration cfg;

    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_gen2drv [S_DATA_COUNT-1:0];

    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_s_mon2scb [S_DATA_COUNT-1:0];
    
    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_m_mon2scb [M_DATA_COUNT-1:0];

    function new(
        virtual if_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        ) vif_s_axis [S_DATA_COUNT-1:0],
        
        virtual if_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        ) vif_m_axis [M_DATA_COUNT-1:0]
    );

        for(int i = 0; i < S_DATA_COUNT; i++) begin
            this.vif_s_axis[i] = vif_s_axis[i];
        end
        for(int i = 0; i < M_DATA_COUNT; i++) begin
            this.vif_m_axis[i] = vif_m_axis[i];            
        end

        // create object
        env = new();
        cfg = new(S_DATA_COUNT);

        if(!cfg.randomize()) begin
            $display("Error configuration randomize...");
            $fatal();
        end


        for(int i = 0; i < S_DATA_COUNT; i++) begin
            mbx_gen2drv[i] = new();
            mbx_s_mon2scb[i] = new();
        end
        for(int i = 0; i < M_DATA_COUNT; i++) begin
            mbx_m_mon2scb[i] = new();            
        end


        // проброс конфигурации
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            env.agnt_s_axis[i].gen.cfg = cfg;
            env.agnt_s_axis[i].drv.cfg = cfg;
        end

        for(int i = 0; i < M_DATA_COUNT; i++) begin
            env.agnt_m_axis[i].drv.cfg = cfg;            
        end

        env.scb.cfg = cfg;

        // подключение mailbox'ов 
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            env.agnt_s_axis[i].gen.mbx_gen2drv = mbx_gen2drv[i];
            env.agnt_s_axis[i].drv.mbx_gen2drv = mbx_gen2drv[i];

            env.agnt_s_axis[i].mon.mbx_mon2scb = mbx_s_mon2scb[i];
            env.scb.mbx_in[i] = mbx_s_mon2scb[i];
        end

        for(int i = 0; i < M_DATA_COUNT; i++) begin
            env.agnt_m_axis[i].mon.mbx_mon2scb = mbx_m_mon2scb[i]; 
            env.scb.mbx_out[i] = mbx_m_mon2scb[i];
        end


        // подключение интерфейсов 
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            env.agnt_s_axis[i].drv.vif_axis = this.vif_s_axis[i];
            env.agnt_s_axis[i].mon.vif_axis = this.vif_s_axis[i];
        end

        for(int i = 0; i < M_DATA_COUNT; i++) begin
            env.agnt_m_axis[i].drv.vif_axis = this.vif_m_axis[i];
            env.agnt_m_axis[i].mon.vif_axis = this.vif_m_axis[i];
        end
        
    endfunction

    virtual task run();
        fork
            env.run();
            wait_done();
            timeout();
        join
    endtask

    virtual task timeout();
        repeat(cfg.timeout_value) @(posedge vif_m_axis[0].clk);
        $display("********TEST FAILED********");
        $display("Timeout...");
        $stop();
    endtask

    virtual task wait_done();
        wait(&env.scb.done);
        if(|env.scb.fail) begin
            $display("********TEST FAILED********");
        end else begin
            $display("********TEST PASSED********");
        end
        $stop();
    endtask

endclass