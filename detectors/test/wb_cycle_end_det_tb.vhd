-- 2018 Slawomir Siluk slaweksiluk@gazeta.pl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vhdlbaselib;

library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;

entity wb_cycle_end_det_tb is
generic (
	runner_cfg : string;
	encoded_tb_cfg : string
);
end entity;

architecture bench of wb_cycle_end_det_tb is

	type tb_cfg_t is record
		max_pending : positive;
		req_prob : real range 0.0 to 1.0;
		ack_prob : real range 0.0 to 1.0;
	end record tb_cfg_t;

	impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
	begin
	return (
	    max_pending => positive'value(get(encoded_tb_cfg, "max_pending")),
	    req_prob => real'value(get(encoded_tb_cfg, "req_prob")),
	    ack_prob => real'value(get(encoded_tb_cfg, "ack_prob"))
	);
	end function decode;

	constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

	constant CLK_PERIOD	: time := 10 ns;
	constant MAX_PENDING : natural := 4;
	signal clk : std_logic := '0';
	signal rst : std_logic;
	signal wb_request : boolean := false;
	signal wb_acknowledge : boolean := false;
	signal cycle_finished : boolean := false;
	signal requests_pending : natural;
	signal max_requests_pending : boolean := false;
	constant tb_logger : logger_t := get_logger("tb");
	signal wb_req : std_logic;
	signal wb_ack : std_logic;
	signal wb_cycle	: boolean := false;
	constant max_trans	: natural := 64;
begin

	stimulus : process
	    variable rnd1 : RandomPType;
	    variable rnd2 : RandomPType;
		variable req_cnt : natural range 0 to max_trans;
		variable ack_cnt : natural range 0 to max_trans;
	begin
		test_runner_setup(runner, runner_cfg);
		set_format(display_handler, verbose, true);
		show(tb_logger, display_handler, verbose);
		if run("smoke-test") then
			wait until rising_edge(clk);
		elsif run("default") then
			wait until rising_edge(clk);
			check_false(cycle_finished);
			check_equal(requests_pending, 0);
			check_false(max_requests_pending);
		elsif run("one-req") then
			wait until rising_edge(clk);
			wb_request <= true;
			wait until rising_edge(clk) and wb_request;
			wait until rising_edge(clk);
			check_false(cycle_finished);
			check_equal(requests_pending, 1);
			check_false(max_requests_pending);
		elsif run("one-req-ack") then
			wait until rising_edge(clk);
			wb_request <= true;
			wait until rising_edge(clk) and wb_request;
			wb_request <= false;
			wb_acknowledge <= true;
			wait until rising_edge(clk) and wb_acknowledge;
			wb_acknowledge <= false;
			check_true(cycle_finished);
			wait until rising_edge(clk);
			check_equal(requests_pending, 0);
			check_false(max_requests_pending);

		elsif run("double one-req-ack") then
			wait until rising_edge(clk);
			wb_request <= true;
			wait until rising_edge(clk) and wb_request;
			wb_request <= false;
			wb_acknowledge <= true;
			wait until rising_edge(clk) and wb_acknowledge;
			wb_acknowledge <= false;
			check_true(cycle_finished);
			wait until rising_edge(clk);
			check_equal(requests_pending, 0);
			check_false(max_requests_pending);

			wait until rising_edge(clk);
			wb_request <= true;
			wait until rising_edge(clk) and wb_request;
			wb_request <= false;
			wb_acknowledge <= true;
			wait until rising_edge(clk) and wb_acknowledge;
			wb_acknowledge <= false;
			check_true(cycle_finished);
			wait until rising_edge(clk);
			check_equal(requests_pending, 0);
			check_false(max_requests_pending);

		elsif run("req-until-counter-full") then
			wait until rising_edge(clk);
			wb_request <= true;
			for i in 1 to MAX_PENDING loop
				wait until rising_edge(clk) and wb_request;
				if i = MAX_PENDING then
					check_true(max_requests_pending, "max not asserted");
				end if;
			end loop;
			wb_request <= false;
			wait until rising_edge(clk);
			check_true(max_requests_pending, "max not asserted");
			wait until rising_edge(clk);
			check_true(max_requests_pending, "max not tied high");

		elsif run("cnt-ovf-expected-to-fail") then
			wait until rising_edge(clk);
			wb_request <= true;
			for i in 1 to MAX_PENDING +1 loop
				wait until rising_edge(clk) and wb_request;
			end loop;

		elsif run("ack-until-counter-zero") then
			wait until rising_edge(clk);
			wb_request <= true;
			for i in 1 to MAX_PENDING loop
				wait until rising_edge(clk) and wb_request;
			end loop;
			wb_request <= false;
			wait until rising_edge(clk);
			wb_acknowledge <= true;
			for i in 1 to MAX_PENDING loop
				wait until rising_edge(clk) and wb_acknowledge;
				if i = MAX_PENDING then 
					check_true(cycle_finished, "cycle not finished");
				end if;
			end loop;
			wb_acknowledge <= false;
			check_false(max_requests_pending, "max not deasserted");
			wait until rising_edge(clk);
			check_equal(requests_pending, 0, "counter not cleared");
			check_false(max_requests_pending, "max not tied low");

		elsif run("random") then
		    rnd1.InitSeed(rnd1'instance_name);
		    rnd2.InitSeed(rnd2'instance_name);
			wait until rising_edge(clk);
			loop
				wait until rising_edge(clk);
				if wb_request then
					req_cnt := req_cnt +1;
				end if;
				if wb_acknowledge then
					ack_cnt := ack_cnt +1;
				end if;
				wb_acknowledge <= false;
				wb_request <= false;
				exit when cycle_finished;

				if rnd1.Uniform(0.0, 1.0) < tb_cfg.req_prob and not max_requests_pending and req_cnt < max_trans then
					wb_request <= true;
					wb_cycle <= true;
				end if;
				if rnd2.Uniform(0.0, 1.0) < tb_cfg.ack_prob and wb_cycle and ack_cnt < max_trans then
					wb_acknowledge <= true;
				end if;

				-- Check
				debug(tb_logger, "req_cnt"&natural'image(req_cnt));
				debug(tb_logger, "ack_cnt"&natural'image(ack_cnt));
			end loop;
			check_equal(req_cnt, ack_cnt, "req != ack");
			wait until rising_edge(clk);
		end if;
	    test_runner_cleanup(runner);
	wait;
	end process;
	test_runner_watchdog(runner, 3 ms);

	wb_req <= '1' when wb_request else '0';
	wb_ack <= '1' when wb_acknowledge else '0';

	dut : entity vhdlbaselib.wb_cycle_end_det
	generic map	(
		MAX_PENDING => MAX_PENDING
	) port map (
		clk                  => clk,
		rst                  => rst,
		wb_request           => wb_request,
		wb_acknowledge       => wb_acknowledge,
		cycle_finished       => cycle_finished,
		requests_pending     => requests_pending,
		max_requests_pending => max_requests_pending
	);

	clk <= not clk after CLK_PERIOD / 2;

end architecture;
