#include <ST/iostm32f207zx.h>
#include "lcd.h"

#define CHARACTER_WIDTH 10
#define CHARACTER_HEIGHT 20
#define OBSTACLE_WIDTH 10
#define OBSTACLE_HEIGHT 10
#define CHARACTER_COLOR 0xf00
#define CHARACTER_CLEAR_COLOR 0xfff
#define OBSTACLE_COLOR 0x000
#define OBSTACLE_CLEAR_COLOR 0xfff
#define GROUND_CLEAR_COLOR 0xfff
#define GROUND_COLOR 0x000
#define CLOUD_COLOR 0x000

        NAME    GAME
        
        PUBLIC GAME_Draw_Character
        PUBLIC GAME_Set_Jumping
        PUBLIC GAME_Init
        PUBLIC GAME_Update
        
        EXTERN IMG_Dinosaur1
        EXTERN IMG_Dinosaur2
        EXTERN IMG_Dinosaur3
        EXTERN IMG_Bird1
        EXTERN IMG_Bird2
        EXTERN IMG_Bird3
        EXTERN IMG_Cactus
        EXTERN IMG_Ground
        EXTERN IMG_Cloud
        EXTERN LCD_WriteString
        EXTERN FONT_13
        EXTERN STR_Timer
        EXTERN STR_WhiteSpace
        EXTERN BUZZER_Init
        EXTERN BUZZER_MakeSound
 
        SECTION .game : CODE (2)
        THUMB
        
GAME_Set_Jumping
        PUSH {LR}
        // First bit specifies were in jump state.
        ORR R12, R12, #1
        // Initialize the velocity 
        MOV R2, #7
        POP {PC}
        
GAME_End_Jumping
        PUSH {LR}
        // Reset position
        MOV R1, #2
        // Turn off the jump state bit
        BIC R12, R12, #1
        POP {PC}   

/*
 * Draws the static part of the ground, which is just a line
 */
GAME_Draw_Ground_Init
        PUSH {R0-R12, LR}
        
        MOV R0, #0
        MOV R1, #121
        
        MOV R0, #0
        GAME_Draw_Ground_Init_Loop_1:
       
        MOV R2, #GROUND_COLOR
        BL LCD_WritePixel
        ADD R0, R0, #1
        
        CMP R0, #130
        BLT GAME_Draw_Ground_Init_Loop_1

        POP {R0-R12, PC} 
      
GAME_Init
        PUSH {LR}
        // Init the timer count
        LDR R0, =TIM2_CNT
        LDR R1, [R0]
        EOR R1, R1, R1
        STR R1, [R0] 
        
        // Draw the static stuff like clouds and the ground
        BL GAME_Draw_Ground_Init
        
        MOV R0, #15
        MOV R1, #35
        MOV R2, #CLOUD_COLOR
        BL GAME_Draw_Cloud
        
        MOV R0, #75
        MOV R1, #65
        MOV R2, #CLOUD_COLOR
        BL GAME_Draw_Cloud
        
        // Init the games state
        MOV R0, #35 // x-coord of player
        MOV R1, #2  // y-coord of player
        MOV R2, #0  // y-coord of velcoity for the player
        MOV R3, #90 // x-coord of obstacle
        MOV R4, #2  // y-coord of obstacle
        MOV R9, #0  // Decides whether to draw the cactus or the bird
        MOV R10, #1 // Decides which animation to use
        MOV R11, #0 // Is used to move the ground
        MOV R12, #0 // Is used to check if in jump state
        
        POP {PC}
        
