library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity crc_gen_tb is
end entity;

architecture bench of crc_gen_tb is

	component crc_gen is
		generic
		(
			ADL		: time 	:= 500 ps;
			SLAVE_WIDTH : natural := 8;
			MASTER_WIDTH : natural := 16
		);
		port
		(
			clk : in std_logic;
			rst : in std_logic;
			s_data : in std_logic_vector (SLAVE_WIDTH-1 downto 0);
			s_valid : in std_logic;
			s_last : in std_logic;
			s_ready : out std_logic;
			m_data : out std_logic_vector (MASTER_WIDTH-1 downto 0);
			m_valid : out std_logic;
			m_ready : in std_logic
		);
	end component;

	constant SLAVE_WIDTH : natural := 8;
	constant MASTER_WIDTH : natural := 16;
	signal clk : std_logic;
	signal rst : std_logic;
	signal s_data : std_logic_vector (SLAVE_WIDTH-1 downto 0);
	signal s_valid : std_logic;
	signal s_last : std_logic;
	signal s_ready : std_logic;
	signal m_data : std_logic_vector (MASTER_WIDTH-1 downto 0);
	signal m_valid : std_logic;
	signal m_ready : std_logic;

	constant CLK_PERIOD : time := 10 ns;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
	constant stop_clock : boolean := false;
begin

	uut : crc_gen
		generic map
		(
			ADL => ADL,
			SLAVE_WIDTH  => SLAVE_WIDTH,
			MASTER_WIDTH => MASTER_WIDTH
		)
		port map
		(
			clk     => clk,
			rst     => rst,
			s_data  => s_data,
			s_valid => s_valid,
			s_last  => s_last,
			s_ready => s_ready,
			m_data  => m_data,
			m_valid => m_valid,
			m_ready => m_ready
		);

	stimulus : process begin
			rst		<= '1' after ADL;
			s_data	<= (others => '0') after ADL;
			s_valid	<= '0' after ADL;
			s_last	<= '0' after ADL;
			m_ready	<= '0' after ADL;
		
		wait for LDL;	
		wait until rising_edge(clk);
			rst	<= '0' after ADL;
			
			
		-- Toggle s_valid
		wait for LDL;
		wait until rising_edge(clk);
			s_valid	<= '1' after ADL;
		wait for LDL;
		wait until rising_edge(clk);
			s_valid	<= '0' after ADL;
		wait for LDL;
		wait until rising_edge(clk);
			s_valid	<= '1' after ADL;			
			
		
		wait for LDL;
		wait until rising_edge(clk);
			s_last	<= '1' after ADL;
		wait until rising_edge(clk);
			s_last	<= '0' after ADL;
			s_valid	<= '0' after ADL;
			
		
		
		-- Toggle m_ready
		wait for LDL;
		wait until rising_edge(clk);
			m_ready	<= '1' after ADL;
		wait until rising_edge(clk);
			
		wait for LDL;
		assert false report " <<< SUCCESS >>> " severity failure;
		
				
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

