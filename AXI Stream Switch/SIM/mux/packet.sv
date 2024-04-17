class packet_axis #(
    parameter T_DATA_WIDTH = 8,
    parameter T_DEST_WIDTH = 8    
);

    rand int len;

    rand    bit     [T_DEST_WIDTH-1:0]      dest;//куда пакет направляется
    rand    bit     [T_DATA_WIDTH-1:0]      data [];
    bit                                     last;

    constraint c_packet {
        len > 0;
        len -> {
            data.size() == len;
        }
        dest == 0;  
    }

endclass

class packet_axim #(
    parameter T_DATA_WIDTH = 8,
    parameter T_ID_WIDTH = 8
);

    rand int len;

    rand    bit     [T_ID_WIDTH-1:0]        id;//откуда пакет пришел(номер порта)
    rand    bit     [T_DATA_WIDTH-1:0]      data [];
    bit                                     last;

    constraint c_packet {
        len > 0;
        len -> {
            data.size() == len;
        }  
    }

endclass
