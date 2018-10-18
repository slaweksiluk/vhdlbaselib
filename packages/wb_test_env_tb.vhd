--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wb_test_env_tb.vhd
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
library xil_defaultlib;
use xil_defaultlib.wb_test_env_pkg.all;
	

entity wb_test_env_tb is
end wb_test_env_tb;
architecture wb_test_env_tb_arch of wb_test_env_tb is

signal rst		: std_logic := '1';
signal clk		: std_logic := '0';

shared variable stop_clock	: boolean := false;
constant CLK_PERIOD	: time := 10 ns;
constant LDL	: time := CLK_PERIOD * 10;
constant ADL	: time := CLK_PERIOD / 5;


constant WB_SLAVES	: natural := 3;
constant ADR_WIDTH	: natural := 8;
constant DAT_WIDTH	: natural := 4;

constant MAGIC_NUM	: natural := 4235;



begin


stim: process 
	variable ex_data : std_logic_vector(DAT_WIDTH-1 downto 0) := x"7";
begin

wait for LDL;
wait until rising_edge(clk);
	rst		<= '0';
	
-- initialize wbs
--	SET_WBS_STORE(ex_data);
	

if WB_SLAVES = 1 then	
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
end if;


	for a in 0 to WB_SLAVES-1 loop
		wait until rising_edge(clk);
			SINGLE_PIPE_WR(a, a+MAGIC_NUM, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;

	wait for LDL;
	for a in 0 to WB_SLAVES-1 loop	
		wait until rising_edge(clk);
			SINGLE_PIPE_RD(a, a+MAGIC_NUM, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;
	
	
	wait for LDL;
	assert false
	 report " <<<SUCCESS>>> "
	 severity failure;
	wait;

end process;


						


single_wbs_gen: if WB_SLAVES = 1 generate
	-- WTE master stim signals
	signal wte_wbm_cyc		: std_logic := '0';
	signal wte_wbm_stb		: std_logic := '0';
	signal wte_wbm_we		: std_logic := '0';
	signal wte_wbm_adr		: std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_dat_i	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_dat_o	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_ack		: std_logic := '0';
	signal wte_wbm_err		: std_logic := '0';
	-- WTE slave stim signals
	signal wte_wbs_cyc		: std_logic := '0';
	signal wte_wbs_stb		: std_logic := '0';
	signal wte_wbs_we		: std_logic := '0';
	signal wte_wbs_adr		: std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbs_dat_i	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbs_dat_o	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbs_ack		: std_logic := '0';
	signal wte_wbs_err		: std_logic := '0';
begin

wbm_stim_inst: WBM_STIM(clk, rst, wte_wbm_cyc, wte_wbm_stb, wte_wbm_we, wte_wbm_adr, 
				wte_wbm_dat_i, wte_wbm_dat_o, wte_wbm_ack, wte_wbm_err, WTE_DONE);

wbs_stim_inst: WBS_STIM(clk, rst, wte_wbs_cyc, wte_wbs_stb, wte_wbs_we, wte_wbs_adr,
						wte_wbs_dat_i, wte_wbs_dat_o, wte_wbs_ack, wte_wbs_err);
						
	wte_wbs_cyc		<= wte_wbm_cyc;						
	wte_wbs_stb		<= wte_wbm_stb;						
	wte_wbs_we		<= wte_wbm_we;						
	wte_wbs_adr		<= wte_wbm_adr;						
	wte_wbs_dat_i	<= wte_wbm_dat_o;
	-- from slave to master
	wte_wbm_dat_i	<= wte_wbs_dat_o;
	wte_wbm_ack		<= wte_wbs_ack;
	wte_wbm_err		<= wte_wbs_err;
end generate;


multi_wbs_gen: if WB_SLAVES > 1 generate
	-- types for easy multplexing
	type dat_arr_t is array (0 to WB_SLAVES-1) of std_logic_vector(DAT_WIDTH-1 downto 0);

	-- WTE master stim signals
	signal wte_wbm_cyc		: std_logic := '0';
	signal wte_wbm_stb		: std_logic := '0';
	signal wte_wbm_we		: std_logic := '0';
	signal wte_wbm_adr		: std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_dat_i	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_dat_o	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbm_ack		: std_logic := '0';
	signal wte_wbm_err		: std_logic := '0';
	-- WTE slave stim signals
	signal wte_wbs_cyc		: std_logic := '0';
	signal wte_wbs_stb		: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	signal wte_wbs_we		: std_logic := '0';
	signal wte_wbs_adr		: std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbs_dat_i	: std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
	signal wte_wbs_dat_o	: dat_arr_t  := (others => (others => '0'));
	signal wte_wbs_ack		: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	signal wte_wbs_err		: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	
	-- multi sigs
	signal wte_wbm_stb_multi	: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	signal wte_wbm_dat_i_multi	: dat_arr_t  := (others => (others => '0'));
	signal wte_wbm_ack_multi		: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	signal wte_wbm_err_multi		: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	shared variable wbs_id			: natural := 0; -- fix it in VHDL assistant sources, becasue it valid vhdl
begin
-- single wbm inst
wbm_stim_inst: WBM_STIM(clk, rst, wte_wbm_cyc, wte_wbm_stb, wte_wbm_we, wte_wbm_adr, 
				wte_wbm_dat_i, wte_wbm_dat_o, wte_wbm_ack, wte_wbm_err, WTE_DONE);

	-- no muliplexed signals
	wte_wbs_cyc		<= wte_wbm_cyc;		
	wte_wbs_we		<= wte_wbm_we;						
	wte_wbs_adr		<= wte_wbm_adr;						
	wte_wbs_dat_i	<= wte_wbm_dat_o;	
	wbs_for_gen: for s in 0 to WB_SLAVES-1 generate
-- multi wbs stim
wbs_stim_inst: WBS_STIM(clk, rst, wte_wbs_cyc, wte_wbs_stb(s), wte_wbs_we, wte_wbs_adr,
					wte_wbs_dat_i, wte_wbs_dat_o(s), wte_wbs_ack(s), wte_wbs_err(s));
	-- myltiplexed signals
		-- from master to slave
		wte_wbs_stb(s)	<= wte_wbm_stb_multi(s);						
		-- from slave to master
		wte_wbm_dat_i_multi(s)		<= wte_wbs_dat_o(s);
		wte_wbm_ack_multi(s)		<= wte_wbs_ack(s);
		wte_wbm_err_multi(s)		<= wte_wbs_err(s);
	end generate;
	
-- Logic for choosing which slave is now connected. Currenlty ADR = slave id
-- Sim cycles comment -> it was not wokirng when wbs_id assigment was in process
-- and the rest outside the process. Why?
	wbs_id_proc: process(wte_wbm_adr, wte_wbm_stb, wte_wbm_dat_i_multi, wte_wbm_ack_multi, wte_wbm_err_multi) begin
		wbs_id	:= to_integer(unsigned(wte_wbm_adr));
		wte_wbm_stb_multi(wbs_id)	<= wte_wbm_stb;
		wte_wbm_dat_i		<= wte_wbm_dat_i_multi(wbs_id);
		wte_wbm_ack			<= wte_wbm_ack_multi(wbs_id);
		wte_wbm_err			<= wte_wbm_err_multi(wbs_id);			
	end process;
end generate;



	
generate_clk : process
begin
	while not stop_clock loop
		clk <= '0', '1' after CLK_PERIOD / 2;
		wait for CLK_PERIOD;
	end loop;
	wait;
end process;
end wb_test_env_tb_arch;
