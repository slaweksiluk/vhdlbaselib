--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Design Name:   
-- Module Name:   D:/GIT/HDL-LIB/wishbone/wb_switch_tb.vhd
-- Project Name:  wisbone_switch
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: wb_switch
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.math_real.all; 
USE ieee.numeric_std.ALL;


library xil_defaultlib;
use xil_defaultlib.wb_switch_pkg.all;
use xil_defaultlib.common_pkg.all;	
use xil_defaultlib.wb_test_env_pkg.all; 
 
ENTITY wb_switch_tb IS
END wb_switch_tb;
 
ARCHITECTURE behavior OF wb_switch_tb IS 

	 
	constant DAT_WIDTH			: natural := 4;
	constant ADR_WIDTH			: natural := 8;
	constant MASTERS			: natural := 3;
	
	constant OFFSETS_ARR		: offsets_arr_t := (
			0 => 0,
			1 => 4, 
			2 => 8,
			3 => 16,
			others => 0
		);
	
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal wbs_adr : std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
   signal wbs_dat_i : std_logic_vector(DAT_WIDTH-1 downto 0) := (others => '0');
   signal wbs_sel : std_logic := '0';
   signal wbs_cyc : std_logic := '0';
   signal wbs_stb : std_logic := '0';
   signal wbs_we : std_logic := '0';
   signal wbm_dat_i : std_logic_vector(DAT_WIDTH*MASTERS-1 downto 0) := (others => '0');
   signal wbm_ack : std_logic_vector(MASTERS-1 downto 0) := (others => '0');
   signal wbm_rty : std_logic_vector(MASTERS-1 downto 0) := (others => '0');
   signal wbm_err : std_logic_vector(MASTERS-1 downto 0) := (others => '0');
   signal wbm_stall : std_logic_vector(MASTERS-1 downto 0) := (others => '0');

 	--Outputs
   signal wbs_dat_o : std_logic_vector(DAT_WIDTH-1 downto 0);
   signal wbs_ack : std_logic;
   signal wbs_rty : std_logic;
   signal wbs_err : std_logic;
   signal wbs_stall : std_logic;
   signal wbm_adr : std_logic_vector(ADR_WIDTH-1 downto 0);
   signal wbm_dat_o : std_logic_vector(DAT_WIDTH-1 downto 0);
   signal wbm_sel : std_logic_vector(DAT_WIDTH/8-1 downto 0);
   signal wbm_cyc : std_logic;
   signal wbm_stb : std_logic_vector(MASTERS-1 downto 0);
   signal wbm_we : std_logic;
   
   constant MAGIC_NUM	: natural := 4235;

constant clk_period : time := 10 ns;
constant LDL	: time := CLK_PERIOD * 10;
constant ADL	: time := CLK_PERIOD / 5;
 

BEGIN
   -- Stimulus process
stim_proc: process begin		
wait for LDL;
wait until rising_edge(clk);
	rst		<= '0';
	

