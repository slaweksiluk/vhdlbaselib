library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vhdlbaselib;

library vunit_lib;
context vunit_lib.vunit_context;

entity axis_fifo_tb is
generic (
	runner_cfg : string
);
end entity;

architecture bench of axis_fifo_tb is

  constant DEPTH : positive := 4;
  signal clk : std_logic;
  signal rst : std_logic;
  signal s_axis_data : std_logic_vector(7 downto 0);
  signal s_axis_valid : std_logic;
  signal s_axis_ready : std_logic;
  signal m_axis_data : std_logic_vector(7 downto 0);
  signal m_axis_valid : std_logic;
  signal m_axis_ready : std_logic;

  constant CLK_PERIOD : time := 10 ns;
  constant stop_clock : boolean := false;
begin

  uut : entity vhdlbaselib.axis_fifo
    generic map
    (
      DEPTH => DEPTH
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

  stimulus : process
  begin
	test_runner_setup(runner, runner_cfg);

	m_axis_ready <= '0';
	s_axis_valid <= '0';

	if run("write2_read2") then
		report "write first word";
		wait until rising_edge(clk);
		wait until rising_edge(clk) and s_axis_ready = '1';
		s_axis_valid <= '1';
		s_axis_data <= x"01";
		wait until rising_edge(clk);
		s_axis_valid <= '0';
		wait until rising_edge(clk) and m_axis_valid = '1' for 3*CLK_PERIOD;
		-- TODO fall through
		-- check_equal(m_axis_valid, '1', "valid not asserted");

		wait for 20 ns;
		report "write second word";
		wait until rising_edge(clk);
		wait until rising_edge(clk) and s_axis_ready = '1';
		s_axis_valid <= '1';
		s_axis_data <= x"02";
		wait until rising_edge(clk);
		s_axis_valid <= '0';

		wait for 20 ns;
		wait until rising_edge(clk);
		report "read first word";
		m_axis_ready <= '1';
		wait until rising_edge(clk) and m_axis_valid = '1';
		assert m_axis_data = x"01" severity failure;
		m_axis_ready <= '0';

		wait for 20 ns;
		wait until rising_edge(clk);
		report "read second word";
		m_axis_ready <= '1';
		wait until rising_edge(clk) and m_axis_valid = '1';
		assert m_axis_data = x"02" severity failure;
		m_axis_ready <= '0';

	elsif run("full and empty") then
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		for i in 1 to DEPTH loop
			s_axis_valid <= '1';
			s_axis_data <= std_logic_vector(to_unsigned(i, s_axis_data'length));
			wait until rising_edge(clk) and s_axis_ready = '1';
		end loop;
		s_axis_valid <= '0';
		wait until rising_edge(clk);

		wait until rising_edge(clk);
		wait until rising_edge(clk);
		for i in 1 to DEPTH loop
			m_axis_ready <= '1';
			wait until rising_edge(clk) and m_axis_valid = '1';
			assert m_axis_data = std_logic_vector(to_unsigned(i, m_axis_data'length))
				severity failure;
		end loop;
		m_axis_ready <= '0';
		wait until rising_edge(clk);

	end if;

	wait for 10 ns;
    test_runner_cleanup(runner);
	wait;
  end process;
  test_runner_watchdog(runner, 1 us);

  generate_clk : process
  begin
    while not stop_clock loop
      clk <= '0', '1' after CLK_PERIOD / 2;
      wait for CLK_PERIOD;
    end loop;
    wait;
  end process;

end architecture;

