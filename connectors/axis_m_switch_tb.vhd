--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_m_switch_tb.vhd
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
use vhdlbaselib.axis_pkg.all;
use vhdlbaselib.axis_sw_pkg.all;
use vhdlbaselib.axis_test_env_pkg.all;

entity axis_m_switch_tb is
end entity;

architecture bench of axis_m_switch_tb is
	constant DATA_WIDTH	: natural := 32;
	

	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal sel : std_logic_vector(0 downto 0) := "0";
	signal ate_s	: axi_st := (data => (others => 'Z'), keep => (others => 'Z'), valid => 'Z', last => 'Z', ready => 'Z');
	signal ate_m1	: axi_st := (data => (others => 'Z'), keep => (others => 'Z'), valid => 'Z', last => 'Z', ready => '0');
	signal ate_m2	: axi_st := (data => (others => 'Z'), keep => (others => 'Z'), valid => 'Z', last => 'Z', ready => '0');
	
	signal s_i		: axis_s_i;
	signal s_o		: axis_s_o;
	signal m1_i		: axis_m_i;
	signal m1_o		: axis_m_o;
	signal m2_i		: axis_m_i;
	signal m2_o		: axis_m_o;


	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
			
begin

stimulus : process
variable test_len		: natural := 5;	
variable ate_inst		: natural := 1;
begin
	wait for LDL;
	rst		<= '0' after ADL;
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, DATA_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, DATA_WIDTH);
	ATE_USER_SET_STATE(SLAVE_E, ATE_STATE_RUN);
	ATE_USER_SET_STATE(MASTER_E, ate_inst, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, ate_inst, ATE_STATE_IDLE);

	ate_inst := 2;
	sel	<= "1";
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, DATA_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, DATA_WIDTH);
	ATE_USER_SET_STATE(SLAVE_E, ATE_STATE_RUN);
	ATE_USER_SET_STATE(MASTER_E, ate_inst, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, ate_inst, ATE_STATE_IDLE);
	
	
for i in 1 to 100 loop
	ate_inst := 1;
	test_len := 63;
	sel	<= "0";
	wait for LDL;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, DATA_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, DATA_WIDTH);
	ATE_USER_SET_STATE(SLAVE_E, ATE_STATE_RUN);
	ATE_USER_SET_STATE(MASTER_E, ate_inst, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, ate_inst, ATE_STATE_IDLE);	
	
	ate_inst := 2;
	test_len := 63;
	sel	<= "1";
	wait for LDL;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := PRNG;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, DATA_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, DATA_WIDTH);
	ATE_USER_SET_STATE(SLAVE_E, ATE_STATE_RUN);
	ATE_USER_SET_STATE(MASTER_E, ate_inst, ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(MASTER_E, ate_inst, ATE_STATE_IDLE);	

	ATE_INCREMENT_SEED(BOTH_E);
end loop;
wait for LDL;
assert false
report " <<<SUCCESS>>> "
severity failure;
wait;
end process;
	
--------------------------------------------------------------------------------
-- ATE
--------------------------------------------------------------------------------
-- Ate global set
	ATE_USER_INIT(1,2);
-- SLAVE PROCS
	ate_stim1: ATE_S_STIM(clk, rst, ate_s);
 	ate_s_wg1: ATE_S_WATCHDOG(WIDTH, clk, rst, ate_s, 1);
			
-- MASTER1 PROCS
	ate_verif1: ATE_M_VERIF(clk, rst, ate_m1, 1);
	ate1_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate_m1, 1);
	ate_m_wg1: MASTER_WATCHDOG_PROC(clk, rst, ate_m1, 1);
 	ate1_m_wg: ATE_M_WATCHDOG(WIDTH, clk, rst, ate_m1, 1);
 	
-- MASTER2 PROCS
	ate2_master_proc: ATE_M_VERIF(clk, rst, ate_m2, 2);
	ate2_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate_m2, 2);
	ate2_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate_m2, 2);	
 	ate2_m_wg: ATE_M_WATCHDOG(WIDTH, clk, rst, ate_m2, 2);
 	
-- ATE <--> UUT
	s_i.data	<= ate_s.data after ADL;
	s_i.keep	<= ate_s.keep after ADL;
	s_i.valid	<= ate_s.valid after ADL;
	s_i.last	<= ate_s.last after ADL;
	s_i.last	<= ate_s.last after ADL;
	ate_s.ready	<= s_o.ready;
	
	ate_m1.data		<= m1_o.data;
	ate_m1.keep		<= m1_o.keep;
	ate_m1.valid	<= m1_o.valid;
	ate_m1.last		<= m1_o.last;
	m1_i.ready		<= ate_m1.ready after ADL;
 	
	ate_m2.data		<= m2_o.data;
	ate_m2.keep		<= m2_o.keep;
	ate_m2.valid	<= m2_o.valid;
	ate_m2.last		<= m2_o.last;
	m2_i.ready		<= ate_m2.ready after ADL; 	
 	
 		uut : entity vhdlbaselib.axis_m_switch
 		generic map (ADL => ADL)
		port map
		(
			clk => clk,
			rst => rst,
			sel => sel,
			s_i		=> s_i,
			s_o		=> s_o,
			m_i(0)	=> m1_i,
			m_i(1)	=> m2_i,
			m_o(0)	=> m1_o,
			m_o(1)	=> m2_o
		);


	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

