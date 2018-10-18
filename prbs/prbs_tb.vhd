--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: prbs_tb.vhd
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

entity prbs_tb is
end entity;

architecture bench of prbs_tb is


	constant ERR_CNT_WIDTH	: natural := 4;
	constant WIDTH : natural := 32;
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal seed : std_logic_vector(WIDTH-1 downto 0) := x"aabbccdd";
	signal m_data : std_logic_vector(WIDTH-1 downto 0);
	signal m_valid		: std_logic := '0';
	signal m_ready		: std_logic := '0';
	signal s_data : std_logic_vector(WIDTH-1 downto 0);
	signal s_valid		: std_logic := '0';
	signal s_ready		: std_logic := '0';
	signal inject_err		: std_logic := '0';
	signal trig			: std_logic := '1';
		

	constant WIRE_DELAY	: time := 20 ns;
	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
--	constant ADL	: time := CLK_PERIOD / 5;
	constant ADL	: time := 0 ps;

		
begin



stimulus : process begin
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0' after ADL;
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '1' after ADL;
	
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0' after ADL;
		
	wait for LDL;
	wait until rising_edge(clk);
		inject_err		<= '1' after ADL;
	wait until rising_edge(clk);
		inject_err		<= '0' after ADL;
	
	wait for LDL;
	wait until rising_edge(clk);
		inject_err		<= '1' after ADL;
	wait until rising_edge(clk);
	wait until rising_edge(clk);
		inject_err		<= '0' after ADL;
	
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '1' after ADL;



wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;


	uut_gen : entity work.prbs_gen
		generic map
		(
			ADL		=> ADL,
			WIDTH => WIDTH
		)
		port map
		(
			clk  => clk,
			rst  => rst,
			seed => seed,
			trig	=> trig,
			inject_err	=> inject_err,
			m_data => m_data,
			m_valid => m_valid,
			m_ready	=> m_ready
		);
		
	uut_chk : entity work.prbs_chk
	generic map
	(
		ADL		=> ADL,
		WIDTH         => WIDTH,
		ERR_CNT_WIDTH => ERR_CNT_WIDTH
	)
	port map
	(
		clk     => clk,
		rst     => rst,
		seed    => seed,
		trig	=> trig,
		s_data  => s_data,
		s_valid => s_valid,
		s_ready => s_ready
	);

s_data <= transport m_data after WIRE_DELAY;
s_valid <= transport m_valid after WIRE_DELAY;
m_ready <= transport s_ready after WIRE_DELAY;




	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;
	
