#include <ST/iostm32f207zx.h>

        NAME Buzzer

        PUBLIC BUZZER_Init
        PUBLIC BUZZER_MakeSound

        SECTION .buzzer : CODE (2)
        THUMB
        
BUZZER_Init
        PUSH {R0, R1, R2}
        
        // Enable the GPIO port A
        LDR.W R0, =RCC_AHB1ENR
        LDR R1, [R0]
        ORR R1, R1, #(1<<0)
        STR R1, [R0]
        
        // Set pins on Port A as outputs
        LDR.W R0, =GPIOA_MODER
        LDR R1, [R0]
        BIC R1, R1, #(3 << 20) 
        ORR R1, R1, #(1 << 20)
        STR R1, [R0]
        
        // Set speed of GPIO 2MHz
        LDR.W R0, =GPIOA_OSPEEDR
        LDR R1, [R0] 
        ORR R1, R1, #(0 << 20)
        STR R1, [R0]
        
        POP {R0, R1, R2}
        BX LR
        
BUZZER_MakeSound
        PUSH {R0, R1, R2, R3}
        
        MOV R0, R5
        LDR R2, =GPIOA_BSRR
        LDR R3, [R2]
        SquareWave: 
            //Set bit high
            LDR R2, =GPIOA_BSRR
            LDR R3, [R2]
            ORR R3, R3, #(1 << 10)
            STR R3, [R2]
            
            // Wait a while
            MOV R1, R4
            Buzzer_Delay1:
                SUBS R1, R1, #1
                BHS Buzzer_Delay1
            
            //Set bit low
            LDR R2, =GPIOA_BSRR
            LDR R3, [R2]
            ORR R3, R3, #(1 << 26)
            STR R3, [R2]
            
            MOV R1, R4
            Buzzer_Delay2:
                SUBS R1, R1, #1
                BHS Buzzer_Delay2
                
            SUBS R0, R0, #1
            BHS SquareWave
        
        POP {R0, R1, R2, R3}
        BX LR
        
        END