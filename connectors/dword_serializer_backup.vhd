----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: dword_serializer - Behavioral
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
library xil_defaultlib;
--use xil_defaultlib.pcie_pkg.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dword_serializer is
	Generic(ADL				: time	:= 500 ps;
			S_AXIS_W		: natural := 128;
			S_AXIS_READY_N	: boolean := false;
			M_AXIS_W		: natural := 32;
			M_AXIS_VALID_N	: boolean := false		
			);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
-- DIN interface
			s_data	: in STD_LOGIC_VECTOR(127 downto 0);
			s_valid	: in STD_LOGIC_VECTOR(3 downto 0);
			s_ready	: out STD_LOGIC;
-- DOUT interface
			m_data	: out STD_LOGIC_VECTOR (31 downto 0);
			m_valid	: out STD_LOGIC;
			m_ready	: in STD_LOGIC);
end dword_serializer;

architecture Behavioral of dword_serializer is
-- Ille razy dout miesci sie w din? minus jeden bo ?
constant WORD_COUNTER_W 	: natural := S_AXIS_W/M_AXIS_W-1;	     

-- Wyjscie licznika 3-bitowe, bo sa 4 slowa, a 0 oznacza brak zadnego slowa
signal current_word		: std_logic_vector(WORD_COUNTER_W-1 downto 0);
signal I				: natural range 0 to 3;


-- Wyjscie synchronicznie do clk
signal m_data_s		: std_logic_vector(M_AXIS_W-1 downto 0);
signal m_valid_s	: std_logic;

-- 
--signal s_ready_s	: std_logic;

-- Licznik aktualnego slowa
signal sclr				: std_logic;
signal sclr_s				: std_logic;
signal ce				: std_logic;

begin
I	<= to_integer(unsigned(current_word));


-- Rejest wyjsciowy
din_reg_proc: process(clk)
begin
if rising_edge(clk) then
if rst = '1' then
	m_data		<= (others => '0') after ADL;
	m_valid		<= '0' after ADL;
--else
elsif m_ready = '1' then
	m_data		<= m_data_s after ADL;
	m_valid		<= m_valid_s after ADL;
end if;
end if;
end process;





-- Logika kombinacyjna do przetwarzania s_valid na sygnaly sterujace licznikiem.
--  ready musi byc sterowane asynchronicznie. s_valid wieksze niz 1 slowo musi spowodac,
--  ze na najblizszym takcie zegarowy ready bedzie nisko. W przypadku synchronicznej
--  zmiany nastapi to tuz PO takcie zegarowym - nie moze tak byc.
-- 20 lipca
--   Sygnal s_ready_s == sclr_s;
counter_driver: process(s_valid, current_word)
begin
	case s_valid is 
		when "0000" =>	
	-- Brak slow licznik czeka
			sclr_s	<= '1';

		when "0001" =>
	-- Jedno slowo - licznik nie startuje
			sclr_s	<= '1';
	-- Dwa slowa - kasuj po 1
		when "0011" =>
			if current_word = "001" then
				sclr_s	<= '1';
			else
				sclr_s	<= '0';
			end if;
	-- Trzy slowa - kasuj po 2
		when "0111" =>
			if current_word = "010" then
				sclr_s	<= '1';
			else
				sclr_s	<= '0';
			end if;
	-- Cztery slowa - kasuj po 3
		when "1111" =>
			if current_word = "011" then
				sclr_s	<= '1';
			else
				sclr_s	<= '0';		
			end if;
	-- Tu nie wchodzi
		when others =>
			sclr_s	<= '1';
	end case;
end process;
--  Czyszczenie licznika musi byc powiazane z m_ready, poniewaz 
--   w przypadku obnizenia m_ready podczas ostatniego slowa
--   sclr czysci licznik, i wyjscie licznika jest nie poprawne
sclr		<= '1' when sclr_s = '1' and m_ready = '1' else '0';

--  s_ready to zawszze sclr, z wyjatkiem syhtuacji gdy nic sie
--   nie dzieje i modul czeka na dane. Wtedy jest rowne 1.
s_ready		<= '1' when s_valid = "0000" else sclr;





-- Generalnie m_valid = 1 zawsze gdy s_valid != 0. Chodzi to ze dane musza
--   zostac niezwlocznie odebrane. Jesli nie zostana odebrane natychmiast
--   to przepddna, bo na nastepnym takcie zegarowym pojawia sie nowe. Mozna
--   to zrobi przez rejestr, ale wtedy dane tez musialby byc zachowywane w 
--   rejestrze. Nalezy tez obserwowac czy odbiornik jest gotowy - sygnal
--   m_ready. 
ce	<= '0' when s_valid = "0000" or s_valid = "0001" or m_ready = '0' else  '1';


-- Dane wyjsciowe sa wazne, gdy s_valid != 0000 i ...
m_valid_s	<= '1' when s_valid /= "0000" else '0';
-- Wyjscie danych zalezy od stanu licznika, ktory zmienia sie synchroniczne
--   do zegara
m_data_s <= s_data((M_AXIS_W*(I+1)-1) downto M_AXIS_W*I);
--I=0:					31							0
--I=1:					63							32
--I=2:					95							64
--I=3:					127							96 

-- Ewntualnie mozna jesxcze zrobic s_valid i s_data jako rejetry, bo sa na wejsciach
--   ale to kosmetyka
word_counter_inst: entity xil_defaultlib.counter
	Generic Map(WIDTH => WORD_COUNTER_W)
    Port Map( 	clk 	=> clk, 
           		sclr	=> sclr,
				ce		=> ce,
				q 		=> current_word);

end Behavioral;
