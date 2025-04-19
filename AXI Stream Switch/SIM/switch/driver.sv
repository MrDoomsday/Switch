class driver_s_axis #(
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

    virtual if_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) vif_axis;

    packet_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) p;

    function new();
    endfunction

    virtual task run();
        reset_port();
        wait(vif_axis.reset_n);
        forever begin
            drive();
        end
    endtask

    virtual task reset_port();
        vif_axis.data   <= '0;
        vif_axis.id     <= '0;
        vif_axis.dest   <= '0;
        vif_axis.user   <= '0;
        vif_axis.keep   <= '0;
        vif_axis.last   <= '0;
        vif_axis.valid  <= '0;
    endtask

    virtual task drive();
        int delay;
        mbx_gen2drv.get(p);

        if(!std::randomize(delay) with {
            delay inside {[cfg.min_pause_pkt:cfg.max_pause_pkt]};
        }) begin
            $display("Error randomization pause for pkt");
            $fatal();
        end

        vif_axis.id     <= p.id;
        vif_axis.dest   <= p.dest;
        vif_axis.user   <= p.user;

        for(int i = 0; i < p.data.size(); i++) begin
            vif_axis.data   <= p.data[i];
            vif_axis.keep   <= i == (p.data.size()-1) ? p.keep : '1;
            vif_axis.last   <= i == (p.data.size()-1);
            vif_axis.valid  <= 1'b1;

            do begin
                @(posedge vif_axis.clk);
            end
            while(!vif_axis.ready);
        end
        vif_axis.data   <= '0;
        vif_axis.id     <= '0;
        vif_axis.dest   <= '0;
        vif_axis.user   <= '0;
        vif_axis.keep   <= '0;
        vif_axis.last   <= '0;
        vif_axis.valid  <= '0;

        repeat(delay) @(posedge vif_axis.clk);
    endtask

endclass


class driver_m_axis #(
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
);

    configuration cfg;

    virtual if_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) vif_axis;


    function new();
    endfunction


    virtual task run();
        reset_port();
        wait(vif_axis.reset_n);
        forever begin
            drive();
        end
    endtask


    virtual task reset_port();
        vif_axis.ready <= 1'b0;
    endtask


    virtual task drive();
        int delay_low, delay_high;

        if(!std::randomize(delay_low) with {
            delay_low inside {[cfg.min_low_ready:cfg.max_low_ready]};
        }) begin
            $display("Error randomization master_ready low level signal...");
            $fatal();
        end

        if(!std::randomize(delay_high) with {
            delay_high inside {[cfg.min_high_ready:cfg.max_high_ready]};
        }) begin
            $display("Error randomization master_ready high level signal...");
            $fatal();
        end

        vif_axis.ready <= 1'b1;
        repeat(delay_high) @ (posedge vif_axis.clk);
        vif_axis.ready <= 1'b0;
        repeat(delay_low) @ (posedge vif_axis.clk);
    endtask


endclass