#include <ST/iostm32f207zx.h>

        NAME    LCD
        
        PUBLIC LCD_Init
        PUBLIC LCD_Clear
        PUBLIC LCD_MeasureString
        PUBLIC LCD_WriteCharacter
        PUBLIC LCD_WriteImage
        PUBLIC LCD_WritePixel
        PUBLIC LCD_WriteString
        PUBLIC LCD_WriteTemplateImage
        
        SECTION .commands : CONST (2)

CMD_CASET   EQU  0 // Column address set
CMD_COMSCN  EQU  1 // Common scan direction
CMD_DATCTL  EQU  2 // Data format control
CMD_DISCTL  EQU  3 // Display control
CMD_DISINV  EQU  4 // Inverse display
CMD_DISNOR  EQU  5 // Normal display
CMD_DISOFF  EQU  6 // Display off
CMD_DISON   EQU  7 // Display on
CMD_NOP     EQU  8 // NOP instruction
CMD_OSCOFF  EQU  9 // Internal oscillation off
CMD_OSCON   EQU 10 // Internal oscillation on
CMD_PASET   EQU 11 // Page address set
CMD_PWRCTR  EQU 12 // Power control
CMD_RAMWR   EQU 13 // Writing to memory
CMD_SLPIN   EQU 14 // Sleep in
CMD_SLPOUT  EQU 15 // Sleep out
CMD_VOLCTR  EQU 16 // Voltage control

CMD_OpCodes
        DC8 0x15 // CMD_CASET
        DC8 0xbb // CMD_COMSCN
        DC8 0xbc // CMD_DATCTL
        DC8 0xca // CMD_DISCTL
        DC8 0xa7 // CMD_DISINV
        DC8 0xa6 // CMD_DISNOR
        DC8 0xae // CMD_DISOFF
        DC8 0xaf // CMD_DISON
        DC8 0x25 // CMD_NOP
        DC8 0xd2 // CMD_OSCOFF
        DC8 0xd1 // CMD_OSCON
        DC8 0x75 // CMD_PASET
        DC8 0x20 // CMD_PWRCTR
        DC8 0x5c // CMD_RAMWR
        DC8 0x95 // CMD_SLPIN
        DC8 0x94 // CMD_SLPOUT
        DC8 0x81 // CMD_VOLCTR

CMD_Params
        DC8  2 // CMD_CASET
        DC8  1 // CMD_COMSCN
        DC8  3 // CMD_DATCTL
        DC8  3 // CMD_DISCTL
        DC8  0 // CMD_DISINV
        DC8  0 // CMD_DISNOR
        DC8  0 // CMD_DISOFF
        DC8  0 // CMD_DISON
        DC8  0 // CMD_NOP
        DC8  0 // CMD_OSCOFF
        DC8  0 // CMD_OSCON
        DC8  2 // CMD_PASET
        DC8  1 // CMD_PWRCTR
        DC8 -1 // CMD_RAMWR
        DC8  0 // CMD_SLPIN
        DC8  0 // CMD_SLPOUT
        DC8  2 // CMD_VOLCTR

        SECTION .lcd : CODE (2)
        THUMB

/**
 * Initializes the LCD.
 */
