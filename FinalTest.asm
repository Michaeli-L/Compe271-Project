.data
# Frame Buffer
frameBuffer:
    .space 0x80000          # Space for the framebuffer (512x512 resolution, 4 bytes per pixel)

# Prompt and Input
promptMessage:
    .asciiz "Please enter your movement (WASD): \n"
inputChar:
    .space 2                # Space for console input (1 char + null terminator)

# Array Data
Array:       .word 0,0,1,1,3,2,3,0,0,0
             .word 0,0,0,1,1,3,3,0,0,1
             .word 0,0,1,1,3,2,3,0,0,0
             .word 0,0,0,1,1,3,3,0,0,1
             .word 0,0,1,1,3,2,3,0,0,0
             .word 0,0,0,1,1,3,3,0,0,1
             .word 0,0,1,1,3,2,3,0,0,0
             .word 0,0,0,1,1,3,3,0,0,1

# Messages
Printf1:     .asciiz "The initial LFSR seed is: "
Newline:     .asciiz "\n"
result_msg:  .asciiz "Result: "
lfsr:        .word 0x55AAFF00

# MIDI Data
notes: .byte 72, 72, 76, 72, 72, 74, 76, 74, 72, 67, 72, 76, 72, 74, 76, 77, 79, 77, 76, 72, 76, 74, 72
num_notes: .word 20           # Number of notes in the melody
duration: .byte 100          # Duration for each note (100 ms)
instrument: .byte 1         # Instrument number
volume: .byte 100            # Volume level

.text
.globl main

main:
   # 1. Display the Array as an 8x10 grid
    li $t0, 0                    # Row index

RowLoop:
    bge $t0, 8, LFSR_Start      # Exit to LFSR if row >= 8

    li $t1, 0                    # Column index for each row

ColumnLoop:
    bge $t1, 10, NextRow         # If column >= 10, go to next row

    # Calculate address of Array[t0][t1]
    mul $t2, $t0, 10             # Row index * 10 (10 elements per row)
    add $t2, $t2, $t1            # Add column index
    sll $t2, $t2, 2              # Multiply by 4 to get byte offset
    la $t3, Array                # Load base address of Array
    add $t3, $t3, $t2            # Calculate address of Array[t0][t1]

    # Load and print the value
    lw $a0, 0($t3)               # Load the value from Array[t0][t1]
    li $v0, 1                    # Print integer syscall
    syscall

    # Increment column index
    addi $t1, $t1, 1
    j ColumnLoop

NextRow:
    # Print a newline after each row
    li $v0, 4
    la $a0, Newline
    syscall

    # Increment row index and repeat
    addi $t0, $t0, 1
    j RowLoop

# 2. LFSR Generation and Printing
LFSR_Start:
    # Print the initial seed message
    li $v0, 4
    la $a0, Printf1
    syscall

    lw $a0, lfsr                  # Load initial LFSR seed

    # Initialize loop counter
    li $t0, 0

LfsrLoop:
    # Print the current LFSR value in hexadecimal
    li $v0, 1                    # Print integer syscall
    move $a0, $a0
    syscall

    # Perform LFSR operations
    srl $t1, $a0, 1               # Shift LFSR right by 1
    sll $t2, $a0, 2              # Prepare feedback bit
    xor $a0, $t1, $t2            # XOR feedback bit with shifted LFSR

    # Print newline after each LFSR result
    li $v0, 4
    la $a0, Newline
    syscall

    # Increment loop counter and repeat for 32 iterations
    addi $t0, $t0, 1
    blt $t0, 2, LfsrLoop         # Loop for 32 iterations

    # Call function1 for further processing
    li $a0, 10              # Load 10 into $a0 (argument for function1)
    jal function1           # Call function1

    move $s0, $v0           # Save the return value from function1 in $s0

    # Print the result from function1
    li $v0, 4               # syscall to print string
    la $a0, result_msg
    syscall

    li $v0, 1               # syscall to print integer
    move $a0, $s0           # Move result to $a0 for printing
    syscall

    # MIDI Playback Code
    la $t0, notes             # Load address of notes array into $t0
    lw $t1, num_notes         # Load number of notes into $t1

    # Load the parameters for MIDI playback
    lb $a1, duration          # Load duration into $a1
    lb $a2, instrument        # Load instrument into $a2
    lb $a3, volume            # Load volume into $a3