GAME_Update
        PUSH {LR}
        
        // Clear the ground (moves each frame)
        PUSH {R2}
        MOV R2, #GROUND_CLEAR_COLOR
        BL GAME_Draw_Ground
        POP {R2}
        
        // Clear the obstacle
        PUSH {R2} 
        MOV R2, #OBSTACLE_CLEAR_COLOR
        BL GAME_Draw_Obstacle
        POP {R2}
                
        // Clear the character
        PUSH {R2}
        MOV R2, #CHARACTER_CLEAR_COLOR
        BL GAME_Draw_Character
        POP {R2}
        
        // Update the position of the obstacle
        PUSH {R0, R1, R2}
        LDR R0, =TIM2_CNT
        LDR R0, [R0]
        MOV R2, #1000
        UDIV R0, R0, R2
        LDR R1, =STR_Timer  
        
        SUB R3, R3, #3
        
        CMP R0, #10
        IT GT
        SUBGT R3, R3, #2
        
        CMP R0, #20
        IT GT
        SUBGT R3, R3, #2
        POP {R0, R1, R2}
        
        // Check if the obstacle is off screen
        CMP R3, #-10
        IT LT
        MOVLT R3, #132
        IT LT
        ADDLT R9, R9, #1
        
        // Check if the jump bit is on
        PUSH {R0}
        AND R0, R12, #0x1
        CMP R0, #0x1
        POP {R0}
        // Skip code to allow player to jump if they are jumping
        BEQ GAME_Update_Jump_State
        
        // The player is not in jump state if here
        GAME_Update_Default_State:
          // Check to see if jump button was pressed
          PUSH {R0, R1}
          LDR R0, =GPIOG_IDR
          LDR R1, [R0]
          TST R1, #0x40
          POP {R0, R1}
          IT EQ
          // Move to jump state if it was pressed
          BLEQ GAME_Set_Jumping
        
          B GAME_Update_End

        // Player in jump state if here
        GAME_Update_Jump_State:
        
          // Update the position and velocity
          ADD R1, R1, R2
          SUB R2, R2, #1
          
          // Check if should stop jumping
          CMP R1, #2
          IT LT
          BLLT GAME_End_Jumping

          B GAME_Update_End
        
        GAME_Update_End:
        
        // Go to next animation
        ADD R10, R10, #1
        CMP R10, #7
        IT EQ
        MOVEQ R10, #1
        
        // Move the ground a little bit
        SUB R11, R11, #3
        CMP R11, #-130
        IT LT
        MOVLT R11, #0
        
        // Draw the ground
        PUSH {R2}
        MOV R2, #GROUND_COLOR
        BL GAME_Draw_Ground
        POP {R2}
        
        // Draw the obstacle
        PUSH {R2}
        MOV R2, #OBSTACLE_COLOR
        BL GAME_Draw_Obstacle
        POP {R2}
        
        // Draw the caracter
        PUSH {R2}
        MOV R2, #CHARACTER_COLOR
        BL GAME_Draw_Character
        POP {R2}
        
        // Draw the game time
        BL GAME_Draw_Time
        
        // Reset the game state if there was a collision
        BL GAME_Check_For_Overlap
        
        POP {PC}

/*
 * R3 = X-coord, R4 = Y-coord 
 * R2 must be set to the obstacles color
 */
GAME_Draw_Obstacle
        PUSH {R0, R1, R3, R4, R5, R6, LR}
        
        // The LSB of R9 decides whether to draw the cactus or the bird
        TST R9, #1
        BEQ GAME_Draw_Obstacle_Load_Bird
        // Load in the cactus image
        LDR R6, =IMG_Cactus
        B GAME_Draw_Obstacle_Done_With_Load
GAME_Draw_Obstacle_Load_Bird
        // Load in the bird image
        // Figure out which sprite to use for animation
        CMP R10, #1
        IT EQ
        LDREQ R6, =IMG_Bird1
        CMP R10, #2
        IT EQ
        LDREQ R6, =IMG_Bird2
        CMP R10, #3
        IT EQ
        LDREQ R6, =IMG_Bird3
        CMP R10, #4
        IT EQ
        LDREQ R6, =IMG_Bird1
        CMP R10, #5
        IT EQ
        LDREQ R6, =IMG_Bird2
        CMP R10, #6
        IT EQ
        LDREQ R6, =IMG_Bird3 
GAME_Draw_Obstacle_Done_With_Load
        
        MOV R0, R3
        MOV R1, R4
        
        ADD R1, R1, #100
        
       // Loop through all the pixels and draw out the player
        MOV R4, #0
        GAME_Draw_Obstacle_Loop_1:
          MOV R5, #0
          GAME_Draw_Obstacle_Loop_2:
          
          LDRB R3, [R6]
          ADD R6, R6, #1
          
          ADD R0, R0, R5
          ADD R1, R1, R4
          
          CMP R3, #1
          IT EQ
          BLEQ LCD_WritePixel
          
          SUB R0, R0, R5
          SUB R1, R1, R4

          ADD R5, R5, #1
          CMP R5, #21
          BLT GAME_Draw_Obstacle_Loop_2
        ADD R4, R4, #1
        CMP R4, #18
        BLT GAME_Draw_Obstacle_Loop_1
        
        POP {R0, R1, R3, R4, R5, R6, PC}

