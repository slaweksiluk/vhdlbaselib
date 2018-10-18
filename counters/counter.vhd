--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: counter.vhd
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


entity counter is
	Generic(ADL		: time	:= 0 ps; 
			WIDTH 	: natural);
    Port ( clk : in  STD_LOGIC;
           sclr : in  STD_LOGIC;
           ce : in  STD_LOGIC;
           q : out  STD_LOGIC_VECTOR (WIDTH-1 downto 0));
end counter;

architecture Behavioral of counter is

signal count	: unsigned(WIDTH-1 downto 0);

begin


counter_proc: process (clk) 
begin
   if rising_edge(clk) then
      if sclr = '1' then 
         count <= (others => '0') after ADL;
      elsif ce = '1' then		
         count <= count + 1 after ADL;
      end if;
   end if;
end process; 

q <= std_logic_vector(count);

end Behavioral;

