library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;

entity axis_fifo_ate_tb is
generic (
	runner_cfg : string;
	fwft : boolean := false
);
end entity;

architecture bench of axis_fifo_ate_tb is

	constant WIDTH : positive := 8;
	constant DEPTH : positive := 4;
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal s_axis_data : std_logic_vector(7 downto 0);
	signal s_axis_valid : std_logic;
	signal s_axis_ready : std_logic;
	signal m_axis_data : std_logic_vector(7 downto 0);
	signal axis_keep : std_logic_vector(0 downto 0) := "1";
	signal m_axis_valid : std_logic;
	signal m_axis_ready : std_logic;

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant test_len : natural := 512;
	constant ate_inst : natural := 1;
begin

stimulus : process
begin
	test_runner_setup(runner, runner_cfg);

	if run("write and read") then
		wait for 10 ns;
		rst		<= '0';
		wait for 10 ns;
		ATE_SET_TEST_LEN(BOTH_E, test_len);
		FILL_INC_STORE(SLAVE_E, ate_inst, test_len, WIDTH);
		FILL_INC_STORE(MASTER_E, ate_inst, test_len, WIDTH);
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	elsif run("rand s valid") then
		ATE_SET_STIM_MODE(SLAVE_E, PRNG);
		wait for 10 ns;
		rst		<= '0';
		wait for 10 ns;
		ATE_SET_TEST_LEN(BOTH_E, test_len);
		FILL_INC_STORE(SLAVE_E, ate_inst, test_len, WIDTH);
		FILL_INC_STORE(MASTER_E, ate_inst, test_len, WIDTH);
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	elsif run("rand m ready") then
		ATE_SET_STIM_MODE(MASTER_E, PRNG);
		wait for 10 ns;
		rst		<= '0';
		wait for 10 ns;
		ATE_SET_TEST_LEN(BOTH_E, test_len);
		FILL_INC_STORE(SLAVE_E, ate_inst, test_len, WIDTH);
		FILL_INC_STORE(MASTER_E, ate_inst, test_len, WIDTH);
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	elsif run("rand s valid rand m ready") then
		ATE_SET_STIM_MODE(BOTH_E, PRNG);
		wait for 10 ns;
		rst		<= '0';
		wait for 10 ns;
		ATE_SET_TEST_LEN(BOTH_E, test_len);
		FILL_INC_STORE(SLAVE_E, ate_inst, test_len, WIDTH);
		FILL_INC_STORE(MASTER_E, ate_inst, test_len, WIDTH);
		ATE_USER_SET_STATE(ATE_STATE_RUN);
		ATE_USER_WAIT_ON_STATE(ATE_STATE_IDLE);

	elsif run("fwft") and fwft then
		wait for 10 ns;
		rst		<= '0';
		wait for 10 ns;
		ATE_SET_TEST_LEN(BOTH_E, test_len);
		FILL_INC_STORE(SLAVE_E, ate_inst, test_len, WIDTH);
		FILL_INC_STORE(MASTER_E, ate_inst, test_len, WIDTH);
		ATE_USER_SET_STATE(SLAVE_E, ATE_STATE_RUN);
		wait for 50 ns;
		check_equal(m_axis_valid, '1', "fwft not working");
	end if;
    test_runner_cleanup(runner);
	wait;
end process;
test_runner_watchdog(runner, 30 us);

	ATE_USER_INIT(1,1);

	axis_master_vc : entity vhdlbaselib.axis_master
	generic map
	(
		ID => 1
	)
	port map
	(
		clk   => clk,
		rst   => rst,
		data  => s_axis_data,
		keep  => axis_keep,
		valid => s_axis_valid,
		last  => open,
		ready => s_axis_ready
	);
	axis_slave_vc : entity vhdlbaselib.axis_slave
	generic map
	(
		ID => 1
	)
	port map
	(
		clk   => clk,
		rst   => rst,
		data  => m_axis_data,
		keep  => axis_keep,
		valid => m_axis_valid,
		last  => '0',
		ready => m_axis_ready
	);
	dut : entity vhdlbaselib.axis_fifo
	generic map
	(
	  DEPTH => DEPTH,
		FWFT => fwft
	)
	port map
	(
	  clk          => clk,
	  rst          => rst,
	  s_axis_data  => s_axis_data,
	  s_axis_valid => s_axis_valid,
	  s_axis_ready => s_axis_ready,
	  m_axis_data  => m_axis_data,
	  m_axis_valid => m_axis_valid,
	  m_axis_ready => m_axis_ready
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

