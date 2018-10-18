library ieee;
use ieee.std_logic_1164.all;

library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;

entity axis_master is
Generic (
	ID	: natural
);
Port (
	clk : in std_logic;
	rst : in std_logic;
	data : out std_logic_vector;
	keep : out std_logic_vector;
	valid : out std_logic;
	last : out std_logic;
	ready : in std_logic
);
end axis_master;
architecture sim of axis_master is
	signal data_l : std_logic_vector(data'range);
	signal keep_l : std_logic_vector(keep'range);
	signal valid_l : std_logic;

begin

ATE_S_STIM(clk, rst, data_l, keep_l, valid_l, last, ready, ID);
ATE_S_WATCHDOG(data'length, clk, rst, data_l, keep_l, valid_l, ready, ID);

data <= data_l;
keep <= keep_l;
valid <= valid_l;

end architecture;
