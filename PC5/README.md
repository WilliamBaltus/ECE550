# Project Checkpoint 4: Processor
Billy Toth (wrt10)<br>
William Baltus (wjb40)<br>
ECE 550<br>
Fall 2024 

## Processor.v
The Processor file is the central piece to this project that handles the coordination of all of the components as well as the inputs from skeleton, imem, and dmem. The process starts by going to the PC module to get the address of what instruction we need to run. Then, we using that address to get the instruction from the IMEM. After getting the instruction we pass the instruction to the Control module which gives us a series of signals that will turn on or off the other modules in our processor as well as decided which operation the ALU will run. From here the individual components of the processor will run depending on whether the signals are turned on or off updating the register, the dmem, and other operations. 

## pc.v
PC is simply a register file that we can update or reset as the program progresses. 

## Control.v
Controls function is to take in the opcode provided by the skeleton and generate the necessary aluopcode to decide which operation the alu will run as well as the data control signals. These signals were Rwe, Rdst, ALUinB, DMwe, and Rwd which we discussed in class. Depending on the opcode we recieved each signal was assigned a value of 0 or 1 so that the processor would operate as expected for each operation. 

## Clocks (freq_div_by2.v and freq_div_by4.v)
We wrote two clock splits a divide by 2 and a divide by 4. This makes the clock time periods go from lasting one original clock cycle to two or 4 original clock cycles. Additionally, there is functionality to reset the clock cycle when needed. 

## IMEM
This is the Instruction Memory for our project that is controlled by the skeleton. Our instructions are stored here that will be run through when the processor is running. This file was generated using the process described in The About Testing Processor file provided. 

## DMEM
This is the Data Memory for our project that is controlled by the skeleton. This is where we will be loading data in and saving data to throughout the program (primarily with commands lw and sw). This file was generated using the process described in The About Testing Processor file provided. 

## All other files
All of the other files in this were given to us. This includes skeleton, alu, and dffe.

