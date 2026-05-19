# Hardware Priority Queue / Task Scheduler (VHDL)

This repository contains the VHDL implementation of a **Hardware Priority Queue / Task Scheduler** developed for the Logic Networks (*Reti Logiche*) course at Politecnico di Milano (A.Y. 2025/2026).

The project was awarded an excellent grade of **29/30**.

## Project Overview
The system is a synchronous hardware module designed to act as a dynamic, contiguously allocated priority queue. It interfaces with an external single-port RAM to maintain, manipulate, and sort a list of tasks.

Each element (Task) occupies **1 Byte** in memory and is divided into two informative fields:
* **Task ID (6 bits):** Unique identifier for the task (from 1 to 63; zero is reserved).
* **Priority (2 bits):** Urgency level of the task, where `00` represents the highest priority and `11` (3 decimal) represents the lowest.

RAM address `0x0000` constantly stores and updates the total number of valid tasks currently present in the queue.

## Supported Operations
The module receives commands via the `i_op` bus (2 bits) and triggers on the rising edge of the `i_start` handshake signal. Upon completion, it asserts the `o_done` flag.

1.  **`00` - Decrement Priority (Increase priority value):** Iterates through the entire list and increments the priority value of each task by 1 (effectively lowering its logical importance), saturating at the maximum value (`11`).
2.  **`01` - Remove First Task:** Extracts the highest-priority task (located at address `1`), outputs its ID to the `o_task_id` bus, compacts the memory via a *forward shift* of all subsequent elements, and decrements the task counter.
3.  **`10` - Insert Task:** Performs a full pre-scan to prevent inserting duplicate IDs. If the ID is unique, it identifies the correct position to maintain priority sorting (stable sorting, placing the new task behind existing tasks with identical priority), executes a *backward shift* to clear space, and inserts the new task.
4.  **`11` - Clear Memory:** Logically resets the memory by clearing the task counter at address `0` in a single clock cycle.

##  Hardware Architecture
The design adopts a **Behavioral RTL approach**, modeling a **FSMD (Finite State Machine with Datapath)** organized according to the standard **two-process pattern**:

* **Synchronous Process (Sequential Network):** Driven by the system clock `i_clk` and an asynchronous reset `i_rst`. It manages the state register updates (26 total states) and stabilizes the internal Datapath registers (read/write pointers, counters, and output registers).
* **Combinational Process (Control Unit & Inferenced Datapath):** Computes the next state of the FSM, generates RAM control signals (`o_mem_en`, `o_mem_we`), and inferences the operational hardware components (adders, subtractors, comparators, and multiplexers) required for data processing.

### Robustness and Self-Limiting Architecture
The architecture implements intrinsic protection against *memory overflow*. With 6 bits allocated for the Task ID (yielding 63 valid combinations excluding zero) and a built-in blocking mechanism for duplicates, the list can mathematically never exceed 63 elements. This renders the system completely immune to an overflow of the 8-bit RAM counter (which has a theoretical capacity of 255), ensuring absolute operational stability under any workload.

##  Validation and Testing
The correct behavior of the circuit was extensively validated using pre- and post-synthesis simulations (*Behavioral* and *Functional*) within AMD Vivado across two primary scenarios:
1.  **Standard Testbench:** Validation of standard insertion, removal, and modification sequences under normal operational flows.
2.  **Stress Test & Edge Cases (Custom):** Verification of system resilience under critical boundary conditions:
    * Attempted insertion of duplicate IDs (correctly aborted without memory corruption).
    * Removal (`01`) or priority modification (`00`) operations executed on an entirely empty list (handled gracefully without logical stalls).
    * Priority saturation handling beyond the maximum threshold of `3`.

##  Development Tools
* **Environment:** AMD Xilinx Vivado Design Suite
* **Target HW:** Xilinx Artix-7 FPGA
* **Language:** VHDL-93 (Core reference library: `IEEE.NUMERIC_STD`)

##  Repository Structure
task_scheduler.vhd : the VHD file itself
technical_report.pdf : relation (in italian) we had to make about the project
* `project_reti_logiche.vhd`: Main hardware module source code.
* `tb_edge_cases.vhd`: Advanced testbench for edge-case simulations.
* `Relazione_Finale.pdf`: Detailed technical project report.

---
*Developed by Matteo Mancin - Politecnico di Milano*
