class configuration;

// интервалs рандомизации длины пакета
            int     min_size_pkt = 1;
            int     max_size_pkt = 100;
// интервалы рандомизации паузы между пакетами
            int     min_pause_pkt = 0;
            int     max_pause_pkt = 10;
//интервалы длительности низкого уровня ready на приемном конце 
            int     min_low_ready = 0;
            int     max_low_ready = 10;
//интервалы длительности высокого уровня ready на приемном конце
            int     min_high_ready = 0;
            int     max_high_ready = 10;



// условия завершения теста
    int count_transaction = 10000;
    int timeout_value = 1000_000_000;



    function void post_randomize();
        string str;
        str = $sformatf(        "Minimal size packet =            %d\n", min_size_pkt);
        str = {str, $sformatf(  "Maximal size packet =            %d\n", max_size_pkt)};
        str = {str, $sformatf(  "Minimal pause for packet =       %d\n", min_pause_pkt)};
        str = {str, $sformatf(  "Maximal pause for packet =       %d\n", max_pause_pkt)};

        str = {str, $sformatf(  "Minimal low level for ready =    %d\n", min_low_ready)};
        str = {str, $sformatf(  "Maximal low level for ready =    %d\n", max_low_ready)};
        str = {str, $sformatf(  "Minimal high level for ready =   %d\n", min_high_ready)};
        str = {str, $sformatf(  "Maximal high level for ready =   %d\n", max_high_ready)};
        str = {str, $sformatf(  "Count transaction per channel =  %d\n", count_transaction)};
        
        $display(str);
    endfunction

endclass