# UVM-Based Verification of 4-Bit Adder

This project demonstrates the use of Universal Verification Methodology (UVM) to verify a 4-bit combinational adder design. The project contains the SystemVerilog design module, interface, and a comprehensive UVM-based testbench that verifies the functionality of the design using various verification components.

## Project Structure

### Design Module (`adder_4_bit.sv`)

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
```systemverilog
class transaction extends uvm_sequence_item;
  rand bit [3:0] a;
  rand bit [3:0] b;
  bit [4:0] y;
  
    function new(input string path = "transaction");
      super.new(path);
    endfunction
  
  `uvm_object_utils_begin(transaction)
    `uvm_field_int(a, UVM_DEFAULT)
    `uvm_field_int(b, UVM_DEFAULT)
    `uvm_field_int(y, UVM_DEFAULT)
  `uvm_object_utils_end
endclass

```
#### Generator

The `generator` creates random transactions and sends them to the driver.
```systemverilog
class generator extends uvm_sequence #(transaction);
  `uvm_object_utils(generator)
  
  transaction t;
  integer i;
  
  function new(input string path = "generator");
    super.new(path);
  endfunction
  
  
  virtual task body();
    t = transaction::type_id::create("t");
    repeat(10) 
    begin
      start_item(t);
      t.randomize();
      `uvm_info("GEN",$sformatf("Data send to Driver a :%0d , b :%0d",t.a,t.b), UVM_NONE);
      finish_item(t);
    end
  endtask
endclass
```
#### Driver

The `driver` applies the generated transactions to the DUT using the interface.

```systemverilog
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)
 
  function new(input string path = "driver", uvm_component parent = null);
    super.new(path, parent);
    endfunction
 
  transaction tc;
  virtual add_if aif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tc = transaction::type_id::create("tc");

    if(!uvm_config_db #(virtual add_if)::get(this,"","aif",aif)) 
      `uvm_error("DRV","Unable to access uvm_config_db");
  endfunction
 
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tc);
      aif.a <= tc.a;
      aif.b <= tc.b;
      `uvm_info("DRV", $sformatf("Trigger DUT a: %0d ,b :  %0d",tc.a, tc.b), UVM_NONE); 
      seq_item_port.item_done();
      #10;
    end
  endtask
endclass
```
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

### Top-Level Testbench Module (`adder_4_bit_tb.sv`)

The top-level module instantiates the DUT and interface and runs the UVM test.

## How to Run

1. **Requirements:**

   - A simulator (e.g. EDA Playground) supporting SystemVerilog and UVM (e.g., Synopsys VCS, Cadence Xcelium, Mentor Questa).

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

## Future Work

- Extend verification for corner cases (e.g., overflow).
- Add functional and code coverage reports.
- Parameterize the design for variable bit widths (e.g. 8-bit, 16-bit)

## References

- [UVM Reference Manual](https://www.accellera.org/)
- [SystemVerilog Language Reference](https://www.ieee.org/)

---

Feel free to reach out for any questions or suggestions regarding this project!

