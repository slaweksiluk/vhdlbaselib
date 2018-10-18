-- Slawomir Siluk slaweksiluk@gazeta.pl
-- Descriptor structure:
-- [ DESC_LEN_H .. DESC_LEN_L | DESC_ADDR_H .. DESC_ADDR_L ]
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
use vunit_lib.memory_pkg.all;
use vunit_lib.wishbone_pkg.all;

library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;
entity wb_master_axis_master_bridge_tb is
generic (
	runner_cfg : string;
	encoded_tb_cfg : string
);
end entity;

architecture bench of wb_master_axis_master_bridge_tb is

	type tb_cfg_t is record
		data_width : positive range 8 to 128;
		addr_width : positive range 32 to 64;
		num_desc : positive;
		max_trans : positive;
		ack_prob : real range 0.0 to 1.0;
		stall_prob : real range 0.0 to 1.0;
		buf_rd_prob : real range 0.0 to 1.0;
	end record tb_cfg_t;

	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
	    data_width => positive'value(get(encoded_tb_cfg, "data_width")),
	    addr_width => positive'value(get(encoded_tb_cfg, "addr_width")),
	    num_desc => positive'value(get(encoded_tb_cfg, "num_desc")),
		max_trans => positive'value(get(encoded_tb_cfg, "max_trans")),
	    ack_prob => real'value(get(encoded_tb_cfg, "ack_prob")),
	    stall_prob => real'value(get(encoded_tb_cfg, "stall_prob")),
	    buf_rd_prob => real'value(get(encoded_tb_cfg, "buf_rd_prob"))
	);
	end function decode;

	constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

	constant DESC_LEN_WIDTH : positive := tb_cfg.addr_width/2;
	constant DESC_ADDR_WIDTH : positive := tb_cfg.addr_width;
	constant DESC_WIDTH : positive := DESC_ADDR_WIDTH + DESC_LEN_WIDTH;
	constant DESC_ADDR_H : natural := tb_cfg.addr_width-1;
	constant DESC_ADDR_L : natural := 0;
	constant DESC_LEN_H : natural := tb_cfg.addr_width+DESC_LEN_WIDTH -1;
	constant DESC_LEN_L : natural := tb_cfg.addr_width;
	constant BYTES_PER_TRANSACTION : positive := tb_cfg.data_width/8;
	signal clk : std_logic := '0';
	signal rst : std_logic;
	signal wb_adr : std_logic_vector(tb_cfg.addr_width-1 downto 0);
	signal wb_dat_i : std_logic_vector(tb_cfg.data_width-1 downto 0) := (others => '1');
	signal wb_dat_o : std_logic_vector(tb_cfg.data_width-1 downto 0);
	signal wb_sel : std_logic_vector(tb_cfg.data_width/8-1 downto 0);
	signal wb_cyc : std_logic;
	signal wb_stb : std_logic;
	signal wb_we : std_logic;
	signal wb_ack : std_logic := '0';
	signal wb_stall : std_logic := '0';
	signal m_axis_data : std_logic_vector(tb_cfg.data_width-1 downto 0);
	signal m_axis_valid : std_logic;
	signal m_axis_ready : std_logic;
	signal axis_desc_data : std_logic_vector(DESC_WIDTH -1 downto 0);
	signal axis_desc_addr : std_logic_vector(DESC_ADDR_H downto DESC_ADDR_L);
	signal axis_desc_length : std_logic_vector(DESC_LEN_H downto DESC_LEN_L);
	signal axis_desc_valid : std_logic;
	signal axis_desc_ready : std_logic;
	constant EXT_BUF_DEPTH : positive := 16;
	signal buf_room : natural range 0 to EXT_BUF_DEPTH := EXT_BUF_DEPTH;

	signal pending_acks_dbg : natural;
	shared variable ACov : CovPType ;  -- Declare
	signal wb_request : boolean;
	signal done : boolean;
	constant max_cycles : natural := 64;
	signal state_cyc_end : boolean;

	-- Local tb constants
	constant MEM_BYTES : positive := tb_cfg.num_desc * tb_cfg.max_trans * BYTES_PER_TRANSACTION;

	-- Vunit bfm's
	constant desc_axis : axi_stream_master_t :=
		new_axi_stream_master(data_length => DESC_WIDTH);
	constant desc_stream : stream_master_t := as_stream(desc_axis);
	constant data_axis : axi_stream_slave_t :=
		new_axi_stream_slave(data_length => tb_cfg.data_width);
	constant data_stream : stream_slave_t := as_stream(data_axis);
	constant memory : memory_t := new_memory;
	constant buf : buffer_t := allocate(memory, MEM_BYTES);
	constant wishbone_slave : wishbone_slave_t :=
	  new_wishbone_slave(memory => memory,
		ack_high_probability => tb_cfg.ack_prob,
		stall_high_probability => tb_cfg.stall_prob
	  );

	constant tb_logger : logger_t := get_logger("tb");

	constant CLK_PERIOD : time := 10 ns;

	impure function set_desc(
		byte_len : positive;
		byte_addr : natural)
		return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(byte_len, DESC_LEN_WIDTH)) &
			std_logic_vector(to_unsigned(byte_addr, DESC_ADDR_WIDTH));
	end function set_desc;

