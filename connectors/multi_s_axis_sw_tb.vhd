--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: multi_s_axis_sw_tb.vhd
-- Language: VHDL
-- Description: 
-- slave1 - (15 downto 8) is tested withour m ready deasserting (TEST1) slave0
-- (7..0) is tested with one m_ready deassertion after third data word (TEST2)
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library xil_defaultlib;
use work.common_pkg.all;

entity multi_s_axis_sw_tb is
end entity;

architecture bench of multi_s_axis_sw_tb is

	component multi_s_axis_sw is
		generic
		(
			SLAVES : natural := 2;
			WIDTH : natural := 8
		);
		port
		(
			clk : in std_logic;
			rst : in std_logic;
			s_data : in std_logic_vector(SLAVES*WIDTH-1 downto 0);
			s_valid : in std_logic_vector(SLAVES-1 downto 0);
			s_ready : out std_logic_vector(SLAVES-1 downto 0);
			m_data : out std_logic_vector(WIDTH-1 downto 0);
			m_valid : out std_logic;
			m_ready : in std_logic;
			slave_sel : in std_logic_vector(calc_width(SLAVES-1)-1 downto 0)
		);
	end component;

	constant SLAVES : natural := 2;
	constant WIDTH : natural := 8;
	constant LOOP_LEN	: natural := 8;
	
	signal clk : std_logic;
	signal rst : std_logic;
	signal s_data : std_logic_vector(SLAVES*WIDTH-1 downto 0);
	signal s_valid : std_logic_vector(SLAVES-1 downto 0);
	signal s_ready : std_logic_vector(SLAVES-1 downto 0);
	signal m_data : std_logic_vector(WIDTH-1 downto 0);
	signal m_valid : std_logic;
	signal m_ready : std_logic;
	signal slave_sel : std_logic_vector(calc_width(SLAVES-1)-1 downto 0);
--	signal s_data1		: std_logic_vector(WIDTH-1 downto 0);
	signal s_data_nat	: natural;
	signal s_data0_nat	: natural;	
	signal m_data0		: natural;
	
	
--	signal s_data		: natural range 0 to;
	
	
	

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;


begin

	uut : multi_s_axis_sw
		generic map
		(
			SLAVES => SLAVES,
			WIDTH  => WIDTH
		)
		port map
		(
			clk       => clk,
			rst       => rst,
			s_data    => s_data,
			s_valid   => s_valid,
			s_ready   => s_ready,
			m_data    => m_data,
			m_valid   => m_valid,
			m_ready   => m_ready,
			slave_sel => slave_sel
		);

stimulus_slave : process begin
		s_data_nat		<= 0;
		s_valid		<= "00";
		slave_sel	<= "1";
--
-- TEST 1
--
	wait for LDL;
	report " <<<SLAVE>>> TEST1 - SLAVE1 (15..8) )without deasserting m_ready";
	report " <<<SLAVE>>> Switching to slave 1";
	wait until rising_edge(clk);
		slave_sel	<= "1";
	for I in 1 to LOOP_LEN loop
		wait until rising_edge(clk) and s_ready(1) = '1';
			s_valid(1)		<= '1';			
			s_data_nat			<= s_data_nat + 1;
	end loop;	
	wait until rising_edge(clk) and s_ready(1) = '1';
		s_data_nat	<= 0;
		s_valid(1)	<= '0';

--
-- TEST 2
--
	wait for LDL;
	report " <<<SLAVE>>> TEST1 - SLAVE1 (15..8) )without deasserting m_ready";
	report " <<<SLAVE>>> Switching to slave 1";
	wait until rising_edge(clk);
		slave_sel	<= "1";
	for I in 1 to LOOP_LEN loop
		wait until rising_edge(clk) and s_ready(1) = '1';
			s_valid(1)		<= '1';			
			s_data_nat			<= s_data_nat + 1;
	end loop;	
	wait until rising_edge(clk) and s_ready(1) = '1';
		s_data_nat	<= 0;
		s_valid(1)	<= '0';		
		
--
-- TEST 3
--
	wait for LDL;
	report " <<<SLAVE>>> TEST2 - SLAVE0 (7..0) ) with deasserting m_ready";
	report " <<<SLAVE>>> Switching to slave 0";
	wait until rising_edge(clk);
		slave_sel	<= "0";
	for I in 1 to LOOP_LEN loop
		wait until rising_edge(clk) and s_ready(0) = '1';
			s_valid(0)		<= '1';			
			s_data0_nat			<= s_data0_nat + 1;
	end loop;	
	wait until rising_edge(clk) and s_ready(0) = '1';
		s_data0_nat	<= 0;
		s_valid(0)	<= '0';		
		
		
	wait;
end process;

-- Conversion s_data to std_logic_vector
s_data(15  downto 8)	<= std_logic_vector(to_unsigned(s_data_nat, WIDTH));
s_data(7 downto 0)		<= std_logic_vector(to_unsigned(s_data0_nat, WIDTH));
	

-- Converts m_data to nat for easy comparison
m_data0	<= to_integer(unsigned(m_data));


verify_master : process begin
--
-- TEST 1
--
		m_ready		<= '1';
	wait for LDL;
	wait until rising_edge(clk);
		m_ready		<= '1';
	
	report "   <<<MASTER>>> TEST 1: verify master. m_ready high from sim start";
	for I in 1 to LOOP_LEN loop
		wait until rising_edge(clk) and m_valid='1';
		assert m_data0 = I
		 report " <<<FAILURE>>> TEST1: m_data not matching on index " & 
		 													integer'image(I)
		 severity failure;
	end loop;
	wait until rising_edge(clk);
		m_ready		<= '0';
	

--
-- TEST 2
--
	wait for LDL;
		m_ready		<= '0';
	wait for LDL;
	wait until rising_edge(clk);
		m_ready		<= '1';
	
	report "   <<<MASTER>>> TEST 1: verify master";
	for I in 1 to LOOP_LEN loop
		wait until rising_edge(clk) and m_valid='1';
		assert m_data0 = I
		 report " <<<FAILURE>>> TEST1: m_data not matching on index " & 
		 													integer'image(I)
		 severity failure;
	end loop;
	wait until rising_edge(clk);
		m_ready		<= '0';	
	
--
-- TEST 3
--
		m_ready		<= '0';
	wait for LDL;
	wait until rising_edge(clk);
		m_ready		<= '1';
	
	report "   <<<MASTER>>> TEST2: verify master with m_ready deasserting";
	for I in 1 to LOOP_LEN loop
		wait until rising_edge(clk) and m_valid='1';
		assert m_data0 = I
		 report " <<<FAILURE>>> TEST2: m_data not matching on index " & 
		 													integer'image(I)
		 severity failure;
		 -- READY LOW
		 if I = 3 then
	 		m_ready	<= '0';
		 	wait for LDL/3;
		 	wait until rising_edge(clk);
		 	m_ready	<= '1';
		 end if;			 
	end loop;
	wait until rising_edge(clk);
		m_ready		<= '0';



	wait for LDL;
	assert false
	 report " <<<SUCCESS>>> "
	 severity failure;
	wait;
end process;

	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

