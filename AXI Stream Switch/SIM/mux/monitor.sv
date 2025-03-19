class monitor_s_axis #(
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
);
    //global
    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
        )
    ) mbx_mon2scb;
    
    virtual if_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) vif_axis;

    packet_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) p;

    //local
    mailbox #(
        packet_axis #(
            .DATA_WIDTH (DATA_WIDTH),
            .ID_WIDTH   (ID_WIDTH),
            .DEST_WIDTH (DEST_WIDTH),
            .USER_WIDTH (USER_WIDTH)
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

            p.data[0]   = vif_axis.data;
            p.id        = vif_axis.id;
            p.dest      = vif_axis.dest;
            p.user      = vif_axis.user;
            p.keep      = vif_axis.keep;
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
                    поэтому они не индексируются, а назначаются один раз для всего пакета
                */
                for(int i = 0; i < size_pkt; i++) begin
                    packet_axis #(
                        .DATA_WIDTH (DATA_WIDTH),
                        .ID_WIDTH   (ID_WIDTH),
                        .DEST_WIDTH (DEST_WIDTH),
                        .USER_WIDTH (USER_WIDTH)
                    ) pkt;
                    
                    word_collection.get(pkt);
                    
                    p.data[i]   = pkt.data[0];
                    p.keep      = pkt.keep;

                    if(i == size_pkt-1) begin
                        p.last  = pkt.last;
                        p.id    = pkt.id;
                        p.dest  = pkt.dest;
                        p.user  = pkt.user;
                    end
                end

                word_collection = new();//уничтожаем старый объект и создаем новый
                mbx_mon2scb.put(p);//сохраняем пакет целиком
            end
        end
    endtask

endclass

class monitor_m_axis #(
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
) extends monitor_s_axis #(
    .DATA_WIDTH (DATA_WIDTH),
    .ID_WIDTH   (ID_WIDTH),
    .DEST_WIDTH (DEST_WIDTH),
    .USER_WIDTH (USER_WIDTH)
);

endclass
