#include <stdint.h>

#define APB_BASE_ADDR 0x10000000
#define GPO_OFFSET 0x1000
#define GPI_OFFSET 0x2000
#define GPIO_OFFSET 0x3000
#define UART_OFFSET 0x4000

#define GPO_BASE_ADDR  (APB_BASE_ADDR + GPO_OFFSET)
#define GPI_BASE_ADDR  (APB_BASE_ADDR + GPI_OFFSET)
#define GPIO_BASE_ADDR  (APB_BASE_ADDR + GPIO_OFFSET)
#define UART_BASE_ADDR  (APB_BASE_ADDR + UART_OFFSET)

#define GPO_CR      (*(uint32_t *)(GPO_BASE_ADDR + 0x00))
#define GPO_ODR     (*(uint32_t *)(GPO_BASE_ADDR + 0x04))
#define GPI_CR      (*(uint32_t *)(GPI_BASE_ADDR + 0x00))
#define GPI_IDR     (*(uint32_t *)(GPI_BASE_ADDR + 0x04))
#define GPIO_ODR     (*(uint32_t *)(GPIO_BASE_ADDR + 0x00))
#define GPIO_CR      (*(uint32_t *)(GPIO_BASE_ADDR + 0x04))
#define GPIO_IDR     (*(uint32_t *)(GPIO_BASE_ADDR + 0x08))

// APB_SlaveIntf_UART 모듈의 주소 매핑에 따름
#define UART_TXDATA (*(volatile uint32_t *)(UART_BASE_ADDR + 0x00))
#define UART_RXDATA (*(volatile uint32_t *)(UART_BASE_ADDR + 0x04))
#define UART_STATUS (*(volatile uint32_t *)(UART_BASE_ADDR + 0x08))

// UART_STATUS 비트 정의 (APB_SlaveIntf_UART 설계에 따름)
#define UART_RX_VALID (1u << 0) // bit 0: 수신 데이터 있음
#define UART_TX_FULL  (1u << 1) // bit 1: 송신 FIFO 꽉 참

// --- 모드 스위치 핀 정의 (GPIO[7:5]) ---
#define MODE_SWITCH_PORT  GPIO_IDR
#define SW_LED_LEFT     (1u << 7)  // GPIO[7]
#define SW_LED_RIGHT    (1u << 6)  // GPIO[6]
#define SW_GPI_TO_GPO   (1u << 5)  // GPIO[5]

// --- 모드 정의 ---
#define MODE_NONE         0
#define MODE_LED_LEFT     1
#define MODE_LED_RIGHT    2
#define MODE_GPI_TO_GPO   3

void System_init();
void delay(uint32_t t);
void LED_write(uint32_t data);
void LED_leftShift(uint32_t *);
void LED_rightShift(uint32_t *);

int main()
{
    int ledData = 0x01;
    uint32_t status;

    uint32_t prev_switch = 0; // 이전 모드 저장 변수
    uint32_t active_mode = MODE_NONE; // 현재 활성 모드 변수
    
    uint32_t current_switch; // 현재 스위치 상태 변수

    System_init();

    while(1){
        // uart 상시 동작
        status = UART_STATUS;
        if(status & UART_RX_VALID){
            uint32_t rxData = UART_RXDATA & 0xff;
            // [수정] 수신된 데이터(rxData)에 따라 모드 변경
            if (rxData == 'L') {
                active_mode = MODE_LED_LEFT;
                LED_write(ledData); // 모드 변경 시 즉시 반영
            } else if (rxData == 'R') {
                active_mode = MODE_LED_RIGHT;
                LED_write(ledData); // 모드 변경 시 즉시 반영
            } else if (rxData == 'O') {
                active_mode = MODE_GPI_TO_GPO;
                ledData = 0x01;
            } else {
                // 'L', 'R', 'O' 외 다른 문자를 받으면 끔
                active_mode = MODE_NONE;
            }

            // 수신된 데이터를 다시 송신
            while(UART_STATUS & UART_TX_FULL); // 송신 준비 대기
            UART_TXDATA = rxData;
        }

        // 모드 변경 감지
        uint32_t current_switch = MODE_SWITCH_PORT;
        uint32_t new_press = current_switch & ~prev_switch; // 새로 눌린 스위치
        uint32_t new_release = ~current_switch & prev_switch; // 새로 떼어진 스위치
        prev_switch = current_switch; // 이전 모드 업데이트

        // 새로 눌린 스위치가 있으면, 그 스위치로 모드 변경 (우선순위: 7 > 6 > 5)
        if (new_press & SW_LED_LEFT) {
            active_mode = MODE_LED_LEFT;
        } else if (new_press & SW_LED_RIGHT) {
            active_mode = MODE_LED_RIGHT;
        } else if (new_press & SW_GPI_TO_GPO) {
            active_mode = MODE_GPI_TO_GPO;
            ledData = 0x01;
        }

        // 스위치가 떼어졌을 때, 떼어진 스위치가 현재 활성 모드였다면?
        if (new_release & active_mode) {
            // 현재 모드(A)가 꺼졌으므로, 다른 켜져있는 스위치로 모드를 복구
            if (current_switch & SW_LED_LEFT) {
                active_mode = MODE_LED_LEFT;
            } else if (current_switch & SW_LED_RIGHT) {
                active_mode = MODE_LED_RIGHT;
            } else if (current_switch & SW_GPI_TO_GPO) {
                active_mode = MODE_GPI_TO_GPO;
                ledData = 0x01;
            } else {
                active_mode = MODE_NONE; // 켜진 스위치가 아무것도 없으면 기본 모드
                ledData = 0x01;
            }
            
        }

        // active_mode에 따른 동작 수행
        if(active_mode == MODE_LED_LEFT){
            LED_write(ledData);
            delay(200);
            LED_leftShift(&ledData);
        } else if(active_mode == MODE_LED_RIGHT){
            LED_write(ledData);
            delay(200);
            LED_rightShift(&ledData);
        } else if(active_mode == MODE_GPI_TO_GPO){
            uint32_t gpiData = (*(uint32_t *)&GPI_IDR) & 0xff;
            LED_write(gpiData);
        } else {
            // 모든 모드 비활성화 시 LED 끄기
            LED_write(0x00);
        }
    }
    return 0;
}

void System_init(){
    GPO_CR = 0xff;
    GPI_CR = 0xff;
    GPIO_CR = 0x0f;
}

void delay(uint32_t t){
    uint32_t temp = 0;

    for(int i=0; i<t; i++){
        for(int j=0; j<1000 ; j++){
            temp++;
        }
    }
}

void LED_write(uint32_t data){
    GPO_ODR = data;
}

void LED_leftShift(uint32_t *pData){
    *pData = *pData << 1 | *pData >> 7;
}

void LED_rightShift(uint32_t *pData){
    *pData = *pData >> 1 | *pData << 7;
}