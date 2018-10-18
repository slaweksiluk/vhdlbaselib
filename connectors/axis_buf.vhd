--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_buf.vhd
-- Language: VHDL
-- Description: 
-- 	
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 29.06.16 0.02 - Added LAST support
-- 
-- TODO
-- * m_valid will never be asserte when s_valid is asserted without m_ready. The
--	proper behaviour would be to add additinal condidiotnons to propagate s_valid
--	signal
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

--library xil_defaultlib;
library vhdlbaselib;

entity axis_buf is
	Generic ( 
		ADL		: time := 0 ps;
		WIDTH	: natural	:= 128
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
	-- Slave
		s_data		: in std_logic_vector(WIDTH-1 downto 0);
		s_valid		: in std_logic;
		s_last		: in std_logic;
		s_ready		: out std_logic;
	-- Master
		m_data		: out std_logic_vector(WIDTH-1 downto 0);
		m_valid		: out std_logic;
		m_last		: out std_logic;
		m_ready		: in std_logic
    );
end axis_buf;

architecture Behavioral2 of axis_buf is

signal m_ready_rise_e	: std_logic := '0';
signal m_ready_fall_e	: std_logic := '0';

signal buf_valid_r		: std_logic := '0';
signal m_data_r			: std_logic_vector(WIDTH-1 downto 0) := (others => 'U');
signal m_valid_r		: std_logic := '0';
signal m_ready_r		: std_logic := '0';
signal buf_r			: std_logic_vector(WIDTH-1 downto 0) := (others => 'U');

signal m_last_r			: std_logic := '0';
signal buf_last_r		: std_logic := '0';

