----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: pulse_sync - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

library xil_defaultlib;

entity pulse_sync is
    Port ( clk_src : in STD_LOGIC;
           sig_src : in STD_LOGIC;
           clk_dst : in STD_LOGIC;
           sig_dst : out STD_LOGIC);
end pulse_sync;
architecture Behavioral of pulse_sync is

signal sig_src_toggle	: std_logic := '0';
signal sig_dst_toggle	: std_logic := '0';
signal sig_dst_toggle_r	: std_logic := '0';
signal sig_dst_c		: std_logic := '0';
signal data_sync1 		: std_logic := '0';

attribute ASYNC_REG               : string;
attribute ASYNC_REG of data_sync1 : signal is "TRUE";
  
begin



-- Wychwytywanie w domenie clk src
sig_toogle_det_proc: process (clk_src) begin
if rising_edge(clk_src) then
	sig_src_toggle		<= sig_src_toggle xor sig_src;
end if;
end process;


-- Synchronizacaji do clk dst
data_sync : FD
generic map (
  INIT => '0'
)
port map (
  C    => clk_dst,
  D    => sig_src_toggle,
  Q    => data_sync1
);


data_sync_reg : FD
generic map (
  INIT => '0'
)
port map (
  C    => clk_dst,
  D    => data_sync1,
  Q    => sig_dst_toggle
);

-- Wykrywanie zmnian w domenie clk dst i wystawienie na  zewnatrz 
-- przez rejestr
sig_event_det_proc: process (clk_dst) begin
if rising_edge(clk_dst) then
	sig_dst_toggle_r		<= sig_dst_toggle;
	sig_dst					<= sig_dst_c;
end if;
end process;
sig_dst_c	<= '0' when sig_dst_toggle_r = sig_dst_toggle else '1';






end Behavioral;
