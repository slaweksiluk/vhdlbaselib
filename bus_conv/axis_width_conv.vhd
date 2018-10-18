--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_width_conv.vhd
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
library vhdlbaselib;
use vhdlbaselib.common_pkg.all;


entity axis_width_conv is
	Generic(ADL					: time		:= 0 ps;
			SLAVE_WIDTH			: natural 	:= 32;
			MASTER_WIDTH		: natural 	:= 8;
			MSB_FIRST			: boolean 	:= true;
			USE_KEEP			: boolean 	:= false
			);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
-- din interface
			s_data	: in std_logic_vector(slave_width-1 downto 0);
			s_keep	: in std_logic_vector(axis_keep_width(slave_width)-1 downto 0);
			s_valid	: in std_logic;
			s_ready	: out std_logic;
-- dout interface
			m_data	: out std_logic_vector (MASTER_WIDTH-1 downto 0);
			m_valid	: out std_logic;
			m_ready	: in std_logic    );
end axis_width_conv;
architecture axis_width_conv_arch of axis_width_conv is

     

signal sclr_c		: std_logic := '0';
signal sclr_c_c		: std_logic := '0';
signal m_ready_buf		: std_logic := '0';
signal m_valid_buf		: std_logic := '0';
signal m_valid_buf_c		: std_logic := '0';
signal m_data_buf		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => '0');
signal m_data_buf_c		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => '0');
signal rst_cnt_c		: std_logic := '1';

signal ce_cnt_c		: std_logic := '0';
signal m_data_r		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => '0');



begin

-- When master width is lower than slave
m_lt_s_gen: if MASTER_WIDTH < SLAVE_WIDTH generate
	-- Wyjscie licznika 3-bitowe, bo sa 4 slowa, a 0 oznacza brak zadnego slowa
	constant SM_RATIO			: positive := SLAVE_WIDTH/MASTER_WIDTH;
	constant KEEP_WIDTH			: positive := axis_keep_width(SLAVE_WIDTH);
	constant WORD_COUNTER_W 	: natural := SM_RATIO-1;	

	signal current_word		: std_logic_vector(WORD_COUNTER_W-1 downto 0);
	signal i				: natural range 0 to 2**WORD_COUNTER_W-1;
	signal s_keep_c			: std_logic_vector(KEEP_WIDTH-1 downto 0) := (others => '0');	
	signal s_keep_c_nat		: natural range 0 to 2**KEEP_WIDTH -1;
begin
	-- s_keep_c to s_keep probkowane gdy valid = 1
	s_keep_c		<= s_keep when s_valid = '1' else (others => '0');
	s_keep_c_nat	<= to_integer(unsigned(s_keep_c));
	

	-- Currenlty max master width is 32 bit
	-- Logika kombinacyjna do przetwarzania s_keep na sygnaly sterujace licznikiem.
	counter_driver: process(s_keep_c_nat, i)
	begin
		--report "KEEP_WIDTH="&positive'image(KEEP_WIDTH);
		case s_keep_c_nat is 
			when 0 =>	
		-- Brak slow licznik czeka
				sclr_c	<= '1';

			when 1 =>
		-- Jedno slowo - licznik nie startuje
				sclr_c	<= '1';
		-- Dwa slowa - kasuj po 1
			when 3 =>
				if i = (2 * SM_RATIO ) / KEEP_WIDTH -1 then
					sclr_c	<= '1';
				else
					sclr_c	<= '0';
				end if;
		-- Trzy slowa - kasuj po 2
			when 7 =>
				if  i =  (3 * SM_RATIO) / KEEP_WIDTH -1 then
					sclr_c	<= '1';
				else
					sclr_c	<= '0';
				end if;
		-- Cztery slowa - kasuj po 3
			when 15 =>
				if  i = (4 * SM_RATIO) / KEEP_WIDTH -1 then
					sclr_c	<= '1';
				else
					sclr_c	<= '0';		
				end if;
		-- Tu nie wchodzi
			when others =>
				sclr_c	<= '1';
		end case;
	end process;
	--  Czyszczenie licznika musi byc powiazane z m_ready, poniewaz 
	--   w przypadku obnizenia m_ready podczas ostatniego slowa
	--   sclr czysci licznik, i wyjscie licznika jest nie poprawne
	sclr_c_c <= '1' when sclr_c = '1' and m_ready_buf = '1' else '0';

	--  s_ready to zawszze sclr, z wyjatkiem syhtuacji gdy nic sie
	--   nie dzieje i modul czeka na dane. Wtedy jest rowne 1.
	--s_ready		<= 	'1' when s_keep = "0000" 
	--				'0' when m_ready_buf = '0'
	--				else sclr_c_c;

	-- Generalnie m_valid = 1 zawsze gdy s_valid != 0. Chodzi to ze dane musza
	--   zostac niezwlocznie odebrane. Jesli nie zostana odebrane natychmiast
	--   to przepddna, bo na nastepnym takcie zegarowym pojawia sie nowe. Mozna
	--   to zrobi przez rejestr, ale wtedy dane tez musialby byc zachowywane w 
	--   rejestrze. Nalezy tez obserwowac czy odbiornik jest gotowy - sygnal
	--   m_ready. 
	ce_cnt_c	<= '0' when s_keep_c_nat = 0 or s_keep_c_nat = 1 or m_ready_buf = '0' else  '1';

	-- Dane wyjsciowe sa wazne, gdy s_valid != 0000 i ...
	-- 7/10/15
	-- s_valid /= "0000" zamienione na rownosci, bo powodowalo bledy w sim.
	m_valid_buf	<= '1' when (s_keep_c_nat = 1 or s_keep_c_nat = 3 or
							s_keep_c_nat = 7 or s_keep_c_nat = 15) and s_valid = '1' else '0';
						
	-- Wyjscie danych zalezy od stanu licznika, ktory zmienia sie synchroniczne
	--   do zegara
	not_rev_gen: if not MSB_FIRST generate
		m_data_buf <= s_data((MASTER_WIDTH*(I+1)-1) downto MASTER_WIDTH*I);
	end generate;
	
	rev_gen: if MSB_FIRST generate
		signal s_data_rev		: std_logic_vector(SLAVE_WIDTH-1 downto 0) := (others => '0');
	begin
		s_data_rev <= reverse_bytes(s_data);
		m_data_buf <= s_data_rev((MASTER_WIDTH*(I+1)-1) downto MASTER_WIDTH*I);
	end generate;
	--I=0:					31							0
	--I=1:					63							32
	--I=2:					95							64
	--I=3:					127							96 
	--dat_proc: process(clk) begin
	--if rising_edge(clk) then
	--	m_data_buf	<= m_data_buf_c after ADL;
	--end if;
	--end process;
	rst_cnt_c <= sclr_c_c or rst;
	-- OUT assigment
	s_ready <= sclr_c_c;
	
		-- Ewntualnie mozna jesxcze zrobic s_valid i s_data jako rejetry, bo sa na wejsciach
	--   ale to kosmetyka
	word_counter_inst: entity vhdlbaselib.counter
		Generic Map(	ADL		=> ADL,
						WIDTH 	=> WORD_COUNTER_W)
		Port Map( 	clk 	=> clk, 
		       		sclr	=> rst_cnt_c,
					ce		=> ce_cnt_c,
					q 		=> current_word);
					
	i	<= to_integer(unsigned(current_word));
	
	-- Output assigment
	m_data	<= m_data_r;
	
