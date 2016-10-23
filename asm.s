#include <ST/iostm32f207zx.h>
#include "lcd.h"
#include "game.h"

        NAME    main
        
        PUBLIC __iar_data_init3
        PUBLIC __iar_program_start
        PUBLIC STR_Timer
        PUBLIC STR_WhiteSpace
        
        EXTERN FONT_13
        EXTERN BUZZER_Init
        EXTERN BUZZER_MakeSound
        
        SECTION .stack : DATA (8)

        DS8 0x100
stack_base
        
        SECTION .intvec : CODE (6)
        THUMB
        
        DATA
__vector_table
        DC32 stack_base                 ; 0 (Initial Stack Pointer)
        DC32 __iar_program_start        ; 1 (Reset)
        DC32 0                          ; 2 (NMI)
        DC32 0                          ; 3 (Hard Fault)
        DC32 0                          ; 4 (Memory Management Fault)
        DC32 0                          ; 5 (Bus Fault)
        DC32 0                          ; 6 (Usage Fault)
        DC32 0                          ; 7 (Reserved)
        DC32 0                          ; 8 (Reserved)
        DC32 0                          ; 9 (Reserved)
        DC32 0                          ; 10 (Reserved)
        DC32 0                          ; 11 (SVCall)
        DC32 0                          ; 12 (Reserved)
        DC32 0                          ; 13 (Reserved)
        DC32 0                          ; 14 (PendSV)
        DC32 0                          ; 15 (Systick)
        
        THUMB
__iar_program_start
        B       main

        SECTION .vars : DATA (2)
        DATA
        
STR_Timer
        DC8 "XXXXXXXX"
        
STR_WhiteSpace
        DC8 "XXXXXXXX"
        
        SECTION .text : CODE (2)
        THUMB

__iar_data_init3
        BX LR

main    
        // Init the buzzer
        BL BUZZER_Init

        // Init the timer
        LDR R0, =RCC_APB1ENR
        LDR R1, [R0]
        ORR R1, R1, #(1<<0) 
        STR R1, [R0]
                        
        LDR R0, =TIM2_PSC 
        LDR R1, [R0]
        MOV R1, #0x3e80
        STR R1, [R0]
        
        LDR R0, =TIM2_EGR 
        LDR R1, [R0]
        ORR R1, R1, #(1<<0)
        STR R1, [R0]
        
        LDR R0, =TIM2_CR1
        LDR R1, [R0]
        ORR R1, R1, #0x00000001        
        STR R1, [R0]

        // Init the user button
        // Enable the GPIO ports G
        LDR R0, =RCC_AHB1ENR
        LDR R1, [R0]
        ORR R1, R1, #(1<<6)
        STR R1, [R0]
        
        // Set pins on Port G as inputs
        LDR.W R0, =GPIOG_MODER
        LDR R1, [R0]
        BIC R1, R1, #(3 << 12) 
        ORR R1, R1, #(0 << 12)
        STR R1, [R0]
        
        // Fill whitespace string with a bunch of spaces
        LDR R0, =STR_WhiteSpace
        LDR R1, =0x20202020
        STR R1, [R0], #4
        LDR R1, =0
        STR R1, [R0], #4
    
        // Init LCD and Game
        BL LCD_Init  
        BL GAME_Init

        // Loop forever for the game
        game_loop:
                BL GAME_Update      
                B game_loop
        
        END
