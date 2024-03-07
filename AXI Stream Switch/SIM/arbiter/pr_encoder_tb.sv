module pr_encoder_tb();


    localparam WIDTH_N = 8;//размер входного вектора request
    localparam AMOUNT_M = 4;//максимальное число допустимых одновременных ответов

    bit clk;
    bit reset_n;

    bit     [WIDTH_N-1:0]                   req_i;
    bit                                     req_vld_i;
    bit                                     req_rdy_o;

    bit     [AMOUNT_M-1:0][WIDTH_N-1:0]     gnt_o;
    bit                                     gnt_vld_o;
    bit                                     gnt_rdy_i;



    pr_encoder #(
        .WIDTH_N(WIDTH_N),//размер входного вектора request
        .AMOUNT_M(AMOUNT_M)//максимальное число допустимых одновременных ответов
    ) DUT (
        .clk        (clk),
        .reset_n    (reset_n),
    
        .req_i      (req_i),
        .req_vld_i  (req_vld_i),
        .req_rdy_o  (req_rdy_o),
    
        .gnt_o      (gnt_o),
        .gnt_vld_o  (gnt_vld_o),
        .gnt_rdy_i  (gnt_rdy_i)
    );

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************             TEST            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    always begin
        clk = 1'b0;
        #10;
        clk = 1'b1;
        #10;
    end


    mailbox mbx_request = new();
    bit done;//тест завершается
    int cnt_transaction;
    int cnt_complete_transaction;
    int cnt_fail_transaction;
    

    task generate_reset();
        reset_n <= 1'b0;
        repeat(10) @(posedge clk);
        reset_n <= 1'b1;
    endtask

    task drive_request(int amount_transaction);
        wait(reset_n);
        repeat(amount_transaction) begin
            bit [WIDTH_N-1:0] req_next;
            req_next = $urandom();
            mbx_request.put(req_next);//сохраняем для будущего тестирования 

            req_i <= req_next;
            req_vld_i <= 1'b1;

            do begin
                @(posedge clk);
            end 
            while(!req_rdy_o);

            req_i <= 0;
            req_vld_i <= 1'b0;
            @(posedge clk);
        end
    endtask

    task drive_grant();
        gnt_rdy_i <= 1'b0;
        wait(reset_n);
        forever begin
            gnt_rdy_i <= 1'b1;
            repeat($urandom_range(10, 0)) @(posedge clk);
            gnt_rdy_i <= 1'b0;
            repeat($urandom_range(10, 0)) @(posedge clk);            
        end
    endtask

    task transaction_checker(int amount_transaction);
        wait(reset_n);
        forever begin
            @(posedge clk);
            if(gnt_rdy_i && gnt_vld_o) begin
                bit [WIDTH_N-1:0] curr_req;
                int current_amount_grant;//текущее число активных подтверждений 
                bit detect_fail;

                detect_fail = 0;
                current_amount_grant = 0;
                mbx_request.get(curr_req);

                /*Пробегаемся по всему массиву request и сравниваем с выходным результатом*/
                for(int i = 0; i < WIDTH_N; i++) begin
                    if(curr_req[i] && (current_amount_grant < AMOUNT_M)) begin//если число единиц во входном векторе больше максимального числа разрешений, то дальше бессмысленно проверять
                        if(gnt_o[AMOUNT_M - current_amount_grant - 1] != ({WIDTH_N{1'b1}} << i)) begin
                            detect_fail = 1'b1;
                            $error("Transaction failed! Gnt receive[%0d] = %0h, expected = %0h", current_amount_grant, gnt_o[current_amount_grant], ({WIDTH_N{1'b1}} << i));
                        end
                        current_amount_grant++;
                    end
                end

                cnt_transaction++;
                if(detect_fail) cnt_fail_transaction++;
                else cnt_complete_transaction++;
            end

            if(cnt_transaction >= amount_transaction) begin
                done = 1;
            end
        end
    endtask

    task wait_done();
        wait(reset_n);
        wait(done);
        if(cnt_fail_transaction > 0) begin
            $display("---------TEST FAILED---------");
            $display("Count error transaction = %0d", cnt_fail_transaction);
        end
        else begin
            $display("+++++++++TEST PASSED+++++++++");
            $display("Count complete transaction = %0d", cnt_complete_transaction);
        end
        $display("Count all transaction = %0d", cnt_transaction);
        $stop();
    endtask

    task test(int amount_transaction);
        fork
            generate_reset();
            drive_request(amount_transaction);
            drive_grant();
            transaction_checker(amount_transaction);
            wait_done();
        join
    endtask


    initial begin
        int size_test = 100000;
        test(size_test);
    end

endmodule