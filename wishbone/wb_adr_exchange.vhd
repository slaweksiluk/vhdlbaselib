--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wb_adr_exchange.vhd
-- Language: VHDL
-- Description: 
-- 	It's assumed it's working with vme64x_core and wb_switch form EUCLUD project.
--	It means vme cyces are issued every 15 clk cycles. It desent chackec if 
--	address is ia any range - adr input unconnected
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;

entity wb_adr_exchange is
	Generic ( 
		ADL						: time 		:= 0 ps;
		DAT_WIDTH				: natural 	:= 8;
		WBM_ADR_WIDTH			: natural 	:= 32		

	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
		-- Wishbone slave interface
		wbs_dat_i : in  std_logic_vector(DAT_WIDTH-1 downto 0);
		wbs_sel   : in std_logic_vector(3 downto 0);
		wbs_cyc   : in std_logic;
		wbs_stb   : in std_logic;
		wbs_we    : in std_logic;
		wbs_ack   : out  std_logic;
		wbs_stall : out  std_logic;    	
		
		-- Wishbone master interface
		wbm_adr   : out std_logic_vector(WBM_ADR_WIDTH-1 downto 0);
		wbm_dat_o : out std_logic_vector(DAT_WIDTH-1 downto 0);
		wbm_sel   : out std_logic_vector(3 downto 0);
		wbm_cyc   : out std_logic;
		wbm_stb   : out std_logic;
		wbm_we    : out std_logic;
		wbm_ack   : in  std_logic;
		wbm_stall : in  std_logic;
		
		max_write_adr	: in std_logic_vector(WBM_ADR_WIDTH-1 downto 0)
		
    );
end wb_adr_exchange;
architecture wb_adr_exchange_arch of wb_adr_exchange is

	signal rst_cnt_r		: std_logic := '1';
	signal ce_r				: std_logic := '0';
	signal cnt_r			: std_logic_vector(WBM_ADR_WIDTH-1 downto 0);
	signal ce_c				: std_logic := '0';
	signal rst_cnt_c		: std_logic := '1';
	
	
begin
	
-- Counter inst & ce/rst logic
counter_inst : entity vhdlbaselib.counter
	generic map	(
		ADL   => ADL,
		WIDTH => WBM_ADR_WIDTH
	)
	port map(
		clk  => clk,
		sclr => rst_cnt_r,
		ce   => ce_r,
		q    => cnt_r);

ce_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		ce_r <= '0';
	else
		ce_r <= ce_c;
	end if;
end if;
end process;	
ce_c <= '1' when wbs_cyc = '1' and wbm_ack = '1' else '0';

rst_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		rst_cnt_r <= '1' ;
	else
		rst_cnt_r <= rst_cnt_c ;		
	end if;
end if;
end process;	
rst_cnt_c <= '1' when (cnt_r = max_write_adr and ce_c = '1') else '0';	


-- Output the wbm_adr - registered
adr_proc: process(clk) begin
if rising_edge(clk) then
	wbm_adr	<= cnt_r ;
end if;
end process;


-- Direct conncetion between wbm and wbs
	-- WBS -> WBM
		wbm_dat_o <= wbs_dat_i;
		wbm_sel   <= wbs_sel;
		wbm_cyc   <= wbs_cyc;
		wbm_stb   <= wbs_stb;
		wbm_we    <= wbs_we;
	-- WBS -> WBM
		wbs_ack   <= wbm_ack;
		wbs_stall <= wbm_stall;
		
		
	

end wb_adr_exchange_arch;
