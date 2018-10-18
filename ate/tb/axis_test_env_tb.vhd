--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_test_env_tb.vhd
-- Language: VHDL
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-- Revision 0.01 - Added mult-inst for master
-- Additional Comments:
--								
--				+++++++++				+++++++++
-- ATE_SLAVE -> + UUT 1	+	--------> 	+ UUT 2 +	--------> ATE2_MASTER (m_ready stim)
--				+++++++++		|		+++++++++
--								|						
--								|						
--							ATE1_MASTER
--							(listen only)				
--

--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;


entity axis_test_env_tb is
end axis_test_env_tb;
architecture axis_test_env_tb_arch of axis_test_env_tb is





--------------------------------------------------------------------------------
-- CUT HERE
--------------------------------------------------------------------------------
constant MAX_TEST_LEN	: natural := 64;
constant LFSR_SHIFT_ITERS	: natural := 2;
constant SLAVE_WIDTH	: natural := 32;
constant MASTER_WIDTH	: natural := 32;
signal ate_s_valid		: std_logic := '0';
signal ate_s_data		: std_logic_vector(SLAVE_WIDTH-1 downto 0) := (others => 'U');
signal ate_s_keep		: std_logic_vector(SLAVE_WIDTH/8-1 downto 0) := (others => 'U');
signal ate_s_ready		: std_logic := '0';
signal ate_s_last		: std_logic := '0';
signal ate1_m_ready		: std_logic := '0';
signal ate1_m_valid		: std_logic := '0';
signal ate1_m_last		: std_logic := '0';
signal ate1_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => 'U');
signal ate1_m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0) := (others => 'U');
signal ate2_m_ready		: std_logic := '0';
signal ate2_m_valid		: std_logic := '0';
signal ate2_m_last		: std_logic := '0';
signal ate2_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => 'U');
signal ate2_m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0) := (others => 'U');
--------------------------------------------------------------------------------
-- END HERE
--------------------------------------------------------------------------------

-- Specific tests
constant PUSH_TO_STORE_TEST		: boolean := false;
constant ATE_DOUBLE_TRIGER_TEST	: boolean := false;
constant MASTER_QUIT_FAIL_TEST	: boolean := false;


signal clk		: std_logic := '0';
signal rst		: std_logic := '0';

signal s_valid		: std_logic := '0';
signal s_last		: std_logic := '0';
signal s_data		: std_logic_vector(SLAVE_WIDTH-1 downto 0);
signal s_keep		: std_logic_vector(SLAVE_WIDTH/8-1 downto 0);
signal s_ready		: std_logic := '0';
signal m_ready1		: std_logic := '0';
signal m_valid1		: std_logic := '0';
signal m_last1		: std_logic := '0';
signal m_data1		: std_logic_vector(MASTER_WIDTH-1 downto 0);
signal m_keep1		: std_logic_vector(MASTER_WIDTH/8-1 downto 0);
signal m_ready2		: std_logic := '0';
signal m_valid2		: std_logic := '0';
signal m_last2		: std_logic := '0';
signal m_data2		: std_logic_vector(MASTER_WIDTH-1 downto 0);
signal m_keep2		: std_logic_vector(MASTER_WIDTH/8-1 downto 0);


constant CLK_PERIOD			: time := 10 ns;
constant LDL				: time := CLK_PERIOD * 10;
--constant ADL				: time := CLK_PERIOD * 0;
constant ADL				: time := CLK_PERIOD / 5;

signal stop_the_clock		: boolean := false;

constant UBYTE	: std_logic_vector(8-1 downto 0) := "--------";


begin
--------------------------------------------------------------------------------
-- CUT HERE
--------------------------------------------------------------------------------
-- Ate global set
	ATE_USER_INIT(1,2);
-- Execute test procedures
-- SLAVE PROCS
	slave_proc: ATE_S_STIM(clk, rst, ate_s_data, ate_s_keep, ate_s_valid, 
			ate_s_last, ate_s_ready, 1);
 	ate1_s_wg: ATE_S_WATCHDOG(MASTER_WIDTH, clk, rst, ate_s_data, 
 			ate_s_keep, ate_s_valid, ate_s_ready, 1);
			
			
