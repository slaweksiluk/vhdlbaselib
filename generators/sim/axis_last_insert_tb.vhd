--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_last_insert_tb.vhd
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



entity axis_last_insert_tb is
end entity;

architecture bench of axis_last_insert_tb is

	constant WIDTH : natural := 8;
	constant LAST_PATTERN : std_logic_vector(WIDTH-1 downto 0) := x"77";
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal s_data : std_logic_vector(WIDTH-1 downto 0);
	signal s_valid : std_logic;
	signal s_last : std_logic;
	signal s_ready : std_logic;
	signal m_data : std_logic_vector(WIDTH-1 downto 0);
	signal m_valid : std_logic;
	signal m_last : std_logic;
	signal m_ready : std_logic := '0';

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


	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
			
begin


stimulus: process 
variable test_len		: natural := 32;	
variable slave_test_len		: natural := 32;	
variable master_test_len		: natural := 32;	
constant ate_inst		: natural := 1;
variable data_before		: natural;
variable data_after		: natural;		
begin
	wait for LDL;
	rst		<= '0' after ADL;
	wait for LDL;
	report "FuncTest#1 - trivial, not last insertion only data passing";
	report "TestCase1 - trivial";
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	
	wait for LDL;
	report "TestCase2 - prng";
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	
	wait for LDL;
	report "TestCase3 - prng";
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);	
	
	
	wait for LDL;
	report "FuncTest#2 - inserting last";
	report "TestCase1 - 3 regular data, then LAST PATTERN";
	slave_test_len := 4;
	master_test_len := 3;	
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, slave_test_len, SLAVE_WIDTH);
	FILL_STORE(SLAVE_E, ate_inst, slave_test_len-1, LAST_PATTERN);
	FILL_LAST_STORE(MASTER_E, 1, master_test_len);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);	
	
	wait for LDL;
	report "TestCase2 - 3 regular data, then LAST PATTERN, then 3 regular data with ";
	slave_test_len := 7;
	master_test_len := 6;	
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	-- Fill slave store
	for i in 0 to 2 loop
		FILL_STORE(SLAVE_E, ate_inst, i, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;
		FILL_STORE(SLAVE_E, ate_inst, 3, LAST_PATTERN);
	for i in 3 to 6 loop
		FILL_STORE(SLAVE_E, ate_inst, i+1, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;						
	FILL_LAST_STORE(MASTER_E, 1, 3);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);		
	
	
	wait for LDL;
	report "TestCase3 -  regular data, then LAST PATTERN, then regular data";
	data_before := 17;
	data_after := 33;
	slave_test_len := data_before + data_after +1;
	master_test_len := data_before + data_after;	
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	-- Fill slave store
	for i in 0 to data_before-1 loop
		FILL_STORE(SLAVE_E, ate_inst, i, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;
		FILL_STORE(SLAVE_E, ate_inst, data_before, LAST_PATTERN);
	for i in data_before to data_before + data_after loop
		FILL_STORE(SLAVE_E, ate_inst, i+1, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;						
	FILL_LAST_STORE(MASTER_E, 1, data_before);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	
	wait for LDL;
	report "TestCase4 -  m_ready PRNG";
	data_before := 7;
	data_after := 24;
	slave_test_len := data_before + data_after +1;
	master_test_len := data_before + data_after;	
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	-- Fill slave store
	for i in 0 to data_before-1 loop
		FILL_STORE(SLAVE_E, ate_inst, i, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;
		FILL_STORE(SLAVE_E, ate_inst, data_before, LAST_PATTERN);
	for i in data_before to data_before + data_after loop
		FILL_STORE(SLAVE_E, ate_inst, i+1, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;						
	FILL_LAST_STORE(MASTER_E, 1, data_before);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);		
	
	wait for LDL;
	report "TestCase5 -  m_ready double PRNG";
	data_before := 13;
	data_after := 17;
	slave_test_len := data_before + data_after +1;
	master_test_len := data_before + data_after;	
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	-- Fill slave store
	for i in 0 to data_before-1 loop
		FILL_STORE(SLAVE_E, ate_inst, i, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;
		FILL_STORE(SLAVE_E, ate_inst, data_before, LAST_PATTERN);
	for i in data_before to data_before + data_after loop
		FILL_STORE(SLAVE_E, ate_inst, i+1, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;						
	FILL_LAST_STORE(MASTER_E, 1, data_before);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);			
	
	wait for LDL;
	report "TestCase6 - double prng in loop";
	data_before := 7;
	data_after := 3;
	slave_test_len := data_before + data_after +1;
	master_test_len := data_before + data_after;	
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	-- Fill slave store
	for i in 0 to data_before-1 loop
		FILL_STORE(SLAVE_E, ate_inst, i, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;
		FILL_STORE(SLAVE_E, ate_inst, data_before, LAST_PATTERN);
	for i in data_before to data_before + data_after loop
		FILL_STORE(SLAVE_E, ate_inst, i+1, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;						
	FILL_LAST_STORE(MASTER_E, 1, data_before);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
for t in 0 to 127 loop
	wait for LDL;
	report "    loop: "&natural'image(t);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	ATE_INCREMENT_SEED(BOTH_E);
end loop;	


	wait for LDL;
	report "TestCase7 - double prng in loop (no data after lat character)";
	data_before := 4;
	data_after := 0;
	slave_test_len := data_before + data_after +1;
	master_test_len := data_before + data_after;	
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	-- Fill slave store
	for i in 0 to data_before-1 loop
		FILL_STORE(SLAVE_E, ate_inst, i, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;
		FILL_STORE(SLAVE_E, ate_inst, data_before, LAST_PATTERN);
	FILL_LAST_STORE(MASTER_E, 1, data_before);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
for t in 0 to 127 loop
	wait for LDL;
	report "    loop: "&natural'image(t);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	ATE_INCREMENT_SEED(BOTH_E);
end loop;		


	wait for LDL;
	report "TestCase8 - double prng in loop with after/before data number raondom";
for t in 0 to 127 loop
	data_before := rand_natural(1,3);
	data_after := rand_natural(0,3);
	slave_test_len := data_before + data_after +1;
	master_test_len := data_before + data_after;	
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.VERIF_MASTER_LAST := true;
	ATE_SET_TEST_LEN(SLAVE_E, slave_test_len);
	ATE_SET_TEST_LEN(MASTER_E, master_test_len);
	-- Fill slave store
	for i in 0 to data_before-1 loop
		FILL_STORE(SLAVE_E, ate_inst, i, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;
		FILL_STORE(SLAVE_E, ate_inst, data_before, LAST_PATTERN);
	for i in data_before to data_before + data_after loop
		FILL_STORE(SLAVE_E, ate_inst, i+1, std_logic_vector(to_unsigned(i, WIDTH)));			
	end loop;		
	FILL_LAST_STORE(MASTER_E, 1, data_before);
	FILL_INC_STORE(MASTER_E, ate_inst, master_test_len, MASTER_WIDTH);
	wait for LDL;
	report "    loop: "&natural'image(t)&" data_before: "&natural'image(data_before);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);
	ATE_INCREMENT_SEED(BOTH_E);
end loop;		

	

wait for LDL;
assert false
report " <<< [STIM]   SUCCESS >>> "
severity failure;
wait;
end process;

	uut : entity vhdlbaselib.axis_last_insert
		generic map
		(
			ADL          => ADL,
			LAST_PATTERN => LAST_PATTERN
		)
		port map
		(
			clk     => clk,
			rst     => rst,
			s_data  => s_data,
			s_valid => s_valid,
			s_last  => s_last,
			s_ready => s_ready,
			m_data  => m_data,
			m_valid => m_valid,
			m_last  => m_last,
			m_ready => m_ready
		);

	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
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

end architecture;

