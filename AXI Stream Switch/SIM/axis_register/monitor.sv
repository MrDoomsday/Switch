class minitor_axis
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8    
);
    //global
    mailbox #(
        axis_packet #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH),
            .T_USER_WIDTH   (T_USER_WIDTH)
        )
    ) mbx_mon2scb;
    
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

    //local
    mailbox #(
        axis_packet #(
            .T_DATA_WIDTH   (T_DATA_WIDTH),
            .T_ID_WIDTH     (T_ID_WIDTH),
            .T_USER_WIDTH   (T_USER_WIDTH)
        )
    ) word_collection;//для коллекционирования отдельных слов, которые регистрируем от интерфейса

    function new();
        word_collection = new();
    endfunction

    virtual task run();
        wait(vif_stream.reset_n);
        forever begin
            monitoring();
        end
    endtask


    virtual task monitoring();
        /*
            планируется при помощи монитора собирать пакет из отдельных слов, которые наблюдаются на интерфейсе
        */
        @(posedge vif_stream.clk);
        if(vif_stream.ready && vif_stream.valid) begin
            p = new();
            if(!p.randomize() with {
                len == 1;
            }) begin //нужно создать однословный пакет для буферизации
                $display("Error randomization in monitor...");
                $fatal();
            end

            p.id = vif_stream.id;
            p.data[0] = vif_stream.data;
            p.user = vif_stream.user;
            p.last = vif_stream.last;
            word_collection.put(p);

            if(vif_stream.last) begin//детектировано последнее слово в пакете, можно начать сборку пакета в один класс
                int size_pkt;

                size_pkt = word_collection.num();

                //создаем класс пакета
                p = new();
                if(!p.randomize() with {
                    len == size_pkt;
                }) begin
                    $display("Error randomization in monitor, last packet...");
                    $fatal();
                end
                /*
                    теперь извлекаем последовательно содержимое очереди 
                    с коллекцией отдельных слов word_collection
                    и собираем класс полного пакета p;
                    Другие поля (dest, id, last) одинаковы на протяжении всего пакета,
                    поэтому они не индексируются, а назначаются одинаково для всех итераций цикла
                */
                for(int i = 0; i < size_pkt; i++) begin
                    axis_packet #(
                        .T_DATA_WIDTH   (T_DATA_WIDTH),
                        .T_ID_WIDTH     (T_ID_WIDTH),
                        .T_USER_WIDTH   (T_USER_WIDTH)
                    ) pkt;
                    
                    word_collection.get(pkt);
                    

                    p.id = pkt.id;
                    p.data[i] = pkt.data[0];
                    p.user = pkt.user;
                    p.last = pkt.last;
                end

                word_collection = new();//уничтожаем старый объект и создаем новый
                mbx_mon2scb.put(p);//сохраняем пакет целиком
            end
        end
    endtask


endclass