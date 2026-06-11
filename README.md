
# AXI4 Slave RTL Design, FPGA Implementation and UVM Verification

## Overview

Designed and verified an AXI4 Slave supporting burst read/write transactions, VALID/READY handshaking, WSTRB-based byte enables, write responses, and burst read operations.

## Features

- AXI4 Burst Write Support
- AXI4 Burst Read Support
- INCR Burst Transfers
- WSTRB Byte Enables
- VALID/READY Handshaking
- Write Response Channel
- Self-Checking Scoreboard
- Functional Coverage
- SystemVerilog Assertions
- FPGA Validation

## Verification Architecture

Sequence → Sequencer → Driver → DUT

Monitor → Scoreboard

Monitor → Coverage

## Results

- PASS = 4
- FAIL = 0
- Burst Read/Write Verified
- Protocol Assertions Checked

## Tools

- SystemVerilog
- UVM 1.2
- Riviera-PRO
- Vivado
- FPGA
