# UVM-Based Verification of 4-Bit Adder

This project demonstrates the use of Universal Verification Methodology (UVM) to verify a 4-bit combinational adder design. The project contains the SystemVerilog design module, interface, and a comprehensive UVM-based testbench that verifies the functionality of the design using various verification components.

## Project Structure

### Design Module (`design.sv`)

The adder module performs a simple 4-bit addition and outputs the 5-bit result.

```systemverilog
module add(
  input [3:0] a, b,
  output [4:0] y
);
  assign y = a + b;
endmodule
```

### Interface (`add_if`)

The interface connects the testbench with the design-under-test (DUT) by defining the input and output signals:

```systemverilog
interface add_if();
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] y;
endinterface
```

### Testbench Structure

#### Transaction

The `transaction` class represents data items (input and expected output) used during the test.

#### Generator

The `generator` creates random transactions and sends them to the driver.

#### Driver

The `driver` applies the generated transactions to the DUT using the interface.

#### Monitor

The `monitor` observes the DUT's outputs and sends them to the scoreboard for checking.

#### Scoreboard

The `scoreboard` compares the DUT output with the expected output to verify correctness.

#### Agent

The `agent` encapsulates the driver, monitor, and sequencer to provide a reusable verification component.

#### Environment

The `environment` connects the agent and scoreboard, providing the testbench structure.

#### Test

The `test` defines the test sequence and initiates the verification process.

### Top-Level Testbench Module (`add_tb.sv`)

The top-level module instantiates the DUT and interface and runs the UVM test.

## How to Run

1. **Requirements:**

   - A simulator supporting SystemVerilog and UVM (e.g., Synopsys VCS, Cadence Xcelium, Mentor Questa).

2. **Compilation:**
   Compile the design and testbench files along with UVM libraries.

   ```bash
   vlog -sv design.sv add_if.sv testbench.sv +incdir+$(UVM_HOME)/src
   ```

3. **Simulation:**
   Run the simulation with the UVM test specified.

   ```bash
   vsim -c -do "run -all" add_tb
   ```

4. **Output:**

   - Waveform: View the generated `dump.vcd` file to analyze signal transitions.
   - Log: Check the simulation log for verification results and UVM messages.

## Features

- **UVM Components:** Full utilization of UVM components (transaction, driver, monitor, scoreboard, etc.).
- **Randomization:** Randomized input generation to stress-test the design.
- **Coverage:** Functional coverage through monitored transactions.
- **Reusability:** Modular and reusable verification components.

## Verification Flow

1. The generator produces random input transactions.
2. The driver applies these transactions to the DUT.
3. The monitor captures the DUT outputs.
4. The scoreboard checks if the DUT output matches the expected values.
5. Results are logged, and the test passes or fails based on the comparison.

## Example Simulation Log

```
UVM_INFO @ 0: GEN: Data sent to Driver a: 5, b: 3
UVM_INFO @ 10: DRV: Trigger DUT a: 5, b: 3
UVM_INFO @ 20: MON: Data sent to Scoreboard a: 5, b: 3, y: 8
UVM_INFO @ 20: SCO: Test Passed
```

## File List

- `design.sv`: 4-bit adder module.
- `add_if.sv`: Interface for connecting testbench and DUT.
- `testbench.sv`: UVM testbench including all components and the top-level test.
- `dump.vcd`: Generated waveform file.

## Future Work

- Extend verification for corner cases (e.g., overflow).
- Add functional and code coverage reports.
- Parameterize the design for variable bit widths.

## References

- [UVM Reference Manual](https://www.accellera.org/)
- [SystemVerilog Language Reference](https://www.ieee.org/)

---

Feel free to reach out for any questions or suggestions regarding this project!

