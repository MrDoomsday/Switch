class environment #(
    parameter S_DATA_COUNT = 2,
    parameter M_DATA_COUNT = 2,
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
);


    agent_s_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) agnt_s_axis [S_DATA_COUNT-1:0];


    agent_m_axis #(
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) agnt_m_axis [M_DATA_COUNT-1:0];


    scoreboard #(
        .S_DATA_COUNT(S_DATA_COUNT),
        .M_DATA_COUNT(M_DATA_COUNT),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .DEST_WIDTH (DEST_WIDTH),
        .USER_WIDTH (USER_WIDTH)
    ) scb;


    function new();
        for(int i = 0; i < S_DATA_COUNT; i++) begin
            agnt_s_axis[i] = new();
        end
        for(int i = 0; i < M_DATA_COUNT; i++) begin
            agnt_m_axis[i] = new();
        end
        scb = new();
    endfunction


    virtual task run();
        fork
            for(int i = 0; i < S_DATA_COUNT; i++) begin
                fork
                    automatic int k = i;
                    agnt_s_axis[k].run();         
                join_none
            end

            for(int i = 0; i < M_DATA_COUNT; i++) begin
                fork
                    automatic int p = i;
                    agnt_m_axis[p].run();         
                join_none
            end
            
            scb.run();
        join
    endtask

endclass