begin

	dut : entity vhdlbaselib.wb_master_axis_master_bridge
	port map (
		clk             => clk,
		rst             => rst,
		wb_adr          => wb_adr,
		wb_dat_i        => wb_dat_i,
		wb_dat_o        => wb_dat_o,
		wb_sel          => wb_sel,
		wb_cyc          => wb_cyc,
		wb_stb          => wb_stb,
		wb_we           => wb_we,
		wb_ack          => wb_ack,
		wb_stall        => wb_stall,
		m_axis_data     => m_axis_data,
		m_axis_valid    => m_axis_valid,
		m_axis_ready    => m_axis_ready,
		buf_room        => buf_room,
		axis_desc_addr  => axis_desc_data(axis_desc_addr'range),
		axis_desc_length=> axis_desc_data(axis_desc_length'range),
		axis_desc_valid => axis_desc_valid,
		axis_desc_ready => axis_desc_ready,
		pending_acks_dbg => pending_acks_dbg
	);

	stimulus : process
		variable desc_len : positive;
		variable desc_addr: natural;
		variable desc_data : std_logic_vector(axis_desc_data'range);
		variable test_data : std_logic_vector(m_axis_data'range) :=
			std_logic_vector(to_unsigned(16#ef#, tb_cfg.data_width));
		variable test_data2 : std_logic_vector(m_axis_data'range) :=
			std_logic_vector(to_unsigned(16#45#, tb_cfg.data_width));
		variable temp_data : std_logic_vector(m_axis_data'range);
		variable got_data : std_logic_vector(m_axis_data'range);
		variable exp_data : std_logic_vector(m_axis_data'range);
	    variable rnd : RandomPType;
		variable transactions : natural;
		variable total_transactions : natural;
		variable cycle : natural := 0;
	begin
		test_runner_setup(runner, runner_cfg);
		set_format(display_handler, verbose, true);
		show(tb_logger, display_handler, verbose);
		if run("smoke-test") then
			wait until rising_edge(clk);

		elsif run("single-length-one") then
			wait until rising_edge(clk);
			-- Set wishbone memory
			write_word(memory, 0, test_data);
			-- Set descriptor
			desc_data := set_desc(BYTES_PER_TRANSACTION*1, 0);
			info(tb_logger, "desc push");
			push_stream(net, desc_stream, desc_data);
			-- Expect data on the axis data interface
			pop_stream(net, data_stream, temp_data);
			check_equal(test_data, temp_data, "data");
			wait until rising_edge(clk);

		elsif run("single-length-two") then
			wait until rising_edge(clk);
			-- Set wishbone memory
			write_word(memory, 0, test_data);
			write_word(memory, 1, test_data2);
			-- Set descriptor
			desc_data := set_desc(BYTES_PER_TRANSACTION*2, 0);
			push_stream(net, desc_stream, desc_data);
			-- Expect data on the axis data interface
			pop_stream(net, data_stream, temp_data);
			check_equal(temp_data, test_data, "data1");
			pop_stream(net, data_stream, temp_data);
			check_equal(temp_data, test_data2, "data2");
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk);

		elsif run("variable-desc-length") then
			while not ACov.isCovered and cycle < max_cycles loop

			wait until rising_edge(clk);
			for i in 0 to tb_cfg.num_desc * tb_cfg.max_trans -1 loop
				write_word(memory, i*BYTES_PER_TRANSACTION,
					std_logic_vector(to_unsigned(i, tb_cfg.data_width)));
			end loop;

			-- Set descriptor
			transactions := 0;
			total_transactions := 0;
			for i in 1 to tb_cfg.num_desc loop
				transactions := rnd.RandInt(1, tb_cfg.max_trans);
				desc_data := set_desc(transactions*BYTES_PER_TRANSACTION, total_transactions*BYTES_PER_TRANSACTION);
				-- Update for next loop
				total_transactions := total_transactions + transactions;
				push_stream(net, desc_stream, desc_data);
			end loop;
			info(tb_logger, "total_transactions = "&to_string(total_transactions));

			-- Expect data on the axis data interface
			for i in 0 to total_transactions -1 loop
				pop_stream(net, data_stream, got_data);
				exp_data := std_logic_vector(to_unsigned(i, exp_data'length));
				check_equal(got_data, exp_data, "data");
			end loop;
			wait until rising_edge(clk);

			cycle := cycle +1;
			info(tb_logger, "cycle = "&to_string(cycle));
			wait until rising_edge(clk) and wb_cyc = '0';
			end loop;

		done <= true;
		wait until rising_edge(clk);
		info(tb_logger, "print covarage report");
		ACov.WriteBin ; -- Report
		check_true(ACov.isCovered, "not covered", warning);
		end if;
	    test_runner_cleanup(runner);
	wait;
	end process;
	test_runner_watchdog(runner, 3000 us);

	coverage: process begin
		ACov.AddCross(
			"req/ack/pending/desc",
			GenBin(1),           -- wb req
			GenBin(0,1),         -- wb ack
			GenBin(0,1),         -- pending_acks
			GenBin(0,1)
			);
		while not done loop
--			info(tb_logger, "block on wait ");
			wait until rising_edge(clk) and wb_cyc = '1';
			ACov.ICover(
				(
				to_integer(wb_request),
				to_integer(wb_ack),
				pending_acks_dbg,
				to_integer(axis_desc_valid)
				));
		end loop;
		wait;
	end process;

	wb_request <= true when wb_stb = '1' and wb_stall = '0' else false;

	axis_desc_vc : entity vunit_lib.axi_stream_master
	generic map (
		master => desc_axis)
	port map (
		aclk   => clk,
		tvalid => axis_desc_valid,
		tready => axis_desc_ready,
		tdata  => axis_desc_data,
		tlast  => open
	);

  axis_data_vc : entity vunit_lib.axi_stream_slave
    generic map (
      slave => data_axis)
    port map (
      aclk   => clk,
      tvalid => m_axis_valid,
      tready => m_axis_ready,
      tdata  => m_axis_data,
      tlast  => '0');

	wishbone_vc : entity vunit_lib.wishbone_slave
	generic map (
		wishbone_slave => wishbone_slave
	)
	port map (
		clk   => clk,
		adr   => wb_adr,
		dat_i => wb_dat_o,
		dat_o => wb_dat_i,
		sel   => wb_sel,
		cyc   => wb_cyc,
		stb   => wb_stb,
		we    => wb_we,
		stall => wb_stall,
		ack   => wb_ack
	);

	buf_model: process
		variable room : natural;
	    variable rnd : RandomPType;
	begin
		wait until rising_edge(clk);
		room := buf_room;
		if (m_axis_valid and m_axis_ready) = '1' then
			room := room -1;
		end if;
		if rnd.Uniform(0.0, 1.0) < tb_cfg.buf_rd_prob and room < EXT_BUF_DEPTH then
			room := room +1;
		end if;
		buf_room <= room;
	end process;

	clk <= not clk after CLK_PERIOD / 2;

end architecture;

