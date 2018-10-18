-- Slawomir Siluk slaweksiluk@gazeta.pl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_slave_axis_master_bridge is
Port (
	clk		: in std_logic;

	-- Wishbone slave interface
	wb_dat_i : in std_logic_vector;
	wb_sel : in std_logic_vector;
	wb_cyc : in std_logic;
	wb_stb : in std_logic;
	wb_we : in std_logic;
	wb_ack : out  std_logic;
	wb_stall : out  std_logic;

	-- AXIS master interface
	axis_data : out std_logic_vector;
	axis_valid : out std_logic;
	axis_ready : in std_logic
);
end wb_slave_axis_master_bridge;
architecture beh of wb_slave_axis_master_bridge is
begin

axis_reg_proc: process(clk) begin
if rising_edge(clk) then
	if axis_ready = '1' and wb_we = '1' then
		axis_data <= wb_dat_i;
		axis_valid <= wb_cyc and wb_stb;
	end if;
end if;
end process;

ack_proc: process(clk) begin
if rising_edge(clk) then
	if axis_ready = '1' and wb_cyc = '1' and wb_stb = '1' then
		wb_ack <= '1';
	else
		wb_ack <= '0';
	end if;
end if;
end process;

wb_stall <= not axis_ready;

end beh;
