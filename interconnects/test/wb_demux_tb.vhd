library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.memory_pkg.all;
use vunit_lib.wishbone_pkg.all;
use vunit_lib.bus_master_pkg.all;

library vhdlbaselib;
use vhdlbaselib.wishbone_pkg.all;
use vhdlbaselib.wishbone_array_pkg.t_arr_wishbone_master_in;
use vhdlbaselib.wishbone_array_pkg.t_arr_wishbone_master_out;

entity wb_demux_tb is
generic (
	runner_cfg : string;
	encoded_tb_cfg : string
);
end entity;

architecture bench of wb_demux_tb is

	type tb_cfg_t is record
		num_slaves : positive;
		data_width : positive;
		addr_width : positive;
		num_trans : positive;
		ack_prob : real;
		stall_prob : real;
	end record tb_cfg_t;

	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
			num_slaves => positive'value(get(encoded_tb_cfg, "num_slaves")),
			data_width => positive'value(get(encoded_tb_cfg, "data_width")),
			addr_width => positive'value(get(encoded_tb_cfg, "addr_width")),
			num_trans => positive'value(get(encoded_tb_cfg, "num_trans")),
			ack_prob => real'value(get(encoded_tb_cfg, "ack_prob")),
			stall_prob => real'value(get(encoded_tb_cfg, "stall_prob")));
	end function decode;

	constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

	signal clk : std_logic := '0';
	signal rst : std_logic;
	signal sel : natural range 0 to tb_cfg.num_slaves-1;
	signal wbs_i : t_wishbone_slave_in(
		adr(tb_cfg.addr_width-1 downto 0),
		dat(tb_cfg.data_width-1 downto 0),
		sel(tb_cfg.data_width/8-1 downto 0)
	);
	signal wbs_o : t_wishbone_slave_out(
		dat(tb_cfg.data_width-1 downto 0)
	);
	signal wbm_i : t_arr_wishbone_master_in(0 to tb_cfg.num_slaves-1);
	signal wbm_o : t_arr_wishbone_master_out(0 to tb_cfg.num_slaves-1);

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;

	constant master_logger : logger_t := get_logger("master");
	constant tb_logger : logger_t := get_logger("tb");
	constant bus_handle : bus_master_t := new_bus(data_length => tb_cfg.data_width,
		address_length => tb_cfg.addr_width, logger => master_logger);

	constant memory : memory_t := new_memory;
	constant buf : buffer_t := allocate(memory, tb_cfg.num_trans * tb_cfg.data_width/8);

	type slaves_arr_t is array (0 to tb_cfg.num_slaves-1) of wishbone_slave_t;

	impure function slaves_arr_init(
		memory : memory_t;
		tb_cfg : tb_cfg_t
	) return slaves_arr_t is
		variable arr : slaves_arr_t;
	begin
		for i in 0 to tb_cfg.num_slaves -1 loop
			arr(i) := new_wishbone_slave(
				memory => memory,
		        ack_high_probability => tb_cfg.ack_prob,
        		stall_high_probability => tb_cfg.stall_prob
			);
		end loop;
		return arr;
	end function;

	constant slaves_arr : slaves_arr_t := slaves_arr_init(memory, tb_cfg);
begin

	stimulus : process
		variable golden : std_logic_vector(wbs_i.dat'range) := (others => '1');
		variable result : std_logic_vector(wbs_i.dat'range);
	begin
		test_runner_setup(runner, runner_cfg);
		set_format(display_handler, verbose, true);
		show(tb_logger, display_handler, verbose);
		if run("sel0-adr0") then
			for j in 0 to tb_cfg.num_slaves-1 loop
				info(tb_logger, "select slave "&natural'image(j));
				sel <= j;
				wait until rising_edge(clk);
				for i in 0 to tb_cfg.num_trans -1 loop
					golden := std_logic_vector(to_unsigned(i*j, golden'length));
					write_bus(net, bus_handle, i*tb_cfg.data_width/8, golden);
				end loop;
				wait until falling_edge(wbs_i.cyc);
				wait until rising_edge(clk);
				wait until rising_edge(clk);
				wait until rising_edge(clk);
				for i in 0 to tb_cfg.num_trans -1 loop
					golden := std_logic_vector(to_unsigned(i*j, golden'length));
					result := read_word(memory, i*tb_cfg.data_width/8, tb_cfg.data_width/8);
					check_equal(result, golden, "data("&natural'image(i)&")");
				end loop;
				wait until rising_edge(clk);
			end loop;
		end if;
	    test_runner_cleanup(runner);
	wait;
	end process;
	test_runner_watchdog(runner, 100 us);

	dut : entity vhdlbaselib.wb_demux
	generic map (
		MASTERS_NUM => tb_cfg.num_slaves
	) port map (
		clk   => clk,
		rst   => rst,
		sel   => sel,
		wbs_i => wbs_i,
		wbs_o => wbs_o,
		wbm_i => wbm_i,
		wbm_o => wbm_o
	);

	wbm_vc : entity vunit_lib.wishbone_master
	generic map (
		bus_handle => bus_handle)
	port map (
		clk   => clk,
		adr   => wbs_i.adr,
		dat_i => wbs_o.dat,
		dat_o => wbs_i.dat,
		sel   => wbs_i.sel,
		cyc   => wbs_i.cyc,
		stb   => wbs_i.stb,
		we    => wbs_i.we,
		stall => wbs_o.stall,
		ack   => wbs_o.ack
	);

	wbs_vc_gen: for i in 0 to tb_cfg.num_slaves -1 generate
		signal adr : std_logic_vector(tb_cfg.addr_width-1 downto 0);
		signal dat_i : std_logic_vector(tb_cfg.data_width-1 downto 0);
		signal dat_o : std_logic_vector(tb_cfg.data_width-1 downto 0);
		signal sel : std_logic_vector(tb_cfg.data_width/8-1 downto 0);
		signal cyc : std_logic;
		signal stb : std_logic;
		signal we : std_logic;
		signal stall : std_logic;
		signal ack : std_logic;
	begin
		wbs_vc : entity vunit_lib.wishbone_slave
		generic map (
			wishbone_slave => slaves_arr(i)
		) port map (
			clk   => clk,
			adr   => adr,
			dat_i => dat_i,
			dat_o => dat_o,
			sel   => sel,
			cyc   => cyc,
			stb   => stb,
			we    => we,
			stall => stall,
			ack   => ack
		);
		wbm_i(i).dat <= dat_o;
		wbm_i(i).ack <= ack;
		wbm_i(i).stall <= stall;
		adr <= wbm_o(i).adr;
		dat_i <= wbm_o(i).dat;
		sel <= wbm_o(i).sel;
		cyc <= wbm_o(i).cyc;
		stb <= wbm_o(i).stb;
		we <= wbm_o(i).we;
	end generate;

	clk <= not clk after CLK_PERIOD / 2;

end architecture;
