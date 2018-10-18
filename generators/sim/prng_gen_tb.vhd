--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: prng_gen_tb.vhd
-- Language: VHDL
-- Description: 
-- 	TB for prng
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- TO DO - test for m_ready deassertions
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library xil_defaultlib;
use xil_defaultlib.axis_test_env_pkg.all;


entity prng_gen_tb is
end entity;

architecture bench of prng_gen_tb is

	constant WIDTH : natural := 4;
	constant LIMIT_WIDTH	: natural := 4;
	constant MODE_WIDTH	: natural := 2;
	

	signal clk : std_logic;
	signal rst : std_logic;
	signal m_data : std_logic_vector(WIDTH-1 downto 0);
	signal m_valid : std_logic;
	signal m_ready : std_logic;
	signal seed : std_logic_vector(WIDTH-1 downto 0);
	signal trig		: std_logic := '0';
	signal mode		: std_logic_vector(MODE_WIDTH-1 downto 0);
	signal gen_limit		: std_logic_vector(LIMIT_WIDTH-1 downto 0);
	
	signal ate_m_ready		: std_logic := '0';
	signal ate_m_valid		: std_logic := '0';
	signal ate_m_data		: std_logic_vector(WIDTH-1 downto 0);
	
	constant CLK_PERIOD	: time := 10 ns;
	constant LDL		: time := 10 * CLK_PERIOD;
	constant ADL 		: time := CLK_PERIOD / 5;
	shared variable stop_clock : boolean := false;
	
	shared variable GEN_LIMIT_SIM	: std_logic_vector(LIMIT_WIDTH-1 downto 0) := "0111";
	shared variable BURST_LEN_SIM	: natural := to_integer(unsigned(GEN_LIMIT_SIM)) +1;
	
	constant DONT_CARE	: std_logic_vector(WIDTH-1 downto 0) := (others => '-');
	
begin

	uut : entity xil_defaultlib.prng_gen
		generic map
		(
			WIDTH => WIDTH,
			ADL   => ADL,
			USE_TRIG => true,
			LIMIT_WIDTH => LIMIT_WIDTH,
			MODE_WIDTH	=> MODE_WIDTH
		)
		port map
		(
			clk     	=> clk,
			rst     	=> rst,
			m_data  	=> m_data,
			m_valid 	=> m_valid,
			m_ready 	=> m_ready,
			seed    	=> seed,
			trig		=> trig,
			mode		=> mode,
			gen_limit	=> gen_limit
		);

	stimulus : process begin
	-- ATE
		ATE_MASTER_QUIT_TEST := false;
		ATE_SET_TEST_LEN(BURST_LEN_SIM, "M");
		FILL_ALL_MASTER_STORE(BURST_LEN_SIM, DONT_CARE);
		
	-- Init
			seed		<= x"a";
			rst			<= '1';
			mode		<= "00";
			gen_limit	<= GEN_LIMIT_SIM;


		wait for LDL;
		wait until rising_edge(clk);
			rst	<= '0' after ADL;

		report " <<< TEST 1 >>> Continuous mode, triggering and m_ready deasserting";
		wait until rising_edge(clk);
			trig		<= '1' after ADL;
		wait until rising_edge(clk);
			trig		<= '0' after ADL;
			
	-- ATE
		ATE_TRIG <= not ATE_TRIG;
		wait until ATE_DONE'event;
		wait for LDL;
	
		
		
			
		report " <<< TEST 2 >>> Limit AR mode";

			mode <= "01" after ADL;
	-- Rst needed to quit from Continuous
		wait until rising_edge(clk);
			rst		<= '1' after ADL;
		wait until rising_edge(clk);
			rst		<= '0' after ADL;
	-- FSM trig again
		wait until rising_edge(clk);
			trig		<= '1' after ADL;
		wait until rising_edge(clk);
			trig		<= '0' after ADL;
	-- ATE
		ATE_MASTER_QUIT_TEST := true;					
		ATE_TRIG <= not ATE_TRIG;
		wait until ATE_DONE'event;
		wait for LDL;		
		
			
		report " <<< TEST 3 >>> Limit mode";			
			mode <= "10" after ADL;
	-- FSM trig
		wait until rising_edge(clk);
			trig		<= '1' after ADL;
		wait until rising_edge(clk);
			trig		<= '0' after ADL;			

	-- ATE
		ATE_TRIG <= not ATE_TRIG;
		wait until ATE_DONE'event;
			
			
		wait for LDL;
		stop_clock := true;
		wait for LDL;
		assert false report " <<< DONE >>> " severity failure;
		
		wait;
	end process;
	
-- ATE
	-- MASTER PROCS
	master_proc: AXIS_MASTER_STIM_PROC(ATE_DONE, clk, rst, ate_m_data, ate_m_valid, ate_m_ready);
	m_ready_proc: M_READY_STIM_PROC(clk, rst, ate_m_valid, ate_m_ready);
	m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate_m_data, ate_m_valid, ate_m_ready);
-- Signals assigment
	-- Master ATE in
	ate_m_valid <= m_valid;
	ate_m_data	<= m_data;
	-- Master ATE out
	m_ready		<= ate_m_ready after ADL;

	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

