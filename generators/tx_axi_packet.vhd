----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: tx_axi_packet - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 	Transmitted packet length is n = packet_len+1, eg if pack???
--	Real: n = packet_len
--	Need to consider changing it to n = packet_len+1 (0 -> 1)
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 16/09/15
-- Po wielu probach wyglda na to ze nie jest mozliwe polaczenie sygnalow m_ready 
-- i s_ready przez rejestr. Dodwanie rejestow buforujaych nic nie daje...
-- Dodalem wiec sygnal ready_sel, ktory w stanie wysokim pozwala na sterowanie
-- s_ready bezposrednio przez m_redy. W stanie niskim s_ready zawsze nisko.

-- 21.12.15
-- Przenioslem packet length do portow - mozliwa dynamiczna zmiana. Dlugosc pakietu
-- jest zatrzaskiwana na poczatku kazdego pakietu sygnalem latch_len sterowanym
-- z FSM. Maksymalana szerokosc dlugosci pakietu: 32 bity - typ natural.

-- 10/02/16
-- Generator nie uruchomi sie dopoki s_ready nie bedzie wysoko - trzeba by to
-- poprawic, bo od takiego blokowanie powinien sluzyc synal trigger

-- TO DO:
-- 		* clean code
-- 		* fix also for trig level mode (current tb no working)
-- 		* check if setting the s_ready high despite the s_valid state AND add 
--			an option for force s_ready for one cycle when m_ready low (resolving
--			dead-locks		
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.math_real.all;

--library work;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tx_axi_packet is
	Generic ( ADL			   : time	 := 0 ps;
			  DATA_WIDTH	   : natural := 8;
			  PACKET_LEN_WIDTH : natural := 8;
			  TRIG_MODE_PULSE	: boolean := false
			   ); 
    Port ( clk          : in STD_LOGIC;
           rst          : in STD_LOGIC;
           s_data 		: in STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
           s_valid 		: in STD_LOGIC;
           s_ready 		: out STD_LOGIC;
           m_data 		: out STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
           m_valid 		: out STD_LOGIC;
           m_ready 		: in STD_LOGIC;
           m_last		: out STD_LOGIC;
           trigger 		: in STD_LOGIC;
           packet_len   : in STD_LOGIC_VECTOR(PACKET_LEN_WIDTH-1 downto 0) );
end tx_axi_packet;

architecture Behavioral of tx_axi_packet is

-- Stale
--constant COUNTER_WIDTH  : natural := natural((log2(real(PACKET_LEN)) + real(1.0)));
-- Dlugosc licznika do szerokosc dlugosci pakietu
constant COUNTER_WIDTH  : natural := PACKET_LEN_WIDTH;

type state_type	is (IDLE_STATE, 
					TX_STATE
					);
signal state	: state_type;

signal rst_cnt_c		: std_logic := '1';
signal rst_cnt_r		: std_logic := '1';
signal ce_cnt		: std_logic := '0';
signal q			: std_logic_vector(COUNTER_WIDTH-1 downto 0);
signal Q_i 			: natural range 0 to (2**PACKET_LEN_WIDTH-1);
signal counted		: boolean;

signal ready_sel		: std_logic;

signal packet_len_nat   : natural range 0 to (2**PACKET_LEN_WIDTH-1);

signal m_data_buf		: std_logic_vector(DATA_WIDTH-1 downto 0);
signal m_valid_buf		: std_logic := '0';
signal m_ready_buf		: std_logic := '0';
signal m_last_buf		: std_logic := '0';
signal tx_state_quit_c	: std_logic := '0';
signal Q_i_is_zero		: std_logic := '0';
	
begin




-- Wyjsiowy bufor axis - wewnetrznym interfesme wyjsciowym jest m_..._buf
axis_buf_inst : entity work.axis_buf
	generic map	(
		ADL   => ADL,
		WIDTH => DATA_WIDTH )
	port map (
		clk     => clk,
		rst     => rst,
		s_data  => m_data_buf,
		s_valid => m_valid_buf,
		s_last 	=> m_last_buf,
		s_ready => m_ready_buf,
		m_data  => m_data,
		m_valid => m_valid,
		m_last 	=> m_last,
		m_ready => m_ready );


-- Bezposrednie przekierowanie wejscia na wyjscie 
m_data_buf	 	<= s_data;
m_valid_buf 	<= s_valid when ready_sel = '1' else '0';
s_ready			<= m_ready_buf when ready_sel = '1' else '0';



--
-- Licznik odpowiada tylko za generowanie sygnalu last
--

-- Sterowanie licznikien. Licznik liczy udane pobrania danych ze strony slave
ce_cnt	<= '1' when s_valid = '1' and m_ready_buf = '1' and ready_sel = '1' else '0';


counter_inst: entity work.counter
	Generic map( 	WIDTH 	=> COUNTER_WIDTH,
					ADL		=> ADL)
	PORT map (
		clk 	=> clk,
		sclr 	=> rst_cnt_c,
		ce		=> ce_cnt, -- kazdy odczyt slave to przeslane slowo 
		q 		=> q
	);
Q_i 		<= to_integer(unsigned(q));
Q_i_is_zero <= '1' when Q_i = 0 else '0';

-- Nowy sposob na flage zakoncznia licznia. Gdy przedostania ramka 
-- i sygnal cce wysoko
counted		<= true when (Q_i = packet_len_nat-1) and ce_cnt = '1' else false;

packet_len_nat	<= to_integer(unsigned(packet_len));


last_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		rst_cnt_r		<= '1' after ADL;
	else
		rst_cnt_r		<= '0' after ADL;
		if counted and m_valid_buf = '1' and m_ready_buf = '1' then
--			m_last_buf 	<= '1' after ADL;
			rst_cnt_r		<= '1' after ADL;			
		end if;
		
		if m_last_buf = '1' and m_ready_buf = '1' and m_valid_buf = '1' then
--			m_last_buf 	<= '0' after ADL;
		end if;
	end if;
end if;
end process;
rst_cnt_c <= rst_cnt_r or m_last_buf;

m_last_buf <= '1' when counted else '0';
 
--
--
-- 
fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state	<= IDLE_STATE after ADL;
		ready_sel <= '0' after ADL; -- no  transmit;
	
	else
		case state is
		when IDLE_STATE =>
			if trigger = '1' then
				state		<= TX_STATE after ADL;
				ready_sel 	<= '1' after ADL; -- transmit = m_ready_buf
			end if;
		
		when TX_STATE =>
			if tx_state_quit_c = '1' then
				ready_sel 	<= '0' after ADL; -- no transmit, wait for trigger
				state		<= IDLE_STATE after ADL;						
			end if;
		when others =>
		end case;
	end if;
end if;
end process;

-- quit_tx_state

puls_trig_gen: if TRIG_MODE_PULSE generate
--	tx_state_quit_c <= m_last_buf and m_ready_buf and m_valid_buf and Q_i_is_zero and not ce_cnt;
	tx_state_quit_c <= m_last_buf and m_ready_buf and m_valid_buf;
end generate;
	
level_trig_gen: if not TRIG_MODE_PULSE generate
	signal trigger_fall_e		: std_logic := '0';
begin
	tx_state_quit_c <= (m_last_buf and m_ready_buf and not trigger) or (trigger_fall_e and Q_i_is_zero and not ce_cnt);
	event_det_inst : entity work.event_det
		generic map 	(
			ADL        => ADL,
			EVENT_EDGE => "FALL",
			OUT_REG    => true,
			SIM        => true	)
		port map	(
			clk       => clk,
			sig       => trigger,
			sig_event => trigger_fall_e
		);
end generate;
		



end Behavioral;
