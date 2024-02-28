class axis_packet
#(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8,
    parameter T_USER_WIDTH = 8 
);

    rand int len;

    rand    bit     [T_ID_WIDTH-1:0]        id;
    rand    bit     [T_DATA_WIDTH-1:0]      data [];
    rand    bit     [T_USER_WIDTH-1:0]      user;
    bit                                     last;

    constraint c_packet {
        len > 0;
        len -> {
            data.size() == len;
        }  
    }

endclass