class driver_axis
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8   
);

    configuration cfg;
    mailbox #(
        axis_packet #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH),
            .T_USER_WIDTH   (T_USER_WIDTH)
        )
    ) mbx_gen2drv;
    virtual stream_intf 
    #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) vif_stream;

    axis_packet #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) p;

    function new();
    endfunction

    virtual task run();
        reset_port();
        wait(vif_stream.reset_n);
        forever begin
            drive();
        end
    endtask

    virtual task reset_port();
        vif_stream.id       <= {T_ID_WIDTH{1'b0}};
        vif_stream.data     <= {T_DATA_WIDTH{1'b0}};
        vif_stream.user     <= {T_USER_WIDTH{1'b0}};
        vif_stream.last     <= 1'b0;
        vif_stream.valid    <= 1'b0;
    endtask

    virtual task drive();
        int delay;
        int pause_word;
        mbx_gen2drv.get(p);

        if(!std::randomize(delay) with {
            delay inside {[cfg.min_pause_pkt:cfg.max_pause_pkt]};
        }) begin
            $display("Error randomization pause for pkt");
            $fatal();
        end

        for(int i = 0; i < p.data.size(); i++) begin
            if(!std::randomize(pause_word) with {
                pause_word inside {[cfg.min_pause_word:cfg.max_pause_word]};
            }) begin
                $display("Error randomization pause for word");
                $fatal();
            end


            vif_stream.id       <= p.id;
            vif_stream.data     <= p.data[i];
            vif_stream.user     <= p.user;
            vif_stream.last     <= i == (p.data.size()-1);
            vif_stream.valid    <= 1'b1;

            do begin
                @(posedge vif_stream.clk);
            end
            while(!vif_stream.ready);
            //выдерживаем паузу между отдельными словами в пакете
            vif_stream.valid    <= 1'b0;
            repeat(pause_word) @ (posedge vif_stream.clk);
        end
        vif_stream.id       <= {T_ID_WIDTH{1'b0}};
        vif_stream.data     <= {T_DATA_WIDTH{1'b0}};
        vif_stream.user     <= {T_USER_WIDTH{1'b0}};
        vif_stream.last     <= 1'b0;
        vif_stream.valid    <= 1'b0;

        repeat(delay) @(posedge vif_stream.clk);
    endtask

endclass


class driver_axim
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8    
);

    configuration cfg;

    virtual stream_intf 
    #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) vif_stream;


    function new();
    endfunction


    virtual task run();
        reset_port();
        wait(vif_stream.reset_n);
        forever begin
            drive();
        end
    endtask


    virtual task reset_port();
        vif_stream.ready <= 1'b0;
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

        vif_stream.ready <= 1'b1;
        repeat(delay_high) @ (posedge vif_stream.clk);
        vif_stream.ready <= 1'b0;
        repeat(delay_low) @ (posedge vif_stream.clk);
    endtask


endclass