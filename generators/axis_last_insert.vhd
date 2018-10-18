--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_last_insert.vhd
-- Language: VHDL
-- Description: 
--	Module recives regular data and waits for LAST PATTERN 'L':
--	AXIS data:	...<D3><L><D2><D1><D0>...
--
--	Output is the same with L removed and Last signal assrted
--	AXIS data:	...  <D3><D2><D1><D0>...
--						  _____________________
--	AXIS last:	__________|
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;

entity axis_last_insert is
	Generic ( 
		ADL				: time := 0 ps;
		LAST_PATTERN	: std_logic_vector;
		COUNTER_WIDTH	: natural := 4
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
	-- Slave
		s_data		: in std_logic_vector;
		s_valid		: in std_logic;
		s_last		: in std_logic;
		s_ready		: out std_logic;
	-- Master
		m_data		: out std_logic_vector;
		m_valid		: out std_logic;
		m_last		: out std_logic;
		m_ready		: in std_logic    	
    );
end axis_last_insert;
architecture Behav of axis_last_insert is

signal valid1			: std_logic;
signal data1			: std_logic_vector(s_data'range);
signal m_data_buf		: std_logic_vector(s_data'range);
signal m_valid_buf	: std_logic;
signal m_last_buf		: std_logic;
signal m_ready_buf	: std_logic;
signal got_last_pattern	: boolean := false;
signal oe				: std_logic;	
signal rst_cnt			: std_logic;	
signal ce_cnt			: std_logic;
signal val_cnt			: std_logic_vector(COUNTER_WIDTH-1 downto 0);
constant COUNTER_FULL	: std_logic_vector(COUNTER_WIDTH-1 downto 0) := (others => '1');

begin
	
reg_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		valid1	<= '0' after ADL;
	elsif m_ready_buf = '1' and oe = '1' then
		data1	<= s_data after ADL;
		valid1	<= s_valid after ADL;	
	end if;
end if;
end process;


-- out registerred
mout_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		m_valid_buf		<= '0' after ADL;
	elsif m_ready_buf = '1' then
		if oe = '1' then
			m_data_buf		<= data1 after ADL;
			m_valid_buf		<= valid1 after ADL;
			m_last_buf		<= '0' after ADL;	
			if m_last_buf = '1' then
				m_valid_buf		<= '0' after ADL;
			end if;
			if got_last_pattern then
				m_last_buf	<= '1' after ADL;
			end if;
		else
			m_valid_buf		<= '0' after ADL;				
		end if;
	end if;
end if;
end process;

--m_last	<= m_last_to;
	
oe <= '1' when val_cnt = COUNTER_FULL
		else '0' when s_valid = '0'
		else '1';
		
		
counter_inst : entity vhdlbaselib.counter
	generic map	(
		ADL   => ADL,
		WIDTH => COUNTER_WIDTH)
	port map	(
		clk  => clk,
		sclr => rst_cnt,
		ce   => ce_cnt,
		q    => val_cnt
	);
rst_cnt <= '1' when rst = '1'
		else '1' when oe = '1' and m_ready_buf = '1'
		else '0';
ce_cnt <= '1' when s_valid = '0' and m_ready_buf = '1' else '0';


s_ready	<=  m_ready_buf;

got_last_pattern <= true when s_data = LAST_PATTERN and s_valid = '1' else false;


-- Out buf
axis_buf_inst : entity vhdlbaselib.axis_buf
	generic map	(
		ADL   => ADL,
		WIDTH => m_data'length	)
	port map(
		clk     => clk,
		rst     => rst,
		s_data  => m_data_buf,
		s_valid => m_valid_buf,
		s_last  => m_last_buf,
		s_ready => m_ready_buf,
		m_data  => m_data,
		m_valid => m_valid,
		m_last  => m_last,
		m_ready => m_ready
	);

		
end Behav;
