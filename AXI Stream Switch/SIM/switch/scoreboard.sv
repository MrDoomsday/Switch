class scoreboard #(
    parameter S_DATA_COUNT = 8,
    parameter M_DATA_COUNT = 8,
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
);

    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_in [S_DATA_COUNT-1:0];

    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_out [M_DATA_COUNT-1:0];
    
    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_reordering [M_DATA_COUNT-1:0]; // очередь для хранения транзакций, которые предназначаются для каждой из очередей

    packet_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) p_in, p_out;


    configuration cfg;

    bit [M_DATA_COUNT-1:0] done = 0;
    bit [M_DATA_COUNT-1:0] fail = 0;
    int cnt_all_transaction; // количество всех фреймов


    function new();
        for(int i = 0; i < M_DATA_COUNT; i++) begin
            mbx_reordering[i] = new();
        end
    endfunction

    virtual task run();
        fork
            reorder_packets();
            for(int i = 0; i < S_DATA_COUNT; i++) begin
                fork
                    automatic int k = i;
                    check_pkt(k);
                join_none
            end
        join
    endtask

    /*
        Суть заключается в следующем. У нас имеется S_DATA_COUNT входных очередей, в которых содержатся пакеты, которые должны 
        попасть на один из выходов [0:M_DATA_COUNT-1], вот нам нужно эти пакеты рассортировать. т.е. извлечь из входных очередей,
        определить на какой выходной порт пакет должен попасть и переложить из входной очереди в соответствующую очередь перераспределенных пакетов.
        А потом уже проверить правильность работы свича
    */
    virtual task reorder_packets();
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            fork
                automatic int k = i;
                forever begin
                    packet_axis #(
                        .DATA_WIDTH (DATA_WIDTH),
                        .ID_WIDTH   (ID_WIDTH),
                        .DEST_WIDTH (DEST_WIDTH),
                        .USER_WIDTH (USER_WIDTH)
                    ) p_tmp;
                    mbx_in[k].get(p_tmp);
                    if(p_tmp.dest < M_DATA_COUNT) begin
                        mbx_reordering[p_tmp.dest].put(p_tmp);
                        // $display("Packet transit, src = %0d, dest = %0d", k, p_tmp.dest);                            
                    end else begin
                        // $display("Packet drop, src = %0d, dest = %0d", k, p_tmp.dest);
                    end
                end
            join_none
        end        
    endtask

    virtual task check_pkt(int index_mport);
        automatic int size_data_in;
        automatic int size_data_out;
        automatic int size_queue;
        automatic int cnt_transaction;
        automatic int cnt_error_transaction;
        fork
            forever begin
                mbx_out[index_mport].get(p_out);
                size_data_out = p_out.len;

                // ищем соответствующий данному пакету mailbox из массива входных maibox'ов
                size_queue = mbx_reordering[index_mport].num(); // определяем количество пакетов в очереди

                for(int i = 0; i < size_queue; i++) begin // ищем выходной пакет в очереди перераспределенных входных пакетов
                    automatic bit data_fatal = 0;   // выставляется в единицу в случае несовпадения данных в пакетах при поиске активного входного mailbox'а
                    mbx_reordering[index_mport].get(p_in);
                    size_data_in = p_in.len;

                    if(size_data_in != size_data_out) begin
                        if(i == size_queue - 1) begin
                            $error("Array is not detected!!!");
                            $fatal();
                        end
                        else begin
                            mbx_reordering[index_mport].put(p_in); // кладем элемент обратно в очередь
                            continue; // дальше код смысла выполнять особого нету, поэтому переходим к следующей итерации цикла
                        end
                    end

                    // проверка совпадения данных в пакетах
                    for(int j = 0; j < p_in.len; j++) begin
                        if(p_in.data[j] != p_out.data[j]) begin
                            data_fatal = 1;
                            break;
                        end
                    end

                    if(data_fatal == 0) begin
                        break; // выходим из главного цикла
                    end else begin
                        mbx_reordering[index_mport].put(p_in); // кладем элемент обратно в очередь
                    end

                    // если мы дошли сюда - значит поиск пакета успехом не увенчался :(
                    if(i == size_queue - 1) begin
                        $error("Array is not detected!!!");
                        $fatal();
                    end
                end

                // keep
                if(p_in.keep != p_out.keep) begin
                    $display("Error KEEP, out = %0h, in = %0h", p_out.keep, p_in.keep);
                    $error();
                    cnt_error_transaction++;
                end
                
                cnt_transaction++;
                cnt_all_transaction++;

                if(cnt_transaction % 1000 == 0) begin
                    $display("Check %0d transaction, port = %0d", cnt_transaction, index_mport);
                end
            end
            begin // условием завершения теста на канале является достижение количества проверенных пакетов, сгенерированных генераторами
                wait(cnt_all_transaction >= S_DATA_COUNT*cfg.count_transaction);

                $display("Test channel %0d, All packets: %0d", index_mport, cnt_transaction);
                if(cnt_error_transaction > 0) begin
                    fail[index_mport] = 1;
                    $display("Test channel %0d is failed, error: %0d", index_mport, cnt_error_transaction);
                end
                done[index_mport] = 1;
            end
        join
    endtask


endclass