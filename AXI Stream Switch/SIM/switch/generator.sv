class axis_generator #(
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
);


    configuration cfg;

    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_gen2drv;
    
    packet_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
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
            dest inside {[cfg.min_dest:cfg.max_dest]};
        }) begin
            $display("Error randomization packet for axi stream slave...");
            $fatal();
        end

        mbx_gen2drv.put(p);
    endtask

endclass