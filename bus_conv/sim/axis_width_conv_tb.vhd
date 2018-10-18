--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_width_conv_tb.vhd
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
use vhdlbaselib.axis_test_env_pkg.all;
use vhdlbaselib.common_pkg.all;
library vunit_lib;
context vunit_lib.vunit_context;
	

entity axis_width_conv_tb is
  generic  (
    runner_cfg : string;
	SLAVE_WIDTH : natural := 32;
	MASTER_WIDTH : natural := 8;
	USE_KEEP	: boolean := false;
	RAND_STIM	: boolean := false;
	SLAVE_TEST_LEN : natural := 64
);
end entity;

architecture bench of axis_width_conv_tb is


	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal s_data : std_logic_vector(slave_width-1 downto 0) := (others => '0');
	signal s_keep : std_logic_vector(axis_keep_width(slave_width)-1 downto 0);
	signal s_valid : std_logic;
	signal s_ready : std_logic;
	signal m_data : std_logic_vector (MASTER_WIDTH-1 downto 0) := (others => '0');
	signal m_valid : std_logic;
	signal m_ready : std_logic;


	-- ATE
	signal ate_s_valid		: std_logic := '0';
	signal ate_s_data		: std_logic_vector(SLAVE_WIDTH-1 downto 0) := (others => 'U');
	signal ate_s_keep		: std_logic_vector(s_keep'range) := (others => 'U');
	signal ate_s_ready		: std_logic := '0';
	signal ate_s_last		: std_logic := '0';
	signal ate_m_ready		: std_logic := '0';
	signal ate_m_valid		: std_logic := '0';
	signal ate_m_last		: std_logic := '0';
	signal ate_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => 'U');
	signal ate_m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0) := (others => 'U');

	
	
	constant CLK_PERIOD			: time := 10 ns;
	constant LDL				: time := CLK_PERIOD * 10;
	constant ADL				: time := CLK_PERIOD / 5;
	signal stop_clock		: boolean := false;

	-- Triggers
	signal ATE_DONE		: boolean := false;

	-- SIM PAR
	constant TEST_LEN	: natural := 20;
	constant MAGIC_ADD	: natural := 45345235;
	constant DONT_CARE	: std_logic_vector(32-1 downto 0) := (others => '-');
	
	
begin

--------------------------------------------------------------------------------
-- Master lower than slave
--------------------------------------------------------------------------------
deser_test_gen: if true generate
stimulus : process 	
	constant SM_RATIO			: positive := SLAVE_WIDTH/MASTER_WIDTH;
	variable slave_test_len		: natural := SLAVE_TEST_LEN;	
	variable master_test_len	: natural := slave_test_len*SM_RATIO;	
begin
-- Vvunit init
test_runner_setup(runner, runner_cfg);
while test_suite loop
if run("Test1") and MASTER_WIDTH < SLAVE_WIDTH and USE_KEEP = false then

	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0';

	wait for LDL;	
	report "TestCase#1 - tranfering data when keep is high";
	if RAND_STIM then
		ATE_SET_STIM_MODE(BOTH_E, PRNG);
	end if;	
	FILL_INC_STORE(BOTH_E, 1, master_test_len, MASTER_WIDTH);
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

elsif run("Test2") and MASTER_WIDTH < SLAVE_WIDTH and USE_KEEP = true then
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0';
	-- Slave test is fixed to 4
	slave_test_len := 4;
	master_test_len := SLAVE_TEST_LEN*SM_RATIO;
	wait for LDL;	
	report "FuncTest#1 - slave last data slice invalid";
	report "TestCase#1 trivial";
	if RAND_STIM then
		ATE_SET_STIM_MODE(BOTH_E, PRNG);
	end if;		
	FILL_INC_STORE(BOTH_E, 1, master_test_len, MASTER_WIDTH);
	FILL_SLAVE_KEEP_STORE(3, "0111");
	ATE_SET_TEST_LEN(MASTER_E, master_test_len-1);
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

--	-- TEST3 last word keep 0011
	wait for LDL;
	report "TestCase#2 two words disabled";	
	FILL_SLAVE_KEEP_STORE(3, "0011");
	ATE_SET_TEST_LEN(MASTER_E, master_test_len-2);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	wait for LDL;
	report "TestCase#3 three words disabled";	
	FILL_SLAVE_KEEP_STORE(3, "0001");
	ATE_SET_TEST_LEN(MASTER_E, master_test_len-3);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

