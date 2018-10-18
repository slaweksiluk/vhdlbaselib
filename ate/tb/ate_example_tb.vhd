--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: ate_example_tb.vhd
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;


entity ate_example_tb is
end ate_example_tb;
architecture ate_example_tb_arch of ate_example_tb is

constant SLAVE_WIDTH : natural := 32;
constant MASTER_WIDTH : natural := 32;

signal clk		: std_logic := '0';
signal rst		: std_logic := '1';

signal s_valid		: std_logic := '0';
signal s_last		: std_logic := '0';
signal s_data		: std_logic_vector(SLAVE_WIDTH-1 downto 0);
signal s_keep		: std_logic_vector(SLAVE_WIDTH/8-1 downto 0);
signal s_ready		: std_logic := '0';
signal m_ready		: std_logic := '0';
signal m_valid		: std_logic := '0';
signal m_last		: std_logic := '0';
signal m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0);
signal m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0);


constant CLK_PERIOD			: time := 10 ns;
constant LDL				: time := CLK_PERIOD * 10;
signal stop_the_clock		: boolean := false;



begin
--------------------------------------------------------------------------------
-- ATE instances start
--------------------------------------------------------------------------------
-- Ate global set
ATE_USER_INIT(1,1);

axis_slave_vc : entity vhdlbaselib.axis_slave
	generic map
	(
		ID => 1
	)
	port map
	(
		clk   => clk,
		rst   => rst,
		data  => s_data,
		keep  => s_keep,
		valid => s_valid,
		last  => s_last,
		ready => s_ready
	);

axis_master_vc : entity vhdlbaselib.axis_master
	generic map
	(
		ID => 1
	)
	port map
	(
		clk   => clk,
		rst   => rst,
		data  => m_data,
		keep  => m_keep,
		valid => m_valid,
		last  => m_last,
		ready => m_ready
	);

--------------------------------------------------------------------------------
-- ATE instances end
--------------------------------------------------------------------------------


stimulus: process 
variable test_len		: natural := 32;
variable ate_inst		: natural := 1;
begin
	wait for LDL;
	rst		<= '0';
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, test_len);
	FILL_INC_STORE(SLAVE_E, ate_inst, test_len, SLAVE_WIDTH);
	FILL_INC_STORE(MASTER_E, ate_inst, test_len, MASTER_WIDTH);
	ATE_USER_SET_STATE(ATE_STATE_RUN);
	ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

wait for LDL;
assert false
report " <<< [STIM]   SUCCESS >>> "
severity failure;
wait;
end process;


dut: entity vhdlbaselib.connector
	generic map
	(
		ADL            => 0 ps,
		S_AXIS_W       => SLAVE_WIDTH,
		S_AXIS_READY_N => false,
		M_AXIS_W       => MASTER_WIDTH,
		M_AXIS_VALID_N => false
	)
	port map
	(
		clk     => clk,
		rst     => rst,
		s_valid => m_valid,
		s_last	=> m_last,
		s_data  => m_data,
		s_keep  => m_keep,
		s_ready => m_ready,
		m_ready => s_ready,
		m_data  => s_data,
		m_keep  => s_keep,
		m_valid => s_valid,
		m_last	=> s_last
);


clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after CLK_PERIOD / 2;
      wait for CLK_PERIOD;
    end loop;
    wait;
  end process;


end ate_example_tb_arch;