-- MASTER1 PROCS
	ate1_master_proc: ATE_M_VERIF(clk, rst, ate1_m_data, ate1_m_keep,
			ate1_m_valid, ate1_m_last, ate1_m_ready, 1);
--	ate1_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate1_m_valid, 
--			ate1_m_ready, 1); -- Listen only
	ate1_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate1_m_data, 
			ate1_m_valid, ate1_m_ready, 1);
 	ate1_m_wg: ATE_M_WATCHDOG(MASTER_WIDTH, clk, rst, ate1_m_data, 
 			ate1_m_keep, ate1_m_valid, ate1_m_ready, 1);
 	
-- MASTER2 PROCS
	ate2_master_proc: ATE_M_VERIF(clk, rst, ate2_m_data, ate2_m_keep, 
			ate2_m_valid, ate2_m_last, ate2_m_ready, 2);
	ate2_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate2_m_valid,  ate2_m_ready, 2);
	ate2_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate2_m_data, ate2_m_valid, 
			ate2_m_ready, 2);	
 	ate2_m_wg: ATE_M_WATCHDOG(MASTER_WIDTH, clk, rst, ate2_m_data, 
 			ate2_m_keep, ate2_m_valid, ate2_m_ready, 2);
 	
-- Signals assigment
	-- Slave ATE out
	s_valid		<= ate_s_valid after ADL;
	s_last		<= ate_s_last after ADL;
	s_keep		<= ate_s_keep after ADL;
	s_data		<= ate_s_data after ADL;
	-- Slave ATE in
	ate_s_ready	<= s_ready;
	
	
	-- Master ATE1 in
	ate1_m_valid 	<= m_valid1;
	ate1_m_last		<= m_last1;
	ate1_m_data		<= m_data1;
	ate1_m_keep		<= m_keep1;
	ate1_m_ready	<= m_ready1; -- listen  only
--	m_ready1		<= ate1_m_ready after ADL;	 -- drive ready	
	
	-- Master ATE2 in
	ate2_m_valid 	<= m_valid2;
	ate2_m_last		<= m_last2;
	ate2_m_data		<= m_data2;
	ate2_m_keep		<= m_keep2;
	-- Master ATE1 out - stim m_ready
	m_ready2		<= ate2_m_ready after ADL;	
--------------------------------------------------------------------------------
-- END HERE
--------------------------------------------------------------------------------


stimulus: process begin
		ATE_COMMON_CFG.VERBOSE := false;
--		lfsr_state(SLAVE_LFSR_ID) := x"01010101";
		rst		<= '1';
-- Data store gen
	for I in 0 to MAX_TEST_LEN-1 loop
		FILL_STORES(BOTH_E, I, std_logic_vector(to_unsigned(I, SLAVE_WIDTH)));
	end loop;	
	
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0';
	wait until rising_edge(clk);
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, 8);
		
	--
	-- FuncTest1 - tivial 
	-- 
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & "  - trivial";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
	report "   master1 done, waiting on master2...";	
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
	
	
	wait for LDL;
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & "  - trivial 2x with LDL between";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
	wait for LDL;
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
			
--	-- not passed - commented out
--	wait for LDL;
--	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & "  - trivial 2x without LDL between";
--	ATE_USER_SET_STATE(ATE_STATE_RUN);
--	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
--	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
--	report "   triggering next test without delay...";	
--	ATE_USER_SET_STATE(ATE_STATE_RUN);
--	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
--	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);		
--		

	
--
-- Expect to failure tests
--
	-- FuncTest - detection of invalidate retriggering by user (dobue enter RUN 
	--	state). This test is passed when failure detect
	if ATE_DOUBLE_TRIGER_TEST then
		report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & "  - double trig";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		wait for CLK_PERIOD;
		ATE_USER_SET_STATE(ATE_STATE_RUN);	
		ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
		ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
		wait for LDL;
		assert false
		 report "   Failure - expected to be deteced and stopped by ATE"
		 severity failure;
		wait;
	end if;
	
	-- The master ate interface shold detect when the UUT dives m_valid longer 
	-- then expected
	if MASTER_QUIT_FAIL_TEST then
		wait for LDL;
		report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & "  - quit test (expect to fail)";
		ATE_SET_TEST_LEN(SLAVE_E, 8);		
		ATE_SET_TEST_LEN(MASTER_E, 4);		
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
		ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
		wait for LDL;
		assert false
		 report "   Failure - expected to be deteced and stopped by ATE"
		 severity failure;
		wait;
	end if;	
	
