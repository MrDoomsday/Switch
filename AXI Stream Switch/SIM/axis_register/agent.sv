class agent_axis
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8    
);

    generator_slave #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) gen;

    driver_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) drv;

    minitor_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) mon;


    function new();
        gen = new();
        drv = new();
        mon = new();
    endfunction

    virtual task run();
        fork
            gen.run();
            drv.run();
            mon.run();
        join
    endtask

endclass


class agent_axim
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8    
);

    driver_axim #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) drv;


    minitor_axis #(//у нас экземпляр монитора одинаков как для входных, так и для выходных портов
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) mon;


    function new();
        drv = new();
        mon = new();
    endfunction

    virtual task run();
        fork
            drv.run();
            mon.run();
        join
    endtask

endclass