LCD_Init
        PUSH {R0, R1, LR}
                
        // Initialize the SPI interface
        BL SPI_Init
        
        // Reset the LCD
        LDR R0, =GPIOE_BSRR
        MOV R1, #(1 << 5+16)
        STR R1, [R0]
        
        // Wait a while
        LDR R0, =1000000
        LCD_Init_Delay1:
            SUBS R0, R0, #1
            BHS LCD_Init_Delay1
        
        // Activate the LCD
        LDR R0, =GPIOE_BSRR
        MOV R1, #(1 << 5)
        STR R1, [R0]
        
        // Wait a while
        LDR R0, =1000000
        LCD_Init_Delay2:
            SUBS R0, R0, #1
            BHS LCD_Init_Delay2
        
        // Send control information for the display
        LDR R0, =CMD_DISCTL
        LDR R1, =(0x00 << 0) | (0x20 << 8) | (0x11 << 16)
        BL LCD_SendCommand
        
        // Enable the LCD's oscillator
        LDR R0, =CMD_OSCON
        BL LCD_SendCommand
        
        // Enable the LCD's voltage regulators
        LDR R0, =CMD_VOLCTR
        LDR R1, =(0x20 << 0) | (0x00 << 8)
        BL LCD_SendCommand
        
        // Bring the LCD out of sleep mode
        LDR R0, =CMD_SLPOUT
        BL LCD_SendCommand
        
        // Set the LCD to invert its colors
        LDR R0, =CMD_DISINV
        BL LCD_SendCommand
        
        // Set the data format for the LCD
        LDR R0, =CMD_DATCTL
        LDR R1, =(0x00 << 0) | (0x00 << 8) | (0x02 << 16)
        BL LCD_SendCommand
        
        // Enable the LCD's voltage regulators
        LDR R0, =CMD_PWRCTR
        LDR R1, =(0x1f << 0)
        BL LCD_SendCommand
        
        // Clear the LCD
        LDR R0, =0xfff
        BL LCD_Clear
        
        // Wait a while
        LDR R0, =1000000
        LCD_Init_Delay3:
            SUBS R0, R0, #1
            BHS LCD_Init_Delay3
        
        // Turn the display on
        LDR R0, =CMD_DISON
        BL LCD_SendCommand
        
        // Turn the backlight on
        LDR R0, =GPIOB_BSRR
        MOV R1, #(1 << 0)
        STR R1, [R0]
        
        POP {R0, R1, PC}
        LTORG
        
/**
 * Clears the LCD to a color.
 * 
 * Inputs:
 * R0 - The color to clear the display to
 */
LCD_Clear
        PUSH {R0, R1, R2, R3, R4, R5, LR}
        
        // Relocate the color, strip any extra bits
        UBFX R2, R0, #0, #12
        
        // Set the page address
        LDR R0, =CMD_PASET
        LDR R1, =(0 << 0) | (131 << 8)
        BL LCD_SendCommand
        
        // Set the column address
        LDR R0, =CMD_CASET
        LDR R1, =(0 << 0) | (131 << 8)
        BL LCD_SendCommand
        
        // Calculate byte 1
        UBFX R3, R2, #4, #8
        ORR R3, R3, #0x100
        
        // Calculate byte 2
        UBFX R4, R2, #0, #4
        UBFX R5, R2, #8, #4
        ORR R4, R5, R4, LSL #4
        ORR R4, R4, #0x100
        
        // Calculate byte 3
        UBFX R5, R2, #0, #8
        ORR R5, R5, #0x100
        
        // Select the LCD
        BL SPI_Select
        
        // Begin the data write
        LDR R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_RAMWR]
        BL SPI_Exchange
        
        // Write the data
        LDR R1, =132*132
        LCD_Clear_Loop:
            // Send byte 1 (RG)
            MOV R0, R3
            BL SPI_Exchange
            
            // Send byte 2 (BR)
            MOV R0, R4
            BL SPI_Exchange

            // Send byte 3 (GB)
            MOV R0, R5
            BL SPI_Exchange
            
            SUBS R1, R1, #2
            BHI LCD_Clear_Loop
        
        // Send a NOP to signal that the write is over
        LDR R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_NOP]
        BL SPI_Exchange
        
        // Deselect the LCD
        BL SPI_Deselect
        
        POP {R0, R1, R2, R3, R4, R5, PC}
        LTORG


/**
 * Measures the dimensions of a string.
 * 
 * Inputs:
 * R4 - Address of font data
 * R5 - Address of string
 * 
 * Outputs:
 * R0 - Width (in pixels) of the string
 * R1 - Height (in pixels) of the string
 */
