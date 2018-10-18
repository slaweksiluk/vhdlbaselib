library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;

entity axis_fall_through_tb is
generic (
	runner_cfg : string
);
end entity;

architecture bench of axis_fall_through_tb is

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
	constant ate_inst : natural := 1;
begin

stimulus : process
	variable test_len : natural := 1;
	variable dref : std_logic_vector(s_axis_data'range) := x"ab";
begin
	test_runner_setup(runner, runner_cfg);

	if run("fall through check") then
		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		s_axis_valid <= '1';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '1');

	elsif run("double fall through check") then
		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		s_axis_valid <= '1';
		wait until rising_edge(clk);
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '1', "first high");
		wait until rising_edge(clk);
		m_axis_ready <= '1';
		wait until rising_edge(clk);
		m_axis_ready <= '0';
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0', "first low");

		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		s_axis_valid <= '1';
		wait until rising_edge(clk);
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '1', "second high");
		wait until rising_edge(clk);
		m_axis_ready <= '1';
		wait until rising_edge(clk);
		m_axis_ready <= '0';
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0', "second low");

	elsif run("ready after valid") then
		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		s_axis_data <= dref;
		s_axis_valid <= '1';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		m_axis_ready <= '1';
		wait until rising_edge(clk);
		check_equal(m_axis_data, dref);
		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0');
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0');
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0');
		wait until rising_edge(clk);
		wait until rising_edge(clk);

	elsif run("valid after ready") then
		m_axis_ready <= '1';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		s_axis_data <= dref;
		s_axis_valid <= '1';
		wait until rising_edge(clk);
		s_axis_valid <= '0';
		wait until rising_edge(clk) and m_axis_valid = '1';
		check_equal(m_axis_data, dref);
		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0');
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0');

	elsif run("valid with ready") then
		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		s_axis_data <= dref;
		s_axis_valid <= '1', '0' after CLK_PERIOD + 2 ns;
		m_axis_ready <= '1';
		wait until rising_edge(clk) and m_axis_valid = '1';
		check_equal(m_axis_data, dref);
		m_axis_ready <= '0';
		s_axis_valid <= '0';
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0');
		wait until rising_edge(clk);
		check_equal(m_axis_valid, '0');


	end if;
    test_runner_cleanup(runner);
	wait;
end process;
test_runner_watchdog(runner, 2 us);

	dut : entity vhdlbaselib.axis_fall_through
	port map
	(
		clk => clk,
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

