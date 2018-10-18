--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: lfsr_counter.vhd
-- Language: VHDL
-- Description: Linear feedback shift register with rst and ce. It outputs seed
-- value vhile in reset state. 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


entity lfsr_counter is
  generic(
	ADL		: time 	:= 0 ps;
  	WIDTH : natural := 4);
  port (
	rst 	: in std_logic;
	clk		: in std_logic;
	ce		: in std_logic;
	-- Wyjscie licznika
	dout : out std_logic_vector(WIDTH-1 downto 0);
	-- Wartosc poczatkowa licznika
	seed	 	:  in std_logic_vector(WIDTH-1 downto 0)	
	);
end lfsr_counter;

architecture imp_lfsr_counter of lfsr_counter is
  signal lfsr: std_logic_vector (WIDTH-1 downto 0);
  signal d0	: std_logic := '0';
begin
	
	
	d0	<= lfsr(WIDTH-1) xor lfsr(WIDTH-2);

	process (clk) begin
	if rising_edge(clk) then
		if (rst = '1') then
			lfsr <= seed after ADL;
        elsif ce = '1' then
            lfsr <= lfsr(WIDTH-2 downto 0) & d0 after ADL;
		end if;
	end if;
end process;
dout	<= lfsr;

end architecture imp_lfsr_counter; 
