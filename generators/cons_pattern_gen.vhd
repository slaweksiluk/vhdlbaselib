--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: cons_pattern_gen.vhd
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
--use IEEE.NUMERIC_STD.ALL;

entity cons_pattern_gen is
	Generic ( 
		DATA_WIDTH	: natural := 8;
		USE_TRIG 	: boolean := true
		);
    Port (
    	-- Sys
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
    	-- AXIS master
    	m_data		: out std_logic_vector(DATA_WIDTH-1 downto 0);
    	m_valid		: out std_logic;
    	m_ready		: in std_logic;
    	
    	-- Ctrl, conf
    	pattern		: in std_logic_vector(DATA_WIDTH-1 downto 0);
    	trig		: in std_logic
    );
end cons_pattern_gen;
architecture cons_pattern_gen_arch of cons_pattern_gen is

signal trig_gen		: std_logic := '0';

begin


use_trig_gen: if USE_TRIG generate
		trig_gen	<= trig;
end generate;

no_trig_gen: if not USE_TRIG generate
	trig_gen		<= '1';
end generate;
	
proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		m_data	<= (others => '0');
		m_valid		<= '0';
	elsif trig_gen = '1' then
		m_data	<= pattern;
		m_valid	<= '1';
	end if;
end if;
end process;


end cons_pattern_gen_arch;