end generate;



--------------------------------------------------------------------------------
-- Master grater than slave 
--------------------------------------------------------------------------------
m_gt_s_gen: if MASTER_WIDTH > SLAVE_WIDTH generate
	constant WIDTH_RATIO		: natural := MASTER_WIDTH / SLAVE_WIDTH;
	constant COUNTER_WIDTH		: natural := calc_width(WIDTH_RATIO);
	signal cnt					: std_logic_vector(COUNTER_WIDTH-1 downto 0) := (others => '0');
	signal I					: natural range 0 to WIDTH_RATIO -1;
	signal ce_cnt_r		: std_logic := '0';
	
	
begin
	-- Clear counter every time it reaches MASTER_WIDTH / SLAVE_WIDTH
	rst_cnt_c <= '1' when rst = '1' or 
		(ce_cnt_c = '1' and (I = WIDTH_RATIO -1)) else '0';

	-- Increment counter every time slave ready and slave valid are high
	ce_cnt_c <= '1' when m_ready_buf = '1' and s_valid = '1' else '0';
--	ce_proc: process(clk) begin
--	if rising_edge(clk) then
--		ce_cnt_r <= ce_cnt_c;
--	end if;
--	end process;
	


	data_proc: process(clk) begin
	if rising_edge(clk) then
		if m_ready_buf = '1' then
			-- Data bus connection
			m_data_buf((I+1)*SLAVE_WIDTH-1 downto I*SLAVE_WIDTH) <= s_data after ADL;
			-- master data is valid when counter is reseted
			m_valid_buf <= rst_cnt_c after ADL;	
		end if;	
	end if;
	end process;
	 


	-- s ready path
	s_ready <= m_ready_buf;
	

	
	counter_inst: entity vhdlbaselib.counter
		Generic Map(	ADL		=> ADL,
						WIDTH 	=> COUNTER_WIDTH)
		Port Map( 	clk 	=> clk, 
		       		sclr	=> rst_cnt_c,
					ce		=> ce_cnt_c,
					q 		=> cnt);
	I	<= to_integer(unsigned(cnt));

	-- Reverse data if neccessary
	not_rev_gen: if not MSB_FIRST generate
		m_data	<= m_data_r;
	end generate; 

	rev_gen: if MSB_FIRST generate
		m_data	<= reverse_bytes(m_data_r);
end generate; 

end generate;


--
-- Common stuff independent of bus widths ratio - always generated
--
	-- AXIS BUFFER
	axis_buf_inst : entity vhdlbaselib.axis_buf
		generic map	(
			ADL   => ADL,
			WIDTH => MASTER_WIDTH)
		port map	(
			clk     => clk,
			rst     => rst,
			s_data  => m_data_buf,		-- I INT
			s_valid => m_valid_buf,		-- I INT
			s_last	=> '0',
			s_ready => m_ready_buf,		-- O INT
			m_data  => m_data_r,		-- O TOP
			m_valid => m_valid,			-- O TOP
			m_ready => m_ready			-- I TOP
		);


end axis_width_conv_arch;
