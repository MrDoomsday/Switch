class scoreboard
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8  
);

    mailbox #(
        axis_packet #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH),
            .T_USER_WIDTH   (T_USER_WIDTH)
        )
    ) mbx_in;

    mailbox #(
        axis_packet #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH),
            .T_USER_WIDTH   (T_USER_WIDTH)
        )
    ) mbx_out;
    
    axis_packet #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) p_in, p_out;


    configuration cfg;

    bit done = 0;
    int cnt_transaction;
    int cnt_error_transaction;



    function new();
    endfunction

    virtual task run();
        forever begin
            check_pkt(); 
        end
    endtask


    virtual task check_pkt();
        int size_data_in;
        int size_data_out;

        mbx_out.get(p_out);
        mbx_in.get(p_in);

        size_data_in = p_in.data.size();
        size_data_out = p_out.data.size();

        //check length
        if(size_data_in != size_data_out) begin
            $display("Error size data array, out = %0d, in = %0d", p_out.data.size(), p_in.data.size());
            $error();
            cnt_error_transaction++;
        end

        //check data in packet
        for(int i = 0; i < size_data_out; i++) begin
            if(p_in.data[i] != p_out.data[i]) begin
                $display("Error data array, out[%0d] = %0h, in[%0d] = %0h", i, p_out.data.size(), i, p_in.data.size());
                $error();
                cnt_error_transaction++;
            end
        end

        //check field packet
        //dest
        if(p_in.user != p_out.user) begin
            $display("Error user signal, out = %0h, in = %0h", p_out.user, p_in.user);
            $error();
            cnt_error_transaction++;
        end

        //id
        if(p_in.id != p_out.id) begin
            $display("Error ID, out = %0h, in = %0h", p_out.id, p_in.id);
            $error();
            cnt_error_transaction++;
        end

        //last
        if(p_in.last != p_out.last) begin
            $display("Error last, out = %0b, in = %0b", p_out.last, p_in.last);
            $error();
            cnt_error_transaction++;
        end

        cnt_transaction++;

        if(cnt_transaction >= cfg.count_transaction) begin
            done = 1;
        end
    endtask


endclass