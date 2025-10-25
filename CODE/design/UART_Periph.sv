`timescale 1ns / 1ps

module UART_Periph(
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR, // APB Master의 PADDR[3:0]와 연결
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,   // APB Master의 PSEL3에 연결
    output logic [31:0] PRDATA, // APB Master의 PRDATA3에 연결
    output logic        PREADY,  // APB Master의 PREADY3에 연결

    // UART Core Signal
    output logic       txd,
    input  logic       rxd
);

    // APB 인터페이스와 UART_TOP 모듈 간의 신호
    logic [7:0] w_tx_pushdata;
    logic       w_tx_push;
    logic [7:0] w_rx_popdata;
    logic       w_rx_valid;
    logic       w_rx_pop;
    logic       w_tx_full;  

    APB_SlaveIntf_UART U_APB_SlaveIntf_UART (
        .PCLK           (PCLK),
        .PRESET         (PRESET),
        .PADDR          (PADDR[3:2]), // '32'h1000_3xxx' 하위 2비트만 사용
        .PWRITE         (PWRITE),
        .PENABLE        (PENABLE),
        .PWDATA         (PWDATA),
        .PSEL           (PSEL),
        .PRDATA         (PRDATA),
        .PREADY         (PREADY),
        .i_rx_popdata   (w_rx_popdata),
        .i_rx_valid     (w_rx_valid),
        .i_tx_full      (w_tx_full),
        .o_rx_pop       (w_rx_pop),
        .o_tx_pushdata  (w_tx_pushdata),
        .o_tx_push      (w_tx_push)
    );
    uart_top U_UART_Top (
        .clk            (PCLK),
        .rst            (PRESET),
        .rx             (rxd),
        .tx             (txd),
        .o_rx_popdata   (w_rx_popdata),
        .o_rx_valid     (w_rx_valid),
        .i_rx_pop       (w_rx_pop),
        .i_tx_pushdata  (w_tx_pushdata),
        .i_tx_push      (w_tx_push),
        .o_tx_full      (w_tx_full)
    );


endmodule

module APB_SlaveIntf_UART(
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 1:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    
    // UART_Top Signal
    input logic [ 7:0] i_rx_popdata,
    input logic        i_rx_valid,
    input logic        i_tx_full,
    output logic       o_rx_pop,
    output logic [ 7:0] o_tx_pushdata,
    output logic        o_tx_push
);
    logic [31:0] slv_reg0_txdata; // TxData (Write-Only)
    logic [31:0] slv_reg1_rxdata; // RxData (Read-Only)
    logic [31:0] slv_reg2_status; // Status (Read-Only)


    //top level 신호와 연결
    assign o_tx_pushdata = slv_reg0_txdata[7:0];

    // status 레지스터 구성
    // bit[0] : o_rx_valid (1: 수신 데이터 있음, 0: 수신 데이터 없음)
    // bit[1] : o_tx_full  (1: 전송 불가, 0: 전송 가능)
    assign slv_reg2_status = {30'b0, i_tx_full, i_rx_valid};

    // RxData 레지스터 구성
    assign slv_reg1_rxdata = {24'b0, i_rx_popdata};

    // o_rx_pop 신호는 읽기 동작 시 활성화
    assign o_rx_pop = (PSEL && PENABLE && !PWRITE && (PADDR == 2'd1));

    always_ff @( posedge PCLK, posedge PRESET ) begin
        if(PRESET) begin
            slv_reg0_txdata <= 32'b0;
            PREADY <= 1'b0;
            o_tx_push <= 1'b0;
        end else begin
            PREADY <= 1'b0;
            o_tx_push <= 1'b0; // 기본적으로 0

            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR) // GPO 와 유사하게 주소 매핑
                        2'd0: begin
                            slv_reg0_txdata <= PWDATA;
                            o_tx_push <= 1'b1; // 쓰기 발생 시 1 사이클 펄스
                        end
                        2'd1: ; // RxData는 읽기 전용
                        2'd2: ; // Status는 읽기 전용
                        default: ;
                    endcase
                end else begin
                    // 읽기 동작
                    case (PADDR)
                        2'd0: PRDATA <= slv_reg0_txdata; // TxData (읽을 수도 있게)
                        2'd1: PRDATA <= slv_reg1_rxdata; // RxData
                        2'd2: PRDATA <= slv_reg2_status; // Status
                        default: PRDATA <= 32'b0;
                    endcase
                end
            end
        end
    end
endmodule