note_loop:
    lb $a0, 0($t0)            # Load the current note's pitch into $a0
    li $v0, 31                # Syscall for MIDI playback
    syscall                    # Call syscall to play the note

    addi $t0, $t0, 1          # Move to the next note
    subi $t1, $t1, 1          # Decrement the notes counter
    bgtz $t1, note_loop       # Repeat until all notes are played

#Finished with Passing Grade
    # Jump to graphic 
    jal GameLoop

# Function 1: Adds 5 to the input and calls function2
function1:
    addi $sp, $sp, -8       # Allocate space on stack for $ra and $a0
    sw $ra, 4($sp)          # Save return address
    sw $a0, 0($sp)          # Save the input argument

    addi $a0, $a0, 5        # Add 5 to the argument
    jal function2           # Call function2

    lw $a0, 0($sp)          # Restore the input argument (for clean-up)
    lw $ra, 4($sp)          # Restore return address
    addi $sp, $sp, 8        # Deallocate stack space
    jr $ra                  # Return to caller

# Function 2: Multiplies the input by 2
function2:
    addi $sp, $sp, -4       # Allocate space on stack for $ra
    sw $ra, 0($sp)          # Save return address

    add $v0, $a0, $a0       # $v0 = $a0 * 2 (double the input)

    lw $ra, 0($sp)          # Restore return address
    addi $sp, $sp, 4        # Deallocate stack space
    jr $ra                  # Return to caller

# Function to implement the game loop
GameLoop:
    # Initial position and size of the rectangle
    li $t5, 0              # x-coordinate
    li $t6, 200            # y-coordinate
    li $t7, 10             # width
    li $t8, 10             # height
    li $t0, 0x808080       # color (Grey)
# Draw first rectangle - Red
    li $a0, 0      # x-coordinate
    li $a1, 100    # width
    li $a2, 0      # y-coordinate
    li $a3, 100    # height
    li $t0, 0x00FF0000 # color (Red)
    jal DrawRectangle

# Draw second rectangle - Green
    li $a0, 0      # x-coordinatex
    li $a1, 100    # width
    li $a2, 100    # y-coordinate
    li $a3, 100    # height
    li $t0, 0x00FF00 # color (Green)
    jal DrawRectangle
# Draw third rectangle - Blue
    li $a0, 100    # x-coordinate
    li $a1, 100    # width
    li $a2, 0      # y-coordinate
    li $a3, 100    # height
    li $t0, 0x0000FF # color (Blue)
    jal DrawRectangle

# Draw fourth rectangle - White
    li $a0, 100    # x-coordinate
    li $a1, 100    # width
    li $a2, 100    # y-coordinate
    li $a3, 100    # height
    li $t0, 0xFFFFFF # color (White)
    jal DrawRectangle

# Draw fifth rectangle - Red
    li $a0, 200    # x-coordinate
    li $a1, 100    # width
    li $a2, 0      # y-coordinate
    li $a3, 100    # height
    li $t0, 0xFF0000 # color (Red)
    jal DrawRectangle

# Draw sixth rectangle - Green
    li $a0, 200    # x-coordinate
    li $a1, 100    # width
    li $a2, 100    # y-coordinate
    li $a3, 100    # height
    li $t0, 0x00FF00 # color (Green)
    jal DrawRectangle

# Draw seventh rectangle - Green
    li $a0, 300    # x-coordinate
    li $a1, 100    # width
    li $a2, 0      # y-coordinate
    li $a3, 100    # height
    li $t0, 0x00FF00 # color (Green)
    jal DrawRectangle

# Draw eighth rectangle - Red
    li $a0, 300    # x-coordinate
    li $a1, 100    # width
    li $a2, 100      # y-coordinate
    li $a3, 100    # height
    li $t0, 0x00FF0000 # color (Red)
    jal DrawRectangle
    
