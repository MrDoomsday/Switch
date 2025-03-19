class scoreboard #(
    parameter S_DATA_COUNT = 8, // число входов мультиплексора
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
    ) mbx_out;
    
    packet_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
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
        int active_mailbox; // указывает на входной mailbox, в котором содержится текущий выходной пакет

        mbx_out.get(p_out);
        size_data_out = p_out.len;

        // ищем соответствующий данному пакету mailbox из массива входных maibox'ов
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            automatic bit data_fatal = 0;   // выставляется в единицу в случае несовпадения данных в пакетах при поиске активного входного mailbox'а
            mbx_in[i].try_peek(p_in);       // читаем первый элемент очереди без его извлечения
            size_data_in = p_in.len;

            if(size_data_in != size_data_out) begin
                if(i == S_DATA_COUNT - 1) begin
                    $error("Array is not detected!!!");
                    $fatal();
                end
                else begin
                    continue; // дальше код смысла выполнять особого нету, поэтому переходим к следующей итерации цикла
                end
            end

            for(int j = 0; j < p_in.len; j++) begin
                if(p_in.data[j] != p_out.data[j]) begin
                    data_fatal = 1;
                    break; // проверяем, что данные в пакетах совпадают
                end
            end

            if(data_fatal == 0) begin
                active_mailbox = i; // если все данные совпали - считаем, что нашли нужную очередь
                break; // выходим из главного цикла
            end

            if(i == S_DATA_COUNT - 1) begin
                $error("Array is not detected!!!");
                $fatal();
            end
        end

        mbx_in[active_mailbox].get(p_in);

        // id
        if(active_mailbox != p_out.id) begin
            $display("Error ID, out = %0h, in = %0h", p_out.id, active_mailbox);
            $error();
            cnt_error_transaction++;
        end

        // keep
        if(p_in.keep != p_out.keep) begin
            $display("Error KEEP, out = %0h, in = %0h", p_out.keep, p_in.keep);
            $error();
            cnt_error_transaction++;
        end

        cnt_transaction++;

        if(cnt_transaction % 1000 == 0) begin
            $display("Check %0d transaction", cnt_transaction);
        end

        /*
            Почему S_DATA_COUNT? У нас S_DATA_COUNT генераторов с одинаковым количеством 
            генерируемого содержимого
        */
        if(cnt_transaction >= S_DATA_COUNT*cfg.count_transaction) begin
            done = 1;
        end
    endtask


endclass