/*
 * R0 = X-coord, R1 = Y-coord
 * R2 must be set to the characters color
 */
GAME_Draw_Character
        PUSH {R0, R1, R2, R3, R4, R5, R6, LR}
        
        // Figure out which sprite to use for animation
        CMP R10, #1
        IT EQ
        LDREQ R6, =IMG_Dinosaur2
        CMP R10, #2
        IT EQ
        LDREQ R6, =IMG_Dinosaur2
        CMP R10, #3
        IT EQ
        LDREQ R6, =IMG_Dinosaur2
        CMP R10, #4
        IT EQ
        LDREQ R6, =IMG_Dinosaur3
        CMP R10, #5
        IT EQ
        LDREQ R6, =IMG_Dinosaur3
        CMP R10, #6
        IT EQ
        LDREQ R6, =IMG_Dinosaur3
        TST R12, #1
        IT NE
        LDRNE R6, =IMG_Dinosaur1
        
        MOV R4, #120
        SUB R1, R4, R1
        SUB R1, R1, #15
        
        // Loop through all the pixels and draw out the player
        MOV R4, #0
        GAME_Draw_Character_Loop_1:
          MOV R5, #0
          GAME_Draw_Character_Loop_2:
          
          LDRB R3, [R6]
          ADD R6, R6, #1
          
          ADD R0, R0, R5
          ADD R1, R1, R4
          
          CMP R3, #1
          IT EQ
          BLEQ LCD_WritePixel
          
          SUB R0, R0, R5
          SUB R1, R1, R4

          ADD R5, R5, #1
          CMP R5, #15
          BLT GAME_Draw_Character_Loop_2
        ADD R4, R4, #1
        CMP R4, #18
        BLT GAME_Draw_Character_Loop_1
        
        SUB R1, R1, #18
        
        POP {R0, R1, R2, R3, R4, R5, R6, PC}

/*
 * Draws the moving part of the ground
 */ 
GAME_Draw_Ground
        PUSH {R0-R12, LR}
        
        MOV R0, R11
        MOV R1, #123
        
        GAME_Draw_Ground_Loop_3:
        LDR R6, =IMG_Ground
        
        // Loop through all the pixels in the sprite and draw the ones that are on
        MOV R4, #0
        GAME_Draw_Ground_Loop_1:
          MOV R5, #0
          GAME_Draw_Ground_Loop_2:
          
          LDRB R3, [R6]
          ADD R6, R6, #1
          
          ADD R0, R0, R5
          ADD R1, R1, R4
          
          CMP R3, #1
          IT EQ
          BLEQ LCD_WritePixel
          
          SUB R0, R0, R5
          SUB R1, R1, R4

          ADD R5, R5, #1
          CMP R5, #42
          BLT GAME_Draw_Ground_Loop_2
        ADD R4, R4, #1
        CMP R4, #3
        BLT GAME_Draw_Ground_Loop_1
        
        ADD R0, R0, #42
        CMP R0, #130
        BLT GAME_Draw_Ground_Loop_3

        POP {R0-R12, PC}

/*
 * R0 - x-coord of cloud
 * R1 - y-coord of cloud
 * R2 - color of the cloud
 */
GAME_Draw_Cloud
        PUSH {R0-R12, LR}
        
        LDR R6, =IMG_Cloud
                                
        MOV R4, #0
        GAME_Draw_Cloud_Loop_1:
          MOV R5, #0
          GAME_Draw_Cloud_Loop_2:
          
          LDRB R3, [R6]
          ADD R6, R6, #1
          
          ADD R0, R0, R5
          ADD R1, R1, R4
          
          CMP R3, #1
          IT EQ
          BLEQ LCD_WritePixel
          
          SUB R0, R0, R5
          SUB R1, R1, R4

          ADD R5, R5, #1
          CMP R5, #47
          BLT GAME_Draw_Cloud_Loop_2
        ADD R4, R4, #1
        CMP R4, #13
        BLT GAME_Draw_Cloud_Loop_1
        
        POP {R0-R12, PC}

/*
 * Checks to see if the player and obstacle drawing routines drew any overlapping pixels
 * If so it resests the game
 */