--	--
--	-- MIDDLE WORD KEEP CHANGE TEST
--	--
	wait for LDL;
	report "TestCase#4 one word disabled in the middle";		
	FILL_SLAVE_KEEP_STORE(3, "1111");
	FILL_SLAVE_KEEP_STORE(2, "0111");
	FILL_STORES(MASTER_E, 0, x"03020100");		
	FILL_STORES(MASTER_E, 1, x"07060504");		
	FILL_STORES(MASTER_E, 2, x"0C0A0908");		
	FILL_STORES(MASTER_E, 3, x"100f0e0d");
	ATE_SET_TEST_LEN(MASTER_E, master_test_len-1);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	wait for LDL;
	report "TestCase#4 two word disabled in the middle";		
	FILL_SLAVE_KEEP_STORE(3, "1111");
	FILL_SLAVE_KEEP_STORE(2, "0011");
	FILL_STORES(MASTER_E, 0, x"03020100");		
	FILL_STORES(MASTER_E, 1, x"07060504");		
	FILL_STORES(MASTER_E, 2, x"0d0c0908");		
	FILL_STORES(MASTER_E, 3, x"11100f0e");
	ATE_SET_TEST_LEN(MASTER_E, master_test_len-2);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	wait for LDL;
	report "TestCase#5 three word disabled in the middle";		
	FILL_SLAVE_KEEP_STORE(3, "1111");
	FILL_SLAVE_KEEP_STORE(2, "0001");
	FILL_STORES(MASTER_E, 0, x"03020100");		
	FILL_STORES(MASTER_E, 1, x"07060504");		
	FILL_STORES(MASTER_E, 2, x"0e0d0c08");		
	FILL_STORES(MASTER_E, 3, x"1211100f");
	ATE_SET_TEST_LEN(MASTER_E, master_test_len-3);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
end if;
end loop;
test_runner_cleanup(runner);
wait;
end process;
end generate;	

--	--
--	--
--	-- TEST 13 TIED ALL
--		wait for LDL;
--		FILL_SLAVE_KEEP_STORE(3, "1111");
--		FILL_SLAVE_KEEP_STORE(2, "1111");
--		ATE_SET_STIM_MODE(BOTH_E, TIED_TO_VCC);
--		FILL_STORES(MASTER_E, 0, x"04030201");		
--		FILL_STORES(MASTER_E, 1, x"08070605");		
--		FILL_STORES(MASTER_E, 2, x"12111009");		
--		FILL_STORES(MASTER_E, 3, x"16151413");		
--		FILL_STORES(MASTER_E, 4, x"20191817");		
--		FILL_STORES(MASTER_E, 5, x"24232221");		
--		FILL_STORES(MASTER_E, 6, x"28272625");		
--		FILL_STORES(MASTER_E, 7, x"32313029");		
--		FILL_STORES(MASTER_E, 8, DONT_CARE);		
--		FILL_STORES(MASTER_E, 9, DONT_CARE);		
--		FILL_STORES(MASTER_E, 10, DONT_CARE);		


--		FILL_STORES(SLAVE_E, 0, x"04030201");		
--		FILL_STORES(SLAVE_E, 1, x"08070605");		
--		FILL_STORES(SLAVE_E, 2, x"12111009");		
--		FILL_STORES(SLAVE_E, 3, x"16151413");		
--		FILL_STORES(SLAVE_E, 4, x"20191817");		
--		FILL_STORES(SLAVE_E, 5, x"24232221");		
--		FILL_STORES(SLAVE_E, 6, x"28272625");		
--		FILL_STORES(SLAVE_E, 7, x"32313029");
--			
--		ATE_SET_TEST_LEN(SLAVE_E, 8);
--		ATE_SET_TEST_LEN(MASTER_E, 32);
--		ATE_M_TEST_ID := ATE_M_TEST_ID+1;		
--		report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event";
--		ATE_USER_SET_STATE(ATE_STATE_RUN);
--		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

--	-- TEST 14
--		wait for LDL;
--		ATE_SET_TEST_LEN(SLAVE_E, 8);
--		ATE_SET_TEST_LEN(MASTER_E, 32);
--		ATE_M_TEST_ID := ATE_M_TEST_ID+1;		
--		report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event";
--		ATE_USER_SET_STATE(ATE_STATE_RUN);
--		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

