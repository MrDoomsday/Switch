module irr_arbiter_tb();



    localparam WIDTH_REQ = 3;
    localparam SIZE_POINTER = $clog2(WIDTH_REQ);//размер указателя на REQUEST

    bit     clk;
    bit     reset_n;

    bit     [WIDTH_REQ-1:0]         req_i;
    bit     [WIDTH_REQ-1:0]         req_ack_o;

    bit     [WIDTH_REQ-1:0]         gnt_o;
    bit     [SIZE_POINTER-1:0]      gnt_id_o;
    bit                             gnt_vld_o;
    bit                             gnt_rdy_i;

    typedef struct packed {
        bit     [WIDTH_REQ-1:0]         gnt;
        bit     [SIZE_POINTER-1:0]      id;
    } str_grant;

    mailbox mbx_req_gen2drv;;
    mailbox mbx_req_mon2scb;
    mailbox #(str_grant) mbx_gnt_mon2scb;

    int timeout = 1000000;
    int size_sequence = 10000;



    irr_arbiter #(
        .WIDTH_REQ(WIDTH_REQ)
    ) DUT (
        .clk        (clk),
        .reset_n    (reset_n),
    
        .req_i      (req_i),
        .req_ack_o  (req_ack_o),

        .gnt_o      (gnt_o),
        .gnt_id_o   (gnt_id_o),
        .gnt_vld_o  (gnt_vld_o),
        .gnt_rdy_i  (gnt_rdy_i)
    );
    

    always begin
        clk <= 1'b0;
        #10;
        clk <= 1'b1;
        #10;
    end


    initial begin
        mbx_req_gen2drv = new();
        mbx_req_mon2scb = new();
        mbx_gnt_mon2scb = new();
        
        fork
            gen_reset();
            gen_test_sequence(size_sequence);
            drive_req();
            monitor_req();

            drive_gnt();
            monitor_gnt();
            check(size_sequence);
            wait_timeout(timeout);
        join

        repeat(100) @(posedge clk);
        $display("********TEST FINISHED********");
        $stop();
    end

    task gen_reset();
        reset_n <= 1'b0;
        repeat(10) @(posedge clk);
        reset_n <= 1'b1;
    endtask

    task wait_timeout(int tout);
        repeat(tout) @(posedge clk);
        $stop("TIMEOUT");
    endtask

    task gen_test_sequence(int cnt_requests);        
        bit [WIDTH_REQ-1:0] gen_req;

        repeat(cnt_requests) begin
            if(!std::randomize(gen_req) with {
                gen_req > 0;//нам не нужны транзакции с нулевым число запросов
            }) begin
                $display("Error randomization request...");
                $fatal();
            end

            mbx_req_gen2drv.put(gen_req);
        end
    endtask

    task drive_req();
        req_i <= 'b0;
        wait(reset_n);
        
        forever begin
            bit [WIDTH_REQ-1:0] current_request;
            mbx_req_gen2drv.get(current_request);  
            req_i = current_request;

            while(req_i > 0) begin
                req_i <= req_i & inv_bus(req_ack_o);//сбрасываем тот бит, для которого появилось подтверждение
                @(posedge clk);
            end
        end
    endtask

    function bit [WIDTH_REQ-1:0] inv_bus(bit [WIDTH_REQ-1:0] bus);
        bit [WIDTH_REQ-1:0] result;
        for(int i = 0; i < WIDTH_REQ; i++) result[i] = ~bus[i];
        return result;
    endfunction


    task monitor_req();
        wait(reset_n);
        forever begin
            @(posedge clk);
            for(int i = 0; i < WIDTH_REQ; i++) begin
                if(req_i[i] && req_ack_o[i]) begin
                    mbx_req_mon2scb.put(req_i & req_ack_o);//помещаем текущий подтвержденный request в mailbox монитора для анализа
                end
            end
        end
    endtask

    task drive_gnt();
        gnt_rdy_i <= 1'b0;
        wait(reset_n);

        forever begin
            gnt_rdy_i <= 1'b0;
            repeat($urandom_range(10,0)) @(posedge clk);
            gnt_rdy_i <= 1'b1;
            repeat($urandom_range(10,0)) @(posedge clk);
        end
    endtask

    task monitor_gnt();
        wait(reset_n);

        forever begin
            str_grant current_gnt;
            @(posedge clk);
            if(gnt_vld_o && gnt_rdy_i) begin
                current_gnt.gnt = gnt_o;
                current_gnt.id = gnt_id_o;
                mbx_gnt_mon2scb.put(current_gnt);
            end
        end
    endtask

    task check(int cnt_transaction);
        bit [WIDTH_REQ-1:0] req_in;
        str_grant gnt_out;
        int current_transaction;
        int current_fail_transaction;
        int cnt_simultaneous_gnt;
        int cnt_simultaneous_req;
        
        

        forever begin
            mbx_req_mon2scb.get(req_in);
            mbx_gnt_mon2scb.get(gnt_out);

            //проверка соответствия grant'а request'у
            if(gnt_out.gnt != req_in) begin
                $error("Grant doesn't match request! Request = %0b, Grant = %0b", req_in, gnt_out.gnt);
                current_fail_transaction++;
            end
            
            //проверка соотвествия ID'а
            if(gnt_out.gnt[gnt_out.id] != 1'b1) begin
                $error("ID doesn't match grant! ID = %0b, Grant = %0b", gnt_out.id, gnt_out.gnt);
                current_fail_transaction++;
            end

            //проверка количества grant'ов на шине
            cnt_simultaneous_gnt = 0;
            for(int i = 0; i < WIDTH_REQ; i++) begin
                if(gnt_out.gnt[i]) cnt_simultaneous_gnt++;
            end

            if(cnt_simultaneous_gnt > 1) begin
                $error("The number of simultaneous Grant is greater than one. Cnt grant = %0d", cnt_simultaneous_gnt);
                current_fail_transaction++;
            end

            //проверка числа request'ов на шине
            cnt_simultaneous_req = 0;
            for(int i = 0; i < WIDTH_REQ; i++) begin
                if(req_in[i]) cnt_simultaneous_req++;
            end

            if(cnt_simultaneous_req > 1) begin
                $error("The number of simultaneous Request is greater than one. Cnt request = %0d", cnt_simultaneous_req);
                current_fail_transaction++;
            end

            //завершение тестирования
            current_transaction++;
            if(current_transaction >= cnt_transaction) begin
                if(current_fail_transaction > 0) begin
                    $display("****TEST FAILED****");
                    $display("Count erros = %0d", current_fail_transaction);
                end
                else begin
                    $display("****TEST PASSED****");
                    $display("Count transaction = %0d", current_transaction);
                end
                $stop();
            end
        end
    endtask

endmodule