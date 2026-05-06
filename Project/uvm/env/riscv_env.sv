//==============================================================================
// riscv_env.sv — UVM Environment
//------------------------------------------------------------------------------
// Top-level UVM environment connecting all agents, monitors, scoreboard,
// and coverage collector.
//==============================================================================

class riscv_env extends uvm_env;

    `uvm_component_utils(riscv_env)

    // Agents
    imem_agent          m_imem_agent;
    dmem_agent          m_dmem_agent;

    // Monitors
    wb_monitor          m_wb_mon;
    dmem_store_monitor  m_store_mon;
    conv_pe_monitor     m_conv_mon;

    // Scoreboard
    riscv_scoreboard    m_scoreboard;

    // Coverage
    riscv_coverage      m_coverage;

    function new(string name = "riscv_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Agents
        m_imem_agent = imem_agent::type_id::create("m_imem_agent", this);
        m_dmem_agent = dmem_agent::type_id::create("m_dmem_agent", this);

        // Monitors
        m_wb_mon    = wb_monitor::type_id::create("m_wb_mon", this);
        m_store_mon = dmem_store_monitor::type_id::create("m_store_mon", this);
        m_conv_mon  = conv_pe_monitor::type_id::create("m_conv_mon", this);

        // Scoreboard
        m_scoreboard = riscv_scoreboard::type_id::create("m_scoreboard", this);

        // Coverage
        m_coverage = riscv_coverage::type_id::create("m_coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect WB monitor to scoreboard and coverage
        m_wb_mon.ap.connect(m_scoreboard.wb_export);
        m_wb_mon.ap.connect(m_coverage.analysis_export);

        // Connect store monitor to scoreboard
        m_store_mon.ap.connect(m_scoreboard.store_export);

        // Connect Conv-PE monitor to scoreboard and coverage
        m_conv_mon.ap.connect(m_scoreboard.conv_export);
        m_conv_mon.ap.connect(m_coverage.conv_export);
    endfunction

endclass : riscv_env