--------------------------------------------------------------------------------
-- Master grather than slave
--------------------------------------------------------------------------------
--m_gt_s_sim_gen: if MASTER_WIDTH > SLAVE_WIDTH generate
--constant WIDTH_RATIO		: natural := MASTER_WIDTH / SLAVE_WIDTH;
--constant MASTER_TEST_LEN	: natural := 128;
--constant SLAVE_TEST_LEN		: natural := MASTER_TEST_LEN*WIDTH_RATIO;
--	begin
--stim: process begin
--	
--			ATE_SET_STIM_MODE(BOTH_E, TIED_TO_VCC);
--			for D in 0 to SLAVE_TEST_LEN-1 loop 
--				FILL_STORES(SLAVE_E, D, D+10, SLAVE_WIDTH);		
--			end loop;
--			UNIFY_STORES(SLAVE_E, MASTER_WIDTH, SLAVE_WIDTH);
----			UNIFY_STORES(SLAVE_E);
--			ATE_SET_TEST_LEN(SLAVE_E, SLAVE_TEST_LEN);
--			ATE_SET_TEST_LEN(MASTER_E, MASTER_TEST_LEN);
--			
--			
--			
--			
--			rst		<= '1';
--		wait for LDL;
--		wait until rising_edge(clk);
--			rst		<= '0';
--		wait until rising_edge(clk);
--	
--		ATE_M_TEST_ID := 1;
--		report " TEST " & natural'image(ATE_M_TEST_ID) & " - trivial";
--		ATE_USER_SET_STATE(ATE_STATE_RUN);
--		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
--		
--		
--		
--		wait for LDL;
--		ATE_M_TEST_ID := ATE_M_TEST_ID+1;		
--		ATE_SET_STIM_MODE(SLAVE_E, PRNG);
--		ATE_SET_STIM_MODE(MASTER_E, TIED_TO_VCC);
--		report " TEST " & natural'image(ATE_M_TEST_ID) & " - valid prng";
--		ATE_USER_SET_STATE(ATE_STATE_RUN);
--		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
--		
--		
--		
--		wait for LDL;
--		ATE_M_TEST_ID := ATE_M_TEST_ID+1;		
--		ATE_SET_STIM_MODE(MASTER_E, PRNG);
--		ATE_SET_STIM_MODE(SLAVE_E, TIED_TO_VCC);
--		report " TEST " & natural'image(ATE_M_TEST_ID) & " - ready prng";
--		ATE_USER_SET_STATE(ATE_STATE_RUN);
--		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);


--		wait for LDL;
--		ATE_M_TEST_ID := ATE_M_TEST_ID+1;		
--		ATE_SET_STIM_MODE(BOTH_E, PRNG);
--		report " TEST " & natural'image(ATE_M_TEST_ID) & " - double prng";
--		ATE_USER_SET_STATE(ATE_STATE_RUN);
--		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
--wait for LDL;
--assert false
-- report " <<<SUCCESS>>> "
-- severity failure;
--wait;		
--end process;
--end generate;


	uut : entity vhdlbaselib.axis_width_conv
		generic map
		(
			ADL          => ADL,
			SLAVE_WIDTH  => SLAVE_WIDTH,
			MASTER_WIDTH => MASTER_WIDTH,
			MSB_FIRST	 => FALSE
		)
		port map
		(
			clk     => clk,
			rst     => rst,
			s_data  => s_data,
			s_keep  => s_keep,
			s_valid => s_valid,
			s_ready => s_ready,
			m_data  => m_data,
			m_valid => m_valid,
			m_ready => m_ready
		);


--
-- ATE
--
--slave_store_gen: for I in 0 to TEST_LEN-1 generate -- fill data store for slave
--	signal data	: std_logic_vector(SLAVE_WIDTH-1 downto 0);
--begin
--	data	<= std_logic_vector(to_unsigned(I+MAGIC_ADD, data'length));
--	FILL_STORES(SLAVE_E, I, data);
--end generate;

--master_store_gen: for I in 0 to TEST_LEN*4-1 generate -- fill data store for master
--	signal data	: std_logic_vector(SLAVE_WIDTH-1 downto 0);
--begin
--	data	<= std_logic_vector(to_unsigned(I+MAGIC_ADD, data'length));
--	FILL_STORES(MASTER_E, I, data);
--end generate;

-- Ate global set
	ATE_USER_INIT(1,1);
-- SLAVE PROCS
	slave_proc: ATE_S_STIM(clk, rst, ate_s_data, ate_s_keep, ate_s_valid, 
			ate_s_last, ate_s_ready, 1);
 	ate_s_wg: ATE_S_WATCHDOG(MASTER_WIDTH, clk, rst, ate_s_data, 
 			ate_s_keep, ate_s_valid, ate_s_ready, 1);
-- MASTER PROCS
	ate_master_proc: ATE_M_VERIF(clk, rst, ate_m_data, ate_m_keep,
			ate_m_valid, ate_m_last, ate_m_ready, 1);
	ate_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate_m_valid, 
			ate_m_ready, 1); -- Listen only
	ate_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate_m_data, 
			ate_m_valid, ate_m_ready, 1);
 	ate_m_wg: ATE_M_WATCHDOG(MASTER_WIDTH, clk, rst, ate_m_data, 
 			ate_m_keep, ate_m_valid, ate_m_ready, 1);
-- Signals assigment
	-- Slave ATE out
	s_valid		<= ate_s_valid after ADL;
--	s_last		<= ate_s_last after ADL;
	s_keep		<= ate_s_keep after ADL;
	s_data		<= ate_s_data after ADL;
	-- Slave ATE in
	ate_s_ready	<= s_ready;
	-- Master ATE in
	ate_m_valid 	<= m_valid;
--	ate_m_last		<= m_last;
	ate_m_data		<= m_data;
--	ate_m_keep		<= m_keep;
	m_ready			<= ate_m_ready after ADL;	 -- drive ready		


	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