report " [stim] testing offset boudaries";
	for a in 1 to MASTERS loop
		wait until rising_edge(clk);
			SINGLE_PIPE_WR(OFFSETS_ARR(a)-1, a+MAGIC_NUM-1, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
--		wait until rising_edge(clk);			
--			SINGLE_PIPE_WR(OFFSETS_ARR(a), a+MAGIC_NUM, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;

	wait for LDL;
	for a in 1 to MASTERS loop	
		wait until rising_edge(clk);
			SINGLE_PIPE_RD(OFFSETS_ARR(a)-1, a+MAGIC_NUM-1, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
--		wait until rising_edge(clk);
--			SINGLE_PIPE_RD(OFFSETS_ARR(a), a+MAGIC_NUM, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;
	
	
wait for LDL;
WBS_ACK_DELAY := 1;
report " [stim] testing offset boudaries with wbs slave ack respone delay";
	for a in 1 to MASTERS loop
		wait until rising_edge(clk);
			SINGLE_PIPE_WR(OFFSETS_ARR(a)-1, a+MAGIC_NUM-1, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
--		wait until rising_edge(clk);			
--			SINGLE_PIPE_WR(OFFSETS_ARR(a), a+MAGIC_NUM, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;

	wait for LDL;
	for a in 1 to MASTERS loop	
		wait until rising_edge(clk);
			SINGLE_PIPE_RD(OFFSETS_ARR(a)-1, a+MAGIC_NUM-1, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
--		wait until rising_edge(clk);
--			SINGLE_PIPE_RD(OFFSETS_ARR(a), a+MAGIC_NUM, WTE_TRIG, ADR_WIDTH, DAT_WIDTH);
	end loop;

wait for LDL;
assert false
report " <<<SUCCESS>>> "
severity failure;
wait;
end process;




multi_wbs_gen: if MASTERS > 1 generate
	constant WB_SLAVES	: natural := MASTERS;

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
	signal wte_wbs_dat_o	: std_logic_vector(DAT_WIDTH*WB_SLAVES-1 downto 0) := (others => '0');
	signal wte_wbs_ack		: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	signal wte_wbs_err		: std_logic_vector(WB_SLAVES-1 downto 0) := (others => '0');
	
begin

-- single wbm inst
	wbm_stim_inst: WBM_STIM(clk, rst, wte_wbm_cyc, wte_wbm_stb, wte_wbm_we, wte_wbm_adr, 
					wte_wbm_dat_i, wte_wbm_dat_o, wte_wbm_ack, wte_wbm_err, WTE_DONE);
					
-- connection between wte wbm and uut(slave)
	-- wte -> uut
	wbs_cyc			<= wte_wbm_cyc;
	wbs_stb			<= wte_wbm_stb;
	wbs_we			<= wte_wbm_we;
	wbs_adr			<= wte_wbm_adr;
	wbs_dat_i		<= wte_wbm_dat_o;
	-- wte <- uut
	wte_wbm_dat_i	<= wbs_dat_o;
	wte_wbm_ack		<= wbs_ack;	
	wte_wbm_err		<= wbs_err;
	

-- commectrion between wte wbs and uut(master)
	-- no muliplexed signals uut(wbm) -> wte_wbs
	wte_wbs_cyc		<= wbm_cyc;		
	wte_wbs_we		<= wbm_we;						
	wte_wbs_adr		<= wbm_adr;						
	wte_wbs_dat_i	<= wbm_dat_o;	
	
	-- multi wbs stim		
	wbs_for_gen: for s in 0 to WB_SLAVES-1 generate
		wbs_stim_inst: WBS_STIM(clk, rst, wte_wbs_cyc, wte_wbs_stb(s), wte_wbs_we, wte_wbs_adr,
						wte_wbs_dat_i, wte_wbs_dat_o((slice_range(s, DAT_WIDTH)'range)), 
						wte_wbs_ack(s), wte_wbs_err(s), s, OFFSETS_ARR(s+1)-OFFSETS_ARR(s)-1);
		-- myltiplexed signals
			-- from uut(master) -> wte slave
			wte_wbs_stb(s)	<= wbm_stb(s);						
			-- from wte slave -> uut master
			wbm_dat_i(slice_range(s, DAT_WIDTH)'range)	<= wte_wbs_dat_o((slice_range(s, DAT_WIDTH)'range));
			wbm_ack(s)	<= wte_wbs_ack(s);
			wbm_err(s)	<= wte_wbs_err(s);
		end generate;
end generate;





-- Instantiate the Unit Under Test (UUT)
uut: entity xil_defaultlib.wb_switch 
	generic map(
	    DAT_WIDTH			=> DAT_WIDTH,
	    ADR_WIDTH			=> ADR_WIDTH,
	    MASTERS 			=> MASTERS,
	    OFFSETS_ARR			=> OFFSETS_ARR,
	    SUB_ADR_OFFSET		=> true
	)
	PORT MAP (
		clk => clk,
		wbs_adr => wbs_adr,
		wbs_dat_i => wbs_dat_i,
		wbs_dat_o => wbs_dat_o,
		wbs_cyc => wbs_cyc,
		wbs_stb => wbs_stb,
		wbs_we => wbs_we,
		wbs_ack => wbs_ack,
		wbs_rty => wbs_rty,
		wbs_err => wbs_err,
		wbm_adr => wbm_adr,
		wbm_dat_i => wbm_dat_i,
		wbm_dat_o => wbm_dat_o,
		wbm_cyc => wbm_cyc,
		wbm_stb => wbm_stb,
		wbm_we => wbm_we,
		wbm_ack => wbm_ack,
		wbm_rty => wbm_rty,
		wbm_err => wbm_err
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

END;
