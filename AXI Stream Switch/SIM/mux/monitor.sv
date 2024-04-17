class monitor_axis #(
    parameter T_DATA_WIDTH = 8,
    parameter T_DEST_WIDTH = 8    
);
    //global
    mailbox #(
        packet_axis #(
            .T_DATA_WIDTH(T_DATA_WIDTH),
            .T_DEST_WIDTH(T_DEST_WIDTH)
        )
    ) mbx_mon2scb;
    
    virtual interface_axis 
    #(
        .T_DATA_WIDTH(T_DATA_WIDTH),
        .T_DEST_WIDTH(T_DEST_WIDTH)
    ) vif_axis;

    packet_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) p;

    //local
    mailbox #(
        packet_axis #(
            .T_DATA_WIDTH(T_DATA_WIDTH),
            .T_DEST_WIDTH(T_DEST_WIDTH)
        )
    ) word_collection;//для коллекционирования отдельных слов, которые регистрируем от интерфейса

    function new();
        word_collection = new();
    endfunction

    virtual task run();
        wait(vif_axis.reset_n);
        forever begin
            monitoring();
        end
    endtask


    virtual task monitoring();
        @(posedge vif_axis.clk);
        if(vif_axis.ready && vif_axis.valid) begin
            p = new();
            if(!p.randomize() with {
                len == 1;
            }) begin //нужно создать однословный пакет для буферизации
                $display("Error randomization in monitor...");
                $fatal();
            end

            p.dest      = vif_axis.dest;
            p.data[0]   = vif_axis.data;
            p.last      = vif_axis.last;
            word_collection.put(p);

            if(vif_axis.last) begin//детектировано последнее слово в пакете, можно начать сборку пакета в один класс
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
                    packet_axis #(
                        .T_DATA_WIDTH(T_DATA_WIDTH),
                        .T_DEST_WIDTH(T_DEST_WIDTH)
                    ) pkt;
                    
                    word_collection.get(pkt);
                    
                    p.dest = pkt.dest;
                    p.data[i] = pkt.data[0];
                    p.last = pkt.last;
                end

                word_collection = new();//уничтожаем старый объект и создаем новый
                mbx_mon2scb.put(p);//сохраняем пакет целиком
            end
        end
    endtask

endclass





class monitor_axim #(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8
);
    //global
    mailbox #(
        packet_axim #(
            .T_DATA_WIDTH(T_DATA_WIDTH),
            .T_ID_WIDTH(T_ID_WIDTH)
        )
    ) mbx_mon2scb;
    
    virtual interface_axim 
    #(
        .T_DATA_WIDTH(T_DATA_WIDTH),
        .T_ID_WIDTH(T_ID_WIDTH)
    ) vif_axim;

    packet_axim #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH)
    ) p;

    //local
    mailbox #(
        packet_axim #(
            .T_DATA_WIDTH(T_DATA_WIDTH),
            .T_ID_WIDTH(T_ID_WIDTH)
        )
    ) word_collection;//для коллекционирования отдельных слов, которые регистрируем от интерфейса

    function new();
        word_collection = new();
    endfunction

    virtual task run();
        wait(vif_axim.reset_n);
        forever begin
            monitoring();
        end
    endtask


    virtual task monitoring();
        @(posedge vif_axim.clk);
        if(vif_axim.ready && vif_axim.valid) begin
            p = new();
            if(!p.randomize() with {
                len == 1;
            }) begin //нужно создать однословный пакет для буферизации
                $display("Error randomization in monitor...");
                $fatal();
            end

            p.id        = vif_axim.id;
            p.data[0]   = vif_axim.data;
            p.last      = vif_axim.last;
            word_collection.put(p);

            if(vif_axim.last) begin//детектировано последнее слово в пакете, можно начать сборку пакета в один класс
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
                    packet_axim #(
                        .T_DATA_WIDTH(T_DATA_WIDTH),
                        .T_ID_WIDTH(T_ID_WIDTH)
                    ) pkt;
                    
                    word_collection.get(pkt);
                    
                    p.id = pkt.id;
                    p.data[i] = pkt.data[0];
                    p.last = pkt.last;
                end

                word_collection = new();//уничтожаем старый объект и создаем новый
                mbx_mon2scb.put(p);//сохраняем пакет целиком
            end
        end
    endtask


endclass