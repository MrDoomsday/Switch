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


        SVA_CHECK_STABLE_VLD: assert property (
            @(posedge clk) disable iff(!reset_n) 
            valid & ~ready |-> ##1 valid
        ) else $error("SVA error: VALID change 1->0 for ready is equal to 0");

        SVA_CHECK_STABLE_ID: assert property (
            @(posedge clk) disable iff(!reset_n)
            valid & ~ready |-> ##1 $stable(id)
        ) else $error("SVA error: ID change for valid & !ready");

        SVA_CHECK_STABLE_DATA: assert property (
            @(posedge clk) disable iff(!reset_n)
            valid & ~ready |-> ##1 $stable(data)
        ) else $error("SVA error: DATA change for valid & !ready");

        SVA_CHECK_STABLE_USER: assert property (
            @(posedge clk) disable iff(!reset_n)
            valid & ~ready |-> ##1 $stable(user)
        ) else $error("SVA error: USER change for valid & !ready");

        SVA_CHECK_STABLE_LAST: assert property (
            @(posedge clk) disable iff(!reset_n)
            valid & ~ready |-> ##1 $stable(last)
        ) else $error("SVA error: LAST change for valid & !ready");

    endinterface: stream_intf