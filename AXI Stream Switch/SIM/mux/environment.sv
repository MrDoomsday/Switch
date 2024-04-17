class environment #(
    parameter S_DATA_COUNT = 8,//число входов мультиплексора
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_DEST_WIDTH = 8
);


    agent_axis #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) agnt_axis [S_DATA_COUNT-1:0];


    agent_axim #(
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH)
    ) agnt_axim;


    scoreboard #(
        .S_DATA_COUNT   (S_DATA_COUNT),
        .T_DATA_WIDTH   (T_DATA_WIDTH),
        .T_ID_WIDTH     (T_ID_WIDTH),
        .T_DEST_WIDTH   (T_DEST_WIDTH)
    ) scb;


    function new();
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            agnt_axis[i] = new();
        end
        agnt_axim = new();
        scb = new();
    endfunction


    virtual task run();
        fork
            for(int i = 0; i < S_DATA_COUNT; i++) begin
                fork
                    automatic int k = i;
                    agnt_axis[k].run();         
                join_none
            end

            agnt_axim.run();
            scb.run();
        join
    endtask

endclass