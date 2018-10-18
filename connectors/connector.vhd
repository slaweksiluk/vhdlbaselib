----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: connector - Behavioral
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
-- Logika laczaca FIFO z innym FIFO badz modulem posiadajacym szyne danych i sygnal
--   valid, rd_en, wr_en. Opcjonalnie full/empty. W przypadku braku sygnalu full
--   obsluga przepelniania odbywa sie inna droga. W przypadku polaczenia FIFO z 
--   interfejsem Aurora do kontroli przepelnienia wykorzystane jest NFC. 
----------------------------------------------------------------------------------
--library xil_defaultlib;
--use xil_defaultlib.pcie_pkg.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity connector is
	Generic(ADL				: time	:= 500 ps;
			S_AXIS_W		: natural := 128;
			S_AXIS_READY_N	: boolean := false;
			M_AXIS_W		: natural := 128;
			M_AXIS_VALID_N	: boolean := false		
		);
	Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
-- Interfejs wejsciow
           s_valid 	: in STD_LOGIC;
           s_last	: in std_logic;
           s_data	: in STD_LOGIC_VECTOR(S_AXIS_W-1 downto 0);
           s_keep	: in std_logic_vector(S_AXIS_W/8-1 downto 0);
           s_ready 	: out STD_LOGIC;
-- Interfejs wyjsciowy
           m_ready	: in STD_LOGIC;
           m_data	: out STD_LOGIC_VECTOR(M_AXIS_W-1 downto 0);
           m_keep	: out STD_LOGIC_VECTOR(M_AXIS_W/8-1 downto 0);
           m_valid	: out STD_LOGIC;
           m_last	: out STD_LOGIC
           );
end connector;
architecture Behavioral of connector is


signal m_valid_i	: std_logic;
signal s_valid_i	: std_logic;
signal s_ready_i	: std_logic;
signal s_data_i		: std_logic_vector(S_AXIS_W-1 downto 0);
signal s_keep_i		: std_logic_vector(S_AXIS_W/8-1 downto 0);
signal s_last_i		: std_logic := '0';

begin

-- Polaryzacja ready
ready_neg: IF S_AXIS_READY_N generate
s_ready		<= not s_ready_i;
end generate;
ready_pos: IF not S_AXIS_READY_N generate
s_ready		<= s_ready_i;
end generate;

-- Polaryzacja valid
valid_neg: IF M_AXIS_VALID_N generate
m_valid		<= not m_valid_i;
end generate;
valid_pos: IF not  M_AXIS_VALID_N generate
m_valid		<= m_valid_i;
end generate;



-- Gdy DOUT = DIN 
data_width_equal: IF S_AXIS_W = M_AXIS_W generate

--  Czy tutaj musi byc bezposrednie polacznie? W przypadku
--   gdy szerkosci sa rowne nie stanowi to problemu, ale
--   ale gdy dojdzie konwersja szerokosc pojawi sie tu jakas 
--   logika i brak rejestorow bedzie psuc czasowanie.
--   DO ZBADANIA
-- 15/02/17 
-- Stworzylem modu axis_buf.vhd, ktory pozwala na dodanie stopni rejestrow do 
-- ready w axis st 
s_ready_i	<= m_ready;

out_reg_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		m_valid_i		<= '0' after ADL;
	elsif m_ready = '1' then
		m_data			<= s_data_i after ADL;
		m_keep			<= s_keep_i after ADL;
		m_valid_i		<= s_valid_i after ADL;
		m_last			<= s_last_i after ADL;
	end if;
end if;
end process;

in_reg_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		s_valid_i		<= '0' after ADL;
	elsif m_ready = '1' then
		s_data_i		<= s_data after ADL;
		s_keep_i		<= s_keep after ADL;
		s_valid_i		<= s_valid after ADL;
		s_last_i		<= s_last after ADL;
	end if;
end if;
end process;

end generate;

end Behavioral;