LCD_MeasureString
        PUSH {R2, R3, R5, LR}
        
        // Initialize string width and height
        LDR R0, =0
        LDR R1, =0
        
        // Measure the size of each character
        LCD_MeasureString_MeasureCharacter:
                // Load the next character in the string, exit on NULL
                LDRB R2, [R5], #1
                CBZ R2, LCD_MeasureString_Done
                
                // Load the address of the glyph for the current character
                LDR R2, [R4, R2, LSL #2]
                
                // Read the height and width of the glyph
                LDRB R3, [R2, #1]
                LDRB R2, [R2, #0]
                
                // Add the glyph width to the string width
                ADD R0, R0, R2
                
                // Set the string height to be the glyph height (if larger)
                CMP R1, R3
                IT LO
                MOVLO R1, R3
                
                B LCD_MeasureString_MeasureCharacter
        LCD_MeasureString_Done:
        
        POP {R2, R3, R5, PC}
        LTORG

/**
 * Writes a character to the LCD.
 * 
 * Inputs:
 * R0 - X position
 * R1 - Y position
 * R2 - Character color
 * R3 - Background color
 * R4 - Address of font data
 * R5 - Character to write
 * 
 * Outputs:
 * R0 - Width of the character that was written
 * R1 - Height of the character that was written
 */
LCD_WriteCharacter
        PUSH {R4, R5, LR}
        
        AND R5, R5, #0x7f
        LDR R4, [R4, R5, LSL #2]
        
        BL LCD_WriteTemplateImage
        
        POP {R4, R5, PC}
        LTORG

/**
 * Writes an image to the LCD.
 * 
 * Inputs:
 * R0 - X position
 * R1 - Y position
 * R2 - Address of image data
 */
LCD_WriteImage
        PUSH {R0, R1, R2, R3, R4, R5, R6, LR}
        
        // Read the image's width and height
        LDRB R5, [R2], #1
        LDRB R6, [R2], #1
        
        // Return immediately if either is 0
        CMP R5, #0
        BEQ LCD_WriteImage_Exit
        
        CMP R6, #0
        BEQ LCD_WriteImage_Exit
        
        // Relocate R0 and R1
        MOV R3, R0
        MOV R4, R1
        
        // Set the LCD's column address
        LDR R0, =CMD_CASET
        UBFX R1, R3, #0, #8
        ORR R1, R1, R1, LSL #8
        ADD R1, R1, R5, LSL #8
        SUB R1, R1, #(1 << 8)
        BL LCD_SendCommand
        
        // Set the LCD's page address
        LDR R0, =CMD_PASET
        UBFX R1, R4, #0, #8
        ORR R1, R1, R1, LSL #8
        ADD R1, R1, R6, LSL #8
        SUB R1, R1, #(1 << 8)
        BL LCD_SendCommand
        
        // Calculate the number of pixels
        MUL R5, R5, R6
        
        // Calculate the number of bytes
        ADD R5, R5, R5, LSL #1
        ADD R5, R5, #1
        LSR R5, R5, #1
        
        // Convert the number of bytes to an end address
        ADD R5, R2, R5
        
        // Select the LCD
        BL SPI_Select
        
        // Begin the data write
        LDR.W R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_RAMWR]
        BL SPI_Exchange
        
        // Write the image data
        LCD_WriteImage_SendData:
            LDRB R0, [R2], #1
            ORR R0, R0, #0x100
            BL SPI_Exchange
            
            CMP R2, R5
            BLO LCD_WriteImage_SendData

        // Send a NOP to signal that the write is over
        LDR.W R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_NOP]
        BL SPI_Exchange
        
        // Deselect the LCD
        BL SPI_Deselect
        
        LCD_WriteImage_Exit:
        POP {R0, R1, R2, R3, R4, R5, R6, PC}
        LTORG


/**
 * Writes a pixel to the LCD.
 * 
 * Inputs:
 * R0 - X position
 * R1 - Y position
 * R2[3:0] - Blue Component
 * R2[7:4] - Green Component
 * R2[11:8] - Red Component
 */
LCD_WritePixel
        PUSH {R0, R1, R3, R4, LR}
        
        // Move R0 and R1 into R3 and R4
        MOV R3, R0
        MOV R4, R1
        
        // Set the page address
        LDR R0, =CMD_PASET
        MOV R1, R4
        ORR R1, R1, R1, LSL #8
        BL LCD_SendCommand
        
        // Set the column address
        LDR R0, =CMD_CASET
        MOV R1, R3
        ORR R1, R1, R1, LSL #8
        BL LCD_SendCommand
        
        // Select the LCD
        BL SPI_Select
        
        // Begin the data write
        LDR.W R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_RAMWR]
        BL SPI_Exchange
        
        // Send byte 1 (RG)
        UBFX R0, R2, #4, #8
        ORR R0, R0, #0x100
        BL SPI_Exchange
        
        // Send byte 2 (B0)
        UBFX R0, R2, #0, #4
        UBFX R1, R2, #8, #4
        ORR R0, R1, R0, LSL #4
        ORR R0, R0, #0x100
        BL SPI_Exchange
        
        // Send byte 3 (00)
        UBFX R0, R2, #0, #8
        ORR R0, R0, #0x100
        BL SPI_Exchange
        
        // Send a NOP to signal that the write is over
        LDR.W R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_NOP]
        BL SPI_Exchange
        
        // Deselect the LCD
        BL SPI_Deselect
        
        POP {R0, R1, R3, R4, PC}
        LTORG
       