--	if PUSH_TO_STORE_TEST then
--		report "PUSH_TO_STORE_TEST";
--		ATE_SET_TEST_LEN(MASTER_E,6);
--		-- len, width
--		FILL_INC_STORE(MASTER_E,1, 6, 4);
--		-- num, off, width
--		PUSH_TO_STORE(MASTER_E,1, 2, 3, 4);
--		
--		wait for LDL;
--		ATE_TRIG <= not ATE_TRIG;
--		
--		wait for LDL;
--		assert false
--		 report " <<<SUCCESS>>> "
--		 severity failure;
--		wait;
--		
--	end if;



	--
	-- FuncTest3 - separated trigger 
	--
	wait for LDL;
	report " [STIM] before loop testting of separate trigger";
	FILL_MASTER_LAST_STORE(1, 8);
	ATE_SET_TEST_LEN(BOTH_E, 8);	
	report " [STIM] triggering masters only...";
	ATE_USER_SET_STATE(MASTER_E,ATE_STATE_RUN);
	wait for LDL;
	assert s_valid = '0' 
	  report " [[[  FAIL  ]]]   slave should not be triggered yet"
	  severity failure;	
	report " [STIM]   triggering slave only. Waiting for DONE event...";
	ATE_USER_SET_STATE(SLAVE_E,ATE_STATE_RUN);	
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);



for I in 1 to LFSR_SHIFT_ITERS loop
-- TEST - trivial
	wait for LDL;
	report " [[[   STIM   ]]]   LFSR_SHIFT_ITER: " & natural'image(I);	
	ATE_SET_DEFAULT;
--	FILL_MASTER_LAST_STORE(1, 8);
	ATE_SET_TEST_LEN(BOTH_E, 8);	
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (trivial) triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);



-- TEST reporude bug with to fast valid deassertion when s_valid and s_ready
-- are asserten in the same time AND s_valid is PRNG but the LFSR seed it's full of '1' 
-- Hence, in 16 length test s_valid is all ones - like in TIED_TO_VCC
-- Here to reporduce it neccessary to delay m_ready by one cylce with help of
-- USER_VECTOR mode (no need to set any  values in vec)
-- SUCCESSFULL reporduce!
-- Now need to fix it!
	wait for LDL;
	RESET_MASTER_LAST_STORE;
	FILL_MASTER_LAST_STORE(1, 16);	
	ATE_SET_STIM_MODE(SLAVE_E, PRNG);
	ATE_SET_STIM_MODE(MASTER_E, USER_VECTOR);
	ATE_SET_TEST_LEN(BOTH_E, 16);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (s_valid too fast deassertion BUG)triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);


	wait for LDL;
	ATE_SET_STIM_MODE(SLAVE_E, PRNG);
	ATE_SET_STIM_MODE(MASTER_E, TIED_TO_VCC);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (valid PRNG, ready USR VEC) triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);


	wait for LDL;
	ATE_SET_STIM_MODE(SLAVE_E, TIED_TO_VCC);
	ATE_SET_STIM_MODE(MASTER_E, PRNG);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (valid VCC, ready PRNG)triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);

-- TEST4
	wait for LDL;
	ATE_SET_STIM_MODE(BOTH_E, PRNG);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (PRNG & PRNG) triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);

-- TEST5
	wait for LDL;
	ATE_SET_STIM_MODE(SLAVE_E, TIED_TO_VCC);
	ATE_SET_STIM_MODE(MASTER_E, USER_VECTOR);
	FILL_M_READY_USR_VEC(4, '0');
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
	

