--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_data_drop_tb.vhd
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


entity axis_data_drop_tb is
end entity;

architecture bench of axis_data_drop_tb is

	constant DATA_WIDTH	: natural := 8;
	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal drop_pulse : std_logic := '0';
	signal s_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal s_valid : std_logic;
	signal s_last : std_logic;
	signal s_ready : std_logic;
	signal m_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal m_valid : std_logic;
	signal m_last : std_logic;
	signal m_ready : std_logic;

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
--	constant ADL	: time := CLK_PERIOD / 5;
	constant ADL	: time := 0 ps;
	constant DONT_CARE	: std_logic_vector(8-1 downto 0) := "--------";
	
	
--------------------------------------------------------------------------------
-- ATE declarations starts
--------------------------------------------------------------------------------
	constant SLAVE_WIDTH	: natural := DATA_WIDTH;
	constant MASTER_WIDTH	: natural := DATA_WIDTH;
	signal ate_s_valid		: std_logic := '0';
	signal ate_s_data		: std_logic_vector(SLAVE_WIDTH-1 downto 0) := (others => 'U');
	signal ate_s_keep		: std_logic_vector(SLAVE_WIDTH/8-1 downto 0) := (others => 'U');
	signal ate_s_ready		: std_logic := '0';
	signal ate_s_last		: std_logic := '0';
	signal ate_m_ready		: std_logic := '0';
	signal ate_m_valid		: std_logic := '0';
	signal ate_m_last		: std_logic := '0';
	signal ate_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => 'U');
	signal ate_m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0) := (others => 'U');
--------------------------------------------------------------------------------
-- ATE declarations end
--------------------------------------------------------------------------------	
begin

stimulus: process 
variable test_len		: natural := 5;	
variable ate_inst		: natural := 1;
variable packet_num		: natural;
variable packet_len		: natural;
begin
	wait for LDL;
	rst		<= '0' after ADL;


	wait for LDL;
	report "[STIM] FuncTest#1 - basic";
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	
	wait for LDL;
	report " TestCase1 - basic s valid prng";
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	
	wait for LDL;
	report " TestCase2 - basic m_ready prng";
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	wait for LDL;
	report " TestCase3 - basic double prng";
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

-- Currently master verification is disabled as its not trivial to implement
	wait for LDL;
--	packet_num := 3;
--	packet_len := 32;
	report "[STIM] FuncTest#2 - droppping";
--	report " TestCase1 three packets of length 32. The second is dropeed in the middle";
--	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
--	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
--	ATE_SET_TEST_LEN(SLAVE_E, packet_len*packet_num);
--	ATE_SET_TEST_LEN(MASTER_E, packet_len*(packet_num-1)+4);
--	ATE_CFG.S_LAST_STIM_MODE := LAST_STORE;
--	FILL_LAST_STORE(SLAVE_E, packet_num, packet_len);
--	FILL_INC_STORE(SLAVE_E, ate_inst, packet_len*packet_num, SLAVE_WIDTH);
--	ATE_CFG.MASTER_DATA_SOURCE := NULL_DATA_SOURCE;
--	ATE_CFG.MASTER_QUIT_TEST := false;
--	-- RUN
--	ATE_USER_SET_STATE(ATE_STATE_RUN);
--	wait until rising_edge(clk) and m_valid = '1' and m_last = '1';
--	wait for 50 ns;	
--	drop_pulse <= transport '1' after 1 ps ,'0' after CLK_PERIOD+1 ps;
--	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	
-- Master expects only packet1 and 2
	wait for 3*LDL;
	packet_num := 3;
	packet_len := 16;
	report " TestCase1 three packets of length 16. The second is dropeed in the middle";
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
	-- set store len for slave to repaclaite 0,1,2,,,n ___ 0,1,3,,,n DATA
	ATE_SET_TEST_LEN(SLAVE_E, packet_len*packet_num, packet_len);
	ATE_SET_TEST_LEN(MASTER_E, packet_len);
	ATE_CFG.S_LAST_STIM_MODE := LAST_STORE;
	FILL_LAST_STORE(SLAVE_E, packet_num, packet_len);
	FILL_LAST_STORE(MASTER_E, 1, packet_len);
	FILL_INC_STORE(BOTH_E, ate_inst, packet_len, SLAVE_WIDTH);
	ATE_CFG.MASTER_DATA_SOURCE := STORE_DATA_SOURCE;
	ATE_CFG.MASTER_QUIT_TEST := false;
