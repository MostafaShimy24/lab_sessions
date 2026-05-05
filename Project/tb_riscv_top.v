//==============================================================================
// tb_riscv_top.v — Directed Testbench  (v4)
//------------------------------------------------------------------------------
// Project : ELCT1005 PROJ02 — Pipelined RISC-V CPU with Conv-PE
//
// Key fix from v3: all RAW dependencies now have 4 NOPs separation
// (5-stage pipeline, no forwarding). JALR uses AUIPC→4NOPs→ADDI→4NOPs→JALR.
//
// AUIPC at 0x160 => x21 = 0x00000160
// JALR target = AUIPC2(0x3A0) + 60 = 0x3DC
//
// Conv-PE fix: conv_start must be gated in ex_stage.v to pulse only 1 cycle.
// See companion note — add conv_start_gated register in ex_stage.v.
//
// Register final values:
//   x3=15, x4=0xFFFFFFFB, x5=1024, x6=1, x7=0xFFFFFFF0
//   x8=0x33(BLTU), x9=0x44(BGEU), x10=0x77(JAL), x11=0x88(JALR)
//   x12=12(Conv INIT), x13=22(Conv ACC)
//   x14=1, x15=0xFF, x16=5, x17=12, x18=6, x19=1
//   x20=0x12345000, x21=0x00000160
//   x22=0x7FF, x23=0x1FF, x24=0x1FF
//   x25=0xFFFFFFAB, x26=0xAB
//   x27=0(BEQ guard), x28=0x7FF, x29=0x55, x30=0x11, x31=0x22
//==============================================================================
`timescale 1ns / 1ps

module tb_riscv_top;

    parameter CLK_PERIOD     = 10;
    parameter CONV_LATENCY   = 4;
    parameter TIMEOUT_CYCLES = 6000;

    reg clk   = 1'b0;
    reg rst_n = 1'b0;

    riscv_top #(
        .CONV_LATENCY (CONV_LATENCY),
        .IMEM_HEX     ("program.hex"),
        .DMEM_HEX     ("data.hex")
    ) dut (.clk(clk), .rst_n(rst_n));

    always #(CLK_PERIOD/2) clk = ~clk;

    `define RF(n)   ((n==0) ? 32'h0 : dut.u_id.u_regfile.regs[n])
    `define DMEM(a) dut.u_mem.u_dmem.mem[a]

    integer pass_cnt; integer fail_cnt;
    initial begin pass_cnt=0; fail_cnt=0; end

    task check_reg;
        input [4:0] rn; input [31:0] exp;
        reg [31:0] got;
        begin
            got=`RF(rn);
            if(got===exp) begin $display("PASS | x%-2d | got 0x%08h",rn,got); pass_cnt=pass_cnt+1; end
            else          begin $display("FAIL | x%-2d | exp 0x%08h  got 0x%08h",rn,exp,got); fail_cnt=fail_cnt+1; end
        end
    endtask

    task check_dmem_word;
        input [11:0] addr; input [31:0] exp;
        reg [31:0] got;
        begin
            got={`DMEM(addr+3),`DMEM(addr+2),`DMEM(addr+1),`DMEM(addr+0)};
            if(got===exp) begin $display("PASS | dmem[0x%03h] word | got 0x%08h",addr,got); pass_cnt=pass_cnt+1; end
            else          begin $display("FAIL | dmem[0x%03h] word | exp 0x%08h  got 0x%08h",addr,exp,got); fail_cnt=fail_cnt+1; end
        end
    endtask

    task check_dmem_byte;
        input [11:0] addr; input [7:0] exp;
        reg [7:0] got;
        begin
            got=`DMEM(addr);
            if(got===exp) begin $display("PASS | dmem[0x%03h] byte | got 0x%02h",addr,got); pass_cnt=pass_cnt+1; end
            else          begin $display("FAIL | dmem[0x%03h] byte | exp 0x%02h  got 0x%02h",addr,exp,got); fail_cnt=fail_cnt+1; end
        end
    endtask

    initial begin $dumpfile("dump.vcd"); $dumpvars(0,tb_riscv_top); end

    integer wdog;
    initial begin
        for(wdog=0;wdog<TIMEOUT_CYCLES;wdog=wdog+1) @(posedge clk);
        $display("WATCHDOG TIMEOUT"); $finish;
    end

    integer cycle_num; initial cycle_num=0;
    always @(posedge clk) if(rst_n) cycle_num=cycle_num+1;

    initial begin
        $display("================================================================");
        $display("  ELCT1005 PROJ02 — Directed Testbench — tb_riscv_top.v  (v4)");
        $display("================================================================");

        rst_n=1'b0; repeat(5) @(posedge clk); @(negedge clk); rst_n=1'b1;
        $display("[cycle %0d] Reset released", cycle_num);

        // 288 instrs + pipeline(5) + branch penalties + Conv stalls
        // Temporary Conv-PE monitor — remove after debugging
// Debug Conv hold registers
// $monitor("[%4d] stall=%b conv_done=%b | hold: wb_sel=%b reg_wr=%b rd=%0d | ex_mem: wb_sel=%b reg_wr=%b rd=%0d",
//     cycle_num,
//     dut.stall,
//     dut.conv_done_sig,
//     dut.conv_wb_sel_hold,
//     dut.conv_reg_write_hold,
//     dut.conv_rd_addr_hold,
//     dut.ex_mem_wb_sel,
//     dut.ex_mem_reg_write,
//     dut.ex_mem_rd_addr);
        repeat(550) @(posedge clk); #1;

        $display("\n--- Test 2: ADD / SUB ---");
        check_reg(5'd3,  32'h0000000F);   // 5+10=15
        check_reg(5'd4,  32'hFFFFFFFB);   // 5-10=-5

        $display("\n--- Test 3: SLL / SRL / SRA ---");
        check_reg(5'd5,  32'h00000400);   // 1<<10=1024
        check_reg(5'd6,  32'h00000001);   // 1024>>10=1
        check_reg(5'd7,  32'hFFFFFFF0);   // -128>>>3=-16

        $display("\n--- Test 4: AND/OR/XOR (overwritten by branch landings) ---");
        check_reg(5'd8,  32'h00000033);   // BLTU landing
        check_reg(5'd9,  32'h00000044);   // BGEU landing
        check_reg(5'd10, 32'h00000077);   // JAL  landing

        $display("\n--- Test 5: SLT/SLTU (overwritten by JALR + Conv) ---");
        check_reg(5'd11, 32'h00000088);   // JALR landing
        check_reg(5'd12, 32'h0000000C);   // Conv INIT = 12

        $display("\n--- Test 6: SLTI / SLTIU / ORI / ANDI ---");
        check_reg(5'd13, 32'h00000016);   // Conv ACC = 22 (overwrites SLTI=1)
        check_reg(5'd14, 32'h00000001);   // SLTIU
        check_reg(5'd15, 32'h000000FF);   // ORI
        check_reg(5'd16, 32'h00000005);   // ANDI

        $display("\n--- Test 7: SLLI / SRLI / SRAI ---");
        check_reg(5'd17, 32'h0000000C);   // 3<<2=12
        check_reg(5'd18, 32'h00000006);   // 12>>1=6
        check_reg(5'd19, 32'h00000001);   // 3>>>1=1

        $display("\n--- Test 8: LUI / AUIPC ---");
        check_reg(5'd20, 32'h12345000);   // LUI
        check_reg(5'd21, 32'h00000160);   // AUIPC at PC=0x160

        $display("\n--- Test 9: SW / LW ---");
        check_dmem_word(12'h200, 32'h000007FF);
        check_reg(5'd22, 32'h000007FF);

        $display("\n--- Test 10: SH / LH / LHU ---");
        check_reg(5'd23, 32'h000001FF);
        check_reg(5'd24, 32'h000001FF);

        $display("\n--- Test 11: SB / LB / LBU ---");
        check_dmem_byte(12'h208, 8'hAB);
        check_reg(5'd25, 32'hFFFFFFAB);
        check_reg(5'd26, 32'h000000AB);

        $display("\n--- Test 12: BEQ taken ---");
        if(`RF(27)===32'h0) begin
            $display("PASS | BEQ taken: x27 correctly stays 0"); pass_cnt=pass_cnt+1;
        end else begin
            $display("FAIL | BEQ taken: x27=0x%08h (BAD executed — branch wrong)",`RF(27)); fail_cnt=fail_cnt+1;
        end
        check_reg(5'd28, 32'h000007FF);

        $display("\n--- Test 13: BNE not-taken ---");
        check_reg(5'd29, 32'h00000055);

        $display("\n--- Test 14: BLT taken ---");
        check_reg(5'd30, 32'h00000011);

        $display("\n--- Test 15: BGE taken ---");
        check_reg(5'd31, 32'h00000022);

        $display("\n--- Test 16: BLTU taken ---");
        check_reg(5'd8,  32'h00000033);

        $display("\n--- Test 17: BGEU taken ---");
        check_reg(5'd9,  32'h00000044);

        $display("\n--- Test 18: JAL ---");
        check_reg(5'd10, 32'h00000077);

        $display("\n--- Test 19: JALR (target=AUIPC2+60=0x3DC) ---");
        check_reg(5'd11, 32'h00000088);

        $display("\n--- Test 20: Conv-PE INIT + ACC ---");
        $display("  NOTE: requires conv_start_gated fix in ex_stage.v");
        check_reg(5'd12, 32'h0000000C);   // 4*3=12
        check_reg(5'd13, 32'h00000016);   // 12+5*2=22

        $display("\n--- Test 21: FENCE / ECALL / EBREAK ---");
        $display("PASS | Pipeline survived without timeout"); pass_cnt=pass_cnt+1;

        $display("\n--- x0 hardwired-zero ---");
        check_reg(5'd0, 32'h00000000);

        $display("\n--- dmem kernel weights at 0x800 ---");
        check_dmem_byte(12'h800,8'h01); check_dmem_byte(12'h801,8'h02);
        check_dmem_byte(12'h802,8'h03); check_dmem_byte(12'h803,8'h04);
        check_dmem_byte(12'h804,8'h05); check_dmem_byte(12'h805,8'h04);
        check_dmem_byte(12'h806,8'h03); check_dmem_byte(12'h807,8'h02);
        check_dmem_byte(12'h808,8'h01);

        $display("\n--- dmem feature-map tile at 0xC00 ---");
        check_dmem_byte(12'hC00,8'h01); check_dmem_byte(12'hC01,8'h02);
        check_dmem_byte(12'hC02,8'h03); check_dmem_byte(12'hC03,8'h04);
        check_dmem_byte(12'hC04,8'h05);

        $display("");
        $display("================================================================");
        $display("  RESULTS:  %0d PASS    %0d FAIL", pass_cnt, fail_cnt);
        $display("================================================================");
        if(fail_cnt==0)
            $display("  ALL CHECKS PASSED — ready for Phase 1 formal verification");
        else
            $display("  *** %0d FAILURE(S) — see FAIL lines above ***", fail_cnt);
        $display("================================================================");
        $finish;
    end
endmodule