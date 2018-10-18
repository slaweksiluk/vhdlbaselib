--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: multi_s_axis_sw.vhd
-- Language: VHDL
-- Description: 
-- Module is switching multiple AXIS slave interface to one AXIS master
-- interface. s_data is contacanated vectors of multiple slaves. Its organized
-- like that: MSB[..., SLAVE2, SLAVE1, SLAVE0 ]LSB.
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Non-registered (direct) m_ready - s_ready connection
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library vhdlbaselib;
use vhdlbaselib.common_pkg.all;


entity multi_s_axis_sw is
	Generic ( 
		ADL			: time 		:= 0 ps;
		SLAVES		: natural 	:= 2;
		WIDTH		: natural 	:= 8
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
    	-- Slave interface
    	s_data	: in std_logic_vector(SLAVES*WIDTH-1 downto 0);
    	s_keep	: in std_logic_vector(SLAVES*(WIDTH/8)-1 downto 0);
    	s_valid	: in std_logic_vector(SLAVES-1 downto 0);
    	s_last	: in std_logic_vector(SLAVES-1 downto 0);
    	s_ready	: out std_logic_vector(SLAVES-1 downto 0);
    	
    	-- Master interface
    	m_data	: out std_logic_vector(WIDTH-1 downto 0);
    	m_keep	: out std_logic_vector(WIDTH/8-1 downto 0);
    	m_valid	: out std_logic;
    	m_last	: out std_logic;
    	m_ready	: in std_logic;
    	
    	-- Select slave signal
    	slave_sel	: in std_logic_vector(calc_width(SLAVES-1)-1 downto 0)
    );
end multi_s_axis_sw;
architecture multi_s_axis_sw_arch of multi_s_axis_sw is


signal m_data_c			: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
signal m_keep_c			: std_logic_vector(WIDTH/8-1 downto 0) := (others => '0');
signal m_valid_c		: std_logic := '0';
signal m_last_c			: std_logic := '0';
signal s_ready_c		: std_logic_vector(SLAVES-1 downto 0) := (others => '0');
signal slave_sel_nat	: natural range 0 to SLAVES-1;

begin



-- Switching calculation
data_proc: process(s_data, s_keep, slave_sel_nat, s_last) begin
	m_data_c		<= (others => '0');		
	m_data_c 		<= s_data((slave_sel_nat+1) * WIDTH-1 downto (slave_sel_nat * WIDTH));
	m_keep_c		<= (others => '0');
	m_keep_c 		<= s_keep((slave_sel_nat+1) * (WIDTH/8)-1 downto (slave_sel_nat * (WIDTH/8)));
	m_last_c		<= '0';
	m_last_c		<= s_last(slave_sel_nat);
end process;

-- Valid assigment
m_valid_c 	<= s_valid(slave_sel_nat);


 -- Ready assigment
ready_proc: process(m_ready, slave_sel_nat) begin
	s_ready_c					<= (others => '0');
	s_ready_c(slave_sel_nat)	<= m_ready;
end process;
s_ready						<= s_ready_c;

-- Register outputs
out_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		m_valid		<= '0' after ADL;
	elsif m_ready = '1' then
		m_data	<= m_data_c after ADL;
		m_keep	<= m_keep_c after ADL;
		m_valid	<= m_valid_c after ADL;
		m_last	<= m_last_c after ADL;
	end if;
end if;
end process;

sel_proc: process(clk) begin
if rising_edge(clk) then
	slave_sel_nat	<= to_integer(unsigned(slave_sel)) after ADL;
end if;
end process;



end multi_s_axis_sw_arch;	
