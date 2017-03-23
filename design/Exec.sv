module Exec(
	input logic clk, reset, stall, flush
	input logic PCSrcD,
	input logic RegWriteD,
	input logic MemtoRegD,
	input logic MemWriteD,
	input logic [3:0] ALUControlD,
	input logic BranchD,
	input logic ALUSrcD,
	input logic [1:0] FlagWriteD,
	input logic ImmSrcD,
	input logic [3:0] CondD,
	input logic [3:0] WriteAddrD,
	input logic [31:0] Rd1D, Rd2D, ExtD,
	input logic [1:0] forwardAE, forwardBE,
	input logic [31:0] ALUResultM,
	input logic [31:0] ResultW,
	// shifter input logic
	input logic Immediate,
	input logic [1:0] Sh,
	input logic [4:0] Shamt,
	input logic IsRegister, Carry,
	input logic [31:0] RsShiftD, // remember to parse this to 8 bits
	
	output logic PCSrcM,
	output logic RegWriteM,
	output logic MemtoRegM,
	output logic MemWriteM,
	output logic [31:0] ALUResultM,
	output logic [31:0] WriteDataM,
	output logic [3:0] WriteAddrM
	);

	// internal signal declarations
		logic 	PCSrcE, RegWriteE, MemWriteE, MemtoRegE, 
			ALUSrcE, FlagWriteE, ImmSrcE, BranchE;
		logic [1:0] FlagWriteE;
		logic [3:0] WriteAddrE, CondE, ALUControlE;
		logic [31:0] Rd1E, Rd2E, ExtE;

		logic [31:0] OpA, OpB, nonImmOpB;
		logic [3:0] ALUFlags;
		logic carryIn;
		// signal for shifter output
		logic ShiftOut;
		logic ShiftCarry;

	// Assignments and logic
	
		MemtoRegM <= MemtoRegE;
		WriteAddrM <= WriteAddrE;
		WriteDataM <= nonImmOpB;

	// declaring other modules
		// I did not include Flags in Exec.sv because the flags
		// already get delayed by 1 clock cycle in the condlogic.sv.
		// If this is not correct, add flags as an input port and
		// include flags into this pipereg below. -Julian
		pipereg reg ((clk & ~stall), flush, PCSrcD, RegWriteD, MemtoRegD, MemWriteD, ALUSrcD, 
				FlagWriteD, ALUControlD, /*Flags*/, CondD, Rd1D, Rd2D, RsShiftD, ExtD,
				PCSrcE, RegWriteE, MemWriteE, ALUSrcE, FlagWriteE, ALUControlE, CondE, 
				FlagsE, Rd1E, Rd2E, RsShiftE, ExtE);
		
		// INPUT clk, reset, [3:0] cond, [3:0] ALUFlags
		// INPUT [1:0] FlagW, PCS, RegW, MemW,
		// OUTPUT PCSrc, RegWrite, MemWrite
		condlogic cond (clk, reset, condE, ALUFlags, FlagWriteE, PCSrcE, RegWriteE, MemWriteE, BranchE,
				PCSrcM, RegWriteM, MemWriteM); 
		
		// INPUT [31:0] Rm, [7:0] RsShift, Immediate, [1:0] Sh, [4:0] Shamt, IsRegister, Carry
		// OUTPUT [31:0] Result, ShiftCarry,
		// INPUT [3:0] ALUControl
		shifter shft (nonImmOpB, RsShift, Immediate, Sh, Shamt, IsRegister, Carry, 
				ShiftOut, ShiftCarry, ALUControlE);
		
		// mux
		mux3 m1(Rd1E, ResultW, ALUResultM, forwardAE, OpA);
		mux3 m2(Rd2E, ResultW, ALUResultM, forwardBE, nonImmOpB);
		mux2 m3(ShiftOut, ExtE, ALUSrcE, OpB);

		alu a(OpA, OpB, ALUControlE, ALUResultE, ALUFlags, carryIn);

endmodule