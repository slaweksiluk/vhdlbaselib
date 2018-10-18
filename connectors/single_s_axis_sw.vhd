--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: single_s_axis_sw.vhd
-- Language: VHDL
-- Description: 
-- Module is switching signle AXIS slave interface to multiple AXIS master
-- interface. m_data is contacanated vectors of multiple MASTERS. Its organized
-- like that: MSB[... ,MASTER2, MASTER1, MASTER0]LSB. master_sel represents 
-- bin encoded number of choosen master interface: m0="00", m1="10", m2="10", ...
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--  
-- Revision 0.02 20/01/16 - File updated
-- Additional Comments:
-- Finished and tested with tb. AXIS master and slave ready signals are connected
-- directly. "On the fly" master swicthing is not supported. AXIS slave valid
-- signal has to be deasserted before master_sel i changed. 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;
library vhdlbaselib;
use vhdlbaselib.common_pkg.all;


entity single_s_axis_sw is
	Generic ( 
		ADL			: time		:= 0 ps;
		MASTERS		: natural 	:= 2;
		WIDTH		: natural 	:= 8
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
    	-- Slave interface
    	s_data	: in std_logic_vector(WIDTH-1 downto 0);
    	s_valid	: in std_logic;
    	s_last	: in std_logic;
    	s_ready	: out std_logic;
    	
	    -- Master interface
    	m_data	: out std_logic_vector(MASTERS*WIDTH-1 downto 0);
    	m_valid	: out std_logic_vector(MASTERS-1 downto 0);
		m_last	: out std_logic_vector(MASTERS-1 downto 0);
    	m_ready	: in std_logic_vector(MASTERS-1 downto 0);
    	
    	-- Select master signal
    	master_sel	: in std_logic_vector(calc_width(MASTERS-1)-1 downto 0)
    );
end single_s_axis_sw;
architecture single_s_axis_sw_arch of single_s_axis_sw is


--signal s_data_c			: std_logic_vector(MASTERS*WIDTH-1 downto 0) := (others => '0');
--signal s_data_r			: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
--signal s_valid_c		: std_logic_vector(MASTERS-1 downto 0) := (others => '0');
--signal s_valid_r		: std_logic := '0';
--signal m_ready_r		: std_logic_vector(MASTERS-1 downto 0) := (others => '0');
--signal m_ready_c		: std_logic_vector(MASTERS-1 downto 0) := (others => '0');
--signal m_valid_c		: std_logic_vector(MASTERS-1 downto 0) := (others => '0');
signal master_sel_nat	: natural range 0 to 2**MASTERS-1;
signal master_sel_r		: std_logic_vector(calc_width(MASTERS-1)-1 downto 0);
--signal m_data_c			: std_logic_vector(MASTERS*WIDTH-1 downto 0) := (others => '0');
--signal s_ready_c		: std_logic := '0';

begin



-- Switching calculation
--data_proc: process(master_sel_nat, s_data_r) begin
--	m_data_c		<= (others => '0');
--	m_data_c((master_sel_nat+1) * WIDTH-1 downto (master_sel_nat * WIDTH)) <= s_data_r;
--end process;

--valid_proc: process(master_sel_nat, s_valid_r) begin
--	m_valid_c					<= (others => '0');
--	m_valid_c(master_sel_nat) 	<= s_valid_r;
--end process;

-- s_ready has to bo cnnected to m_ready without registering to prevent data
-- loosing
s_ready		<= m_ready(master_sel_nat);
--s_ready 	<= s_ready_c;

-- Register master outputs
master_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		m_valid	<= (others => '0') after ADL;
	elsif m_ready(master_sel_nat) = '1' then
		m_data	<= (others => '0') after ADL;
		m_data((master_sel_nat+1) * WIDTH-1 downto (master_sel_nat * WIDTH)) <= s_data after ADL;
		m_valid	<= (others => '0') after ADL;
		m_valid(master_sel_nat)	<= s_valid  after ADL;
		m_last	<= (others => '0') after ADL;
		m_last(master_sel_nat)	<= s_last  after ADL;
	end if;
end if;
end process;

--m_ready_proc: process(clk) begin
--if rising_edge(clk) then
--	m_ready_r	<= m_ready after ADL;
--end if;
--end process;



---- Register slave iputs
--slave_proc: process(clk) begin
--if rising_edge(clk) then
--	if m_ready(master_sel_nat) = '1' then
--		s_data_r	<= s_data after ADL;
--		s_valid_r	<= s_valid after ADL;
--	end if;
--end if;
--end process;

m_sel_proc: process(clk) begin
if rising_edge(clk) then
	-- Conversion
	master_sel_r	<= master_sel  after ADL;
end if;
end process;

	master_sel_nat	<= to_integer(unsigned(master_sel_r));

end single_s_axis_sw_arch;	
