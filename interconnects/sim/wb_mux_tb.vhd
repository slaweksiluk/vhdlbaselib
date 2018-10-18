--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wb_mux_tb.vhd
-- Language: VHDL
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vhdlbaselib;
use vhdlbaselib.wishbone_pkg.all;

entity wb_mux_tb is
end entity;

architecture bench of wb_mux_tb is

	component wb_mux is
		generic
		(
			SLAVES_NUM : positive
		);
		port
		(
			clk : in std_logic;
			rst : in std_logic;
			sel : in natural range 0 to SLAVES_NUM-1;
			wbm_i : in t_wishbone_master_in;
			wbm_o : out t_wishbone_master_out;
			wbs_i : in t_arr_wishbone_slave_in(0 to SLAVES_NUM-1);
			wbs_o : out t_arr_wishbone_slave_out(0 to SLAVES_NUM-1)
		);
	end component;

	constant SLAVES_NUM : positive := 2;
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal sel : natural range 0 to SLAVES_NUM-1;
	signal wbm_i : t_wishbone_master_in;
	signal wbm_o : t_wishbone_master_out;
	signal wbs_i : t_arr_wishbone_slave_in(0 to SLAVES_NUM-1);
	signal wbs_o : t_arr_wishbone_slave_out(0 to SLAVES_NUM-1);

	constant CLK_PERIOD : time := 10 ns;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
	
begin

slave_stim : process	begin
	wait for LDL;
	wait until rising_edge(clk);
	rst		<= '0';	
	
	
	for i in 0 to SLAVES_NUM-1 loop
		wbs_i(i).cyc <= '0';
		wbs_i(i).dat <= std_logic_vector(to_unsigned(i, 32));		
		wbs_i(i).stb <= '0';	
		sel		<= i;
		wait for LDL;
		wait until rising_edge(clk);	
		wbs_i(i).cyc <= '1';
		wbs_i(i).stb <= '1';
		wait until rising_edge(clk);
		wbs_i(i).stb <= '0';
		
		wait until rising_edge(clk) and wbs_o(i).ack = '1' for LDL;
		assert wbs_o(i).ack = '1' report "no ack at wbs" severity failure;
		wbs_i(i).cyc <= '0';
		wait for LDL;
	end loop;
	
		
wait for LDL;
wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;



master_verif : process begin
	for i in 0 to SLAVES_NUM-1 loop
		wbm_i.ack <= '0';
		wait until rising_edge(clk) and wbm_o.cyc = '1' and wbm_o.stb = '1';	
		wbm_i.ack <= '1', '0' after CLK_PERIOD +1 ps;
		assert wbm_o.dat = std_logic_vector(to_unsigned(i, 32))
			report "wbm_o data inv" severity failure;			
		wait until rising_edge(clk);
	end loop;
end process;


uut : entity vhdlbaselib.wb_mux
	generic map
	(
		SLAVES_NUM => SLAVES_NUM,
		ARCH => "FULL_REGS"
	)
	port map
	(
		clk   => clk,
		rst   => rst,
		sel   => sel,
		wbm_i => wbm_i,
		wbm_o => wbm_o,
		wbs_i => wbs_i,
		wbs_o => wbs_o
	);



generate_clk : process
begin
	clk <= '0', '1' after CLK_PERIOD / 2;
	wait for CLK_PERIOD;
end process;

end architecture;

