//  Interface: stream_intf
//
    interface stream_intf
        #(
            parameter T_DATA_WIDTH = 8,
            parameter T_ID_WIDTH = 8,
            parameter T_USER_WIDTH = 8
        )(
            input bit clk,
            input bit reset_n
        );
        bit     [T_ID_WIDTH-1:0]        id;
        bit     [T_DATA_WIDTH-1:0]      data;
        bit     [T_USER_WIDTH-1:0]      user;
        bit                             last;
        bit                             valid;
        bit                             ready;


        SVA_CHECK_VLD: assert property (
            @(posedge clk) disable iff(!reset_n) 
            valid & ~ready |-> ##1 valid
        ) else $error("SVA error valid change 1->0 for ready is equal to 0");

        SVA_CHECK_LAST: assert property (
            @(posedge clk) disable iff(!reset_n)
            valid & ~ready |-> ##1 last == $past(last)
        ) else $error("SVA error last change for valid & !ready");

    endinterface: stream_intf