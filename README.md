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
```systemverilog
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  uvm_analysis_port #(transaction) send;
 
  function new(input string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
    send = new("send", this);
  endfunction
 
  transaction t;
  virtual add_if aif;
 
  virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  t = transaction::type_id::create("t");
    
  if(!uvm_config_db #(virtual add_if)::get(this,"","aif",aif)) 
    `uvm_error("MON","Unable to access uvm_config_db");
  endfunction
 
  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      t.a = aif.a;
      t.b = aif.b;
      t.y = aif.y;
      `uvm_info("MON", $sformatf("Data send to Scoreboard a : %0d , b : %0d and y : %0d", t.a,t.b,t.y), UVM_NONE);
      send.write(t);
    end
  endtask
endclass
```
#### Scoreboard

The `scoreboard` compares the DUT output with the expected output to verify correctness.
```systemverilog
class scoreboard extends uvm_scoreboard;
   `uvm_component_utils(scoreboard)
 
  uvm_analysis_imp #(transaction,scoreboard) recv;
 
  transaction tr;
 
  function new(input string path = "scoreboard", uvm_component parent = null);
    super.new(path, parent);
    recv = new("recv", this);
  endfunction
 
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
  endfunction
 
  virtual function void write(input transaction t);
    tr = t;
    `uvm_info("SCO",$sformatf("Data rcvd from Monitor a: %0d , b : %0d and y : %0d",tr.a,tr.b,tr.y), UVM_NONE);
  
    if(tr.y == tr.a + tr.b)
      `uvm_info("SCO","Test Passed", UVM_NONE)
    else
      `uvm_info("SCO","Test Failed", UVM_NONE);
   endfunction
endclass
```

#### Agent

The `agent` encapsulates the driver, monitor, and sequencer to provide a reusable verification component.
```systemverilog
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  function new(input string inst = "AGENT", uvm_component c);
    super.new(inst, c);
  endfunction
  
  monitor m;
  driver d;
  uvm_sequencer #(transaction) seqr;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m = monitor::type_id::create("m",this);
    d = driver::type_id::create("d",this);
    seqr = uvm_sequencer #(transaction)::type_id::create("seqr",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
```
#### Environment

The `environment` connects the agent and scoreboard, providing the testbench structure.
```systemverilog
class env extends uvm_env;
  `uvm_component_utils(env)
 
  function new(input string inst = "ENV", uvm_component c);
    super.new(inst, c);
  endfunction
 
  scoreboard s;
  agent a;
 
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    s = scoreboard::type_id::create("s",this);
    a = agent::type_id::create("a",this);
  endfunction
 
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.recv);
  endfunction
endclass
```
#### Test

The `test` defines the test sequence and initiates the verification process.
```systemverilog
class test extends uvm_test;
  `uvm_component_utils(test)
  
  function new(input string inst = "TEST", uvm_component c);
    super.new(inst, c);
  endfunction
  
  generator gen;
  env e;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    gen = generator::type_id::create("gen");
    e = env::type_id::create("e",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    gen.start(e.a.seqr);
    #50;
    phase.drop_objection(this);
  endtask
endclass
```
### Top-Level Testbench Module (`adder_4_bit_tb.sv`)

The top-level module instantiates the DUT and interface and runs the UVM test.
```systemverilog
module add_tb();
  add_if aif();
  add dut (.a(aif.a), .b(aif.b), .y(aif.y));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
    
  initial begin  
    uvm_config_db #(virtual add_if)::set(null, "uvm_test_top.e.a*", "aif", aif);
    run_test("test");
  end
endmodule
```
## How to Run

1. **Requirements:**
- EDA Playground supporting SystemVerilog and UVM with Aldec Riviera Pro
  - [View on EDA Playground](https://edaplayground.com/x/tb4f)

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

