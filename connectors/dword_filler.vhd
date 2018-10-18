----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: dword_filler - Behavioral
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
-- 7/10/15
-- Konwersja z 128 bit (4 valid) do 128 bit (1 valid) za pomoca FSM, i wartosci
-- reamidner, ktora mowi ile zostalo jeszcze slow 32 bit w poprzednim slowe 128 bit.
-- Na razie sterowanie m_data_l wewntrz FSM, bo prosciej - lepiej by bylo bez rst.
-- TO DO:
--	* przerobic s_valid na jendo bitowy syg i dodac s_keep 16 bitowy
--	s_valid wewntrznie zostanie tak jak bylo (s_valid_internter) i bedzie generowanie na podstawie
--	s_keep[16] i s_valid 	

-- Lates consider that PCIe express has sent abcd msg. Then we wanto to receive
-- abcd. But if PCIe sent:
-- -> xxxa bcde xfgh
-- Then the expeted value to recive is:
-- -> abcd efgh	
-- a was MSB and it has to stay the MSB. Thats wy dword filler has to be tested
--
-- 03/04/17
-- IT seems abve data ordering is wrong.
-- Real CPLD PCIE packet is shown at pg054 at page 81:
-- 
--		D0H2H1H0  D4D3D2D1 --D7D6D5
--	
-- Keep flag is set at data positions BUT D0 is internally (in rx_engine)
-- moved to H0 pos, hence the packet at dword_filler input is:
--
--		------D0  D4D3D2D1 --D7D6D5
--
-- Now the expected output is:
--
--		D3D2D1D0 D7D6D5D4
--
-- Current implementation is wrong becasue D0 was moved to the most-left pos
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library vhdlbaselib;
use vhdlbaselib.common_pkg.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dword_filler is
	Generic ( 
			ADL				: time := 0 ps;
			REV_OUT_SLICES	: boolean := false
		);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           s_data 	: in STD_LOGIC_VECTOR (127 downto 0);
           s_keep 	: in STD_LOGIC_VECTOR (15 downto 0);
           s_valid 	: in STD_LOGIC;

           s_ready 	: out STD_LOGIC;
           m_data 	: out STD_LOGIC_VECTOR (127 downto 0);
           m_valid 	: out STD_LOGIC;
           m_ready 	: in  STD_LOGIC);
end dword_filler;
architecture Behavioral of dword_filler is

-- Stale z indeksami
constant D3_HIGH	: natural := 127;
constant D3_LOW		: natural := 96;
constant D2_HIGH	: natural := 95;
constant D2_LOW		: natural := 64;
constant D1_HIGH	: natural := 63;
constant D1_LOW		: natural := 32;
constant D0_HIGH	: natural := 31;
constant D0_LOW		: natural := 0;


type state_type is (
					IDLE_STATE,
					LACK_OF_1_STATE,
					PRE_LACK_OF_3_STATE,
					BUF0_LACK_OF_3_STATE,
					LACK_OF_3_STATE,
					ERROR_STATE
					);
			
signal state		: state_type;

signal s_valid_inter	: std_logic_vector(3 downto 0) := (others => '0');
signal s_valid_c	: std_logic_vector(3 downto 0) := (others => '0');
signal s_data_i		: std_logic_vector(127 downto 0) := (others => '0');
--signal s_ready_i	: std_logic := '0';

signal buf_data		: std_logic_vector(127 downto 0) := (others => '0');
signal buf_valid	: std_logic_vector(3 downto 0) := (others => '0');

