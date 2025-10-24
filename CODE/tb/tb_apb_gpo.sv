`timescale 1ns / 1ps


module tb_apb_gpo();
    // global signals
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signal;
    logic [ 2:0] PADDR;
    logic        PWRITE;
    logic        PSEL;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    // external signals ports
    logic [3:0] gpo;

    APB_GPO dut(.*);

    always #5 PCLK = ~PCLK;

    task automatic gpo_write(logic [2:0] addr, logic [31:0] data);
        PWRITE = 1'b1;
        PSEL = 1'b1;
        PENABLE = 1'b0;  
        PADDR = addr;
        PWDATA = data;
        @(posedge PCLK);
        PENABLE = 1'b1;
        @(posedge PCLK);
        wait(PREADY);
        @(posedge PCLK);
        PSEL = 1'b0;
        @(posedge PCLK);
    endtask //automatic

    initial begin
        #00 PCLK=0; PRESET = 1;
        #10 PRESET = 0;
        @(posedge PCLK);
        gpo_write(3'h0, 4'hf); // output mode
        gpo_write(3'h4, 4'hf);
        gpo_write(3'h4, 4'h0);
        gpo_write(3'h4, 4'hf);
        gpo_write(3'h4, 4'h0);

        gpo_write(3'h0, 4'h0); // high impedence
        gpo_write(3'h4, 4'hf);
        gpo_write(3'h4, 4'h0);
        gpo_write(3'h4, 4'hf);
        gpo_write(3'h4, 4'h0);


    end
endmodule
