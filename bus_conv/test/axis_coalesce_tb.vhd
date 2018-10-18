-- 2018 Slawomir Siluk slaweksiluk@gazeta.pl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vhdlbaselib;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.axi_stream_pkg.all;
use vunit_lib.stream_master_pkg.all;
use vunit_lib.stream_slave_pkg.all;

library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity axis_coalesce_tb is
generic (
	runner_cfg : string
);
end entity;

architecture bench of axis_coalesce_tb is
	constant TARGETS : positive := 2;
	constant DATA_WIDTH : positive := 8;
	subtype s_data_range is integer range DATA_WIDTH-1 downto 0;
	subtype s_data0_range is integer range DATA_WIDTH-1 downto 0;
	subtype s_data1_range is integer range DATA_WIDTH*2-1 downto DATA_WIDTH;
	subtype m_data_range is integer range 2*DATA_WIDTH-1 downto 0;

	signal clk : std_logic := '0';
	signal rst : std_logic;

	signal s_data0 : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal s_data1 : std_logic_vector(s_data_range);
	signal s_valid0 : std_logic;
	signal s_valid1 : std_logic;
	signal s_ready0 : std_logic;
	signal s_ready1 : std_logic;

	signal m_data : std_logic_vector(m_data_range);
	signal m_valid : std_logic;
	signal m_ready : std_logic;

	-- Vunit bfm's
	constant axis_master0 : axi_stream_master_t :=
		new_axi_stream_master(data_length => DATA_WIDTH);
	constant in0_stream : stream_master_t := as_stream(axis_master0);
	constant axis_master1 : axi_stream_master_t :=
		new_axi_stream_master(data_length => DATA_WIDTH);
	constant in1_stream : stream_master_t := as_stream(axis_master1);
	constant axis_slave : axi_stream_slave_t :=
		new_axi_stream_slave(data_length => 2*DATA_WIDTH);
	constant out_stream : stream_slave_t := as_stream(axis_slave);

	constant tb_logger : logger_t := get_logger("tb");
	constant CLK_PERIOD : time := 10 ns;

begin

	stimulus : process
		variable got_data : std_logic_vector(m_data'range);
		constant DATA0 : std_logic_vector(s_data_range) := x"ab";
		constant DATA1 : std_logic_vector(s_data_range) := x"cd";
	begin
		test_runner_setup(runner, runner_cfg);
		set_format(display_handler, verbose, true);
		show(tb_logger, display_handler, verbose);

		if run("smoke-test") then
			wait until rising_edge(clk);

		elsif run("simultaneus") then
			wait until rising_edge(clk);
			push_stream(net, in0_stream, data0);
			push_stream(net, in1_stream, data1);
			-- Expect data on the axis data interface
			info(tb_logger, "expect data on master interface");
			pop_stream(net, out_stream, got_data);
			check_equal(got_data, data1&data0, "data");
			wait until rising_edge(clk);

		end if;
	    test_runner_cleanup(runner);
	wait;
	end process;
	test_runner_watchdog(runner, 1 us);

	dut : entity vhdlbaselib.axis_coalesce
	generic map (
		DATA_WIDTH => DATA_WIDTH
	) port map (
		clk     => clk,
		rst     => rst,
		s_data(DATA_WIDTH-1 downto 0) => s_data0,
		s_data(DATA_WIDTH*2-1 downto DATA_WIDTH) => s_data1,
		s_valid(0) => s_valid0,
		s_valid(1) => s_valid1,
		s_ready(0) => s_ready0,
		s_ready(1) => s_ready1,
		m_data  => m_data,
		m_valid => m_valid,
		m_ready => m_ready
	);

	axis_master_vc0 : entity vunit_lib.axi_stream_master
	generic map (
		master => axis_master0)
	port map (
		aclk   => clk,
		tvalid => s_valid0,
		tready => s_ready0,
		tdata  => s_data0,
		tlast  => open
	);

	axis_master_vc1 : entity vunit_lib.axi_stream_master
	generic map (
		master => axis_master1)
	port map (
		aclk   => clk,
		tvalid => s_valid1,
		tready => s_ready1,
		tdata  => s_data1,
		tlast  => open
	);

  axis_slave_vc : entity vunit_lib.axi_stream_slave
    generic map (
		slave => axis_slave)
    port map (
		aclk   => clk,
		tvalid => m_valid,
		tready => m_ready,
		tdata  => m_data,
		tlast  => '0'
	);

	clk <= not clk after CLK_PERIOD / 2;

end architecture;

