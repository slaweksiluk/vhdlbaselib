library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;
use vhdlbaselib.txt_util.all;
use vhdlbaselib.common_pkg.all;

entity prbs_gen_tb is
end entity;

architecture bench of prbs_gen_tb is



	constant WIDTH		: natural := 32;
	signal clk 			: std_logic;
	signal rst 			: std_logic := '1';
	signal rst_ate 			: std_logic := '1';
	signal ce			: std_logic := '1';
	signal seed 		: std_logic_vector(WIDTH-1 downto 0) := x"aabbccdd";
	signal inject_err	: std_logic := '0';
	
	signal m_data : std_logic_vector(WIDTH-1 downto 0);
	signal m_valid		: std_logic := '0';
	signal m_ready		: std_logic := '1';
	
	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
	
--------------------------------------------------------------------------------
-- CUT HERE
--------------------------------------------------------------------------------
constant MAX_TEST_LEN	: natural := 32;
constant LFSR_SHIFT_ITERS	: natural := 32;
constant MASTER_WIDTH	: natural := WIDTH;
signal ate1_m_ready		: std_logic := '0';
signal ate1_m_valid		: std_logic := '0';
signal ate1_m_last		: std_logic := '0';
signal ate1_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => '0');
signal ate1_m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0) := (others => 'U');
-- Triggers
constant DONT_CARE	: std_logic_vector(WIDTH-1 downto 0) := (others => '-');

--------------------------------------------------------------------------------
-- END HERE
--------------------------------------------------------------------------------

-- temproray place fr PRBS data
type data_arr_t is array (0 to MAX_TEST_LEN-1) of std_logic_vector(WIDTH-1 downto 0);
shared variable master_store_temp	: data_arr_t;
		
begin
-- Ate global set
ATE_USER_INIT(0,1);




	uut : entity vhdlbaselib.prbs_gen
		generic map
		(
			WIDTH => WIDTH,
			ADL		=> ADL
		)
		port map
		(
			clk  => clk,
			rst  => rst,
			ce	 => ce,
			seed => seed,
			inject_err => inject_err,
			m_data => m_data,
			m_valid => m_valid,
			m_ready	=> m_ready
		);

stimulus : process begin
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0';
		rst_ate	<= '0';
	wait for LDL;


	report " [[[   STIM   ]]]   ATE started";
	wait for LDL;
	ATE_CFG.MASTER_DATA_SOURCE := NULL_DATA_SOURCE;
	ATE_CFG.MASTER_QUIT_TEST := false;
--	ATE_M_TEST_ID := ATE_M_TEST_ID +1;
	ATE_SET_TEST_LEN(MASTER_E, MAX_TEST_LEN);
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
	FILL_ALL_STORE(MASTER_E, 1, MAX_TEST_LEN, DONT_CARE);
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (capturing data) triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	for T in 0 to MAX_TEST_LEN-1 loop		
		wait until rising_edge(clk) and m_valid = '1' and m_ready = '1';
		master_store_temp(T) := m_data;
		if t = 0 then
			assert m_data = seed report "first data is not seed!" severity failure;
		end if;
	end loop;
	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
	
	report "   First three PRBS output words are :"&hstr(master_store_temp(0))&" "
		&hstr(master_store_temp(1))&" "&hstr(master_store_temp(2));			
	
	wait for LDL;
	report "   Resetting UUT";
--	wait until rising_edge(clk);
		rst		<= '1' after ADL;
	wait until rising_edge(clk);
		rst		<= '0' after ADL;
	ATE_CFG.MASTER_DATA_SOURCE := STORE_DATA_SOURCE;
	
	

-- Fill store for test
	for T in 0 to MAX_TEST_LEN-1 loop		
		FILL_STORE(MASTER_E, 1, T, master_store_temp(T));
	end loop;
report "   Data captured. Trigerring in loop tests";
	
	
	wait for LDL;
	report " [[[   STIM   ]]]   testing without ce changes";
for I in 1 to LFSR_SHIFT_ITERS loop
--	report " [[[   STIM   ]]]   LFSR_SHIFT_ITER: " & natural'image(I);
	wait for LDL;
	ATE_SET_TEST_LEN(MASTER_E, MAX_TEST_LEN);
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
--	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (capturing data) triggering. Waiting for DONE event...";
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	wait until rising_edge(clk);
	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, ATE_STATE_IDLE);
	
	wait for LDL;
		rst		<= '1' after ADL;
	wait until rising_edge(clk);
		rst		<= '0' after ADL;
	ATE_INCREMENT_SEED(MASTER_E);
end loop;


	report " [[[   STIM   ]]]   testing with ce changes - m ready cons high";
	ATE_SET_TEST_LEN(MASTER_E, MAX_TEST_LEN);
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
	for I in 1 to LFSR_SHIFT_ITERS loop
		wait for LDL;
		report "   test loop: " & natural'image(I);

		ATE_USER_SET_STATE(ATE_STATE_RUN);
		while not ate_user_check_state(MASTER_E, 1, ATE_STATE_IDLE) loop
			wait until rising_edge(clk) and m_ready = '1';
			ce <= to_std_logic(rand_natural(0,1)) after ADL;
		end loop;
	
		wait for LDL;
			rst		<= '1' after ADL;
		wait until rising_edge(clk);
			rst		<= '0' after ADL;
		ATE_INCREMENT_SEED(MASTER_E);
	end loop;
	
	report " [[[   STIM   ]]]   testing with ce changes - m ready prng";
	ATE_SET_TEST_LEN(MASTER_E, MAX_TEST_LEN);
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
	for I in 1 to LFSR_SHIFT_ITERS loop
		wait for LDL;
		report "   test loop: " & natural'image(I);

		ATE_USER_SET_STATE(ATE_STATE_RUN);
		while not ate_user_check_state(MASTER_E, 1, ATE_STATE_IDLE) loop
			wait until rising_edge(clk);
			ce <= to_std_logic(rand_natural(0,1)) after ADL;
		end loop;

		wait for LDL;	
			rst		<= '1' after ADL;
		wait until rising_edge(clk);
			rst		<= '0' after ADL;
		ATE_INCREMENT_SEED(MASTER_E);
	end loop;	

wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;

	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

--------------------------------------------------------------------------------
-- CUT HERE
--------------------------------------------------------------------------------
-- Execute test procedures
	-- MASTER1 PROCS
	ate1_master_proc: ATE_M_VERIF(clk, rst, ate1_m_data, ate1_m_keep,
			ate1_m_valid, ate1_m_last, ate1_m_ready, 1);
	ate1_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate1_m_valid, 
			ate1_m_ready, 1);
	ate1_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate1_m_data, 
			ate1_m_valid, ate1_m_ready, 1);
 	ate1_m_wg: ATE_M_WATCHDOG(MASTER_WIDTH, clk, rst, ate1_m_data, 
 			ate1_m_keep, ate1_m_valid, ate1_m_ready, 1);
 	
	
	-- Master ATE1 in
	ate1_m_valid 	<= m_valid;
	ate1_m_data		<= m_data;
	m_ready			<= ate1_m_ready after ADL;	 -- drive ready	
--------------------------------------------------------------------------------
-- END HERE
--------------------------------------------------------------------------------
end architecture;

