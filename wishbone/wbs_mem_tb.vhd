library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

library xil_defaultlib;
use xil_defaultlib.wb_test_env_pkg.all;


entity wbs_mem_tb is
end entity;

architecture bench of wbs_mem_tb is


	constant DAT_WIDTH	: natural := 4;
	constant ADR_WIDTH	: natural := 8;
	constant MEM_LEN 	: natural := 2**ADR_WIDTH;
		
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal wbs_cyc : std_logic;
	signal wbs_stb : std_logic;
	signal wbs_adr : std_logic_vector(ADR_WIDTH-1 downto 0);
	signal wbs_we : std_logic;
	signal wbs_dat_i : std_logic_vector(DAT_WIDTH-1 downto 0);
	signal wbs_dat_o : std_logic_vector(DAT_WIDTH-1 downto 0);
	signal wbs_ack : std_logic;

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
		
begin



stimulus : process 	begin
wait for LDL;
rst		<= '0';
wait for LDL;
	for a in 0 to 7 loop
		wait until rising_edge(clk);
			SINGLE_PIPE_WR(a, a, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;

	wait for LDL;
	for a in 0 to 7 loop	
		wait until rising_edge(clk);
			SINGLE_PIPE_RD(a, a, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;

wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;


single_wbs_gen: if true generate
	-- WTE master stim signals
	signal wte_wbm_cyc		: std_logic := '0';
	signal wte_wbm_stb		: std_logic := '0';
	signal wte_wbm_we		: std_logic := '0';
	signal wte_wbm_adr		: std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_dat_i	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_dat_o	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_ack		: std_logic := '0';
	signal wte_wbm_err		: std_logic := '0';
begin

wbm_stim_inst: WBM_STIM(clk, rst, wte_wbm_cyc, wte_wbm_stb, wte_wbm_we, wte_wbm_adr, 
				wte_wbm_dat_i, wte_wbm_dat_o, wte_wbm_ack, wte_wbm_err, WTE_DONE);

						
	wbs_cyc		<= wte_wbm_cyc;						
	wbs_stb		<= wte_wbm_stb;						
	wbs_we		<= wte_wbm_we;						
	wbs_adr		<= wte_wbm_adr;						
	wbs_dat_i	<= wte_wbm_dat_o;
	-- from slave to master
	wte_wbm_dat_i	<= wbs_dat_o;
	wte_wbm_ack		<= wbs_ack;
--	wte_wbm_err		<= wbs_err;
end generate;


	uut : entity xil_defaultlib.wbs_mem
		generic map
		(
			MEM_LEN => MEM_LEN
		)
		port map
		(
			clk       => clk,
			rst       => rst,
			wbs_cyc   => wbs_cyc,
			wbs_stb   => wbs_stb,
			wbs_adr   => wbs_adr,
			wbs_we    => wbs_we,
			wbs_dat_i => wbs_dat_i,
			wbs_dat_o => wbs_dat_o,
			wbs_ack   => wbs_ack
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