-- 
-- Wrong last gemneration
--
	-- TEST6 - testing length = 3: causing wrong last generation in ccsds crcgen
	wait for LDL;
	RESET_MASTER_LAST_STORE;
	FILL_MASTER_LAST_STORE(1, 3);	
	ATE_SET_TEST_LEN(BOTH_E, 3);
	ATE_SET_STIM_MODE(BOTH_E, TIED_TO_VCC);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
	
	-- TEST7 - testing length = 3: causing wrong last generation in ccsds crcgen
	wait for LDL;
	ATE_SET_STIM_MODE(BOTH_E, TIED_TO_VCC);	
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
	
	
--
-- Testin s_valid user vector stimulus
--
	-- TEST8 -- all ones
	wait for LDL;
	RESET_MASTER_LAST_STORE;
	FILL_MASTER_LAST_STORE(1, 10);		
	ATE_SET_TEST_LEN(BOTH_E, 10);
	ATE_SET_STIM_MODE(SLAVE_E, USER_VECTOR);
	ATE_SET_STIM_MODE(MASTER_E, TIED_TO_VCC);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);

	-- TEST9 -- one zero
	wait for LDL;
	ATE_SET_STIM_MODE(SLAVE_E, USER_VECTOR);
	ATE_SET_STIM_MODE(MASTER_E, TIED_TO_VCC);
	FILL_S_VALID_USR_VEC(4, '0');
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);

	-- TEST10 --double zero
	wait for LDL;
	ATE_SET_STIM_MODE(SLAVE_E, USER_VECTOR);
	ATE_SET_STIM_MODE(MASTER_E, TIED_TO_VCC);
	FILL_S_VALID_USR_VEC(4, '0');
	FILL_S_VALID_USR_VEC(5, '0');
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);

	-- TEST11 --double zero + m_ready PRNG
	wait for LDL;
	RESET_MASTER_LAST_STORE;
	FILL_MASTER_LAST_STORE(1, 20);		
	ATE_SET_TEST_LEN(BOTH_E, 20);
	ATE_SET_STIM_MODE(SLAVE_E, USER_VECTOR);
	ATE_SET_STIM_MODE(MASTER_E, PRNG);
	FILL_S_VALID_USR_VEC(4, '0');
	FILL_S_VALID_USR_VEC(5, '0');
	FILL_S_VALID_USR_VEC(5, '0');
	FILL_S_VALID_USR_VEC(20, '0');
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
	
	
	
-- TEST s_keep
	-- TEST12
	wait for LDL;
	FILL_SLAVE_KEEP_STORE(10, "0011");
	ATE_SET_STIM_MODE(BOTH_E, TIED_TO_VCC);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);


--
--
	wait for LDL;
	RESET_MASTER_LAST_STORE;
	FILL_MASTER_LAST_STORE(1, 10);		
	ATE_SET_TEST_LEN(BOTH_E, 10);
	ATE_SET_STIM_MODE(SLAVE_E, TIED_TO_VCC);
	ATE_SET_STIM_MODE(MASTER_E, USER_VECTOR);
	FILL_M_READY_USR_VEC(0, '0');	
	FILL_M_READY_USR_VEC(1, '0');	
	FILL_M_READY_USR_VEC(2, '0');	
	FILL_M_READY_USR_VEC(3, '0');	
	FILL_M_READY_USR_VEC(4, '0');	
	FILL_M_READY_USR_VEC(15, '0');	
	FILL_M_READY_USR_VEC(16, '0');	
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);
	
	
	
--
-- Stim s_last from last store
--
	wait for LDL;
	ATE_SLAVE_CFG(1).S_LAST_STIM_MODE := LAST_STORE;
	RESET_SLAVE_LAST_STORE;
	FILL_SLAVE_LAST_STORE(2, 5);
	RESET_MASTER_LAST_STORE;
	FILL_MASTER_LAST_STORE(1, 5);	
	FILL_MASTER_LAST_STORE(1, 10);	
	ATE_SET_TEST_LEN(BOTH_E, 10);
	ATE_SET_STIM_MODE(SLAVE_E, TIED_TO_VCC);
	ATE_SET_STIM_MODE(MASTER_E, USER_VECTOR);
	FILL_M_READY_USR_VEC(0, '0');	
	FILL_M_READY_USR_VEC(1, '0');	
	FILL_M_READY_USR_VEC(2, '0');	
	FILL_M_READY_USR_VEC(3, '0');	
	FILL_M_READY_USR_VEC(4, '0');	
	FILL_M_READY_USR_VEC(15, '0');	
	FILL_M_READY_USR_VEC(16, '0');	
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (last store) triggering. Waiting for DONE event";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);


