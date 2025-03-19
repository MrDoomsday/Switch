class packet_axis #(
    parameter DATA_WIDTH = 8,
    parameter ID_WIDTH = 1,
    parameter DEST_WIDTH = 1,
    parameter USER_WIDTH = 1
);

    rand int unsigned len;
    rand int unsigned last_bytes; // количество байт в последнем слове пакета
    
    rand    logic   [DATA_WIDTH-1:0]    data [];
    rand    logic   [ID_WIDTH-1:0]      id;
    rand    logic   [DEST_WIDTH-1:0]    dest;
    rand    logic   [USER_WIDTH-1:0]    user;
    rand    logic   [DATA_WIDTH/8-1:0]  keep;
    rand    logic                       last;

    // randomization length packet
    constraint c_len {
        len > 0;
    }

    // randomization payload
    constraint c_payload {
        solve data before len;
        data.size() == len;
    }

    // randomization keep signal
    constraint c_keep {
        solve last_bytes before len;
        last_bytes inside {[1:DATA_WIDTH/8]};
        keep == '1 >> (DATA_WIDTH/8-last_bytes);
    }

endclass