library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_cnt_gen_tb is
end entity;

architecture bench of axis_cnt_gen_tb is

	component axis_cnt_gen is
		generic
		(
			DATA_WIDTH : natural
		);
		port
		(
			clk : in std_logic;
			rst : in std_logic;
			m_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
			m_valid : out std_logic;
			m_ready : in std_logic
		);
	end component;

	constant DATA_WIDTH : natural := 8;
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal m_data : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal m_valid : std_logic ;
	signal m_ready : std_logic := '1';

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
					
begin

	uut : axis_cnt_gen
		generic map
		(
			DATA_WIDTH => DATA_WIDTH
		)
		port map
		(
			clk     => clk,
			rst     => rst,
			m_data  => m_data,
			m_valid => m_valid,
			m_ready => m_ready
		);

	stimulus : process 	begin
		
	wait for LDL;
		wait until rising_edge(clk);
		rst		<= '0';
		
	wait for LDL;
		wait until rising_edge(clk);
		rst		<= '1';
	
	wait for LDL;
		wait until rising_edge(clk);	
		rst		<= '0';
		

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