-- Shift lfsr on the exit
ATE_SHIFT_LFSR(BOTH_E);
end loop;


--
-- Below is the example of using slave keep for both master and slave store
--
	wait for LDL;
	ATE_SET_DEFAULT;
	ATE_SET_TEST_LEN(BOTH_E, 2);
	FILL_SLAVE_KEEP_STORE(0, "0011");
	FILL_SLAVE_KEEP_STORE(1, "1100");
	FILL_INC_STORE_AS_KEEP(SLAVE_E, 8, 8); -- 8 slices, each is 8bit width
--	FILL_MASTER_STORE(0, "UUUUUUUU00010000");
--	FILL_MASTER_STORE(0, "UUUUUUUU00010000");
--	FILL_MASTER_STORE(0, UBYTE&UBYTE&x"0100");
--	FILL_MASTER_STORE(1, x"0302"&UBYTE&UBYTE);
	FILL_INC_STORE_AS_KEEP(MASTER_E, 8, 8); -- 8 slices, each is 8bit width
	ATE_SET_USE_KEEP(BOTH_E, true);
	ATE_SET_USE_LAST(MASTER_E, false);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " generation of sliced data accounting keep store value";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);



--
-- Below is the example of using slave keep for slave store AND counter pattern mode
-- with validating of master keep value
--
	wait for LDL;
	ATE_SET_DEFAULT;
	ATE_SET_DATA_SOURCE(MASTER_E, CNT_PAT_DATA_SOURCE);
	ATE_SET_USE_KEEP(BOTH_E, true);
	ATE_SET_USE_LAST(MASTER_E, false);
	ATE_MASTER_CFG(1).MASTER_SLICE_WIDTH := 8;
	
	ATE_SET_TEST_LEN(BOTH_E, 3);
	FILL_SLAVE_KEEP_STORE(0, "0111");
	FILL_SLAVE_KEEP_STORE(1, "0001");
	FILL_SLAVE_KEEP_STORE(2, "1111");
	FILL_INC_STORE_AS_KEEP(SLAVE_E, 3*4, 8); -- 12 slices, each is 8bit width
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " master verification in counter pattern mode";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 2, ATE_STATE_IDLE);


assert false
report " <<< [STIM]   SUCCESS >>> "
severity failure;
wait;
end process;


uut1: entity vhdlbaselib.connector
	generic map
	(
		ADL            => ADL,
		S_AXIS_W       => SLAVE_WIDTH,
		S_AXIS_READY_N => false,
		M_AXIS_W       => MASTER_WIDTH,
		M_AXIS_VALID_N => false
	)
	port map
	(
		clk     => clk,
		rst     => rst,
		s_valid => s_valid,
		s_last	=> s_last,
		s_data  => s_data,
		s_keep  => s_keep,
		s_ready => s_ready,
		m_ready => m_ready1,
		m_data  => m_data1,
		m_keep  => m_keep1,
		m_valid => m_valid1,
		m_last	=> m_last1
);

uut2: entity vhdlbaselib.connector
	generic map
	(
		ADL            => ADL,
		S_AXIS_W       => SLAVE_WIDTH,
		S_AXIS_READY_N => false,
		M_AXIS_W       => MASTER_WIDTH,
		M_AXIS_VALID_N => false
	)
	port map
	(
		clk     => clk,
		rst     => rst,
		s_valid => m_valid1,
		s_last	=> m_last1,
		s_data  => m_data1,
		s_keep  => m_keep1,		
		s_ready => m_ready1,
		m_ready => m_ready2,
		m_data  => m_data2,
		m_keep  => m_keep2,		
		m_valid => m_valid2,
		m_last	=> m_last2
);
	
	
clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after CLK_PERIOD / 2;
      wait for CLK_PERIOD;
    end loop;
    wait;
  end process;


end axis_test_env_tb_arch;
