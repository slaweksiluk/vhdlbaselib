--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbm_to_axism_tb.vhd
-- Language: VHDL
-- Description: 
-- Test bench for wbm_to_axism module. It contains two stimulues processes:
-- * Wishbone stimulus intaraface
-- wishbone slave interace and is connected to module wb master side.
-- * AXIS stimulues interface
-- axis slave conncted to axis master and is receving 
-- and veryfing data
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library xil_defaultlib;
--use xil_defaultlib.common_pkg.all;
library xil_defaultlib;
use xil_defaultlib.axis_test_env_pkg.all;


entity wbm_to_axism_tb is
end entity;

architecture bench of wbm_to_axism_tb is

--component wbm_to_axism is
----	generic
----	(
----		ADL : time := 0 ps;
----		WB_WIDTH : natural := 8;
----		ADDR_WIDTH : natural := 32;
----		AXIS_WIDTH : natural := 8;
----		WB_BLOCK_READ_LENGTH : natural := 32
----	);
--	port
--	(
--		clk : in std_logic;
--		rst : in std_logic;
--		wb_adr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
--		wb_dat_i : in std_logic_vector(WB_WIDTH-1 downto 0);
--		wb_dat_o : out std_logic_vector(31 downto 0);
--		wb_sel : out std_logic_vector(3 downto 0);
--		wb_cyc : out std_logic;
--		wb_stb : out std_logic;
--		wb_we : out std_logic;
--		wb_ack : in std_logic;
--		wb_stall : in std_logic;
--		axis_m_data : out std_logic_vector(AXIS_WIDTH-1 downto 0);
--		axis_m_valid : out std_logic;
--		axis_m_ready : in std_logic;
--		trig : in std_logic;
--		max_wb_addr : in std_logic_vector(31 downto 0);
--		prog_full : in std_logic
--	);
--end component;

	-- Simulation constants and types

--	constant DW_TO_READ			: natural := 73;
--	constant BYTES_TO_READ		: natural := DW_TO_READ*4;

	constant BYTES_TO_READ		: natural := 532;
	constant DW_TO_READ			: natural := BYTES_TO_READ / 4;

	
	constant WB_WIDTH 			: natural := 32;
	constant BYTE_ADDR_WIDTH 	: natural := 32;
	constant WB_ADDR_WIDTH 		: natural := BYTE_ADDR_WIDTH-2;
	constant AXIS_WIDTH 		: natural := WB_WIDTH;
	constant WB_BLOCK_READ_LENGTH : natural := 32;
	constant WB_CYCLES			: natural := (DW_TO_READ) / WB_BLOCK_READ_LENGTH;
	type data_store_t is array (0 to DW_TO_READ) of 
										std_logic_vector(WB_WIDTH-1 downto 0);
										
	constant BYTES_OVER_TEMP : natural := (BYTES_TO_READ - DW_TO_READ*4);
	constant X	: real := real(BYTES_OVER_TEMP);
	constant Y 	: real := ceil(X / (2 ** X));
	constant BYTES_OVER : natural := natural(Y);

	constant ADDR_REM	: natural := (DW_TO_READ rem WB_BLOCK_READ_LENGTH)+ BYTES_OVER;
	
										
	signal DATA_STORE : data_store_t;
	signal wb_adr_nat : natural;
	
	signal clk : std_logic;
	signal rst : std_logic;
	signal wb_adr : std_logic_vector(WB_ADDR_WIDTH-1 downto 0);
	signal wb_dat_i : std_logic_vector(WB_WIDTH-1 downto 0);
	signal wb_dat_o : std_logic_vector(31 downto 0);
	signal wb_sel : std_logic_vector(3 downto 0);
	signal wb_cyc : std_logic;
	signal wb_stb : std_logic;
	signal wb_we : std_logic;
	signal wb_ack : std_logic;
	signal wb_stall : std_logic;
	signal axis_m_data : std_logic_vector(AXIS_WIDTH-1 downto 0);
	signal axis_m_keep : std_logic_vector(AXIS_WIDTH/8-1 downto 0);
	signal axis_m_valid : std_logic;
	signal axis_m_ready : std_logic;
	signal trig : std_logic;
	signal max_byte_addr : std_logic_vector(31 downto 0);
	signal prog_full : std_logic;
	
	
-- ATE
	constant MASTER_WIDTH		: natural := AXIS_WIDTH;
	constant MASTER_TEST_LEN	: natural := DW_TO_READ + BYTES_OVER;
	signal ate1_m_ready		: std_logic := '0';
	signal ate1_m_valid		: std_logic := '0';
	signal ate1_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0);
	signal ATE1_DONE		: boolean := false;


	constant CLK_PERIOD : time := 10 ns;
	constant ADL 		: time := CLK_PERIOD / 5;
	constant LDL 		: time := CLK_PERIOD * 5;
	
	constant stop_clock : boolean := false;
begin

	uut : entity xil_defaultlib.wbm_to_axism
		generic map
		(
			ADL                  => ADL,
			WB_WIDTH             => WB_WIDTH,
			WB_ADDR_WIDTH        => WB_ADDR_WIDTH,
			BYTE_ADDR_WIDTH      => BYTE_ADDR_WIDTH,
			AXIS_WIDTH           => AXIS_WIDTH,
			WB_BLOCK_READ_LENGTH => WB_BLOCK_READ_LENGTH
		)
		port map
		(
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
			axis_m_data     => axis_m_data,
			axis_m_keep     => axis_m_keep,
			axis_m_valid    => axis_m_valid,
			axis_m_ready    => axis_m_ready,
			trig    		=> trig,
			max_byte_addr 	=> max_byte_addr,
			prog_full       => prog_full
		);
		
