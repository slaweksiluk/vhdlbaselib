----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: native_fifo_to_axi - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Changed dout to native_data
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

entity native_fifo_to_axi is
	Generic( WIDTH	: natural := 32);
    Port ( native_data	: in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
           empty : in STD_LOGIC;
           rd_en : out STD_LOGIC;
           m_data : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
           m_valid : out STD_LOGIC;
           m_ready : in STD_LOGIC);
end native_fifo_to_axi;

architecture Behavioral of native_fifo_to_axi is

begin

m_data	<= native_data;
m_valid	<= not empty;
rd_en	<= m_ready;

end Behavioral;
