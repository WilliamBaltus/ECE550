wjb40 1031917
regfile
Implements a 32-register file with two read ports and one write port. It handles read and write operations, ensuring register 0 is always zero and managing write enables based on control signals.

zero_register
Provides a constant zero output for register 0. This module ensures that the first register always holds the value zero, regardless of any write attempts.

register32
Defines a 32-bit register with enable and clear functionalities using D flip-flops with enable (DFFEs). It stores and updates data based on the clock and control signals.

comparator5bit
Compares a 5-bit input against a constant value specified by the CONST_VAL parameter. It outputs a high signal when the input matches the constant value, facilitating one-hot encoding for register selection.

or32
Implements a hierarchical 32-input OR gate using multiple stages of smaller OR gates. This module aggregates multiple input signals into a single output by performing a logical OR operation across all inputs.

zero_register
Ensures that register 0 always outputs zero by using a series of AND gates that are tied to logic low (0). This prevents any modifications to the zero register during write operations.

register32
Manages individual 32-bit registers within the register file. Each register can be enabled for writing or reset based on the control signals, allowing dynamic data storage and retrieval.

comparator5bit
Used for generating one-hot select lines by comparing register indices with input addresses. It plays a crucial role in determining which register to read from or write to based on the address provided.

or32
Facilitates the selection of data from the appropriate register by combining multiple AND gate outputs. This module effectively multiplexes the selected register's data to the read ports.
