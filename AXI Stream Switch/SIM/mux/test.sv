class test #(
    parameter S_DATA_COUNT = 8,//число входов мультиплексора
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_DEST_WIDTH = 8    
);

    virtual interface_axis #(
        .T_DATA_WIDTH(T_DATA_WIDTH),
        .T_DEST_WIDTH(T_DEST_WIDTH)
    ) vif_slave [S_DATA_COUNT-1:0];

    virtual interface_axim #(
        .T_DATA_WIDTH(T_DATA_WIDTH),
        .T_ID_WIDTH(T_ID_WIDTH)
    ) vif_master;

    environment #(
        .S_DATA_COUNT   (S_DATA_COUNT),
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) env;

    configuration cfg;

    mailbox #(
        packet_axis #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_DEST_WIDTH   (T_DEST_WIDTH)
        )
    ) mbx_gen2drv [S_DATA_COUNT-1:0];

    mailbox #(
        packet_axis #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_DEST_WIDTH   (T_DEST_WIDTH)
        )
    ) mbx_slave_mon2scb [S_DATA_COUNT-1:0];
    
    mailbox #(
        packet_axim #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH)
        )
    ) mbx_master_mon2scb;

    function new(
        virtual interface_axis #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_DEST_WIDTH   (T_DEST_WIDTH)
        ) vif_slave [S_DATA_COUNT-1:0],
        
        virtual interface_axim #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH)
        ) vif_master
    );

        for(int i = 0; i < S_DATA_COUNT; i++) begin
            this.vif_slave[i] = vif_slave[i];
        end
        this.vif_master = vif_master;

        //create object
        env = new();
        cfg = new();

        if(!cfg.randomize()) begin
            $display("Error configuration randomize...");
            $fatal();
        end


        for(int i = 0; i < S_DATA_COUNT; i++) begin
            mbx_gen2drv[i] = new();
            mbx_slave_mon2scb[i] = new();
        end

        mbx_master_mon2scb = new();


        //проброс конфигурации
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            env.agnt_axis[i].gen.cfg = cfg;
            env.agnt_axis[i].drv.cfg = cfg;
        end

        env.agnt_axim.drv.cfg = cfg;
        env.scb.cfg = cfg;

        //подключение mailbox'ов 
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            env.agnt_axis[i].gen.mbx_gen2drv = mbx_gen2drv[i];
            env.agnt_axis[i].drv.mbx_gen2drv = mbx_gen2drv[i];

            env.agnt_axis[i].mon.mbx_mon2scb = mbx_slave_mon2scb[i];
            env.scb.mbx_in[i] = mbx_slave_mon2scb[i];
        end

        env.agnt_axim.mon.mbx_mon2scb = mbx_master_mon2scb;
        env.scb.mbx_out = mbx_master_mon2scb;


        //подключение интерфейсов 
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            env.agnt_axis[i].drv.vif_axis = this.vif_slave[i];
            env.agnt_axis[i].mon.vif_axis = this.vif_slave[i];
        end

        env.agnt_axim.drv.vif_axim = this.vif_master;
        env.agnt_axim.mon.vif_axim = this.vif_master;

    endfunction

    virtual task run();
        fork
            env.run();
            wait_done();
            timeout();
        join
    endtask

    virtual task timeout();
        repeat(cfg.timeout_value) @(posedge vif_master.clk);
        $display("********TEST FAILED********");
        $display("Timeout...");
        $stop();
    endtask

    virtual task wait_done();
        wait(env.scb.done);
        $display("Count transaction = %0d", env.scb.cnt_transaction);
        $display("Count error transaction = %0d", env.scb.cnt_error_transaction);
        if(env.scb.cnt_error_transaction > 0) begin
            $display("********TEST FAILED********");
        end
        else begin
            $display("********TEST PASSED********");
        end
        $stop();
    endtask

endclass