# Draw Nighth rectangle - Green
    li $a0, 400    # x-coordinate
    li $a1, 100    # width
    li $a2, 0      # y-coordinate
    li $a3, 100    # height
    li $t0, 0x0000FF # color (Blue)
    jal DrawRectangle
    
# Draw Tenth rectangle - White
    li $a0, 400    # x-coordinate
    li $a1, 100    # width
    li $a2, 100      # y-coordinate
    li $a3, 100    # height
    li $t0, 0xFFFFFF # color (White)
    jal DrawRectangle    

# Draw Exit rectangle - White
    li $a0, 500    # x-coordinate
    li $a1, 10    # width
    li $a2, 0      # y-coordinate
    li $a3, 10    # height
    li $t0, 0xFFFFFF # color (White)
    jal DrawRectangle     

gameLoop:
    # Draw rectangle at current position
    move $a0, $t5          # x-coordinate
    move $a1, $t7          # width
    move $a2, $t6          # y-coordinate
    move $a3, $t8          # height
    jal DrawRectangle

    # Print prompt message
    la $a0, promptMessage  # Load address of the prompt message
    li $v0, 4              # Syscall for printing a string
    syscall

    # Wait for user input (W, A, S, D keys)
    li $v0, 8              # Syscall for reading a string
    la $a0, inputChar      # Load address to store the input
    li $a1, 2              # Maximum input length (1 char + null terminator)
    syscall

    # Load the input character
    lb $t9, inputChar

    # Reset color back to grey for drawing
    li $t0, 0x808080       

    # Handle user input for movement
    li $t1, 'w'
    beq $t9, $t1, moveUp
    li $t1, 's'
    beq $t9, $t1, moveDown
    li $t1, 'a'
    beq $t9, $t1, moveLeft
    li $t1, 'd'
    beq $t9, $t1, moveRight
    j gameLoop            # Repeat the game loop

moveUp:
    addi $t6, $t6, -10     # Move up by decreasing y-coordinate
    j gameLoop

moveDown:
    addi $t6, $t6, 10     # Move down by increasing y-coordinate
    j gameLoop

moveLeft:
    addi $t5, $t5, -10     # Move left by decreasing x-coordinate
    j gameLoop

moveRight:
    addi $t5, $t5, 10     # Move right by increasing x-coordinate
    j gameLoop


   
# Exit program
    li $v0, 10
    syscall

# Function to draw a rectangle with a given color
DrawRectangle:
    # $a0 = x-coordinate (left edge)
    # $a1 = width
    # $a2 = y-coordinate (top edge)
    # $a3 = height
    # $t0 = color
    # $t1 = frameBuffer base address
    # $t4 = row width in bytes (0x800)

    la $t1, frameBuffer
    add $a1, $a1, $a0         # Set right boundary x-coordinate
    add $a3, $a3, $a2         # Set bottom boundary y-coordinate
    sll $a0, $a0, 2           # Scale x values to bytes (4 bytes per pixel)
    sll $a1, $a1, 2
    sll $a2, $a2, 11          # Scale y values to bytes (512*4 bytes per row)
    sll $a3, $a3, 11
    addu $t2, $a2, $t1        # Set starting address for top edge
    addu $a3, $a3, $t1        # Set ending address for bottom edge
    addu $a2, $t2, $a0        # Set starting address for current row
    addu $a3, $a3, $a0
    addu $t2, $t2, $a1        # Set ending address for current row
    li $t4, 0x800             # Row width in bytes

rectangleYLoop:
    move $t3, $a2             # Start of current row
rectangleXLoop:
    sw $t0, 0($t3)            # Store color in current pixel
    addiu $t3, $t3, 4         # Move to next pixel
    bne $t3, $t2, rectangleXLoop

    addu $a2, $a2, $t4        # Move to start of next row
    addu $t2, $t2, $t4        # Move to end of next row
    bne $a2, $a3, rectangleYLoop

    jr $ra                    # Return from function