-- ATE Run
	-- At first, start both master and slave
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	wait until rising_edge(clk) and m_valid = '1' and m_last = '1';
	wait for 50 ns;	
	drop_pulse <= transport '1' after 1 ps ,'0' after CLK_PERIOD+1 ps;
	-- Start master again when droped packet has finished
	wait until rising_edge(clk) and s_valid = '1' and s_last = '1';
	ATE_USER_SET_STATE(MASTER_E, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	
	wait for 3*LDL;
	packet_num := 3;
	packet_len := 16;
	report " TestCase2 s above but mready is constant 1";
	ATE_CFG.M_READY_DEF_VAL := (others => '1');
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
	-- set store len for slave to repaclaite 0,1,2,,,n ___ 0,1,3,,,n DATA
	ATE_SET_TEST_LEN(SLAVE_E, packet_len*packet_num, packet_len);
	ATE_SET_TEST_LEN(MASTER_E, packet_len);
	ATE_CFG.S_LAST_STIM_MODE := LAST_STORE;
	FILL_LAST_STORE(SLAVE_E, packet_num, packet_len);
	FILL_LAST_STORE(MASTER_E, 1, packet_len);
	FILL_INC_STORE(BOTH_E, ate_inst, packet_len, SLAVE_WIDTH);
	ATE_CFG.MASTER_DATA_SOURCE := STORE_DATA_SOURCE;
	ATE_CFG.MASTER_QUIT_TEST := false;
-- ATE Run
	-- At first, start both master and slave
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	wait until rising_edge(clk) and m_valid = '1' and m_last = '1';
	wait for 50 ns;	
	drop_pulse <= transport '1' after 1 ps ,'0' after CLK_PERIOD+1 ps;
	-- Start master again when droped packet has finished
	wait until rising_edge(clk) and s_valid = '1' and s_last = '1';
	ATE_USER_SET_STATE(MASTER_E, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);	
	
	wait for 3*LDL;
	packet_num := 3;
	packet_len := 16;
	report " TestCase3 s valid prng";
	ATE_CFG.M_READY_DEF_VAL := (others => '0');
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
	-- set store len for slave to repaclaite 0,1,2,,,n ___ 0,1,3,,,n DATA
	ATE_SET_TEST_LEN(SLAVE_E, packet_len*packet_num, packet_len);
	ATE_SET_TEST_LEN(MASTER_E, packet_len);
	ATE_CFG.S_LAST_STIM_MODE := LAST_STORE;
	FILL_LAST_STORE(SLAVE_E, packet_num, packet_len);
	FILL_LAST_STORE(MASTER_E, 1, packet_len);
	FILL_INC_STORE(BOTH_E, ate_inst, packet_len, SLAVE_WIDTH);
	ATE_CFG.MASTER_DATA_SOURCE := STORE_DATA_SOURCE;
	ATE_CFG.MASTER_QUIT_TEST := false;
-- ATE Run
	-- At first, start both master and slave
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	wait until rising_edge(clk) and m_valid = '1' and m_last = '1';
	wait for 50 ns;	
	drop_pulse <= transport '1' after 1 ps ,'0' after CLK_PERIOD+1 ps;
	-- Start master again when droped packet has finished
	wait until rising_edge(clk) and s_valid = '1' and s_last = '1';
	ATE_USER_SET_STATE(MASTER_E, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);	
	
	
	wait for 3*LDL;
	packet_num := 3;
	packet_len := 16;
	report " TestCase4 m ready prng";
	ATE_CFG.M_READY_DEF_VAL := (others => '0');
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
	-- set store len for slave to repaclaite 0,1,2,,,n ___ 0,1,3,,,n DATA
	ATE_SET_TEST_LEN(SLAVE_E, packet_len*packet_num, packet_len);
	ATE_SET_TEST_LEN(MASTER_E, packet_len);
	ATE_CFG.S_LAST_STIM_MODE := LAST_STORE;
	FILL_LAST_STORE(SLAVE_E, packet_num, packet_len);
	FILL_LAST_STORE(MASTER_E, 1, packet_len);
	FILL_INC_STORE(BOTH_E, ate_inst, packet_len, SLAVE_WIDTH);
	ATE_CFG.MASTER_DATA_SOURCE := STORE_DATA_SOURCE;
	ATE_CFG.MASTER_QUIT_TEST := false;
-- ATE Run
	-- At first, start both master and slave
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	wait until rising_edge(clk) and m_valid = '1' and m_last = '1';
	wait for 50 ns;	
	drop_pulse <= transport '1' after 1 ps ,'0' after CLK_PERIOD+1 ps;
	-- Start master again when droped packet has finished
	wait until rising_edge(clk) and s_valid = '1' and s_last = '1';
	ATE_USER_SET_STATE(MASTER_E, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);		
	
	
	wait for 3*LDL;
	packet_num := 3;
	packet_len := 16;
	report " TestCase5 double prng";
	ATE_CFG.M_READY_DEF_VAL := (others => '0');
	ATE_CFG.MASTER_TIMEOUT := 10 us;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
	-- set store len for slave to repaclaite 0,1,2,,,n ___ 0,1,3,,,n DATA
	ATE_SET_TEST_LEN(SLAVE_E, packet_len*packet_num, packet_len);
	ATE_SET_TEST_LEN(MASTER_E, packet_len);
	ATE_CFG.S_LAST_STIM_MODE := LAST_STORE;
	FILL_LAST_STORE(SLAVE_E, packet_num, packet_len);
	FILL_LAST_STORE(MASTER_E, 1, packet_len);
	FILL_INC_STORE(BOTH_E, ate_inst, packet_len, SLAVE_WIDTH);
	ATE_CFG.MASTER_DATA_SOURCE := STORE_DATA_SOURCE;
	ATE_CFG.MASTER_QUIT_TEST := false;
-- ATE Run
	-- At first, start both master and slave
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	wait until rising_edge(clk) and m_valid = '1' and m_last = '1';
	wait for 50 ns;	
	drop_pulse <= transport '1' after 1 ps ,'0' after CLK_PERIOD+1 ps;
	-- Start master again when droped packet has finished
	wait until rising_edge(clk) and s_valid = '1' and s_last = '1';
	ATE_USER_SET_STATE(MASTER_E, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);			
	
	
	wait for 3*LDL;
	packet_num := 3;
	packet_len := 16;
	report " TestCase6 double prng";
	ATE_CFG.M_READY_DEF_VAL := (others => '0');
	ATE_CFG.MASTER_TIMEOUT := 10 us;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
	-- set store len for slave to repaclaite 0,1,2,,,n ___ 0,1,3,,,n DATA
	ATE_SET_TEST_LEN(SLAVE_E, packet_len*packet_num, packet_len);
	ATE_SET_TEST_LEN(MASTER_E, packet_len);
	ATE_CFG.S_LAST_STIM_MODE := LAST_STORE;
	FILL_LAST_STORE(SLAVE_E, packet_num, packet_len);
	FILL_LAST_STORE(MASTER_E, 1, packet_len);
	FILL_INC_STORE(BOTH_E, ate_inst, packet_len, SLAVE_WIDTH);
	ATE_CFG.MASTER_DATA_SOURCE := STORE_DATA_SOURCE;
	ATE_CFG.MASTER_QUIT_TEST := false;
-- ATE Run
for i in 1 to 128 loop
	wait for 10*LDL;
	report " loop inter"&natural'image(i);
	-- At first, start both master and slave
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	wait until rising_edge(clk) and m_valid = '1' and m_last = '1' and m_ready = '1';
	wait for 50 ns;	
	drop_pulse <= transport '1' after 1 ps ,'0' after CLK_PERIOD+1 ps;
	-- Start master again when droped packet has finished
	wait until rising_edge(clk) and s_valid = '1' and s_last = '1';
	ATE_USER_WAIT_ON_STATE(MASTER_E, ATE_STATE_IDLE);		
	ATE_USER_SET_STATE(MASTER_E, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);		

	ATE_INCREMENT_SEED(BOTH_E);
end loop;
wait for LDL;
assert false
report " <<< [STIM]   SUCCESS >>> "
severity failure;
wait;
end process;

	uut : entity vhdlbaselib.axis_data_drop
		generic map
		(
			ADL => ADL
		)
		port map
		(
			clk        => clk,
			rst        => rst,
			drop_pulse => drop_pulse,
			s_data     => s_data,
			s_valid    => s_valid,
			s_last     => s_last,
			s_ready    => s_ready,
			m_data     => m_data,
			m_valid    => m_valid,
			m_last     => m_last,
			m_ready    => m_ready
		);


	
	--------------------------------------------------------------------------------
-- ATE instances start
--------------------------------------------------------------------------------
-- Ate global set
	ATE_USER_INIT(1,1);
-- SLAVE PROCS
	slave_proc: ATE_S_STIM(clk, rst, ate_s_data, ate_s_keep, ate_s_valid, 
			ate_s_last, ate_s_ready);
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
	s_last		<= ate_s_last after ADL;
	s_data		<= ate_s_data after ADL;
	-- Slave ATE in
	ate_s_ready	<= s_ready;
	-- Master ATE in
	ate_m_valid 	<= m_valid;
	ate_m_last		<= m_last;
	ate_m_data		<= m_data;
	m_ready			<= ate_m_ready after ADL;	 -- drive ready	
--------------------------------------------------------------------------------
-- ATE instances end
--------------------------------------------------------------------------------

	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

--clk<=NOT clk AFTER clk_period/2;
end architecture;

