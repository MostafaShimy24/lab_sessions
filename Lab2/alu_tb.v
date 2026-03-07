`timescale 1ns / 1ps

module alu_tb;

    // Inputs
    reg clock;
    reg reset;
    reg start_port;
    reg [31:0] a;
    reg [31:0] b;
    reg [7:0]  opcode;

    // Outputs
    wire done_port;
    wire [31:0] return_port;

    // Instantiate DUT
    alu dut (
        .clock(clock),
        .reset(reset),
        .start_port(start_port),
        .a(a),
        .b(b),
        .opcode(opcode),
        .done_port(done_port),
        .return_port(return_port)
    );

    //-----------------------------------------
    // Clock generation (10ns period)
    //-----------------------------------------
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    //-----------------------------------------
    // Dump waveform
    //-----------------------------------------
    initial begin
        $dumpfile("alu_simulation.vcd");
        $dumpvars(0, alu_tb);
    end

    //-----------------------------------------
    // Stimulus
    //-----------------------------------------
    initial begin

        // Initial values
        reset = 0;
        start_port = 0;
        a = 0;
        b = 0;
        opcode = 0;

        // Release reset
        #20;
        reset = 1;

        //-------------------------------------------------
        // ADD (opcode = 0)
        //-------------------------------------------------
        #10;
        a = 20;
        b = 5;
        opcode = 0;
        start_port = 1;
        #10;
        start_port = 0;

        #10;

        //-------------------------------------------------
        // SUB (opcode = 1)
        //-------------------------------------------------
        a = 20;
        b = 5;
        opcode = 1;
        start_port = 1;
        #10;
        start_port = 0;

        #10;

        //-------------------------------------------------
        // MUL (opcode = 2)
        //-------------------------------------------------
        a = 20;
        b = 5;
        opcode = 2;
        start_port = 1;
        #10;
        start_port = 0;

        #10;

        //-------------------------------------------------
        // AND (opcode = 3)
        //-------------------------------------------------
        a = 20;
        b = 5;
        opcode = 3;
        start_port = 1;
        #10;
        start_port = 0;

        #10;

        //-------------------------------------------------
        // OR (opcode = 4)
        //-------------------------------------------------
        a = 20;
        b = 5;
        opcode = 4;
        start_port = 1;
        #10;
        start_port = 0;

        #10;

        //-------------------------------------------------
        // XOR (opcode = 5)
        //-------------------------------------------------
        a = 20;
        b = 5;
        opcode = 5;
        start_port = 1;
        #10;
        start_port = 0;

        #10;

        //-------------------------------------------------
        // SLL (opcode = 6)
        //-------------------------------------------------
        a = 20;
        b = 5;
        opcode = 6;
        start_port = 1;
        #10;
        start_port = 0;

        #10;

        //-------------------------------------------------
        // SRL (opcode = 7)
        //-------------------------------------------------
        a = 20;
        b = 5;
        opcode = 7;
        start_port = 1;
        #10;
        start_port = 0;

        #50;

        $finish;
    end

endmodule
