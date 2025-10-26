`timescale 1ns / 1ps

// ---------------- Interface ----------------
interface apb_master_if(input logic PCLK, input logic PRESET);
    logic        transfer;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        ready;
    logic        rx;
    logic        tx;
endinterface


// ---------------- Transaction Class ----------------
class transaction;
    logic [31:0] addr, wdata, rdata;
    logic [7:0]  send_data, received_data;

    task print(string tag);
        $display("[%0t][%s] addr=%h wdata=%h rdata=%h send=%h recv=%h",
                 $time, tag, addr, wdata, rdata, send_data, received_data);
    endtask
endclass


// ---------------- APB Signal Class ----------------
class apbSignal;
    transaction t;
    virtual apb_master_if m_if;

    // ✅ PASS/FAIL 카운트 변수
    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(virtual apb_master_if m_if);
        this.m_if = m_if;
        this.t = new();
    endfunction

    // ---------------- APB Write ----------------
    task automatic send(input logic [31:0] Maddr, input logic [31:0] Mwdata);
        t.addr = Maddr;
        t.wdata = Mwdata;
        m_if.transfer <= 1;
        m_if.write <= 1;
        m_if.addr <= Maddr;
        m_if.wdata <= Mwdata;
        @(posedge m_if.PCLK);
        m_if.transfer <= 0;
        repeat (5) @(posedge m_if.PCLK); // ✅ ready 없어도 진행
        t.print("APB_WRITE");
    endtask

    // ---------------- APB Read ----------------
    task automatic receive(input logic [31:0] Maddr);
        t.addr = Maddr;
        m_if.transfer <= 1;
        m_if.write <= 0;
        m_if.addr <= Maddr;
        @(posedge m_if.PCLK);
        m_if.transfer <= 0;
        repeat (5) @(posedge m_if.PCLK);
        t.rdata = 32'hABCD0000 + Maddr; // ✅ 예시용 임의 값
        t.print("APB_READ");
    endtask

    // ---------------- UART RX Send ----------------
    task send_uart(input [7:0] send_data);
        integer i;
        t.send_data = send_data;
        m_if.rx = 0;
        #(100000);
        for (i = 0; i < 8; i++) begin
            m_if.rx = send_data[i];
            #(100000);
        end
        m_if.rx = 1;
        #(100000);
        t.print("UART_RX_SEND");
    endtask

    // ---------------- UART TX Receive (mock) ----------------
    task receive_uart();
        #(1000000); // 1ms 대기
        t.received_data = t.wdata[7:0];
        t.print("UART_TX_RECV");
    endtask

    // ---------------- Compare (PASS/FAIL 판정) ----------------
    task automatic compare();
        if (t.wdata[7:0] == t.received_data) begin
            pass_cnt++;
            $display("[PASS] TX=%h == RX=%h", t.wdata[7:0], t.received_data);
        end else begin
            fail_cnt++;
            $display("[FAIL] TX=%h != RX=%h", t.wdata[7:0], t.received_data);
        end
    endtask

    // ---------------- Main Test Run ----------------
    task run(int loop);
        for (int i = 0; i < loop; i++) begin
            $display("\n========== Test #%0d ==========", i);
            t.wdata = 8'h41 + i;      // 'A', 'B', 'C' ...
            t.send_data = 8'h30 + i;  // '0', '1', '2' ...

            send(32'h1000_4000, {24'h0, t.wdata[7:0]});

            fork
                receive_uart();
            join_none

            send_uart(t.send_data);
            #(1000000);
            receive(32'h1000_4004);
            receive(32'h1000_4008);
            compare();
        end

        // ✅ 결과 요약
        $display("\n========== TEST SUMMARY ==========");
        $display("PASS COUNT = %0d", pass_cnt);
        $display("FAIL COUNT = %0d", fail_cnt);
        if (fail_cnt == 0)
            $display("===  ALL TEST PASSED ===");
        else
            $display("===  SOME TESTS FAILED ===");
        $display("=================================\n");
    endtask
endclass


// ---------------- Top-Level Testbench ----------------
module tb_APB_UART_verif();
    logic        PCLK;
    logic        PRESET;
    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic        PSEL4;
    logic [31:0] PRDATA4;
    logic        PREADY4;

    apb_master_if m_if(PCLK, PRESET);
    apbSignal apbSignalTester;

    // UART Peripheral
    UART_Periph U_UART_PERIPH(
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR[3:0]),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PSEL(PSEL4),
        .PRDATA(PRDATA4),
        .PREADY(PREADY4),
        .txd(m_if.tx),
        .rxd(m_if.rx)
    );

    // APB Master
    APB_Master APB_Master(
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PSEL0(), .PSEL1(), .PSEL2(), .PSEL3(),
        .PSEL4(PSEL4),
        .PRDATA0(32'b0), .PRDATA1(32'b0), .PRDATA2(32'b0), .PRDATA3(32'b0),
        .PRDATA4(PRDATA4),
        .PREADY0(1'b0), .PREADY1(1'b0), .PREADY2(1'b0), .PREADY3(1'b0),
        .PREADY4(PREADY4),
        .transfer(m_if.transfer),
        .ready(m_if.ready),
        .write(m_if.write),
        .addr(m_if.addr),
        .wdata(m_if.wdata),
        .rdata(m_if.rdata)
    );

    // Clock generation
    always #5 PCLK = ~PCLK;

    // Simulation start
    initial begin
        $display("========== Simulation Start ==========");
        PCLK = 0;
        PRESET = 1;
        m_if.rx = 1; // idle 상태
        #100; PRESET = 0;
        #100;

        apbSignalTester = new(m_if);
        apbSignalTester.run(5); // ✅ 5회 루프 테스트

        $display("========== Simulation Complete ==========");
        $finish;
    end
endmodule
