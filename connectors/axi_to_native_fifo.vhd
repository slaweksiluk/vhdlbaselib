----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: axi_to_native_fifo - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Changed din to native_data
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity axi_to_native_fifo is
	Generic( WIDTH	: natural := 32);
    Port ( s_data : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
           s_valid : in STD_LOGIC;
           s_ready : out STD_LOGIC;
           native_data : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
           wr_en : out STD_LOGIC;
           full : in STD_LOGIC);
end axi_to_native_fifo;

architecture Behavioral of axi_to_native_fifo is

begin

wr_en		<= s_valid;
s_ready		<= not full;
native_data	<= s_data;

end Behavioral;
