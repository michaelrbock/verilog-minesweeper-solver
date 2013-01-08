Verilog Minesweeper Solver.
==========================

A Minesweeper AI written in Verilog HDL.

Abstract:
The goal of our end of the year project was to implement an automated version of the game, Minesweeper. 
We implemented a number board generation algorithm, tile cascading, and an artificial intelligence system that could flag mines and solve the game. 
In order to implement this, we used the hardware description language Verilog and simulated our design using ModelSim10.

Quick Start Guide:
1. Start Modelsim
2. Create new project
3. Add existing Files: minesweeper_final.v & minesweeper_tb.v
4. Compile > Compile All
5. Simulate > Start Simulation, choose minesweeper_tb (Enable optimization OFF)
5. run at least 2000000ns
6. Boards and result are printed to Modelsim console
7. To set a different board, open minesweeper_final.v: set mine_row_[0 to 7] to preferred board (lines 52-59), set num_mines on line 248.
8. Save, compile, re-start simulation, run.
