# Asynchronous FIFO Formal Verification README

## 1. FIFO Architecture Description

### Overview
The design is an **asynchronous FIFO** with separate write and read clock domains:

- **Write domain:** `i_w_clk`, `i_w_rstn`, `i_w_inc`
- **Read domain:** `i_r_clk`, `i_r_rstn`, `i_r_inc`

It supports independent write/read operation across two clock domains and exposes:

- `o_full` — FIFO full flag
- `o_empty` — FIFO empty flag
- `o_r_data` — read data output

### Parameters
| Parameter | Meaning |
|---|---|
| `D_SIZE` | Data width |
| `A_SIZE` | Address width |
| `P_SIZE` | Pointer width, intended to be `A_SIZE + 1` |
| `F_DEPTH` | FIFO depth, intended to be `2^A_SIZE` |

Default values from the RTL:

- `D_SIZE = 8`
- `A_SIZE = 4`
- `P_SIZE = 5`
- `F_DEPTH = 16`

### Parameter Consistency Checks
The RTL includes simulation/formal-time sanity checks:

- `P_SIZE` must equal `A_SIZE + 1`
- `F_DEPTH` must equal `2^A_SIZE`

These checks are guarded by `` `ifndef SYNTHESIS ``.

### FIFO Storage
The module `fifo_mem` implements the FIFO memory as a **dual-port memory**:

- Write side uses `w_clk`, `w_inc`, `w_addr`, `w_data`
- Read side uses `r_addr`
- Output data is `r_data`

This separation is necessary for asynchronous operation, allowing writes and reads from different clock domains.

### Pointer Scheme
The FIFO uses **Gray-coded pointers** for clock-domain crossing:

- `gray_w_ptr` — Gray-coded write pointer
- `gray_rd_ptr` — Gray-coded read pointer

The local addresses sent to memory are:

- `w_addr` — write address
- `r_addr` — read address

The synchronized cross-domain pointers are:

- `w2r_ptr` — write pointer synchronized into the read clock domain
- `r2w_ptr` — read pointer synchronized into the write clock domain

### Clock-Domain Crossing
Two instances of `DF_Sync` are used as pointer synchronizers:

1. **Write pointer into read domain**
   - Input: `gray_w_ptr`
   - Output: `w2r_ptr`

2. **Read pointer into write domain**
   - Input: `gray_rd_ptr`
   - Output: `r2w_ptr`

The RTL comments state these must be **2-FF synchronizers**, which is the standard CDC method to reduce metastability risk for multi-bit Gray pointers.

### Flag Logic
#### Full Flag
The `fifo_wr` block is responsible for:

- advancing the write pointer
- generating `w_addr`
- generating `gray_w_ptr`
- asserting `o_full`

The RTL comments state that `fifo_wr` must implement the **Gray-code full rule internally**. In standard async FIFO design, full is detected when the next write pointer matches the synchronized read pointer with the appropriate MSB inversion pattern.

#### Empty Flag
The `fifo_rd` block is responsible for:

- advancing the read pointer
- generating `r_addr`
- generating `gray_rd_ptr`
- asserting `o_empty`

The RTL comments state:

> Empty when synchronized write Gray pointer equals read pointer

So the FIFO is empty when the synchronized write pointer seen in the read domain matches the current read pointer.

---

## 2. Formal Properties (SVA) and Results

### Scope of the Formal Block
The formal module `fifo_system_top_formal` is **bound** to `Async_fifo` and observes:

- both clocks and resets
- write/read increment requests
- `o_full`, `o_empty`
- `w_addr`

It defines:

- `DEPTH = 1 << A_SIZE`
- `seen_empty` — becomes `1` once `o_empty` is observed
- `seen_full` — becomes `1` once `o_full` is observed

### Important Verification Note
The formal environment contains both **assertions** and **matching assumptions** that forbid illegal traffic:

- `assume(!(i_w_inc && o_full));`
- `assume(!(i_r_inc && o_empty));`

That means the proof verifies the FIFO **under a constrained environment** where writes do not occur when full and reads do not occur when empty. This is fine for interface-level safety checking, but it does **not** prove robustness against a hostile or buggy environment trying illegal operations.

### SVA Property Table
| ID | Property Type | Property / Intent | Result |
|---|---|---|---|
| P1 | Assertion | No write request is allowed when FIFO is full: `assert(!(i_w_inc && o_full))` on `i_w_clk` when `i_w_rstn` is high | **PASS** |
| P2 | Assertion | No read request is allowed when FIFO is empty: `assert(!(i_r_inc && o_empty))` on `i_r_clk` when `i_r_rstn` is high | **PASS** |
| P3 | Assertion | Write address must stay within FIFO depth: `assert(w_addr < DEPTH)` on `i_w_clk` when `i_w_rstn` is high | **PASS** |
| A1 | Assumption | Environment never requests write when full: `assume(!(i_w_inc && o_full))` | Assumed |
| A2 | Assumption | Environment never requests read when empty: `assume(!(i_r_inc && o_empty))` | Assumed |
| A3 | Assumption | If FIFO is not full, keep writing: `if (i_w_rstn && !o_full) assume(i_w_inc);` | Assumed |
| A4 | Assumption | Once FIFO is full, start reading: `if (i_r_rstn && o_full) assume(i_r_inc);` | Assumed |
| C1 | Cover | Reach a state where FIFO has been empty before and is now full: `cover(seen_empty && o_full)` | **REACHED** |
| C2 | Cover | Reach a state where FIFO has been full before and is now empty: `cover(seen_full && o_empty)` | **REACHED** |

### Interpretation of the Results
The formal results support the following claims:

- Under the given assumptions, the design never accepts a write while `o_full` is asserted.
- Under the given assumptions, the design never accepts a read while `o_empty` is asserted.
- The write address remains within the legal range.
- Cover analysis confirms that the explored state space includes:
  - an **empty-to-full** scenario
  - a **full-to-empty** scenario

That is useful, because a proof with zero meaningful state exploration can look “clean” while actually saying little. Here, the cover traces show the model did reach the interesting boundary conditions.

---

## 3. SymbiYosys Terminal Output (Final Summary Lines)

```text
SBY 13:47:59 [fifo_system_top_bmc] summary: engine_0 (smtbmc) returned pass
SBY 13:47:59 [fifo_system_top_bmc] summary: engine_0 did not produce any traces
SBY 13:47:59 [fifo_system_top_cover] summary: engine_0 (smtbmc) returned pass
SBY 13:47:59 [fifo_system_top_cover] summary: cover trace: fifo_system_top_cover/engine_0/trace0.vcd
SBY 13:47:59 [fifo_system_top_cover] summary:   reached cover statement fifo_system_top_formal._witness_.check_cover_fifo_system_top_formal_sv_97_35 at fifo_system_top_formal.sv:97.13-97.40 step 1
SBY 13:47:59 [fifo_system_top_cover] summary: cover trace: fifo_system_top_cover/engine_0/trace1.vcd
SBY 13:47:59 [fifo_system_top_cover] summary:   reached cover statement fifo_system_top_formal._witness_.check_cover_fifo_system_top_formal_sv_92_32 at fifo_system_top_formal.sv:92.13-92.40 step 1
SBY 13:48:00 [fifo_system_top_prove] summary: Elapsed clock time [H:MM:SS (secs)]: 0:00:03 (3)
SBY 13:48:00 [fifo_system_top_prove] summary: Elapsed process time [H:MM:SS (secs)]: 0:00:00 (0)
SBY 13:48:00 [fifo_system_top_prove] summary: engine_0 (smtbmc) returned pass for basecase
SBY 13:48:00 [fifo_system_top_prove] summary: engine_0 (smtbmc) returned pass for induction
SBY 13:48:00 [fifo_system_top_prove] summary: engine_0 did not produce any traces
SBY 13:48:00 [fifo_system_top_prove] summary: successful proof by k-induction.
SBY 13:48:00 [fifo_system_top_prove] DONE (PASS, rc=0)
```

---

## 4. Bottom-Line Conclusion

The formal run shows:

- **BMC:** PASS
- **Cover:** PASS, with two generated VCD traces confirming interesting FIFO activity
- **Prove:** PASS by **k-induction**

So the checked properties were successfully proven **under the stated assumptions**.

## 5. One Critical Caveat
Do not oversell these results. The property set is currently **interface-safety oriented**, not a full FIFO correctness proof.

What is **not** yet proven here includes, for example:

- exact ordering of data (FIFO ordering)
- no duplication or loss of data
- correctness of full/empty timing across all pointer transitions
- correct Gray-pointer synchronization behavior internally
- read-data correctness relative to past writes