GAME_Check_For_Overlap
        PUSH {R0-R12, LR}
        
        /*
          R0 - player x
          R1 - player y
          R3 - obstacle x
          R4 - obstacle y
        */

        LDR R11, =IMG_Dinosaur1
        LDR R12, =IMG_Bird2
        
        ADD R0, R0, #-6
        ADD R1, R1, #18
        ADD R4, R4, #18
        
        MOV R6, #0
        GAME_Check_For_Overlap_Loop_1:
          MOV R7, #0
          GAME_Check_For_Overlap_Loop_2:
          
          SUB R0, R0, R7
          SUB R1, R1, R6
          
          LDRB R5, [R11]
          CMP R5, #1
          BNE GAME_Check_for_Overlap_No_Overlap
          
          // Check if (R0, R1) is a pixel for the bird
          SUB R9, R3, R0
          SUB R10, R4, R1   
          
          CMP R9, #0
          BLT GAME_Check_for_Overlap_No_Overlap
          
          CMP R9, #21
          BGE GAME_Check_for_Overlap_No_Overlap
          
          CMP R10, #0
          BLT GAME_Check_for_Overlap_No_Overlap
          
          CMP R10, #18
          BGE GAME_Check_for_Overlap_No_Overlap
          
          MOV R5, #21
          MUL R10, R10, R5
          ADD R10, R10, R9
          
          ADD R12, R12, R10
          LDRB R5, [R12]
          SUB R12, R12, R10
          CMP R5, #1
          BNE GAME_Check_for_Overlap_No_Overlap
          
          // A collision happened
          // Make the fail noise
          LDR R5, =64
          LDR R4, =18500
          BL BUZZER_MakeSound
          LDR R4, =20500
          BL BUZZER_MakeSound
          LDR R5, =128
          LDR R4, =22500
          BL BUZZER_MakeSound
          
          B GAME_Check_for_Overlap_Found_Collision
          
          GAME_Check_for_Overlap_No_Overlap:
                    
          ADD R0, R0, R7
          ADD R1, R1, R6
          ADD R11, R11, #1

          ADD R7, R7, #1
          CMP R7, #15
          BLT GAME_Check_For_Overlap_Loop_2
        ADD R6, R6, #1
        CMP R6, #18
        BLT GAME_Check_For_Overlap_Loop_1
                
        POP {R0-R12, PC}
        
        GAME_Check_for_Overlap_Found_Collision:
        POP {R0-R12, LR}
        PUSH {LR}
        
        PUSH {R2} 
        MOV R2, #OBSTACLE_CLEAR_COLOR
        BL GAME_Draw_Obstacle
        POP {R2}
                
        PUSH {R2}
        MOV R2, #CHARACTER_CLEAR_COLOR
        BL GAME_Draw_Character
        POP {R2}
        
        BL GAME_Init
        POP {PC}
 
/*
 * Draws the curent time of the game
 */
GAME_Draw_Time        
        PUSH {R0-R12, LR}
        
        LDR R0, =TIM2_CNT
        LDR R0, [R0]
        MOV R2, #1000
        UDIV R0, R0, R2
        LDR R1, =STR_Timer  
        
        LDR R2, =10
        MOV R5, #0
        
        // First convert it to decimal
        GAME_Draw_Time_Loop1:
                // R0 mod 10 = R0 - ((R0 / 10) * 10)
                UDIV R3, R0, R2    
                MUL R4, R3, R2
                SUB R4, R0, R4

                CMP R4, #10
                ITE GE
                ADDGE R4, R4, #0x37 // Its a letter
                ADDLT R4, R4, #0x30 // Its a number

                ADD R5, R5, #1
                PUSH {R4}

                MOV R0, R3
                CMP R3, #0
                BNE GAME_Draw_Time_Loop1
      
        // Next store all the characters into the string
        GAME_Draw_Time_Loop2:
                POP {R3}
                STRB R3, [R1], #1
                SUB R5, R5, #1
                CMP R5, #0
                BNE GAME_Draw_Time_Loop2
        
        MOV R3, #0
        STRB R3, [R1]
        
        // Clear the previously drawn string
        MOV R0, #10
        MOV R1, #10
        MOV R2, #0x000
        MOV R3, #0xfff
        LDR R4, =FONT_13
        LDR R5, =STR_WhiteSpace
        BL LCD_WriteString
        
        // Draw the new string
        MOV R0, #10
        MOV R1, #10
        MOV R2, #0x000
        MOV R3, #0xfff
        LDR R4, =FONT_13
        LDR R5, =STR_Timer
        BL LCD_WriteString
                
        POP {R0-R12, PC}

        END