module FIR(
		input logic CLOCK_50,
		input logic rst,
		input logic [0:0] SW,
		output logic [0:0] LEDR,
		output logic [6:0] HEX1, 
//		input logic input_ready,
		output logic clk_05,
		output logic signed [15:0] out);
//		output logic output_ready);

	parameter N = 16;
	
	logic signed [31:0] addr = 0;
	
	int in=0; 
	int input_ready=0;
	int output_ready=0;
	
	logic en_1 = 0, en_2 = 0;
	
	enum {
		state_1,
		state_2,
		state_3
	}state, next_state;
	
	// ----- BUFFER
	logic signed [0:N-1] [N-1:0] buffer = '{16{16'd0}};
	
	// ----- COEFFICIENTS
	logic signed [0:N-1] [N-1:0] coefficients = '{
		-81,			-134,			318,			645,
		-1257,		-2262,		4522,			14633,
		14633,		4522,			-2262,		-1257,
		645,			318,			-134,			-81
	};
	
	reg [26:0] trimmer;
   //int counter=0;
	
	always_ff @(negedge rst, negedge CLOCK_50)
	begin 
		if (~rst)
			begin 
				trimmer<=0;
				clk_05<=0;
			end 
			else 
			begin 
				if (trimmer==20000000)
				begin 
					clk_05<=~clk_05;
					trimmer<=0; 
				end 
				else 
				begin
					trimmer<=trimmer+1;
				end
			end
		end
	
	
	// ----- FLAGS
	always_comb
		begin
			case (state)
			
					state_1: 
						begin
							if (input_ready) 
								begin
									next_state = state_2;
								end
							else
								begin
									next_state = state_1;
								end
						end
						
					state_2:
						begin
							if (en_2)
								begin
									next_state = state_3;
								end
							else
								begin
									next_state = state_2;
								end
						end
						
					state_3:
						begin
							if (output_ready)
								begin
									next_state = state_1;
								end
							else
								begin
									next_state = state_3;
								end
						end
				endcase
		end
		
		
	// ----- CHANGE STATE
	always_ff @(posedge clk_05, negedge rst)
		begin
			if (~rst)
				begin
					state <= state_1;
				end
			else
				begin
					state <= next_state;
				end
		end
	/////////////////////////////////////
		
	// ----- LOGIC
	always_ff @(posedge clk_05, negedge rst) 
		begin
			if(~rst)
				begin
					en_1 <= 0;
					en_2 <= 0;
					out <= 0;
					LEDR<=0;
					output_ready <= 0;
					addr <= 0;
					buffer <= '{16{16'd0}};
				end
			else
				begin
				if(SW==1)begin
					in=1;
					input_ready=1;
					//LEDR=1; 
					end
					else 
					begin 
			
					case (state)
				
						state_1:
							begin
								output_ready <= 0;
								en_1 <= 1;
								out <= addr;
							end
							
						state_2:
							begin
								en_1 <= 0;
								en_2 <= 1;
								addr <= 0;
								if (en_1)
									begin
										buffer <= {in, buffer[0:14]};
									end
							end
							
						state_3:
							begin
								en_2 <= 0;
//								output_ready <= 1;
								if (en_2)
									begin
										for (int i = 0; i < N; i++)
											begin
												addr = addr + coefficients[i] * buffer[i];
											end
											LEDR[0]<=1;
											output_ready <= 1;
									end
							end
					
					endcase
					
				end
				
		end
		end 
		
	always_ff @(posedge clk_05)
	begin
		
	 if (output_ready==1)
			begin 
			HEX1<=7'b1000000 ;
			end 
		end 
		
endmodule

