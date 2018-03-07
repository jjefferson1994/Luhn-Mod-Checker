module highluhnmod16(
	input clock, rst_n,
	//clk and reset
	
	input size_empty,
	output reg read_num,
	input [7:0] num_nibbles,
	//input header for size
	
	input data_empty,
	output reg read_nibble,
	input [3:0] nibble,
	//input header for data
	
	output reg write_check,
	input check_full,
	output reg good_check
	//input header for data
);

localparam IF_EMPTY_SIZE = 0; //state localparams
localparam READ_INTO_REG_SIZE = 1;
localparam CHECK_STEP_SIZE = 2;
localparam WRITE_STEP = 3;
localparam IF_EMPTY_DATA = 4;
localparam READ_INTO_REG_DATA = 5;
localparam CHECK_STEP_DATA = 6;

reg [2:0] cstate_size,cstate_data,cstate_check,nstate_size,nstate_data,nstate_check; //reg for current and next state
reg [4:0] nibreg; // reg for storing nibble value
reg [7:0] nibsize; // reg for storing nib size
reg [3:0] accum; // reg for accumulator

always @ (posedge clock) //this always block checks for the reset of the state machine at each clock cycle
	begin
	if(!rst_n)
		begin
		cstate_size = IF_EMPTY_SIZE; //I have the state running on the same clock in order to reduce time
		cstate_data = IF_EMPTY_DATA;
		cstate_check = WRITE_STEP;
		
		//this has the output signals to 0
		read_num = 0;
		read_nibble = 0;
		write_check = 0;
		end
	else
		begin
		cstate_size = nstate_size;
		cstate_data = nstate_data;
		cstate_check = nstate_check;
	end
	end
	
always @ (*)
	begin
	//this is the state machine for getting a size
	case(cstate_size)
		IF_EMPTY_SIZE:
		begin
		nibreg = 0;//this resets the registers to 0 before calculations are done on the next size
		nibsize = 5;
		accum = 0;
		
		write_check = 0;//this hard sets write to 0 because this is a new message size
		
		if(!(size_empty == 0)) //checks to see if size is empty
			begin
			read_num = 0;
			nstate_size = IF_EMPTY_SIZE;
			end
		else
			begin
			read_num = 0;
			nibsize = num_nibbles;
			nstate_size = READ_INTO_REG_SIZE;
			end
		end
		
		READ_INTO_REG_SIZE: //reads the size into a register
		begin
		read_num = 1;
		nstate_size = CHECK_STEP_SIZE;
		end
		
		CHECK_STEP_SIZE:
		begin
		read_num = 0;
		if(write_check == 1)
			begin
			nstate_size = IF_EMPTY_SIZE;
			read_num = 0;
			end
		else
			begin
			nstate_size = CHECK_STEP_SIZE;
			read_num = 0;
			end
		end
		
		default:
		begin
		nstate_size = IF_EMPTY_SIZE;
		end
	endcase
	
	//this is a state machine for getting a nibble
	case(cstate_data)
		IF_EMPTY_DATA:
		begin
		if(data_empty == 0)
			begin
			read_nibble = 0;
			nstate_data = READ_INTO_REG_DATA;
			end
		else
			begin
			read_nibble = 0;
			nstate_data = IF_EMPTY_DATA;
			end
		end
		
		READ_INTO_REG_DATA:
		begin
		read_nibble = 1;
		nibreg = nibble;
		
		if(nibsize % 2 == 0)//even size remaining branch
		begin
		nibreg = nibreg << 1;
		nibreg = nibreg[4] + nibreg[3:0];
		end	
		else
		begin
		nibreg = nibreg;
		end
	
		accum = accum + nibreg;
		if(accum == 0)
		good_check = 1;
		else
		good_check = 0;
		
		nibsize = nibsize - 1;
		if(nibsize != 0)
			begin
			nstate_data = IF_EMPTY_DATA;
			end
		else
			nstate_data = READ_INTO_REG_DATA;
		end
		
		default:
		begin
		nstate_data = IF_EMPTY_DATA;
		end
	endcase
	
	//this is a state machine for writing to the fifo
	case(cstate_check)
		WRITE_STEP:
		begin
		if((nibsize == 0) && (check_full==0))
			begin
			write_check = 1;
			nstate_check = WRITE_STEP;
			end
		else
			begin
			write_check = 0;
			nstate_check = WRITE_STEP;
			end
		end
		
		default:
		begin
			write_check = 0;
			nstate_check = WRITE_STEP;
		end
	endcase
	end
endmodule