--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbs_mem.vhd
-- Language: VHDL
-- Description: 
-- 	Simple inferred memory generator witch wb slave interface
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Infers the block ram in no change mode according to xst_v6s6.vhd
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;
use vhdlbaselib.common_pkg.all;


entity wbs_mem is
	Generic ( 
		MEM_LEN : natural := 128
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
		-- Whishbone Slave Interface
		wbs_cyc	      : in  std_logic;
		wbs_stb       : in  std_logic;
		wbs_adr       : in  std_logic_vector;
		wbs_we        : in  std_logic;
		wbs_dat_i     : in  std_logic_vector;
		wbs_dat_o     : out std_logic_vector;
		wbs_ack       : out std_logic
--		wbs_err		: out std_logic    	
    );
end wbs_mem;
architecture wbs_mem_arch of wbs_mem is


type ram_t is array(0 to MEM_LEN-1) of std_logic_vector(wbs_dat_i'range);
signal ram : ram_t := ( others => (others => '0'));
signal adr_nat		: natural range 0 to MEM_LEN-1;



begin

mem_proc: process(clk) begin
if rising_edge(clk) then
	if wbs_we = '1' and wbs_stb = '1' and wbs_cyc = '1' then
		ram(adr_nat)	<= wbs_dat_i;
	else
		wbs_dat_o		<= ram(adr_nat);
	end if;
end if;
end process;

adr_nat	<= to_integer(unsigned(wbs_adr(calc_width(MEM_LEN)-1 downto 0)));


ack_proc: process(clk) begin
if rising_edge(clk) then
	if wbs_stb = '1' and wbs_cyc = '1' then
		wbs_ack		<= '1';
	else
		wbs_ack		<= '0';
	end if;
end if;
end process;
	
	


end wbs_mem_arch;
