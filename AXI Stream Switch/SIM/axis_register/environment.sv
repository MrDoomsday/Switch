class environment
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8 
);


    agent_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) agnt_axis;


    agent_axim #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) agnt_axim;


    scoreboard #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_USER_WIDTH   (T_USER_WIDTH)
    ) scb;


    function new();
        agnt_axis = new();
        agnt_axim = new();
        scb = new();
    endfunction


    virtual task run();
        fork
            agnt_axis.run();
            agnt_axim.run();
            scb.run();
        join
    endtask

endclass