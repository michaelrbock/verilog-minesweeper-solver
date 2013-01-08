`timescale 1ns / 1ps

module minesweeper_tb;

	// Inputs
	reg Clk_tb;
	reg Reset_tb;
	reg Start_tb;
	reg Step_tb;

	// Outputs
	
	// Instantiate the Unit Under Test (UUT)
	minesweeper uut (
		.clk(Clk_tb),
		.start(Start_tb), 
		.step(Setp_tb), 
		.reset(Reset_tb)
	);
		
	initial 
	begin
		Clk_tb = 0; // Initialize clock
	end
	
	always  
	begin 
		#10;
		Clk_tb = ~ Clk_tb;
	end
	
	initial begin
	  
	// Initialize Inputs
	#100;
	
	Reset_tb = 1;
	#20;
	Reset_tb = 0;
	#20;
	
	Start_tb = 1;
	#20;

	end //end initial begin
		
endmodule
