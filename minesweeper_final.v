// Created by Justin Walz and Michael Bock
// EE201l Final Project, December 2012

`timescale 1ns / 1ps

module minesweeper (clk, start, step, reset);

	// inputs
	input clk, start, step, reset;

	// register's to hold mine locations 
	
	// EXAMPLE 1: 1 Mine, show cascade and basic flagging algorithm --- num_mines = 1;
	/*
	reg [0:7] mine_row_0 = 8'b00000000;
	reg [0:7] mine_row_1 = 8'b01000000;
	reg [0:7] mine_row_2 = 8'b00000000;
	reg [0:7] mine_row_3 = 8'b00000000; 
	reg [0:7] mine_row_4 = 8'b00000000;
	reg [0:7] mine_row_5 = 8'b00000000;
	reg [0:7] mine_row_6 = 8'b00000000;
	reg [0:7] mine_row_7 = 8'b00000000;
	*/
	
	// EXAMPLE 2: Standard Board: Show the Cascading Algorithm --- num_mines = 6;
	/*
	reg [0:7] mine_row_0 = 8'b00010100;
	reg [0:7] mine_row_1 = 8'b00000000;
	reg [0:7] mine_row_2 = 8'b00000100;
	reg [0:7] mine_row_3 = 8'b00001000; 
	reg [0:7] mine_row_4 = 8'b00000000;
	reg [0:7] mine_row_5 = 8'b00000000;
	reg [0:7] mine_row_6 = 8'b10100000;
	reg [0:7] mine_row_7 = 8'b00000000;
	*/
	

	// EXAMPLE 3: NO LARGE CASCADE, THUS 'LAST RESORT' STATE PICKS RANDOM SPOTS, EVENTUALLY LOSES --- num_mines = 8;
	/*
	reg [0:7] mine_row_0 = 8'b00000100;
	reg [0:7] mine_row_1 = 8'b01000100;
	reg [0:7] mine_row_2 = 8'b00100000;
	reg [0:7] mine_row_3 = 8'b00010000; 
	reg [0:7] mine_row_4 = 8'b00000010;
	reg [0:7] mine_row_5 = 8'b00000101;
	reg [0:7] mine_row_6 = 8'b00000000;
	reg [0:7] mine_row_7 = 8'b00000000;
	*/
	
	// EXAMPLE 4: LARGE CLUSTER, CORNER CASE (with complication), and SCATTERED MINES --- num_mines = 10;
	///*
	reg [0:7] mine_row_0 = 8'b00000100;
	reg [0:7] mine_row_1 = 8'b01100000;
	reg [0:7] mine_row_2 = 8'b01010000;
	reg [0:7] mine_row_3 = 8'b00010000; 
	reg [0:7] mine_row_4 = 8'b00000010;
	reg [0:7] mine_row_5 = 8'b01000000;
	reg [0:7] mine_row_6 = 8'b00001000;
	reg [0:7] mine_row_7 = 8'b10000000;
	//*/
	
	// board number placement
	reg [0:7] number_row_0[7:0];
	reg [0:7] number_row_1[7:0];
	reg [0:7] number_row_2[7:0];
	reg [0:7] number_row_3[7:0];
	reg [0:7] number_row_4[7:0];
	reg [0:7] number_row_5[7:0];
	reg [0:7] number_row_6[7:0];
	reg [0:7] number_row_7[7:0];
	
	// overturned board 
	reg [0:7] pressed_row_0;
	reg [0:7] pressed_row_1;
	reg [0:7] pressed_row_2;
	reg [0:7] pressed_row_3;
	reg [0:7] pressed_row_4;
	reg [0:7] pressed_row_5;
	reg [0:7] pressed_row_6;
	reg [0:7] pressed_row_7;
	
	// flag board
	reg [0:7] flag_row_0;
	reg [0:7] flag_row_1;
	reg [0:7] flag_row_2;
	reg [0:7] flag_row_3;
	reg [0:7] flag_row_4;
	reg [0:7] flag_row_5;
	reg [0:7] flag_row_6;
	reg [0:7] flag_row_7;
	
	// index values for various functions
		// specific row and column on board
	integer row_index;
	integer col_index;
	integer print_index;
	integer move_index;
	integer init_index;
	integer cascade_index;
	integer count_index;
	integer seed;
	integer k;
	
	integer end_game_flagged;
	integer end_game_pressed;
	
	//for flagging state diagram
	reg done_flagging;
	reg done_checking;
	reg [3:0] num_uncovered_spots;
	
	//for checking state diagram
	reg [3:0] num_flagged_spots;
	
	// to hold mine tracking locations
	reg done;
	reg lost;
	reg[3:0] num_mines;
	// register to hold entire row valeus
	reg [0:7] m_above_row;
	reg [0:7] m_current_row;
	reg [0:7] m_below_row;
	
	reg [0:7] n_above_row[7:0];
	reg [0:7] n_current_row[7:0];
	reg [0:7] n_below_row[7:0];
	reg [0:7] n_print_row[7:0];
	
	reg [0:7] p_above_row;
	reg [0:7] p_current_row;
	reg [0:7] p_below_row;
	
	reg [0:7] f_above_row;
	reg [0:7] f_current_row;
	reg [0:7] f_below_row;
	
	
	// QUEUE IMPLEMENTATION
	localparam LENGTH = 256; // this is the maximum size of the board

	reg [LENGTH-1:0] row_index_queue;
	reg [LENGTH-1:0] col_index_queue; // ** INITIALIZE
	reg [7:0] insert_at;
	reg [7:0] next_at;
	
	wire [7:0] queue_length;
	assign queue_length = insert_at - next_at;
	
	//Targets (i.e. pressed spots on board, using indeces)
	integer target_row;
	integer target_col;
	integer finding_row_index;
	integer finding_col_index;
	
	
	reg add_to_queue;
	
	//for cascade queue
	reg [2:0] row_to_enqueue; 
	reg [2:0] col_to_enqueue;
	
	// STATE MACHINE VARIABLES
	
	// overall state machine
	reg [3:0] state;	
	localparam INIT = 4'b0001, SETUP = 4'b0010, COMPUTE = 4'b0100, DONE = 4'b1000, UNK = 4'bXXXX;
	
	reg [4:0] setup_state;
	localparam MOVE = 5'b00001, ITERATE = 5'b00010, _this_is_unused_ = 5'b00100, MOVE_BACK = 5'b01000, INC_ROW = 5'b10000;
	
	reg [5:0] compute_state;
	localparam FINDING_SPOT = 6'b000001, FOUND_SPOT = 6'b000010, GAME_LOGIC = 6'b000100, CASCADE = 6'b001000, PRINT = 6'b010000, CHECK_GAME_OVER = 6'b100000;
	
	reg [4:0] finding_state;
	localparam FINDING_MOVE = 5'b00001, FLAG = 5'b00010, FINDING_MOVE_BACK = 5'b00100, CHECK = 5'b01000, FINDING_INC_ROW = 5'b10000;
	
	reg[1:0] flagging_state;
	localparam FLAGGING_COUNT = 2'b01, FLAGGING = 2'b10;
	
	reg [2:0] check_state;
	localparam CHECK_COUNT = 3'b001, C1 = 3'b010, LAST_RESORT = 3'b100;
	
	reg [1:0] last_resort_state;
	localparam GENERATE = 2'b01, CHECK_LAST_RESORT = 2'b10;
	
	reg[4:0] cascade_state;
	localparam CASCADE_MOVE = 5'b00001, SETUP_ENQUEUE=5'b00010, ENQUEUE = 5'b00100, CASCADE_PUT_BACK = 5'b01000, DEQUEUE = 5'b10000;
	
	reg [2:0] print_state;
	localparam INPUT = 3'b001, OUTPUT = 3'b010, UPDATE = 3'b100, PRINT_UKN = 3'bXXX;
	
	reg[3:0] check_game_over_state;
	localparam OVER_INIT = 4'b0001, OVER_ITERATE_COLS = 4'b0010, OVER_INC_ROW = 4'b0100, OVER_RESULT = 4'b1000;
	
	// -------------------
	
	// state transisitions and RTL logic for main state diagram
	always @ (posedge clk, posedge reset)
	begin
		// asynchronous reset
		if (reset)
		begin
			// set to initialize
			state <= INIT;
			init_index <= 0;
		end	// end reset
		else
		begin
			case(state)
			INIT:
			begin
				if (start)
				begin
					// NSL
					if (init_index == 7)
						state <= SETUP;
						
					// RTL
					if (init_index == 7)
						init_index <= 0;
					else
						init_index <= init_index + 1;
						
						
					//init targets
					target_row <= 0;
					target_col <= 0;
					
					//init queue regs
					insert_at <= 0;
					next_at <= 0;
					
					// initialize index variables
					row_index <= 0;
					col_index <= 0;
					print_index <= 0;
					move_index <= 0;
					cascade_index <= 0;
					finding_row_index <= 0;
					finding_col_index <= 0;
					count_index <= 0;
					seed <= 345;
					k <= 0;
					
					done <= 0;
					lost <= 0;
					// ##################################################################
					num_mines <= 10;
					// ##################################################################

					//init AI vars
					done_flagging <= 0;
					done_checking <= 0;
					num_uncovered_spots <= 0;
					
					num_flagged_spots <= 0;
					
					end_game_flagged <= 0;
					end_game_pressed <= 0;
					
					// init various state variables
					setup_state <= MOVE;
					compute_state <= FINDING_SPOT;
					cascade_state <= CASCADE_MOVE;
					print_state <= INPUT;
					finding_state <= FINDING_MOVE;
					check_state <= CHECK_COUNT;
					flagging_state <= FLAGGING_COUNT;
					last_resort_state <= GENERATE;
					check_game_over_state <= OVER_INIT;
					// init registers
										
					// 8 number rows
					number_row_0[init_index] <= 0;
					number_row_1[init_index] <= 0;
					number_row_2[init_index] <= 0;
					number_row_3[init_index] <= 0;
					number_row_4[init_index] <= 0;
					number_row_5[init_index] <= 0;
					number_row_6[init_index] <= 0;
					number_row_7[init_index] <= 0;
					
					//output for debugging
					/*
					$write(number_row_0[init_index]);
					$write(number_row_1[init_index]);
					$write(number_row_2[init_index]);
					$write(number_row_3[init_index]);
					$write(number_row_4[init_index]);
					$write(number_row_5[init_index]);
					$write(number_row_6[init_index]);
					$write(number_row_7[init_index]);
					$display("  Done...");
					*/
					
					// 8 pressed rows
					pressed_row_0[init_index] <= 0;
					pressed_row_1[init_index] <= 0;
					pressed_row_2[init_index] <= 0;
					pressed_row_3[init_index] <= 0;
					pressed_row_4[init_index] <= 0;
					pressed_row_5[init_index] <= 0;
					pressed_row_6[init_index] <= 0;
					pressed_row_7[init_index] <= 0;
					
					// 8 flag rows
					flag_row_0[init_index] <= 0;
					flag_row_1[init_index] <= 0;
					flag_row_2[init_index] <= 0;
					flag_row_3[init_index] <= 0;
					flag_row_4[init_index] <= 0;
					flag_row_5[init_index] <= 0;
					flag_row_6[init_index] <= 0;
					flag_row_7[init_index] <= 0;
					
					// above, below, current, print, and various other 'temporary variables' rows
					m_above_row[init_index] <= 0;
					m_current_row[init_index] <= 0;
					m_below_row[init_index] <= 0;
					
					n_above_row[init_index] <= 0;
					n_current_row[init_index] <= 0;
					n_below_row[init_index] <= 0;
					n_print_row[init_index] <= 0;
					
					p_above_row[init_index] <= 0;
					p_current_row[init_index] <= 0;
					p_below_row[init_index] <= 0;
					
					f_above_row[init_index] <= 0;
					f_current_row[init_index] <= 0;
					f_below_row[init_index] <= 0;
					
					row_index_queue <= 256'd0;
					col_index_queue <= 256'd0;
					
					row_to_enqueue <= 0;
					col_to_enqueue <= 0;
					
					add_to_queue <= 0;
					
				end // end if(start)
			end // end INIT
			SETUP:
			begin
				// NSL
					// none here, overall state machine moves to COMPUTE in setup_state INC_ROW
				// RTL
				case(setup_state)
				MOVE:
				begin
					//NSL
					if (move_index == 7)
						setup_state <= ITERATE;
					
					//RTL
					if (move_index == 7)
						move_index <= 0;
					else
						move_index <= move_index + 1;
						
					// actually do the move with a case statement
					case(row_index)
					0:
					begin
						m_current_row[move_index] <= mine_row_0[move_index];
					
						 //n_above_row <= mine_row_0;
						 n_current_row[move_index] <= number_row_0[move_index];
						 n_below_row[move_index] <= number_row_1[move_index];
					end
					1:
					begin
						m_current_row[move_index] <= mine_row_1[move_index];
					
						 n_above_row[move_index] <= number_row_0[move_index];
						 n_current_row[move_index] <= number_row_1[move_index];
						 n_below_row[move_index] <= number_row_2[move_index];
					end
					2:
					begin
						m_current_row[move_index] <= mine_row_2[move_index];
						
						 n_above_row[move_index] <= number_row_1[move_index];
						 n_current_row[move_index] <= number_row_2[move_index];
						 n_below_row[move_index] <= number_row_3[move_index];
					end
					3:
					begin
						m_current_row[move_index] <= mine_row_3[move_index];
						
						 n_above_row[move_index] <= number_row_2[move_index];
						 n_current_row[move_index] <= number_row_3[move_index];
						 n_below_row[move_index] <= number_row_4[move_index];
					end
					4:
					begin
						m_current_row[move_index] <= mine_row_4[move_index];
						
						 n_above_row[move_index] <= number_row_3[move_index];
						 n_current_row[move_index] <= number_row_4[move_index];
						 n_below_row[move_index] <= number_row_5[move_index];
					end
					5:
					begin
						m_current_row[move_index] <= mine_row_5[move_index];
					
						 n_above_row[move_index] <= number_row_4[move_index];
						 n_current_row[move_index] <= number_row_5[move_index];
						 n_below_row[move_index] <= number_row_6[move_index];
					end
					6:
					begin
						m_current_row[move_index] <= mine_row_6[move_index];
					
						 n_above_row[move_index] <= number_row_5[move_index];
						 n_current_row[move_index] <= number_row_6[move_index];
						 n_below_row[move_index] <= number_row_7[move_index];
					end
					7:
					begin
						m_current_row[move_index] <= mine_row_7[move_index];
					
						 n_above_row[move_index] <= number_row_6[move_index];
						 n_current_row[move_index] <= number_row_7[move_index];
						 // n_below_row <= ...
					end
					endcase // end MOVE case statement
					
				end
				ITERATE:
				begin
					// NSL
					if (col_index == 7)
						setup_state <= MOVE_BACK;
						
					// RTL
					if (col_index == 7)
						col_index <= 0;
					else
						col_index <= col_index + 1;
						
					if (m_current_row[col_index] == 1)
					begin

						// edge cases
						if (row_index == 0 && col_index == 0)
						begin
							n_current_row[col_index+1] <= n_current_row[col_index+1] + 2'b01; //right
							n_below_row[col_index+1] <= n_below_row[col_index+1] + 2'b01; //bottom right
							n_below_row[col_index] <= n_below_row[col_index] + 2'b01; //bottom
						end
						else if (row_index == 0 && col_index == 7)
						begin
							n_current_row[col_index-1] <= n_current_row[col_index-1] + 2'b01; //left
							n_below_row[col_index-1] <= n_below_row[col_index-1] + 2'b01; //bottom left
							n_below_row[col_index] <= n_below_row[col_index] + 2'b01; //b
						end
						else if (row_index == 7 && col_index == 0)
						begin
							n_above_row[col_index] <= n_above_row[col_index] + 2'b01; //a
							n_above_row[col_index+1] <= n_above_row[col_index+1] + 2'b01; // a r
							n_current_row[col_index+1] <= n_current_row[col_index+1] + 2'b01; //r
						end
						else if (row_index == 7 && col_index == 7)
						begin
							n_above_row[col_index] <= n_above_row[col_index] + 2'b01; //a
							n_above_row[col_index-1] <= n_above_row[col_index-1] + 2'b01; //a l
							n_current_row[col_index-1] <= n_current_row[col_index-1] + 2'b01; //l
						end
						else if (row_index == 0)
						begin
							n_current_row[col_index+1] <= n_current_row[col_index+1] + 2'b01; //right
							n_below_row[col_index+1] <= n_below_row[col_index+1] + 2'b01; //bottom right
							n_below_row[col_index] <= n_below_row[col_index] + 2'b01; //bottom
							n_current_row[col_index-1] <= n_current_row[col_index-1] + 2'b01; //left
							n_below_row[col_index-1] <= n_below_row[col_index-1] + 2'b01; //bottom left
						end
						else if (row_index == 7)
						begin
							n_above_row[col_index] <= n_above_row[col_index] + 2'b01; //a
							n_above_row[col_index+1] <= n_above_row[col_index+1] + 2'b01; // a r
							n_current_row[col_index+1] <= n_current_row[col_index+1] + 2'b01; //r
							n_above_row[col_index-1] <= n_above_row[col_index-1] + 2'b01; //a l
							n_current_row[col_index-1] <= n_current_row[col_index-1] + 2'b01; //l
						end
						else if (col_index == 0)
						begin
							n_above_row[col_index] <= n_above_row[col_index] + 2'b01; //a
							n_above_row[col_index+1] <= n_above_row[col_index+1] + 2'b01; // a r
							n_current_row[col_index+1] <= n_current_row[col_index+1] + 2'b01; //r
							n_below_row[col_index+1] <= n_below_row[col_index+1] + 2'b01; //bottom right
							n_below_row[col_index] <= n_below_row[col_index] + 2'b01; //bottom
						end
						else if (col_index == 7)
						begin
							n_below_row[col_index] <= n_below_row[col_index] + 2'b01; //bottom
							n_current_row[col_index-1] <= n_current_row[col_index-1] + 2'b01; //left
							n_below_row[col_index-1] <= n_below_row[col_index-1] + 2'b01; //bottom left
							n_above_row[col_index] <= n_above_row[col_index] + 2'b01; //a
							n_above_row[col_index-1] <= n_above_row[col_index-1] + 2'b01; //a l
						end
						// every other case
						else 
						begin
							n_below_row[col_index] <= n_below_row[col_index] + 2'b01; //bottom
							n_current_row[col_index-1] <= n_current_row[col_index-1] + 2'b01; //left
							n_below_row[col_index-1] <= n_below_row[col_index-1] + 2'b01; //bottom left
							n_above_row[col_index] <= n_above_row[col_index] + 2'b01; //a
							n_above_row[col_index-1] <= n_above_row[col_index-1] + 2'b01; //a l
							n_above_row[col_index+1] <= n_above_row[col_index+1] + 2'b01; // a r
							n_current_row[col_index+1] <= n_current_row[col_index+1] + 2'b01; //r
							n_below_row[col_index+1] <= n_below_row[col_index+1] + 2'b01; //bottom right
						end
					end

					
				end // end ITERATE
				MOVE_BACK:
				begin
					//NSL
					if (move_index == 7)
						setup_state <= INC_ROW; 
					
					//RTL
					if (move_index == 7)
						move_index <= 0;
					else
						move_index <= move_index + 1;
						
					case(row_index)
					0:
					begin
						 //n_above_row <= mine_row_0;
						 number_row_0[move_index] <= n_current_row[move_index];
						 number_row_1[move_index] <= n_below_row[move_index];
					end
					1:
					begin
						 number_row_0[move_index] <= n_above_row[move_index];
						 number_row_1[move_index] <= n_current_row[move_index];
						 number_row_2[move_index] <= n_below_row[move_index];
					end
					2:
					begin
						 number_row_1[move_index] <= n_above_row[move_index];
						 number_row_2[move_index] <= n_current_row[move_index];
						 number_row_3[move_index] <= n_below_row[move_index];
					end
					3:
					begin
						 number_row_2[move_index] <= n_above_row[move_index];
						 number_row_3[move_index] <= n_current_row[move_index];
						 number_row_4[move_index] <= n_below_row[move_index];
					end
					4:
					begin
						 number_row_3[move_index] <= n_above_row[move_index];
						 number_row_4[move_index] <= n_current_row[move_index];
						 number_row_5[move_index] <= n_below_row[move_index];
					end
					5:
					begin
						 number_row_4[move_index] <= n_above_row[move_index];
						 number_row_5[move_index] <= n_current_row[move_index];
						 number_row_6[move_index] <= n_below_row[move_index];
					end
					6:
					begin
						 number_row_5[move_index] <= n_above_row[move_index];
						 number_row_6[move_index] <= n_current_row[move_index];
						 number_row_7[move_index] <= n_below_row[move_index];
					end
					7:
					begin
						 number_row_6[move_index] <= n_above_row[move_index];
						 number_row_7[move_index] <= n_current_row[move_index];
						 //number_row_ <= n_below_row;
					end
					endcase // end MOVE_BACK casestatement
					
				end // end MOVE_BACK
				INC_ROW:
				begin
					//NSL
					// either way, do below
					setup_state <= MOVE;

					if (row_index == 7)
						state <= COMPUTE;
					// else
						// stay in SETUP
						
					//RTL
					col_index <= 0;
					if (row_index == 7)
						row_index <= 0;
					else
						row_index <= row_index + 1;
						
				end // end INC_ROW
				endcase // end setup_state case statement
			end // end SETUP
			COMPUTE:
			begin
				// NSL
					// moving to done -- will this be in a compute_state?
				// RTL
				case(compute_state)
				FINDING_SPOT:
				begin
					case(finding_state)
					FINDING_MOVE:
					begin
						//NSL
						if (move_index == 7)
						begin
							if (done_checking == 1)
							begin
								finding_state <= CHECK;
								check_state <= LAST_RESORT;
							end
							else
							begin
								if(!done_flagging)
									finding_state <= FLAG;
								else
								begin
									finding_state <= CHECK;
									num_flagged_spots <= 0;
									num_uncovered_spots <= 0;
								end
							end
							
						end
						
						//RTL
						if (move_index == 7)
							move_index <= 0;
						else
							move_index <= move_index + 1;
							
						// actually do the move with a case statement
						case(finding_row_index)
						0:
						begin
							m_current_row <= mine_row_0;
							m_below_row <= mine_row_1;
							
							//n_above_row <= mine_row_0;
							n_current_row[move_index] <= number_row_0[move_index];
							n_below_row[move_index] <= number_row_1[move_index];
							
							// p_above_row
							p_current_row <= pressed_row_0;
							p_below_row <= pressed_row_1;
							
							//f_above_row 
							f_current_row <= flag_row_0;
							f_below_row <= flag_row_1;
							
						end
						1:
						begin
							m_above_row <= mine_row_0;
							m_current_row <= mine_row_1;
							m_below_row <= mine_row_2;
						
							n_above_row[move_index] <= number_row_0[move_index];
							n_current_row[move_index] <= number_row_1[move_index];
							n_below_row[move_index] <= number_row_2[move_index];
							
							p_above_row <= pressed_row_0;
							p_current_row <= pressed_row_1;
							p_below_row <= pressed_row_2;
							
							f_above_row <= flag_row_0;
							f_current_row <= flag_row_1;
							f_below_row <= flag_row_2;
						end
						2:
						begin
							m_above_row <= mine_row_1;
							m_current_row <= mine_row_2;
							m_below_row <= mine_row_3;
							
							n_above_row[move_index] <= number_row_1[move_index];
							n_current_row[move_index] <= number_row_2[move_index];
							n_below_row[move_index] <= number_row_3[move_index];
							
							p_above_row <= pressed_row_1;
							p_current_row <= pressed_row_2;
							p_below_row <= pressed_row_3;
							
							f_above_row <= flag_row_1;
							f_current_row <= flag_row_2;
							f_below_row <= flag_row_3;
						end
						3:
						begin
							m_above_row <= mine_row_2;
							m_current_row <= mine_row_3;
							m_below_row <= mine_row_4;
							
							n_above_row[move_index] <= number_row_2[move_index];
							n_current_row[move_index] <= number_row_3[move_index];
							n_below_row[move_index] <= number_row_4[move_index];
							
							p_above_row <= pressed_row_2;
							p_current_row <= pressed_row_3;
							p_below_row <= pressed_row_4;
							
							f_above_row <= flag_row_2;
							f_current_row <= flag_row_3;
							f_below_row <= flag_row_4;
						end
						4:
						begin
							m_above_row <= mine_row_3;
							m_current_row <= mine_row_4;
							m_below_row <= mine_row_5;
							
							n_above_row[move_index] <= number_row_3[move_index];
							n_current_row[move_index] <= number_row_4[move_index];
							n_below_row[move_index] <= number_row_5[move_index];
							
							p_above_row <= pressed_row_3;
							p_current_row <= pressed_row_4;
							p_below_row <= pressed_row_5;
							
							f_above_row <= flag_row_3;
							f_current_row <= flag_row_4;
							f_below_row <= flag_row_5;
						end
						5:
						begin
							m_above_row <= mine_row_4;
							m_current_row <= mine_row_5;
							m_below_row <= mine_row_6;
						
							n_above_row[move_index] <= number_row_4[move_index];
							n_current_row[move_index] <= number_row_5[move_index];
							n_below_row[move_index] <= number_row_6[move_index];
							
							p_above_row <= pressed_row_4;
							p_current_row <= pressed_row_5;
							p_below_row <= pressed_row_6;
							
							f_above_row <= flag_row_4;
							f_current_row <= flag_row_5;
							f_below_row <= flag_row_6;
						end
						6:
						begin
							m_above_row <= mine_row_5;
							m_current_row <= mine_row_6;
							m_below_row <= mine_row_7;
						
							n_above_row[move_index] <= number_row_5[move_index];
							n_current_row[move_index] <= number_row_6[move_index];
							n_below_row[move_index] <= number_row_7[move_index];
							
							p_above_row <= pressed_row_5;
							p_current_row <= pressed_row_6;
							p_below_row <= pressed_row_7;
							
							f_above_row <= flag_row_5;
							f_current_row <= flag_row_6;
							f_below_row <= flag_row_7;
						end
						7:
						begin
							m_above_row <= mine_row_6;
							m_current_row <= mine_row_7;
							//m_below_row 
							
							n_above_row[move_index] <= number_row_6[move_index];
							n_current_row[move_index] <= number_row_7[move_index];
							// n_below_row <= ...
							
							p_above_row <= pressed_row_6;
							p_current_row <= pressed_row_7;
							//p_below_row <= pressed_row_2;
							
							f_above_row <= flag_row_6;
							f_current_row <= flag_row_7;
							//f_below_row <= flag_row_2;
						end
						endcase
					end //end FINDING_MOVE
					
					FLAG:
					begin
						
						case(flagging_state)
						FLAGGING_COUNT:
						begin
							// NSL
							if (count_index == 7)
								flagging_state <= FLAGGING;
							
							// RTL
							if (count_index == 7)
								count_index <= 0;
							else 
								count_index <= count_index + 1;
								
							case(count_index)
							0:
							begin
								if ( finding_row_index > 0 && finding_col_index > 0)
								begin
									if (p_above_row[finding_col_index-1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;

								end
							end
							1:
							begin
								if ( finding_row_index > 0)
								begin
									if (p_above_row[finding_col_index] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							2:
							begin
								if ( finding_row_index > 0 && finding_col_index < 7)
								begin
									if (p_above_row[finding_col_index+1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							3:
							begin
								if (finding_col_index > 0)
								begin
									if (p_current_row[finding_col_index-1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							4:
							begin
								if (finding_col_index < 7)
								begin
									if (p_current_row[finding_col_index+1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							5:
							begin
								if (finding_row_index < 7 && finding_col_index > 0)
								begin
									if (p_below_row[finding_col_index-1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							6:
							begin
								if (finding_row_index < 7)
								begin
									if (p_below_row[finding_col_index] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							7:
							begin
							if (finding_row_index < 7 && finding_col_index < 7)
								begin
									if (p_below_row[finding_col_index+1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							endcase // end count_index case statement
							
						
						end // end FLAGGING_COUNT
						FLAGGING:
						begin
							//NSL
							flagging_state <= FLAGGING_COUNT;
							num_uncovered_spots <= 0;
							
							if (finding_col_index == 7)
							begin
								finding_state <= FINDING_MOVE_BACK;
							end
							
							
							//RTL
							if (finding_col_index == 7)
								finding_col_index <= 0;
							else
								finding_col_index <= finding_col_index + 1;
								
							
								
							// flag squares
							if (n_current_row[finding_col_index] == num_uncovered_spots)  // *** If number unovered - nujber flags
							begin
								// 0
								if (finding_row_index > 0 && finding_col_index > 0)
								begin
									if (p_above_row[finding_col_index - 1] == 0)
									begin
										f_above_row[finding_col_index - 1] <= 1;
									end
								end
								// 1
								if ( finding_row_index > 0)
								begin
									if (p_above_row[finding_col_index] == 0)
									begin
										f_above_row[finding_col_index] <= 1;
									end
								end
								// 2
								if ( finding_row_index > 0 && finding_col_index < 7)
								begin
									if (p_above_row[finding_col_index + 1] == 0)
									begin
										f_above_row[finding_col_index + 1] <= 1;
									end
								end
								//3 
								if (finding_col_index > 0)
								begin
									if (p_current_row[finding_col_index - 1] == 0)
									begin
										f_current_row[finding_col_index - 1] <= 1;
									end
								end
								//4:
								if (finding_col_index < 7)
								begin
									if (p_current_row[finding_col_index + 1] == 0)
									begin
										f_current_row[finding_col_index + 1] <= 1;
									end
								end
								// 5:
								if (finding_row_index < 7 && finding_col_index > 0)
								begin
									if (p_below_row[finding_col_index - 1] == 0)
									begin
										f_below_row[finding_col_index - 1] <= 1;
									end
								end
								// 6:
								if (finding_row_index < 7)
								begin
									if (p_below_row[finding_col_index] == 0)
									begin
										f_below_row[finding_col_index] <= 1;	
									end
								end
								// 7:
								if (finding_row_index < 7 && finding_col_index < 7)
								begin
									if (p_below_row[finding_col_index + 1] == 0)
									begin
										f_below_row[finding_col_index + 1] <= 1;
									end
								end
								
							end // end flag squares block	
						end // end FLAGGING
						endcase // end flagging state
						
					end //end FLAG
					
					FINDING_MOVE_BACK:
					begin
						//NSL
						finding_state <= FINDING_INC_ROW;
						
						//RTL
						case(finding_row_index)
						0:
						begin
							flag_row_0 <= f_current_row;
							flag_row_1 <= f_below_row;
						end
						1:
						begin
							flag_row_0 <= f_above_row;
							flag_row_1 <= f_current_row;
							flag_row_2 <= f_below_row;
						end
						2:
						begin
							flag_row_1 <= f_above_row;
							flag_row_2 <= f_current_row;
							flag_row_3 <= f_below_row;
						end
						3:
						begin
							flag_row_2 <= f_above_row;
							flag_row_3 <= f_current_row;
							flag_row_4 <= f_below_row;
						end
						4:
						begin
							flag_row_3 <= f_above_row;
							flag_row_4 <= f_current_row;
							flag_row_5 <= f_below_row;
						end
						5:
						begin
							flag_row_4 <= f_above_row;
							flag_row_5 <= f_current_row;
							flag_row_6 <= f_below_row;
						end
						6:
						begin
							flag_row_5 <= f_above_row;
							flag_row_6 <= f_current_row;
							flag_row_7 <= f_below_row;
						end
						7:
						begin
							flag_row_6 <= f_above_row;
							flag_row_7 <= f_current_row;
						end
						endcase // end case(finding_row_index)
						
					end //end FINDING_MOVE_BACK
					
					FINDING_INC_ROW:
					begin
						//NSL
						finding_state <= FINDING_MOVE;
						
						//RTL
						finding_col_index <= 0;
						
						if(finding_row_index == 7)
						begin
							finding_row_index <= 0;

							if (done_flagging == 0)
								done_flagging <= 1;
							else
								done_checking <= 1;
						end
						else
							finding_row_index <= finding_row_index + 1;
					
					end //end FINDING_INC_ROW
					
					CHECK:
					begin
						
						case(check_state)
						
						CHECK_COUNT:
						begin
							//NSL
							if(count_index == 8)
							begin
								check_state <= C1;
							end
							//RTL
							if(count_index == 8)
								count_index <= 0;
							else
								count_index <= count_index + 1;
								
							case(count_index)
							0:
							begin
								if ( finding_row_index > 0 && finding_col_index > 0)
								begin
									if (f_above_row[finding_col_index-1] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_above_row[finding_col_index-1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							1:
							begin
								if ( finding_row_index > 0)
								begin
									if (f_above_row[finding_col_index] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_above_row[finding_col_index] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							2:
							begin
								if ( finding_row_index > 0 && finding_col_index < 7)
								begin
									if (f_above_row[finding_col_index+1] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_above_row[finding_col_index+1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							3:
							begin
								if (finding_col_index > 0)
								begin
									if (f_current_row[finding_col_index-1] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_current_row[finding_col_index-1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							4:
							begin
								if (finding_col_index < 7)
								begin
									if (f_current_row[finding_col_index+1] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_current_row[finding_col_index+1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							5:
							begin
								if (finding_row_index < 7 && finding_col_index > 0)
								begin
									if (f_below_row[finding_col_index-1] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_below_row[finding_col_index-1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							6:
							begin
								if (finding_row_index < 7)
								begin
									if (f_below_row[finding_col_index] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_below_row[finding_col_index] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							7:
							begin
							if (finding_row_index < 7 && finding_col_index < 7)
								begin
									if (f_below_row[finding_col_index+1] == 1)
										num_flagged_spots <= num_flagged_spots + 1;
										
									if (p_below_row[finding_col_index+1] == 0)
										num_uncovered_spots <= num_uncovered_spots + 1;
								end
							end
							8:
							begin
							// check current spot
								if (f_current_row[finding_col_index] == 1)
									num_flagged_spots <= num_flagged_spots + 1;

								if (p_current_row[finding_col_index] == 0)
									num_uncovered_spots <= num_uncovered_spots + 1;
									
							end
							endcase // end count_index case statement
							
						end //end CHECK_COUNT
						
						C1: // if num = num flags
						begin						
							// NSL
							if (n_current_row[finding_col_index] == num_flagged_spots && num_flagged_spots > 0 && count_index == 8 && num_uncovered_spots - num_flagged_spots > 0)
							begin
								// leave and reset
								compute_state <= FOUND_SPOT;
								flagging_state <= FLAGGING_COUNT;
								check_state <= CHECK_COUNT;
								finding_state <= FINDING_MOVE;
								done_checking <= 0;
								done_flagging <= 0;
								num_flagged_spots <= 0;
								num_uncovered_spots <= 0;
								$display("AI Selected Location");
							end
							else if (n_current_row[finding_col_index] == num_flagged_spots && num_flagged_spots > 0  && num_uncovered_spots - num_flagged_spots > 0)
							begin
								// stay in this state
							end
							else if (finding_col_index == 7)
							begin
								finding_col_index <= 0;
								finding_state <= FINDING_INC_ROW;
								check_state <= CHECK_COUNT;
								num_flagged_spots <= 0;
								num_uncovered_spots <= 0;
							end
							else
							begin
								check_state <= CHECK_COUNT;
								num_flagged_spots <= 0;
								num_uncovered_spots <= 0;
								
							end
							
							// RTL
							if (n_current_row[finding_col_index] == num_flagged_spots && num_flagged_spots > 0  && num_uncovered_spots - num_flagged_spots > 0 )
							begin
								if (count_index == 8)
									count_index <= 0;
								else
									count_index <= count_index + 1;
									
							end
							else 
							begin
								if (finding_col_index == 7)
									finding_col_index <= 0;
								else 
									finding_col_index <= finding_col_index + 1;
							end
								
							//check to click
							if (n_current_row[finding_col_index] == num_flagged_spots && num_flagged_spots > 0  && num_uncovered_spots - num_flagged_spots > 0)
							begin
								case(count_index)
								0:
								begin
									if ( finding_row_index > 0 && finding_col_index > 0)
									begin
										if (f_above_row[finding_col_index-1] == 0 && p_above_row[finding_col_index - 1] == 0)
										begin
											target_row <= finding_row_index - 1;
											target_col <= finding_col_index - 1;
										end
									end
								end
								1:
								begin
									if ( finding_row_index > 0)
									begin
										if (f_above_row[finding_col_index] == 0 && p_above_row[finding_col_index] == 0)
										begin
											target_row <= finding_row_index - 1;
											target_col <= finding_col_index;
										end
									end
								end
								2:
								begin
									if ( finding_row_index > 0 && finding_col_index < 7)
									begin
										if (f_above_row[finding_col_index+1] == 0 && p_above_row[finding_col_index+1] == 0)
										begin
											target_row <= finding_row_index - 1;
											target_col <= finding_col_index + 1;
										end
									end
								end
								3:
								begin
									if (finding_col_index > 0)
									begin
										if (f_current_row[finding_col_index-1] == 0 && p_current_row[finding_col_index - 1] == 0)
										begin
											target_row <= finding_row_index;
											target_col <= finding_col_index - 1;
										end
									end
								end
								4:
								begin
									if (finding_col_index < 7)
									begin
										if (f_current_row[finding_col_index+1] == 0 && p_current_row[finding_col_index + 1] == 0)
										begin
											target_row <= finding_row_index;
											target_col <= finding_col_index + 1;
										end
									end
								end
								5:
								begin
									if (finding_row_index < 7 && finding_col_index > 0)
									begin
										if (f_below_row[finding_col_index-1] == 0 && p_below_row[finding_col_index - 1] == 0)
										begin
											target_row <= finding_row_index + 1;
											target_col <= finding_col_index - 1;
										end
									end
								end
								6:
								begin
									if (finding_row_index < 7)
									begin
										if (f_below_row[finding_col_index] == 0 && p_below_row[finding_col_index] == 0)
										begin
											target_row <= finding_row_index + 1;
											target_col <= finding_col_index;
										end
									end
								end
								7:
								begin
								if (finding_row_index < 7 && finding_col_index < 7)
									begin
										if (f_below_row[finding_col_index+1] == 0 && p_below_row[finding_col_index + 1] == 0)
										begin
											target_row <= finding_row_index + 1;
											target_col <= finding_col_index + 1;
										end
									end
								end
								8:
								begin
								// no checks for bounds, b/c in direct spot
									if (f_current_row[finding_col_index] == 0 && p_current_row[finding_col_index] == 0)
									begin
										target_row <= finding_row_index;
										target_col <= finding_col_index;
									end
								end
			
								endcase // end count_index case statement
							end //end if (n_current_row[finding_col_index] == num_flagged_spots)
							
						end //end C1
						
						LAST_RESORT:
						begin
							case(last_resort_state)
							GENERATE:
							begin
								// NSL
								last_resort_state <= CHECK_LAST_RESORT;
								
								// RTL
								target_row <= {$random(seed)} % 8;
								target_col <= {$random(seed + 3)} % 8;
								seed <= seed + 1;
							
							end // end GENERATE
							CHECK_LAST_RESORT:
							begin
								// NSL
								last_resort_state <= GENERATE;
								
								// check to see if unflagged and unpressed
								case(target_row)
								0:
								begin
									if (flag_row_0[target_col] == 0 && pressed_row_0[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								1:
								begin
									if (flag_row_1[target_col] == 0 && pressed_row_1[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								2:
								begin
									if (flag_row_2[target_col] == 0 && pressed_row_2[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								3:
								begin
									if (flag_row_3[target_col] == 0 && pressed_row_3[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								4:
								begin
									if (flag_row_4[target_col] == 0 && pressed_row_4[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								5:
								begin
									if (flag_row_5[target_col] == 0 && pressed_row_5[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								6:
								begin
									if (flag_row_6[target_col] == 0 && pressed_row_6[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								7:
								begin
									if (flag_row_7[target_col] == 0 && pressed_row_7[target_col] == 0)
									begin
										compute_state <= FOUND_SPOT;
										flagging_state <= FLAGGING_COUNT;
										check_state <= CHECK_COUNT;
										finding_state <= FINDING_MOVE;
										done_flagging <= 0;
										done_checking <= 0;
										$display("Last Resort: AI chose random location");
									end
								end
								endcase // end case (target_row)
							
							end // end CHECK_LAST_RESORT

							endcase // end case(last_resort_state)
						end //end LAST_RESORT
						
						endcase //end case(check_state)
					
					end //end CHECK
					
					endcase //end case(finding_state)
				end //end FINDING_SPOT
				
				FOUND_SPOT:
				begin
					// NSL
					compute_state <= GAME_LOGIC;
					
					// RTL
					//reset all finding vars
					done_flagging <= 0;
					num_uncovered_spots <= 0;
					num_flagged_spots <= 0;
					
					// debug output found target
					$display("Chosen Location is: (%d,%d),",target_row, target_col);
										
					//uncover targetted spot 
					case(target_row)
					0:
					begin
						pressed_row_0[target_col] <= 1;
						
						// reset flag
						flag_row_0[target_col] <= 0;
						
						if (mine_row_0[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					1:
					begin
						pressed_row_1[target_col] <= 1;
						
						// reset flag
						flag_row_1[target_col] <= 0;
						
						if (mine_row_1[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					2:
					begin
						pressed_row_2[target_col] <= 1;
						
						// reset flag
						flag_row_2[target_col] <= 0;
						
						if (mine_row_2[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					3:
					begin
						pressed_row_3[target_col] <= 1;
						
						// reset flag
						flag_row_3[target_col] <= 0;
						
						if (mine_row_3[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					4:
					begin
						pressed_row_4[target_col] <= 1;
						
						// reset flag
						flag_row_4[target_col] <= 0;
						
						if (mine_row_4[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					5:
					begin
						pressed_row_5[target_col] <= 1;
						
						// reset flag
						flag_row_5[target_col] <= 0;
						
						if (mine_row_5[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					6:
					begin
						pressed_row_6[target_col] <= 1;
						
						// reset flag
						flag_row_6[target_col] <= 0;
						
						if (mine_row_6[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					7:
					begin
						pressed_row_7[target_col] <= 1;
						
						// reset flag
						flag_row_7[target_col] <= 0;
						
						if (mine_row_7[target_col] == 1)
						begin
							done <= 1;
							lost <= 1;
							compute_state <= PRINT;
						end
					end
					
					endcase //end case(target_row)
					
					// old add to queue spot
					
				end // end FOUND_SPOT
				GAME_LOGIC:
				begin
					//NSL
					case(target_row)
					0:
					begin
						if( number_row_0[target_col]==0 && !mine_row_0[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					1:
					begin
						if( number_row_1[target_col]==0 && !mine_row_1[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					2:
					begin
						if( number_row_2[target_col]==0 && !mine_row_2[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					3:
					begin
						if( number_row_3[target_col]==0 && !mine_row_3[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					4:
					begin
						if( number_row_4[target_col]==0 && !mine_row_4[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					5:
					begin
						if( number_row_5[target_col]==0 && !mine_row_5[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					6:
					begin
						if( number_row_6[target_col]==0 && !mine_row_6[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					7:
					begin
						if( number_row_7[target_col]==0 && !mine_row_7[target_col])
						begin
							compute_state <= CASCADE;
							//and add to queue
							row_index_queue[insert_at] <= target_row[0];
							row_index_queue[insert_at+1] <= target_row[1];
							row_index_queue[insert_at+2] <= target_row[2];
							col_index_queue[insert_at] <= target_col[0];
							col_index_queue[insert_at+1] <= target_col[1];
							col_index_queue[insert_at+2] <= target_col[2];
							insert_at <= insert_at + 3;
						end
						else
							compute_state <= PRINT;
					end
					endcase //end case(target_row)
				end //end GAME_LOGIC
				CASCADE:
				begin
					case(cascade_state)
					CASCADE_MOVE:
					begin
						//NSL
							if(move_index == 7)
								cascade_state <= SETUP_ENQUEUE;
						
						//RTL
						if (move_index == 7)
							move_index <= 0;
						else
							move_index <= move_index + 1;
						
						case(target_row)
						0:
						begin
							 //n_above_row <= mine_row_0;
							 n_current_row[move_index] <= number_row_0[move_index];
							 n_below_row[move_index] <= number_row_1[move_index];
							 
							 //p_above
							 p_current_row <= pressed_row_0;
							 p_below_row <= pressed_row_1;
							 
							 // m_above
							 m_current_row <= mine_row_0;
							 m_below_row <= mine_row_1;
						end
						1:
						begin
							 n_above_row[move_index] <= number_row_0[move_index];
							 n_current_row[move_index] <= number_row_1[move_index];
							 n_below_row[move_index] <= number_row_2[move_index];
							 
							 p_above_row <= pressed_row_0;
							 p_current_row <= pressed_row_1;
							 p_below_row <= pressed_row_2;
							 
							 m_above_row <= mine_row_0;
							 m_current_row <= mine_row_1;
							 m_below_row <= mine_row_2;
						end
						2:
						begin
							 n_above_row[move_index] <= number_row_1[move_index];
							 n_current_row[move_index] <= number_row_2[move_index];
							 n_below_row[move_index] <= number_row_3[move_index];
							 
							 p_above_row <= pressed_row_1;
							 p_current_row <= pressed_row_2;
							 p_below_row <= pressed_row_3;
							 
							 m_above_row <= mine_row_1;
							 m_current_row <= mine_row_2;
							 m_below_row <= mine_row_3;
						end
						3:
						begin
							 n_above_row[move_index] <= number_row_2[move_index];
							 n_current_row[move_index] <= number_row_3[move_index];
							 n_below_row[move_index] <= number_row_4[move_index];
							 
							 p_above_row <= pressed_row_2;
							 p_current_row <= pressed_row_3;
							 p_below_row <= pressed_row_4;
							 
							 m_above_row <= mine_row_2;
							 m_current_row <= mine_row_3;
							 m_below_row <= mine_row_4;
						end
						4:
						begin
							 n_above_row[move_index] <= number_row_3[move_index];
							 n_current_row[move_index] <= number_row_4[move_index];
							 n_below_row[move_index] <= number_row_5[move_index];
							 
							 p_above_row <= pressed_row_3;
							 p_current_row <= pressed_row_4;
							 p_below_row <= pressed_row_5;
							 
							 m_above_row <= mine_row_3;
							 m_current_row <= mine_row_4;
							 m_below_row <= mine_row_5;
						end
						5:
						begin
							 n_above_row[move_index] <= number_row_4[move_index];
							 n_current_row[move_index] <= number_row_5[move_index];
							 n_below_row[move_index] <= number_row_6[move_index];
							 
							 p_above_row <= pressed_row_4;
							 p_current_row <= pressed_row_5;
							 p_below_row <= pressed_row_6;
							 
							 m_above_row <= mine_row_4;
							 m_current_row <= mine_row_5;
							 m_below_row <= mine_row_6;
						end
						6:
						begin
							 n_above_row[move_index] <= number_row_5[move_index];
							 n_current_row[move_index] <= number_row_6[move_index];
							 n_below_row[move_index] <= number_row_7[move_index];
							 
							 p_above_row <= pressed_row_5;
							 p_current_row <= pressed_row_6;
							 p_below_row <= pressed_row_7;
							 
							 m_above_row <= mine_row_5;
							 m_current_row <= mine_row_6;
							 m_below_row <= mine_row_7;
						end
						7:
						begin
							 n_above_row[move_index] <= number_row_6[move_index];
							 n_current_row[move_index] <= number_row_7[move_index];
							 // n_below_row <= ...
							 
							 p_above_row <= pressed_row_6;
							 p_current_row <= pressed_row_7;
							 //p_below_row <= pressed_row_2;
							 
							 m_above_row <= mine_row_6;
							 m_current_row <= mine_row_7;
							 //m_below_row <= 
						end
						endcase //end case(target_row)
					end //end CASCADE_MOVE
					
					SETUP_ENQUEUE:
					begin
						//NSL
						cascade_state <= ENQUEUE;
						
						//RTL
						case(cascade_index)
						0:
						begin
							if ( target_row > 0 && target_col > 0)
							begin
								// uncover
								p_above_row[target_col - 1] <= 1;
								
								if ( p_above_row[target_col - 1] == 0 && n_above_row[target_col - 1] == 0)
								begin
									row_to_enqueue <= target_row-1;
									col_to_enqueue <= target_col-1;
									add_to_queue <= 1;
								end
							end
						end
						1:
						begin
							if ( target_row > 0)
							begin
								// uncover
								p_above_row[target_col] <= 1;
								
								if ( p_above_row[target_col] == 0 && n_above_row[target_col] == 0)
								begin
									row_to_enqueue <= target_row-1;
									col_to_enqueue <= target_col;
									add_to_queue <= 1;
								end
							end
						end
						2:
						begin
							if ( target_row > 0 && target_col < 7)
							begin
								// uncover
								p_above_row[target_col + 1] <= 1;
								
								if ( p_above_row[target_col + 1] == 0 && n_above_row[target_col + 1] == 0)
								begin
									row_to_enqueue <= target_row-1;
									col_to_enqueue <= target_col+1;
									add_to_queue <= 1;
								end
							end
						end
						3:
						begin
							if (target_col > 0)
							begin
								// uncover
								p_current_row[target_col - 1] <= 1;
								
								if ( p_current_row[target_col - 1] == 0 && n_current_row[target_col - 1] == 0)
								begin
									row_to_enqueue <= target_row;
									col_to_enqueue <= target_col-1;
									add_to_queue <= 1;
								end
							end
						end
						4:
						begin
							if (target_col < 7)
							begin
								// uncover
								p_current_row[target_col + 1] <= 1;
								
								if ( p_current_row[target_col + 1] == 0 && n_current_row[target_col + 1] == 0)
								begin
									row_to_enqueue <= target_row;
									col_to_enqueue <= target_col+1;
									add_to_queue <= 1;
								end
							end
						end
						5:
						begin
							if (target_row < 7 && target_col > 0)
							begin
								// uncover
								p_below_row[target_col - 1] <= 1;
								
								if ( p_below_row[target_col - 1] == 0 && n_below_row[target_col - 1] == 0)
								begin
									row_to_enqueue <= target_row+1;
									col_to_enqueue <= target_col-1;
									add_to_queue <= 1;
								end
							end
						end
						6:
						begin
							if (target_row < 7)
							begin
								// uncover
								p_below_row[target_col] <= 1;
							
								if ( p_below_row[target_col] == 0 && n_below_row[target_col] == 0)
								begin
									row_to_enqueue <= target_row+1;
									col_to_enqueue <= target_col;
									add_to_queue <= 1;
								end
							end
						end
						7:
						begin
						if (target_row < 7 && target_col < 7)
							begin
								// uncover
								p_below_row[target_col + 1] <= 1;
								
								if ( p_below_row[target_col + 1] == 0 && n_below_row[target_col + 1] == 0)
								begin
									row_to_enqueue <= target_row+1;
									col_to_enqueue <= target_col+1;
									add_to_queue <= 1;
								end
							end
						end
						endcase // end case(cascade_index)
					end //end SETUP_ENQUEUE
					
					ENQUEUE:
					begin
						//NSL
						if (queue_length > 0 && cascade_index==7)
							cascade_state <= CASCADE_PUT_BACK;
						else if (queue_length==0 && cascade_index==7)
						begin
							cascade_state <= CASCADE_PUT_BACK;
							
							//flush queue
							row_index_queue <= 0;
							col_index_queue <= 0;
							insert_at <= 0;
							next_at <= 0;
							row_to_enqueue <= 0;
							col_to_enqueue <= 0;
							add_to_queue <= 0;
						end
						else
						begin
							cascade_state <= SETUP_ENQUEUE;
						end
						
						//RTL
						if (cascade_index == 7)
							cascade_index <= 0;
						else
							cascade_index <= cascade_index + 1;
							
						// always reset variable
						add_to_queue <= 0;
						
						if (add_to_queue == 1)
						begin
							//and add to queue
							row_index_queue[insert_at] <= row_to_enqueue[0];
							row_index_queue[insert_at+1] <= row_to_enqueue[1];
							row_index_queue[insert_at+2] <= row_to_enqueue[2];
							col_index_queue[insert_at] <= col_to_enqueue[0];
							col_index_queue[insert_at+1] <= col_to_enqueue[1];
							col_index_queue[insert_at+2] <= col_to_enqueue[2];
							insert_at <= insert_at + 3;
						end
						
					end //end ENQUEUE
					
					CASCADE_PUT_BACK:
					begin
					// NSL
					if (queue_length==0)
					begin
						compute_state <= PRINT;
						cascade_state <= CASCADE_MOVE;
					end
					else
					begin
						cascade_state <= DEQUEUE;
					end
					
					//RTL
					case(target_row)
						0:
						begin
							 //p_above
							 pressed_row_0 <= p_current_row;
							 pressed_row_1 <= p_below_row;
						end
						1:
						begin
							 pressed_row_0 <= p_above_row; 
							 pressed_row_1 <= p_current_row;
							 pressed_row_2 <= p_below_row;
						end
						2:
						begin
							 pressed_row_1 <= p_above_row; 
							 pressed_row_2 <= p_current_row;
							 pressed_row_3 <= p_below_row;
						end
						3:
						begin
							 pressed_row_2 <= p_above_row; 
							 pressed_row_3 <= p_current_row;
							 pressed_row_4 <= p_below_row;
						end
						4:
						begin
							 pressed_row_3 <= p_above_row; 
							 pressed_row_4 <= p_current_row;
							 pressed_row_5 <= p_below_row;
						end
						5:
						begin
							 pressed_row_4 <= p_above_row; 
							 pressed_row_5 <= p_current_row;
							 pressed_row_6 <= p_below_row;
						end
						6:
						begin
							 pressed_row_5 <= p_above_row; 
							 pressed_row_6 <= p_current_row;
							 pressed_row_7 <= p_below_row;
						end
						7:
						begin
							 pressed_row_6 <= p_above_row; 
							 pressed_row_7 <= p_current_row;
							 //p_below_row <= pressed_row_;
						end
						endcase //end case(target_row)
					
					end // end CASCADE_PUT_BACK
					
					DEQUEUE:
					begin
						//NSL
						cascade_state <= CASCADE_MOVE;
						
						//RTL
						target_row[0] <= row_index_queue[next_at];
						target_row[1] <= row_index_queue[next_at+1];
						target_row[2] <= row_index_queue[next_at+2];
						target_col[0] <= col_index_queue[next_at];
						target_col[1] <= col_index_queue[next_at+1];
						target_col[2] <= col_index_queue[next_at+2];
						next_at <= next_at + 3;

						//DEBUG PRINT
						//$write("target_row= ");
						//$display("%b",target_row);
						//$write("target_col= ");
						//$display("%b",target_col);
						
					end // end DEQUEUE
					endcase //end case(cascade_state)
				end // end CASCADE
				PRINT:
				begin
					// NSL
						// let print_state 'UPDATE' do all NSL
					// RTL	
					// print output
					case(print_state)
					INPUT:
					begin
						// NSL
						if (print_index == 7)
							print_state <= OUTPUT;
							
						// RTL
						if (print_index == 7)
							print_index <= 0;
						else
							print_index <= print_index + 1;
							
						case(row_index)
						0:
						begin
							n_print_row[print_index] <= number_row_0[print_index];
							m_current_row[print_index] <= mine_row_0[print_index];
							p_current_row[print_index] <= pressed_row_0[print_index];
							f_current_row[print_index] <= flag_row_0[print_index];
						end
						1:
						begin
							n_print_row[print_index] <= number_row_1[print_index];
							m_current_row[print_index] <= mine_row_1[print_index];
							p_current_row[print_index] <= pressed_row_1[print_index];
							f_current_row[print_index] <= flag_row_1[print_index];
						end
						2: 
						begin
							n_print_row[print_index] <= number_row_2[print_index];
							m_current_row[print_index] <= mine_row_2[print_index];
							p_current_row[print_index] <= pressed_row_2[print_index];
							f_current_row[print_index] <= flag_row_2[print_index];
						end
						3: 
						begin
							n_print_row[print_index] <= number_row_3[print_index];
							m_current_row[print_index] <= mine_row_3[print_index];
							p_current_row[print_index] <= pressed_row_3[print_index];
							f_current_row[print_index] <= flag_row_3[print_index];
						end
						4:
						begin	
							n_print_row[print_index] <= number_row_4[print_index];
							m_current_row[print_index] <= mine_row_4[print_index];
							p_current_row[print_index] <= pressed_row_4[print_index];
							f_current_row[print_index] <= flag_row_4[print_index];
						end
						5:
						begin	
							n_print_row[print_index] <= number_row_5[print_index];
							m_current_row[print_index] <= mine_row_5[print_index];
							p_current_row[print_index] <= pressed_row_5[print_index];
							f_current_row[print_index] <= flag_row_5[print_index];
						end
						6:
						begin	
							n_print_row[print_index] <= number_row_6[print_index];
							m_current_row[print_index] <= mine_row_6[print_index];
							p_current_row[print_index] <= pressed_row_6[print_index];
							f_current_row[print_index] <= flag_row_6[print_index];
						end
						7:
						begin	
							n_print_row[print_index] <= number_row_7[print_index];
							m_current_row[print_index] <= mine_row_7[print_index];
							p_current_row[print_index] <= pressed_row_7[print_index];
							f_current_row[print_index] <= flag_row_7[print_index];
						end
						endcase // end INPUT case statement
					end
					OUTPUT:
					begin
						// NSL
						if (col_index == 7)
							print_state <= UPDATE;
							
						// RTL
						if (col_index == 7)
							col_index <= 0;
						else
							col_index <= col_index + 1;
							

						// output value in current row and index
						//$display("R: %d, C: %d, Mine: %d",row_index, col_index, m_current_spot);
						
						if (p_current_row[col_index] == 0)
							if (col_index == 7)
							begin
								if (f_current_row[col_index]==1)
									$write("  #\n");
								else
									$write("  -\n");
							end
							else
							begin
								if (f_current_row[col_index]==1)
									$write("  #");
								else
									$write("  -");
							end
						else if (m_current_row[col_index] == 1)
						begin

							if (col_index == 7)
								$write("  *\n");
							else
								$write("  *");
						end
						else
							if (n_print_row[col_index] == 0)
							begin
								if (col_index == 7)
									$write("  0\n");
								else
									$write("  0");
							end
							else if (n_print_row[col_index] == 1)
							begin
								if (col_index == 7)
									$write("  1\n");
								else
									$write("  1");
							end
							else if (n_print_row[col_index] == 2)
							begin
								if (col_index == 7)
									$write("  2\n");
								else
									$write("  2");
							end
							else if (n_print_row[col_index] == 3)
							begin
								if (col_index == 7)
									$write("  3\n");
								else
									$write("  3");
							end
							else
							begin
								if (col_index == 7)
									$display(n_print_row[col_index]);
								else
									$write(n_print_row[col_index]);
							end
					end
					UPDATE:
					begin
						// NSL
						print_state <= INPUT;
						
						if (row_index == 7)
						begin
							compute_state <= CHECK_GAME_OVER;
							$display("");
							$display("");
						end
							
						// RTL
						col_index <= 0;
						if (row_index == 7)
							row_index <= 0;
						else
							row_index <= row_index + 1;
					end
					endcase // end print_state case statement
					
				end // end print state
				CHECK_GAME_OVER:
				begin
					
					case(check_game_over_state)
					OVER_INIT:
					begin
						//$display("Checking if game is over...");
						// NSL
						check_game_over_state <= OVER_ITERATE_COLS;
						if (done == 1)
							state <= DONE;
					
						// RTL
						// initial check, if set other places in program
						if (done == 1)
						begin
							if (lost == 1)
								$display("AI clicked a mine! Game is lost.");
							else 
								$display("AI Won!");
						end
						else
						begin
							row_index <= 0;
							col_index <= 0;
							end_game_flagged <= 0;
							end_game_pressed <= 0;
						end
					end
					OVER_ITERATE_COLS:
					begin
						// NSL
						if (col_index == 7)
							check_game_over_state <= OVER_INC_ROW;
					
						// RTL
						
						if (col_index == 7)
							col_index <= 0;
						else 
							col_index <= col_index + 1;
							
							
						case(row_index)
						0:
						begin
							if (flag_row_0[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_0[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						1:
						begin
							if (flag_row_1[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_1[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						2:
						begin
							if (flag_row_2[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_2[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						3:
						begin
							if (flag_row_3[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_3[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						4:
						begin
							if (flag_row_4[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_4[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						5:
						begin
							if (flag_row_5[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_5[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						6:
						begin
							if (flag_row_6[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_6[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						7:
						begin
							if (flag_row_7[col_index] == 1)
								end_game_flagged <= end_game_flagged + 1;
								
							if (pressed_row_7[col_index] == 1)
								end_game_pressed <= end_game_pressed + 1;
						end
						
						endcase // end case(row_index)
					end
					OVER_INC_ROW:
					begin
						// NSL
						if (row_index == 7)
							check_game_over_state <= OVER_RESULT;
						else 
							check_game_over_state <= OVER_ITERATE_COLS;
							
						// RTL	
						if (row_index == 7)
							row_index <= 0;
						else 
							row_index <= row_index + 1;

						
					end
					OVER_RESULT:
					begin
						// NSL
						check_game_over_state <= OVER_INIT;

						if (end_game_flagged == num_mines && end_game_pressed == (64 - num_mines))
						begin
							done <= 1;
							lost <= 0; // i.e., won
						end
						else
						begin
							done <= 0; // not done
							compute_state <= FINDING_SPOT;
						end
						// RTL
					end
					
					endcase // end case(check_game_over_state)
					
				end // end CHECK_GAME_OVER
				
				endcase //end compute_state case statement
			end // end COMPUTE
			DONE:
			begin
				// wait here until end of testbench cycle
			end // end DONE
			endcase // end overall state machine case statement
		end // end 'else' for if !reset
	end // end always block
	
endmodule 