--clk : in std_logic;
--rst : in std_logic;
--wb_adr : out std_logic_vector(ADDR_WIDTH-1 downto 0);
--wb_dat_i : in std_logic_vector(WB_WIDTH-1 downto 0);
--wb_dat_o : out std_logic_vector(31 downto 0);
--wb_sel : out std_logic_vector(3 downto 0);
--wb_cyc : out std_logic;
--wb_stb : out std_logic;
--wb_we : out std_logic;
--wb_ack : in std_logic;
--wb_stall : in std_logic;
--axis_m_data : out std_logic_vector(AXIS_WIDTH-1 downto 0);
--axis_m_valid : out std_logic;
--axis_m_ready : in std_logic;
--read_ram_csr : in std_logic;
--max_wb_addr_csr : in std_logic_vector(31 downto 0);
--prog_full : in std_logic		


-- Defining and filling memory space for wishbone slave
	wb_adr_nat	<= to_integer(unsigned(wb_adr));
	data_store_gen: for I in 0 to DW_TO_READ generate
		DATA_STORE(I)	<= std_logic_vector(to_unsigned(I, DATA_STORE(I)'length));
	end generate;

stimulus_wb_slave_addr : process 
	variable exp_adr : natural;
begin
		-- Initial assigments
		rst					<= '1' after ADL;
		prog_full			<= '0' after ADL;		
		trig				<= '0' after ADL;
		max_byte_addr			<= std_logic_vector(to_unsigned(BYTES_TO_READ-1,
											max_byte_addr'length)) after ADL;		

		wb_stall	<= '0' after ADL;
	
	wait for LDL;
	wait until rising_edge(clk);
		rst			<= '0' after ADL;
		trig		<= '1' after ADL;
	wait until rising_edge(clk);
		trig		<= '0' after ADL;
		
-- This loop is terating on indyvidual block cycles and is checking wb_adr value
-- which should be from 0 to 32. In this case 4x8 transactions need to be
-- reealized. 
	report " <<<WB SLAVE>>> receiving requests without using stall";
	for C in 0 to WB_CYCLES-1 loop
		for R in 0 to WB_BLOCK_READ_LENGTH-1 loop 
			exp_adr := (C * WB_BLOCK_READ_LENGTH + R);
			wait until rising_edge(clk) and wb_stb = '1';
			assert wb_adr_nat = exp_adr   
			 report " <<< FAILURE >>> wb addr not matching, expected: " & 
			 	natural'image(C * WB_BLOCK_READ_LENGTH + R) & "   wb_adr_nat: " & 
			 	natural'image(wb_adr_nat)
			 severity failure;
		end loop;
	end loop;
wait;
end process;
	
	
	
	
	
stimulus_wb_slave_ack: process begin
-- Initial assigments
		wb_ack		<= '0' after ADL;
	for C in 1 to WB_CYCLES loop
		for I in 1 to WB_BLOCK_READ_LENGTH loop
			wait until rising_edge(clk) and wb_cyc='1';		
				if I = 1 then
					wait for LDL;
				end if;
				wb_dat_i 	<= DATA_STORE(I-1) after ADL;
				wb_ack		<= '1' after ADL;
		end loop;
		-- Deassert ack every cycle is finished
		wait until rising_edge(clk);
			wb_ack		<= '0' after ADL;		
	end loop;
	
	-- Non multiple of BLOCK length cycle
	if ADDR_REM /= 0 then
		for I in 1 to ADDR_REM loop
			wait until rising_edge(clk) and wb_cyc='1';		
				if I = 1 then
					wait for LDL;
				end if;
				wb_dat_i 	<= DATA_STORE(I-1) after ADL;
				wb_ack		<= '1' after ADL;
		end loop;		
	end if;
	wait until rising_edge(clk);
		wb_ack		<= '0' after ADL;
		
	wait;
end process;


ate_verif: process begin
		ATE_INIT;
	-- Set paramaters
		S_VALID_STIM_MODE := TIED_TO_VCC;
		M_READY_STIM_MODE := TIED_TO_VCC;
	-- Set test lengts
		ATE_SET_TEST_LEN(MASTER_TEST_LEN, "M");
	-- Fill master store on the basis of WB DATA STORE
		for C in 0 to WB_CYCLES-1+1 loop
			for I in 0 to WB_BLOCK_READ_LENGTH-1 loop
				FILL_MASTER_STORE(I + C*WB_BLOCK_READ_LENGTH, std_logic_vector(to_unsigned(I, MASTER_WIDTH)));
			end loop;
		end loop;
		
		
-- TEST1
	ATE_M_TEST_ID := 1;
	report " [STIM]   TEST1 triggering. Waiting for DONE event...";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE1_DONE'event;



wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;


-- ATE
-- MASTER1 PROCS
ate1_master_proc: AXIS_MASTER_STIM_PROC(ATE1_DONE, clk, rst, ate1_m_data, ate1_m_valid, ate1_m_ready, 1);
ate1_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate1_m_data, ate1_m_valid, ate1_m_ready, 1);
ate1_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate1_m_valid, ate1_m_ready, 1);

	-- Master ATE1 in - listen only
	ate1_m_valid 	<= axis_m_valid;
	ate1_m_data		<= axis_m_data;
	-- Master ATE1 out - stim m_ready
	axis_m_ready		<= ate1_m_ready after ADL;	
		
		
-- Clock gen
	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