/**
 * Writes a string to the LCD using the specified colors.
 * 
 * Inputs:
 * R0 - X position
 * R1 - Y position
 * R2 - String color
 * R3 - Background color
 * R4 - Address of font data
 * R5 - Address of string
 * 
 * Outputs:
 * R0 - Width of the string
 * R1 - Height of the string
 */
LCD_WriteString
        PUSH {R5, R6, R7, R8, R9, R10, LR}
        
        // Initialize the string width and height
        LDR R7, =0
        LDR R8, =0
        
        // Copy the string address into R6
        MOV R6, R5
        
        // Write the characters in the string
        LCD_WriteString_WriteCharacter:
            // Stop if the X position is off-screen
            CMP R0, #132
            BHS LCD_WriteString_Done
            
            // Read the next character in the string
            LDRB R5, [R6], #1
            
            // If the character that was read is 0, then stop
            CBZ R5, LCD_WriteString_Done
            
            // Preserve the X and Y position
            MOV R9, R0
            MOV R10, R1
            
            // Write the character
            BL LCD_WriteCharacter
            
            // Add the returned width and height to the total string width and height
            ADD R7, R7, R0
            
            CMP R8, R1
            IT LO
            MOVLO R8, R1
            
            // Restore the X and Y position, shifting for the next character
            ADD R0, R0, R9
            MOV R1, R10
            
            B LCD_WriteString_WriteCharacter
        LCD_WriteString_Done:
        
        // Return the string width and height
        MOV R0, R7
        MOV R0, R8
        
        POP {R5, R6, R7, R8, R9, R10, PC}
        LTORG

/**
 * Writes a template image to the LCD using the specified colors.
 * 
 * Inputs:
 * R0 - X position
 * R1 - Y position
 * R2 - Foreground color
 * R3 - Background color
 * R4 - Address of image data
 * 
 * Outputs:
 * R0 - Width of the image written
 * R1 - Height of the image written
 */