signal buf_valid_value_r		: std_logic;
signal s_data_r		: std_logic_vector(s_data'range);
signal s_valid_r		: std_logic;
signal s_last_r		: std_logic;

begin

m_dat_o_proc: process(clk) begin
if rising_edge(clk) then
--	if m_ready = '1' and s_valid_r = '1' then
	if m_ready = '1' then
		if m_ready_rise_e = '1' and buf_valid_r = '1' then
			m_data_r	<= buf_r after ADL;
			m_last_r	<= buf_last_r after ADL;
			m_valid_r	<= buf_valid_value_r after ADL;
		else
			m_data_r	<= s_data after ADL;
			m_last_r	<= s_last after ADL;
			m_valid_r	<= s_valid after ADL;	
		end if;
	end if;
end if;
end process;
-- OUT
m_data 	<= m_data_r;
m_last	<= m_last_r;
m_valid	<= m_valid_r;


buf_proc: process(clk) begin
if rising_edge(clk) then
	if m_ready_fall_e = '1' then
		buf_r 		<= s_data after ADL; 
		buf_last_r	<= s_last after ADL;
		buf_valid_value_r <= s_valid after ADL;
	end if;
end if;
end process;



-- Przekazuj s_ready z opoznieniem
rdy_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		s_ready		<= '0' after ADL;
		m_ready_r	<= '0' after ADL;
	else
		s_ready		<= m_ready after ADL;	
		m_ready_r	<= m_ready after ADL;	
	end if;
end if;
end process;	




--
-- BUF VALID
--
-- Trzeba jakos rozposnoac czy dane w bufora sa akurat wazne.
-- Staja sie wazne gdy: obnizenie m_ready iii s_valid = '1' iii nie takie same?
-- Przestaja byc wazne gdy: podwyzszenie m_ready
buf_valid_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		buf_valid_r		<= '0' after ADL;
	else
		if (m_ready_fall_e = '1' and s_valid = '1')  then
			buf_valid_r	<= '1' after ADL;
		elsif m_ready_rise_e = '1' then
			buf_valid_r	<= '0' after ADL;
		end if;
	end if;
end if;
end process;	


valid_proc: process(clk) begin
if rising_edge(clk) then
	if m_ready_r = '1' then
		s_valid_r	<= s_valid after ADL;
		s_data_r	<= s_data after ADL;
		s_last_r	<= s_last after ADL;		
	end if;
end if;
end process;

	


-- Wykrycie zmiany w gore
mrdy_rise_event_det_inst : entity vhdlbaselib.event_det
	generic map	(
		ADL			=> ADL,
		EVENT_EDGE => "RISE",
		OUT_REG    => false	)
	port map	(
		clk       => clk,
		sig       => m_ready,
		sig_event => m_ready_rise_e	);
	
-- Wykrycie zmiany w dol
mrdy_fall_event_det_inst : entity vhdlbaselib.event_det
	generic map	(
		ADL			=> ADL,
		EVENT_EDGE => "FALL",
		OUT_REG    => false	)
	port map	(
		clk       => clk,
		sig       => m_ready,
		sig_event => m_ready_fall_e	);	
	
end Behavioral2;

architecture Behavioral1 of axis_buf is

signal m_ready_rise_e	: std_logic := '0';
signal m_ready_fall_e	: std_logic := '0';

signal buf_valid_r		: std_logic := '0';
signal m_data_r			: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
signal m_valid_r		: std_logic := '0';
signal m_ready_r		: std_logic := '0';
signal buf_r			: std_logic_vector(WIDTH-1 downto 0) := (others => '0');

signal m_last_r			: std_logic := '0';
signal buf_last_r		: std_logic := '0';


begin

m_dat_o_proc_proc: process(clk) begin
if rising_edge(clk) then
	if m_ready = '1' then
		if m_ready_rise_e = '1' and buf_valid_r = '1' then
			m_data_r	<= buf_r after ADL;
			m_last_r	<= buf_last_r after ADL;
		else
			m_data_r	<= s_data after ADL;
			m_last_r	<= s_last after ADL;	
		end if;
	end if;
end if;
end process;
-- OUT
m_data 	<= m_data_r;
m_last	<= m_last_r;


buf_proc: process(clk) begin
if rising_edge(clk) then
	if m_ready_fall_e = '1' then
		buf_r 		<= s_data after ADL; 
		buf_last_r	<= s_last after ADL;
	end if;
end if;
end process;



-- Przekazuj s_ready z opoznieniem
rdy_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		s_ready		<= '0' after ADL;
		m_ready_r	<= '0' after ADL;
	else
		s_ready		<= m_ready after ADL;	
		m_ready_r	<= m_ready after ADL;	
	end if;
end if;
end process;	



val_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		m_valid_r		<= '0' after ADL;
	elsif m_ready = '1' then
		-- Gdy oprozniany jest bufor i jest waznty valid zawsze !
		if m_ready_rise_e = '1' and buf_valid_r = '1' then
			m_valid_r		<= '1' after ADL;
		elsif m_ready_r = '1' then
			m_valid_r		<= s_valid after ADL;
		else
			m_valid_r		<= '0' after ADL;
		end if;
	end if;
end if;
end process;
-- OUT
m_valid <= m_valid_r;

	
--
-- BUF VALID
--
-- Trzeba jakos rozposnoac czy dane w bufora sa akurat wazne.
-- Staja sie wazne gdy: obnizenie m_ready iii s_valid = '1' iii nie takie same?
-- Przestaja byc wazne gdy: podwyzszenie m_ready
buf_valid_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		buf_valid_r		<= '0' after ADL;
	else
		if (m_ready_fall_e = '1' and s_valid = '1')  then
			buf_valid_r	<= '1' after ADL;
		elsif m_ready_rise_e = '1' then
			buf_valid_r	<= '0' after ADL;
		end if;
	end if;
end if;
end process;	




-- Wykrycie zmiany w gore
mrdy_rise_event_det_inst : entity vhdlbaselib.event_det
	generic map	(
		ADL			=> ADL,
		EVENT_EDGE => "RISE",
		OUT_REG    => false	)
	port map	(
		clk       => clk,
		sig       => m_ready,
		sig_event => m_ready_rise_e	);
	
-- Wykrycie zmiany w dol
mrdy_fall_event_det_inst : entity vhdlbaselib.event_det
	generic map	(
		ADL			=> ADL,
		EVENT_EDGE => "FALL",
		OUT_REG    => false	)
	port map	(
		clk       => clk,
		sig       => m_ready,
		sig_event => m_ready_fall_e	);	
end Behavioral1;

