library ieee;
use ieee.std_logic_1164.all;

library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;

entity axis_slave is
Generic (
	ID	: natural
);
Port (
	clk : in std_logic;
	rst : in std_logic;
	data : in std_logic_vector;
	keep : in std_logic_vector;
	valid : in std_logic;
	last : in std_logic;
	ready : out std_logic
);
end axis_slave;
architecture sim of axis_slave is
	signal ready_l : std_logic := '0';
begin

ATE_M_VERIF(clk, rst, data, keep, valid, last, ready_l, ID);
M_READY_STIM_PROC(clk, rst, valid, ready_l, ID);
MASTER_WATCHDOG_PROC(clk, rst, data, valid, ready_l, ID);
ATE_M_WATCHDOG(data'length, clk, rst, data, keep, valid, ready_l, ID);

ready <= ready_l;

end architecture;
