library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;

entity axis_buf_tb is
end entity;

architecture bench of axis_buf_tb is


	constant WIDTH : natural := 8;
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal s_data : std_logic_vector(WIDTH-1 downto 0);
	signal s_valid : std_logic;
	signal s_last : std_logic;
	signal s_ready : std_logic;
	signal m_data : std_logic_vector(WIDTH-1 downto 0);
	signal m_valid : std_logic;
	signal m_last : std_logic;

	signal m_ready : std_logic;
--------------------------------------------------------------------------------
-- ATE declarations starts
--------------------------------------------------------------------------------
constant SLAVE_WIDTH	: natural := WIDTH;
constant MASTER_WIDTH	: natural := WIDTH;
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

	
	
	constant TEST_LEN	: natural := 16;
	

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD  / 5;
	
	-- SIM PAR
	constant LFSR_SHIFT_TESTS	: natural := 32;
	
	
begin

	uut : entity work.axis_buf
		generic map
		(
			ADL	  => ADL,
			WIDTH => WIDTH
		)
		port map
		(
			clk     => clk,
			rst     => rst,
			s_data  => s_data,
			s_valid => s_valid,
			s_last	=> s_last,
			s_ready => s_ready,
			m_data  => m_data,
			m_valid => m_valid,
			m_last	=> m_last,
			m_ready => m_ready
		);

	stimulus : process
		constant ATE_INST 	: natural := 1;
	begin
		wait for LDL;
		rst		<= '0' after ADL;
		wait for LDL;	
		report " FuncTest#? trivial";		
		FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
		FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
		ATE_SET_TEST_LEN(BOTH_E, test_len);
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

		

	-- TEST 1 - one cycle m_ready deassertion
		wait for LDL;
		ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
		ATE_CFG.M_READY_STIM_MODE := USER_VECTOR;
		ATE_CFG.MASTER_TIMEOUT := 5 us;
		FILL_M_READY_USR_VEC(4, '0');
		ATE_SET_TEST_LEN(BOTH_E, TEST_LEN);
			rst		<= '1' after ADL;
		wait for LDL;
		wait until rising_edge(clk);
			rst		<= '0' after ADL;
		wait until rising_edge(clk);
		report " [STIM]   TEST1 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
		wait for LDL;

	-- TEST2 - double cycle m _ready deassertion
		ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
		ATE_CFG.M_READY_STIM_MODE := USER_VECTOR;
		FILL_M_READY_USR_VEC(4, '0');
		FILL_M_READY_USR_VEC(5, '0');
		report " [STIM]   TEST2 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
		wait for LDL;
		
		
		
	-- TEST3 - one cycle s_valid deassertion
		ATE_CFG.S_VALID_STIM_MODE := USER_VECTOR;
		ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
		FILL_S_VALID_USR_VEC(4, '0');
		report " [STIM]   TEST3 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
		wait for LDL;
		
	

	-- TEST4 - two cycle s_valid deassertion
		ATE_CFG.S_VALID_STIM_MODE := USER_VECTOR;
		ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
		FILL_S_VALID_USR_VEC(4, '0');
		FILL_S_VALID_USR_VEC(5, '0');
		report " [STIM]   TEST4 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);	
		wait for LDL;


	-- TEST5 - PRNG s_valid deassertion
		ATE_CFG.S_VALID_STIM_MODE := PRNG;
		ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
		report " [STIM]   TEST5 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
		wait for LDL;

	-- TEST6 - PRNG m_ready deassertion
		ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
		ATE_CFG.M_READY_STIM_MODE := PRNG;
		report " [STIM]   TEST6 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
		wait for LDL;				
	
	
	-- TEST8 - user and user
		ATE_CFG.S_VALID_STIM_MODE := USER_VECTOR;
		ATE_CFG.M_READY_STIM_MODE := USER_VECTOR;
		s_valid_usr_vec := (others => '1');
		m_ready_usr_vec	:= (others => '1');
		wait for 0 ps;
		FILL_M_READY_USR_VEC(6, '0');
		FILL_S_VALID_USR_VEC(5, '0');		
		report " [STIM]   TEST7 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);	
		wait for LDL;			
	
	-- TEST8 - both PRNG deassertion
		ATE_CFG.S_VALID_STIM_MODE := PRNG;
		ATE_CFG.M_READY_STIM_MODE := PRNG;
		report " [STIM]   TEST8 triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);		
		wait for LDL;
		
		wait for LDL;
		report "FuncTest#? s_valid transistion when master not ready";		
		ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
		ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
		ATE_USER_SET_STATE(SLAVE_E, 1, ATE_STATE_RUN);
		wait for LDL;
		assert m_ready = '0'
			report " TB interanal err - m ready shokld bere low here"
			severity error;
		assert m_valid = '1' 
			report " m_valid not assretedn when s_valid = 1 and m_ready = 0"	
			severity error;
		ATE_USER_SET_STATE(MASTER_E, 1, ATE_STATE_RUN);			
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);		
		wait for LDL;	
	
	-- TEST 9 with diff LFSR's
	for I in 1 to LFSR_SHIFT_TESTS loop
		ATE_SHIFT_LFSR(MASTER_E);
		ATE_SHIFT_LFSR(SLAVE_E);
		ATE_CFG.S_VALID_STIM_MODE := PRNG;
		ATE_CFG.M_READY_STIM_MODE := PRNG;
		report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " triggering. Waiting for DONE event...";
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);	
		ATE_INCREMENT_SEED(BOTH_E);
		wait for LDL;
	end loop;
	
	
-- END
		wait for LDL;
		assert false
		 report " <<<SUCCESS>>> "
		 severity failure;
		wait;
	end process;


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

end architecture;

