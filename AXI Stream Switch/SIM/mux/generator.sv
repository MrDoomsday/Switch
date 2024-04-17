class generator_slave #(
    parameter T_DATA_WIDTH = 8,
    parameter T_DEST_WIDTH = 8    
);

    configuration cfg;

    mailbox #(
        packet_axis #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_DEST_WIDTH   (T_DEST_WIDTH)
        )
    ) mbx_gen2drv;
    
    
    packet_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) p;

    function new();
    endfunction

    virtual task run();
        repeat(cfg.count_transaction) begin
            gen_transaction();
        end
    endtask


    virtual task gen_transaction();
        p = new();

        if(!p.randomize with {
            len inside {[cfg.min_size_pkt:cfg.max_size_pkt]};
        }) begin
            $display("Error randomization packet for axi stream slave...");
            $fatal();
        end

        mbx_gen2drv.put(p);
    endtask

endclass