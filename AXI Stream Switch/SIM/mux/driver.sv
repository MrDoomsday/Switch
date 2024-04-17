class driver_axis #(
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

    virtual interface_axis #(
        .T_DATA_WIDTH(T_DATA_WIDTH),
        .T_DEST_WIDTH(T_DEST_WIDTH)
    ) vif_axis;

    packet_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
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
        vif_axis.dest     <= {T_DEST_WIDTH{1'b0}};
        vif_axis.data     <= {T_DATA_WIDTH{1'b0}};
        vif_axis.last     <= 1'b0;
        vif_axis.valid    <= 1'b0;
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

        for(int i = 0; i < p.data.size(); i++) begin
            vif_axis.dest     <= p.dest;
            vif_axis.data     <= p.data[i];
            vif_axis.last     <= i == (p.data.size()-1);
            vif_axis.valid    <= 1'b1;

            do begin
                @(posedge vif_axis.clk);
            end
            while(!vif_axis.ready);
        end
        vif_axis.dest     <= {T_DEST_WIDTH{1'b0}};
        vif_axis.data     <= {T_DATA_WIDTH{1'b0}};
        vif_axis.last     <= 1'b0;
        vif_axis.valid    <= 1'b0;

        repeat(delay) @(posedge vif_axis.clk);
    endtask

endclass


class driver_axim #(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8
);

    configuration cfg;

    virtual interface_axim #(
        .T_DATA_WIDTH(T_DATA_WIDTH),
        .T_ID_WIDTH(T_ID_WIDTH)
    ) vif_axim;


    function new();
    endfunction


    virtual task run();
        reset_port();
        wait(vif_axim.reset_n);
        forever begin
            drive();
        end
    endtask


    virtual task reset_port();
        vif_axim.ready <= 1'b0;
    endtask


    virtual task drive();
        int delay_low, delay_high;

        if(!std::randomize(delay_low) with {
            delay_low inside {[cfg.min_low_ready:cfg.max_low_ready]};
        }) begin
            $display("Erorr randomization master_ready low level signal...");
            $fatal();
        end

        if(!std::randomize(delay_high) with {
            delay_high inside {[cfg.min_high_ready:cfg.max_high_ready]};
        }) begin
            $display("Erorr randomization master_ready high level signal...");
            $fatal();
        end

        vif_axim.ready <= 1'b1;
        repeat(delay_high) @ (posedge vif_axim.clk);
        vif_axim.ready <= 1'b0;
        repeat(delay_low) @ (posedge vif_axim.clk);
    endtask


endclass