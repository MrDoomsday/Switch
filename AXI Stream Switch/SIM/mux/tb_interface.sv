    interface interface_axis #(
        parameter T_DATA_WIDTH = 8,
        parameter T_DEST_WIDTH = 8
    )(
        input bit clk,
        input bit reset_n
    );

        bit     [T_DEST_WIDTH-1:0]      dest;//куда пакет направляется
        bit     [T_DATA_WIDTH-1:0]      data;
        bit                             last;
        bit                             valid;
        bit                             ready;


        SVA_CHECK_VLD_STABLE: assert property(
            @(posedge clk) disable iff (!reset_n)
            valid & ~ready |-> ##1 valid
        ) else $error("Valid signal is unstable during zero ready"); 

        SVA_CHECK_OTHERS_STABLE: assert property(
            @(posedge clk) disable iff (!reset_n)
            valid & ~ready |-> ##1 {dest, data, last} == $past({dest, data, last})
        ) else $error("DEST, DATA or LAST signal is unstable during zero ready"); 

    endinterface


    interface interface_axim #(
        parameter T_DATA_WIDTH = 8,
        parameter T_ID_WIDTH = 8    
    )(
        input bit clk,
        input bit reset_n
    );

        bit     [T_ID_WIDTH-1:0]        id;//откуда пакет пришел(номер порта)
        bit     [T_DATA_WIDTH-1:0]      data;
        bit                             last;
        bit                             valid;
        bit                             ready;

        SVA_CHECK_VLD_STABLE: assert property(
            @(posedge clk) disable iff (!reset_n)
            valid & ~ready |-> ##1 valid
        ) else $error("Valid signal is unstable during zero ready"); 

        SVA_CHECK_OTHERS_STABLE: assert property(
            @(posedge clk) disable iff (!reset_n)
            valid & ~ready |-> ##1 {id, data, last} == $past({id, data, last})
        ) else $error("ID, DATA or LAST signal is unstable during zero ready"); 


    endinterface
