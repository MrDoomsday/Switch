class scoreboard #(
    parameter S_DATA_COUNT = 8,//число входов мультиплексора
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_DEST_WIDTH = 8    
);

    mailbox #(
        packet_axis #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_DEST_WIDTH   (T_DEST_WIDTH)
        )
    ) mbx_in [S_DATA_COUNT-1:0];

    mailbox #(
        packet_axim #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH)
        )
    ) mbx_out;
    
    packet_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) p_in;


    packet_axim #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH)
    ) p_out;


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
        int active_mailbox;//указывает на входной mailbox, в котором содержится текущий выходной пакет
        bit data_fatal;//выставляется в единицу в случае несовпадения данных в пакетах при поиске активного входного mailbox'а

        mbx_out.get(p_out);
        size_data_out = p_out.data.size();

        //ищем соответствующий данному пакету mailbox из массива входных maibox'ов
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            data_fatal = 0;
            mbx_in[i].try_peek(p_in);//читаем первый элемент очереди без его извлечения
            size_data_in = p_in.data.size();

            if(size_data_in != size_data_out) begin
                if(i == S_DATA_COUNT - 1) begin
                    $error("Array is not detected!!!");
                    $fatal();
                end
                else begin
                    continue;//дальше код смысла выполнять особого нету, поэтому переходим к следующей итерации цикла
                end
            end

            for(int j = 0; j < p_in.data.size(); j++) begin
                if(p_in.data[j] != p_out.data[j]) begin
                    data_fatal = 1;
                    break;//проверяем, что данные в пакетах совпадают
                end
            end

            if(data_fatal == 0) begin
                active_mailbox = i;//если все данные совпали - считаем, что нашли нужную очередь
                break;//выходим из главного цикла
            end

            if(i == S_DATA_COUNT - 1) begin
                $error("Array is not detected!!!");
                $fatal();
            end
        end

        mbx_in[active_mailbox].get(p_in);
        

        //check length
        if(size_data_in != size_data_out) begin
            $display("Error size data array, out = %0d, in = %0d", p_out.data.size(), p_in.data.size());
            $error();
            cnt_error_transaction++;
            $stop();
        end

        for(int i = 0; i < size_data_out; i++) begin
            if(p_in.data[i] != p_out.data[i]) begin
                $display("Error data array, out[%0d] = %0h, in[%0d] = %0h", i, p_out.data.size(), i, p_in.data.size());
                $error();
                cnt_error_transaction++;
            end
        end


        //id
        if(active_mailbox != p_out.id) begin
            $display("Error ID, out = %0h, in = %0h", p_out.id, active_mailbox);
            $error();
            cnt_error_transaction++;
        end


        cnt_transaction++;

        /*
            Почему S_DATA_COUNT? У нас S_DATA_COUNT генераторов с одинаковым количеством 
            генерируемого содержимого
        */
        if(cnt_transaction >= S_DATA_COUNT*cfg.count_transaction) begin
            done = 1;
        end
    endtask


endclass