signal m_data_l		: std_logic_vector(m_data'range) := (others => '0');

begin

-- Proste przypisane bez kombinacji
s_ready	<= m_ready;


fsm_proc: process(clk) 

begin
if rising_edge(clk) then
	if rst = '1' then
		m_valid		<= '0' after ADL;
		buf_valid	<= "0000" after ADL;
		state		<= IDLE_STATE after ADL;
	else
		case state is 
		when IDLE_STATE =>
			if m_ready = '1' then 
				case s_valid_inter is			
				-- Przypadek najprostszy wszystkie slowa wazne
				when "1111" =>
					m_data_l		<= s_data_i after ADL;
					m_valid		<= '1' after ADL;
				-- Jedno slowo niewazne
				when "0111" =>
					-- Przypisz wazne trzy slowa do wyjscia, ale z lewej strony
					m_data_l(D3_HIGH downto D1_LOW)	<= s_data_i(D2_HIGH downto D0_LOW) after ADL;
					-- Dane jescze nie wazne
					m_valid		<= '0' after ADL;
					-- Przejdz do stanu gdfzie brakuje jednego slowa
					state		<= LACK_OF_1_STATE after ADL;
					-- Jesli nastepnych slow bedzie wiecej niz jedno to zatrzymaj s_ready,
					-- zeby nie nadpisalo s_data_i
					-- 8/10/15
					-- Zakomentowane - niepotrzebne w implementacji z buf_data
	--				if s_valid > "0001" then
	--					s_ready_i		<= '0' after ADL;
	--				end if;
				-- Jedno slowo wazne
				when "0001" =>
					-- Przypisz wazne slowa do wyjscia, ale z prawej strony
					m_data_l(D0_HIGH downto D0_LOW)	<= s_data_i(D0_HIGH downto D0_LOW) after ADL;
					-- Dane jescze nie wazne
					m_valid		<= '0' after ADL;
					-- Przejdz do stanu gdfzie brakuje trzech slow
					state		<= BUF0_LACK_OF_3_STATE after ADL;
				-- Brak waznych slow
				when "0000" =>
					m_data_l		<= (others => '0') after ADL;
					m_valid		<= '0' after ADL;
				when others => state <= ERROR_STATE after ADL;
				end case;
			end if;


		-- W tym stanie bufor jest pusty i brakuje trzech slow
		when BUF0_LACK_OF_3_STATE =>
			if m_ready = '1' then 
				case s_valid_inter is
				-- Doszly cztery
				when "1111" =>
					-- Wstaw D2 D1 D0 z lewej strony, bo prawa juz zajeta
					m_data_l(D3_HIGH downto D1_LOW)	<= s_data_i(D2_HIGH downto D0_LOW) after ADL;
					m_valid							<= '1' after ADL;
					-- Zbuforuj slowo pozostale po lewej (D3),  z prawej strony				
					buf_data(D0_HIGH downto D0_LOW)	<= s_data_i(D3_HIGH downto D3_LOW) after ADL;
					buf_valid						<= "0001" after ADL;
					-- Brakuje trzech slow
					state							<= LACK_OF_3_STATE after ADL;				
				when others => state <= ERROR_STATE after ADL;
				end case;
			end if;
				
		-- W tym stanie brakuje jednego slowa (D3)
		when LACK_OF_1_STATE =>
			if m_ready = '1' then 
				case s_valid_inter is
				-- Najprostszy przypadek, jesli akurat jedno pasuje
				when "0001" =>
					-- Dopisz brakuje slowo z prawej strony
					m_data_l(D0_HIGH downto D0_LOW)	<= s_data_i(D0_HIGH downto D0_LOW) after ADL;
					m_valid							<= '1' after ADL;
					-- Wroc do czekania
					state							<= IDLE_STATE after ADL;
				-- Doszly dwa slowa
				when "0011" =>
					-- Wstaw D1 z prawej strony
					m_data_l(D0_HIGH downto D0_LOW)	<= s_data_i(D1_HIGH downto D1_LOW) after ADL;
					m_valid							<= '1' after ADL;
					-- Teraz na s_data_i pozostalo jedno wazne slowo: D0. Jesli nic
					-- Nie zrobie to przepadnie, bo SLAVE wystwi nowe slowo. Przytrzymam na
					-- Jeden takt s_ready i sce nisko, wtedy s_data nie nadpisze przedwczesnie
					-- s_data_i. NIE NIE Teraz to za pozno! Trzeba obnizyc s_ready jeden takt
					-- wczeniej!
					-- W rakim razie mozna przejsc do stanu  braku trzech slow, wczesniej ladujac
					-- pozosowlae jedno slow D0 do m_data_l
	--				state	<= PRE_LACK_OF_3_STATE after ADL;				
					-- I przywrocic pobieranie slave
	--				s_ready_i	<= '1' after ADL;
					
					-- 8/10/15
					-- Lepiej jednak zrobie to z wykorzystaniem bufora, zeby nie generowac
					-- niepotrzebnych obnizen s_ready. Wpisanie wszystkiego do bufora
					buf_data(D3_HIGH downto D3_LOW)	<= s_data_i(D0_HIGH downto D0_LOW) after ADL;
					buf_valid						<= "1000" after ADL;
					state							<= LACK_OF_3_STATE after ADL;
				-- Doszly cztery
					when "1111" =>
						-- Wstaw D2 D1 D0 z prawej strony, bo lewa juz zajeta
						m_data_l(D2_HIGH downto D0_LOW)	<= s_data_i(D3_HIGH downto D1_LOW) after ADL;
						m_valid							<= '1' after ADL;
						-- Zbuforuj pozostale slowo z lewej strony				
						buf_data(D3_HIGH downto D3_LOW)	<= s_data_i(D0_HIGH downto D0_LOW) after ADL;
						buf_valid						<= "1000" after ADL;
						-- Brakuje trzech slow
						state							<= LACK_OF_3_STATE after ADL;								
				when others => state <= ERROR_STATE after ADL;				
				end case;
			end if;
					
		-- Stan ladowania pozostalosci (z lewek strony!) przed przejsciem DO LACK OF 3 STATE.
		-- Tutaj narazie zakladam ze jest jedna pozostalosc na D0, ale czy zawsze tak bedzie,
		-- ewentualnie czy jakos inaczej mozna wywynioskowac ktore slowa mam zachowac?
		-- Nie, nie bedzie tak latwo wczesniej doszly dwa slowa, a przeciez mogly byc 3 i wtedy
		-- nalezaloby tu nizej zachowac dwa slowa.
		-- Mozna do tego wykorzystac sygnal s_valid_inter, ktory nadal trzyma ilosc slow
		-- z poprzedniego taktu
		-- A tak w gole to lepiej byloby zrobi jakis bufor, zeby zaoszczdzic
		-- jednego obnizenia s_ready (niepotrzebnego)
		when PRE_LACK_OF_3_STATE =>
--			m_data_l(D3_HIGH downto D3_LOW)	<= s_data_i(D0_HIGH downto D0_LOW) after ADL;
--			m_valid							<= '0' after ADL;
--			state							<= LACK_OF_3_STATE after ADL;
			
		
					
		-- W tym stanie brakuje trzech slow (D3,D2,D1)
		when LACK_OF_3_STATE =>
			if m_ready = '1' then 
				case s_valid_inter is
				-- Najprostszy przypadek, akurat trafily sie trzy slowa ( D2 D1 D0)
				when "0111" =>
					-- Wpisz zawartosc bufora (zakladam ze jest tam jedno slow na pozycji D0!):
					m_data_l(D0_HIGH downto D0_LOW)	<= buf_data(D0_HIGH downto D0_LOW) after ADL;
					m_data_l(D3_HIGH downto D1_LOW)	<= s_data_i(D2_HIGH downto D0_LOW) after ADL;
					m_valid							<= '1' after ADL;
					state							<= IDLE_STATE after ADL;
				-- Trafily sie cztery slowa ( D3 D2 D1 D0)
				when "1111" =>
					-- Wpisz zawartosc bufora (zakladam ze jest tam jedno slow na pozycji D0!):
					m_data_l(D0_HIGH downto D0_LOW)	<= buf_data(D0_HIGH downto D0_LOW) after ADL;
					-- Na pozycje D3 D2 D1 wpisz slowa z s_data D2 D1 D0
					m_data_l(D3_HIGH downto D1_LOW)	<= s_data_i(D2_HIGH downto D0_LOW) after ADL;
					m_valid							<= '1' after ADL;
					-- Bufor znow pamieta D3 z s_data z lewej storny, po swoeje prwej stronie
					buf_data(D0_HIGH downto D0_LOW)	<= s_data_i(D3_HIGH downto D3_LOW) after ADL;
					buf_valid						<= "0001" after ADL;
					-- Nadal brakuje trzech slow
					state							<= LACK_OF_3_STATE after ADL;				
				when others => state <= ERROR_STATE after ADL;
				end case;
			end if;
			
		when ERROR_STATE =>
		assert false report "   dword_filler.vhd FSM reached error state" severity failure;
		when others => state <= ERROR_STATE after ADL;
		end case;			
	end if;
end if;
end process;

slave_proc: process(clk) begin
if rising_edge(clk) then
-- 08/10/15
-- Sygnal ce zakomentowany - nie potrzebny w implementacji z buforem,
-- zamiast tego m_ready, na wypadek jego obnizenia
	if m_ready = '1' then
		s_data_i		<= s_data after ADL;
		s_valid_inter	<= s_valid_c after ADL;
	end if;
end if;
end process;

valid_proc: process(s_valid, s_keep) begin
	if s_valid = '1' then
		case s_keep is
			when x"000f" =>
				s_valid_c <= "0001";
			when x"00ff" =>
				s_valid_c <= "0011";
			when x"0fff" =>
				s_valid_c <= "0111";	
			when x"ffff" =>
				s_valid_c <= "1111";
			when others =>
				s_valid_c <= "0000";						
		end case;
	else
		s_valid_c		<= (others => '0');			
	end if;						
end process;


-- Data is naturrally reversed
rev_out_gen: if REV_OUT_SLICES generate
	m_data <= m_data_l;
end generate;

norm_out_gen: if not REV_OUT_SLICES generate
	m_data <= reverse_slices(m_data_l, 32);
end generate;



end Behavioral;
