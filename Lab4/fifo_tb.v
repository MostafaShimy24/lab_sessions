`timescale 1ns/1ps

module fifo_tb;

parameter D_SIZE = 8;
parameter A_SIZE = 3;
parameter P_SIZE = 4;
parameter F_DEPTH = 8;

reg w_clk;
reg r_clk;

reg w_rstn;
reg r_rstn;

reg w_inc;
reg r_inc;

reg [D_SIZE-1:0] w_data;

wire [D_SIZE-1:0] r_data;
wire full;
wire empty;

integer i;

////////////////////////////////////////////////////////
// Scoreboard Model
////////////////////////////////////////////////////////

reg [D_SIZE-1:0] model_fifo [0:F_DEPTH-1];

integer wr_ptr = 0;
integer rd_ptr = 0;
integer count  = 0;

integer errors = 0;

////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////

Async_fifo #(
.D_SIZE(D_SIZE),
.A_SIZE(A_SIZE),
.P_SIZE(P_SIZE),
.F_DEPTH(F_DEPTH)
) dut(

.i_w_clk(w_clk),
.i_w_rstn(w_rstn),
.i_w_inc(w_inc),

.i_r_clk(r_clk),
.i_r_rstn(r_rstn),
.i_r_inc(r_inc),

.i_w_data(w_data),

.o_r_data(r_data),
.o_full(full),
.o_empty(empty)

);

////////////////////////////////////////////////////////
// CLOCKS
////////////////////////////////////////////////////////

initial w_clk = 0;
always #5 w_clk = ~w_clk;

initial r_clk = 0;
always #7 r_clk = ~r_clk;

////////////////////////////////////////////////////////
// RESET
////////////////////////////////////////////////////////

initial begin

w_rstn = 0;
r_rstn = 0;

w_inc = 0;
r_inc = 0;

#40;

w_rstn = 1;
r_rstn = 1;

end

////////////////////////////////////////////////////////
// SCOREBOARD WRITE
////////////////////////////////////////////////////////

always @(posedge w_clk)
begin

if(w_inc && !full)
begin

model_fifo[wr_ptr] = w_data;

wr_ptr = (wr_ptr + 1) % F_DEPTH;

count = count + 1;

end

if(w_inc && full)
begin

$display("OVERFLOW ATTEMPT DETECTED");

end

end

////////////////////////////////////////////////////////
// SCOREBOARD READ CHECK
////////////////////////////////////////////////////////
initial begin
    $dumpfile("simulation.vcd");
    $dumpvars(0, fifo_tb);
end
reg [D_SIZE-1:0] expected;

always @(posedge r_clk)
begin

if(r_inc && !empty)
begin

expected = model_fifo[rd_ptr];

if(expected !== r_data)
begin

$display("DATA MISMATCH: expected=%0d got=%0d",expected,r_data);

errors = errors + 1;

end
else
begin

$display("DATA OK: %0d",r_data);

end

rd_ptr = (rd_ptr + 1) % F_DEPTH;

count = count - 1;

end

if(r_inc && empty)
begin

$display("UNDERFLOW ATTEMPT DETECTED");

end

end

////////////////////////////////////////////////////////
// TEST 1
// Sequential write until full
////////////////////////////////////////////////////////

task test_write_until_full;

begin

$display("===================================");
$display("TEST 1: WRITE UNTIL FIFO FULL");
$display("===================================");

for(i=0;i<10;i=i+1)
begin

@(posedge w_clk);
#1;
w_inc  <= 1;
w_data <= i;

end

@(posedge w_clk);
#1;
w_inc <= 0;

#50;

if(full)
$display("TEST1 PASSED: FULL asserted");
else
begin
$display("TEST1 FAILED: FULL not asserted");
errors = errors + 1;
end

end
endtask

////////////////////////////////////////////////////////
// TEST 2
// Read until empty
////////////////////////////////////////////////////////

task test_read_until_empty;

begin

$display("===================================");
$display("TEST 2: READ UNTIL EMPTY");
$display("===================================");

for(i=0;i<10;i=i+1)
begin

@(posedge r_clk);

r_inc = 1;

end

@(posedge r_clk);

r_inc = 0;

#50;

if(empty)
$display("TEST2 PASSED: EMPTY asserted");
else
begin
$display("TEST2 FAILED: EMPTY not asserted");
errors = errors + 1;
end

end
endtask

////////////////////////////////////////////////////////
// TEST 3
// Simultaneous read/write
////////////////////////////////////////////////////////

task test_simultaneous_rw;

begin

$display("===================================");
$display("TEST 3: SIMULTANEOUS READ/WRITE");
$display("===================================");

for(i=0;i<20;i=i+1)
begin

@(posedge w_clk);
#1;
w_inc  <= $random;
w_data <= $random;

end

for(i=0;i<20;i=i+1)
begin

@(posedge r_clk);

r_inc = $random;

end

#100;

$display("TEST3 COMPLETED");

end
endtask

////////////////////////////////////////////////////////
// TEST 4
// Write while full
////////////////////////////////////////////////////////

task test_write_when_full;

begin

$display("===================================");
$display("TEST 4: WRITE WHEN FIFO FULL");
$display("===================================");

repeat(5)
begin

@(posedge w_clk);
#1;
w_inc <= 1;
w_data <= $random;

end

w_inc = 0;

$display("TEST4 COMPLETED");

end
endtask

////////////////////////////////////////////////////////
// TEST 5
// Read while empty
////////////////////////////////////////////////////////

task test_read_when_empty;

begin

$display("===================================");
$display("TEST 5: READ WHEN FIFO EMPTY");
$display("===================================");

// Drain FIFO first
while(!empty)
begin
    @(posedge r_clk);
    r_inc = 1;
end

r_inc = 0;

#20;

// Now attempt illegal reads
repeat(5)
begin
    @(posedge r_clk);
    r_inc = 1;
end

r_inc = 0;

$display("TEST5 COMPLETED");

end
endtask

////////////////////////////////////////////////////////
// RUN ALL TESTS
////////////////////////////////////////////////////////

initial
begin

wait(w_rstn);

test_write_until_full;

test_read_until_empty;

test_simultaneous_rw;

test_write_when_full;

test_read_when_empty;

#200;

$display("===================================");
$display("SIMULATION RESULT");
$display("===================================");

if(errors == 0)
$display("ALL TESTS PASSED");
else
$display("TESTS FAILED : %0d errors",errors);

$finish;

end

endmodule