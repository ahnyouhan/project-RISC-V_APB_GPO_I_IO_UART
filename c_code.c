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

// --- 모드 스위치 핀 정의 (GPIO[7:4]) ---
#define MODE_SWITCH_PORT  GPIO_IDR
#define MODE_LED_LEFT     (1u << 7)  // GPIO[7]
#define MODE_LED_RIGHT    (1u << 6)  // GPIO[6]
#define MODE_GPI_TO_GPO   (1u << 5)  // GPIO[5]
#define MODE_UART_ECHO    (1u << 4)  // GPIO[4]

void System_init();
void delay(uint32_t t);
void LED_write(uint32_t data);
void LED_leftShift(uint32_t *);
void LED_rightShift(uint32_t *);
// enum{LEFT, RIGHT};

int main()
{
    int ledData = 0x01;
    uint32_t mode;
    uint32_t status;

    System_init();
    while(1){
        mode = MODE_SWITCH_PORT;
        
        if(mode & MODE_LED_LEFT){
            // 왼쪽 시프트 모드
            LED_write(ledData);
            delay(200);
            LED_leftShift(&ledData);
        } else if(mode & MODE_LED_RIGHT){
            // 오른쪽 시프트 모드
            LED_write(ledData);
            delay(200);
            LED_rightShift(&ledData);
        } else if(mode & MODE_GPI_TO_GPO){
            // GPI 입력을 GPO 출력으로 전달
            uint32_t gpiData = (*(uint32_t *)&GPI_IDR) & 0xff;
            LED_write(gpiData);
        } else if(mode & MODE_UART_ECHO){
            // UART 에코 모드
            LED_write(0x00); 
            status = UART_STATUS;
            if(status & UART_RX_VALID){
                uint32_t rxData = UART_RXDATA & 0xff;
                // 수신된 데이터를 다시 송신
                while(UART_STATUS & UART_TX_FULL); // 송신 준비 대기
                UART_TXDATA = rxData;
            }
            ledData = 0x01; // LED 끔
        } else{ // 기본 모드
            LED_write(0x00); // 모든 LED 끔
            ledData = 0x01;
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