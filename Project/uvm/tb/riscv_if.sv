//==============================================================================
// riscv_if.sv — Virtual Interface for Hierarchical Backdoor Access
//------------------------------------------------------------------------------
// Bundles clk and rst_n signals for the UVM environment. Agents and monitors
// use cross-module references (XMR) via `tb_top` to access internal DUT
// signals (imem.mem[], dmem.mem[], regfile.regs[], pipeline registers).
//==============================================================================

interface riscv_if (
    input logic clk,
    input logic rst_n
);

    // =========================================================================
    // Clock-edge helpers for monitors
    // =========================================================================
    clocking mon_cb @(posedge clk);
        default input #1step;
    endclocking

    // =========================================================================
    // Monitor Signals (Hierarchical references allowed in interfaces)
    // =========================================================================
    wire        wb_we      = tb_top.u_dut.wb_we;
    wire [4:0]  wb_addr    = tb_top.u_dut.wb_addr;
    wire [31:0] wb_data    = tb_top.u_dut.wb_data;

    wire        ex_mem_mem_write  = tb_top.u_dut.ex_mem_mem_write;
    wire [31:0] ex_mem_alu_result = tb_top.u_dut.ex_mem_alu_result;
    wire [31:0] ex_mem_rs2_data   = tb_top.u_dut.ex_mem_rs2_data;
    wire [1:0]  ex_mem_mem_size   = tb_top.u_dut.ex_mem_mem_size;

    wire [1:0]  conv_status = tb_top.u_dut.u_ex.u_conv_pe.conv_status;
    wire        conv_busy   = tb_top.u_dut.u_ex.u_conv_pe.conv_busy;
    wire        conv_done   = tb_top.u_dut.u_ex.u_conv_pe.conv_done;
    wire [31:0] conv_result = tb_top.u_dut.u_ex.u_conv_pe.conv_result;

    wire        stall               = tb_top.u_dut.stall;
    wire [31:0] if_id_instr         = tb_top.u_dut.if_id_instr;
    wire [3:0]  id_ex_alu_op        = tb_top.u_dut.id_ex_alu_op;
    wire [31:0] ex_op_a             = tb_top.u_dut.u_ex.op_a;
    wire [31:0] ex_op_b             = tb_top.u_dut.u_ex.op_b;
    wire        id_ex_is_branch     = tb_top.u_dut.id_ex_is_branch;
    wire [2:0]  id_ex_branch_funct3 = tb_top.u_dut.id_ex_branch_funct3;
    wire        ex_branch_taken     = tb_top.u_dut.u_ex.branch_taken;
    wire [31:0] pc_reg              = tb_top.u_dut.u_if.pc_reg;

    // =========================================================================
    // Backdoor Access Functions
    // =========================================================================
    function bit [31:0] read_imem(int addr);
        return tb_top.u_dut.u_imem.mem[addr];
    endfunction

    function void write_imem(int addr, bit [31:0] data);
        tb_top.u_dut.u_imem.mem[addr] = data;
    endfunction

    function bit [7:0] read_dmem(int addr);
        return tb_top.u_dut.u_mem.u_dmem.mem[addr];
    endfunction

    function bit [31:0] read_regfile(int addr);
        return tb_top.u_dut.u_id.u_regfile.regs[addr];
    endfunction

    task release_reset();
        force tb_top.rst_n = 1'b1;
    endtask

endinterface : riscv_if