LCD_WriteTemplateImage
        PUSH {R2, R3, R4, R5, R6, R7, R8, R9, R10, LR}
        
        // Read the image's width and height
        LDRB R5, [R4], #1
        LDRB R6, [R4], #1
        
        // Return immediately if either is 0
        CMP R5, #0
        BEQ LCD_WriteTemplateImage_Exit
        
        CMP R6, #0
        BEQ LCD_WriteTemplateImage_Exit
        
        // Relocate R0 and R1
        MOV R7, R0
        MOV R8, R1
        
        // Sanitize the color inputs
        UBFX R2, R2, #0, #12
        UBFX R3, R3, #0, #12
        
        // Set the LCD's column address
        LDR R0, =CMD_CASET
        UBFX R1, R7, #0, #8
        ORR R1, R1, R1, LSL #8
        ADD R1, R1, R5, LSL #8
        SUB R1, R1, #(1 << 8)
        BL LCD_SendCommand
        
        // Set the LCD's page address
        LDR R0, =CMD_PASET
        UBFX R1, R8, #0, #8
        ORR R1, R1, R1, LSL #8
        ADD R1, R1, R6, LSL #8
        SUB R1, R1, #(1 << 8)
        BL LCD_SendCommand
        
        // Calculate the number of pixels to send
        MUL R9, R5, R6
        
        // Select the LCD
        BL SPI_Select
        
        // Begin the data write
        LDR.W R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_RAMWR]
        BL SPI_Exchange
        
        LDR R10, =0
        
        // Encode and send the image data
        LCD_WriteTemplateImage_SendData:
            // Read the next byte of data if necessary
            CMP R10, #0
            ITT EQ
            LDRBEQ R1, [R4], #1
            LDREQ R10, =(1 << 7)
            
            // Select the color to use for the first pixel
            TST R1, R10
            ITE EQ
            MOVEQ R7, R3 // EQ/0 - Use background color
            MOVNE R7, R2 // NE/1 - Use foreground color
            LSR R10, R10, #1
            
            // Select the color to use for the second pixel
            TST R1, R10
            ITE EQ
            MOVEQ R8, R3 // EQ/0 - Use background color
            MOVNE R8, R2 // NE/1 - Use foreground color
            LSR R10, R10, #1
            
            // Send the first byte (R1 G1)
            UBFX R0, R7, #4, #8
            ORR R0, R0, #0x100
            BL SPI_Exchange
            
            // Send the second byte (B1 R2)
            UBFX R0, R7, #0, #4
            LSL R0, R0, #4
            ORR R0, R0, R8, LSR #8
            ORR R0, R0, #0x100
            BL SPI_Exchange
            
            // Send the third byte (G2 B2)
            UBFX R0, R8, #0, #8
            ORR R0, R0, #0x100
            BL SPI_Exchange
            
            // Loop if there are more pixels available
            SUBS R9, R9, #2
            BHI LCD_WriteTemplateImage_SendData

        // Send a NOP to signal that the write is over
        LDR.W R0, =CMD_OpCodes
        LDRB R0, [R0, #CMD_NOP]
        BL SPI_Exchange
        
        // Deselect the LCD
        BL SPI_Deselect
        
        LCD_WriteTemplateImage_Exit:
        // Return the width and height of the image
        MOV R0, R5
        MOV R1, R6
        
        POP {R2, R3, R4, R5, R6, R7, R8, R9, R10, PC}
        LTORG

       
/**
 * Sends a command and any associated parameters to the LCD.
 * 
 * Inputs:
 * R0 - The command to send (see the CMD_* constants)
 * R1[7:0] - Parameter 1
 * R1[15:8] - Parameter 2
 * R1[23:16] - Parameter 3
 * R1[31:24] - Parameter 4
 */
LCD_SendCommand
        PUSH {R0, R2, R3, R4, LR}
        
        // Read the opcode of the command
        LDR.W R4, =CMD_OpCodes
        LDRB R2, [R4, R0]
        
        // Read the number of parameters of the command
        LDR.W R4, =CMD_Params
        LDRB R3, [R4, R0]
        
        // Select the LCD
        BL SPI_Select
        
        // Send the command
        MOV R0, R2
        BL SPI_Exchange
        
        // Send parameter 1 (if required)
        CMP R3, #1
        BLO LCD_SendCommand_SentParams
        
        UBFX R0, R1, #0, #8
        ORR R0, R0, #0x100
        BL SPI_Exchange
        
        // Send parameter 2 (if required)
        CMP R3, #2
        BLO LCD_SendCommand_SentParams
        
        UBFX R0, R1, #8, #8
        ORR R0, R0, #0x100
        BL SPI_Exchange
        
        // Send parameter 3 (if required)
        CMP R3, #3
        BLO LCD_SendCommand_SentParams
        
        UBFX R0, R1, #16, #8
        ORR R0, R0, #0x100
        BL SPI_Exchange
        
        // Send parameter 4 (none require this, but just in case)
        CMP R3, #4
        BLO LCD_SendCommand_SentParams
        
        UBFX R0, R1, #24, #8
        ORR R0, R0, #0x100
        BL SPI_Exchange
        
        LCD_SendCommand_SentParams:
        
        // Deselect the LCD
        BL SPI_Deselect
        
        POP {R0, R2, R3, R4, PC}
        LTORG
        
        
/**
 * Initializes the SPI interface.
 * 
 * Steps:
 * - Enable GPIO ports A and B
 * - Configure pins that are used (A4, A5, A6, B0, and B1)
 */
SPI_Init
        PUSH {R0, R1}
        
        // Enable GPIO ports A, B, and E
        LDR.W R0, =RCC_AHB1ENR
        LDR R1, [R0]
        ORR R1, R1, #(1 << 0) | (1 << 1) | (1 << 4)
        STR R1, [R0]
        
        // Set A4 (MOSI) and A5 (SCK) to output; set A6 (MISO) to input
        LDR.W R0, =GPIOA_MODER
        LDR R1, [R0]
        BIC R1, R1, #(3 << 8) | (3 << 10) | (3 << 12)
        ORR R1, R1, #(1 << 8) | (1 << 10) | (0 << 12)
        STR R1, [R0]
        
        // Set B0 (BL) and B1 (CS) to output
        LDR.W R0, =GPIOB_MODER
        LDR R1, [R0]
        BIC R1, R1, #(3 << 0) | (3 << 2)
        ORR R1, R1, #(1 << 0) | (1 << 2)
        STR R1, [R0]
        
        // Set E5 (LCD_RST) to output
        LDR.W R0, =GPIOE_MODER
        LDR R1, [R0]
        BIC R1, R1, #(3 << 10)
        ORR R1, R1, #(1 << 10)
        STR R1, [R0]
        
        // Set A4 (MOSI), A5 (SCK), and A6 (MISO) to operate at 50MHz
        LDR.W R0, =GPIOA_OSPEEDR
        LDR R1, [R0]
        BIC R1, R1, #(3 << 8) | (3 << 10) | (3 << 12)
        ORR R1, R1, #(2 << 8) | (2 << 10) | (2 << 12)
        STR R1, [R0]
        
        // Set B0 (BL) and B1 (CS) to operate at 50MHz
        LDR.W R0, =GPIOB_OSPEEDR
        LDR R1, [R0]
        BIC R1, R1, #(3 << 0) | (3 << 2)
        ORR R1, R1, #(2 << 0) | (2 << 2)
        STR R1, [R0]
        
        // Set E5 (LCD_RST) to operate at 50MHz
        LDR.W R0, =GPIOE_OSPEEDR
        LDR R1, [R0]
        BIC R1, R1, #(3 << 10)
        ORR R1, R1, #(2 << 10)
        STR R1, [R0]
        
        // Disable PU/PD on A4 (MOSI) and A5 (SCK); Enable PU on A6 (MISO)
        LDR.W R0, =GPIOA_PUPDR
        LDR R1, [R0]
        BIC R1, R1, #(3 << 8) | (3 << 10) | (3 << 12)
        ORR R1, R1, #(0 << 8) | (0 << 10) | (1 << 12)
        STR R1, [R0]
        
        // Disable PU/PD on B0 (BL) and B1 (CS)
        LDR.W R0, =GPIOB_PUPDR
        LDR R1, [R0]
        BIC R1, R1, #(3 << 0) | (3 << 2)
        ORR R1, R1, #(0 << 0) | (0 << 2)
        STR R1, [R0]
        
        // Disable PU/PD on E5 (LCD_RST)
        LDR.W R0, =GPIOE_PUPDR
        LDR R1, [R0]
        BIC R1, R1, #(3 << 10)
        ORR R1, R1, #(0 << 10)
        STR R1, [R0]
        
        // Set pin A5 (SCK) high
        LDR.W R0, =GPIOA_BSRR
        LDR R1, =(1 << 5)
        STR R1, [R0]
        
        // Set pin B0 (BL) low and pin B1 (CS) high
        LDR.W R0, =GPIOB_BSRR
        LDR R1, =(1 << 0+16) | (1 << 1)
        STR R1, [R0]
        
        // Set pin E5 (LCD_RST) high
        LDR.W R0, =GPIOE_BSRR
        LDR R1, =(1 << 5)
        STR R1, [R0]
        
        
        
        // Return to the caller
        POP {R0, R1}
        BX LR
        LTORG
        
/**
 * Deselects the LCD.
 */
SPI_Deselect
        PUSH {R0, R1}
        LDR.W R0, =GPIOB_BSRR
        MOV R1, #(1 << 1)
        STR R1, [R0]
        POP {R0, R1}
        BX LR
        LTORG
        
        
/**
 * Selects the LCD.
 */
SPI_Select
        PUSH {R0, R1}
        LDR.W R0, =GPIOB_BSRR
        MOV R1, #(1 << 1+16)
        STR R1, [R0]
        POP {R0, R1}
        BX LR
        LTORG
   
   
/**
 * Exchanges a 9-bit value via the SPI interface.
 * 
 * Inputs:
 * R0 - The 9-bit value to be sent via the SPI interface.
 * 
 * Outputs:
 * R0 - The 9-bit value that was received via the SPI interface.
 */
SPI_Exchange
        PUSH {R1, R2, R3, R4}
        
        // Preload SFR addresses
        LDR.W R2, =GPIOA_BSRR
        LDR.W R3, =GPIOA_IDR
        
        // Loop through every bit of the input, starting with bit 8
        MOV R1, #(1 << 8)
        SPI_Exchange_Loop:
            // Set A5 (SCK) low
            MOV R4, #(1 << 5+16)
            STR R4, [R2]
            
            // Test the current bit in the input
            TST R0, R1
            ITE EQ
            MOVEQ R4, #(1 << 4+16) // EQ/0 - set A4 (MOSI) low
            MOVNE R4, #(1 << 4) // NE/1 - set A4 (MOSI) high
            STR R4, [R2]
            
            // Wait a while
            
            MOV R4, #0
            SPI_Exchange_Wait1:
                SUBS R4, R4, #1
                BHI SPI_Exchange_Wait1
                
            
            // Set A5 (SCK) high
            MOV R4, #(1 << 5)
            STR R4, [R2]
            
            // Read the bit from MISO into R0
            LDR R4, [R3]
            TST R4, #(1 << 6)
            ITE EQ
            BICEQ R0, R0, R1 // EQ/0 - clear the bit
            ORRNE R0, R0, R1 // NE/1 - set the bit
            
            
            // Wait a while
            MOV R4, #0
            SPI_Exchange_Wait2:
                SUBS R4, R4, #1
                BHI SPI_Exchange_Wait2
                
            
            // Send the next less-significant bit if there is one
            LSRS R1, R1, #1
            BNE SPI_Exchange_Loop
        
        POP {R1, R2, R3, R4}
        BX LR
        LTORG
        
        END
