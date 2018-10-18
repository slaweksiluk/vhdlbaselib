library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prbs_top_tb is
end entity;

architecture bench of prbs_top_tb is
	constant WIDTH : natural := 32;
	constant ERR_CNT_WIDTH : natural := 32;
	
	component prbs_top is
--		generic
--		(
--			ADL : time := 0 ps;
--			WIDTH : natural := 32;
--			ERR_CNT_WIDTH : natural := 4
--		);
		port
		(
			clk : in std_logic;
			rst : in std_logic;
			trig : in std_logic;
			inject_err : in std_logic;
			sync : out std_logic;
			err_cnt : out std_logic_vector(WIDTH-1 downto 0)
		);
	end component;


	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal trig : std_logic := '1';
	signal inject_err : std_logic := '0';
	signal sync : std_logic := '0';
	signal err_cnt : std_logic_vector(WIDTH-1 downto 0);

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
--	constant ADL	: time := CLK_PERIOD / 5;
	constant ADL	: time := 0 ps;

		
	constant zeros	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
begin

	uut : prbs_top
--		generic map
--		(
--			ADL           => ADL,
--			WIDTH         => WIDTH,
--			ERR_CNT_WIDTH => ERR_CNT_WIDTH
--		)
		port map
		(
			clk        => clk,
			rst        => rst,
			trig       => trig,
			inject_err => inject_err,
			sync       => sync,
			err_cnt    => err_cnt
		);

	stimulus : process	begin
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0' after ADL;
	
	wait for LDL;
	wait until rising_edge(clk) and sync = '1';
	assert err_cnt = zeros
	 report " <<<FAILURE>>> err cnty not zero"
	 severity failure;
	 
	wait until rising_edge(clk);
		inject_err		<= '1' after ADL;
	wait until rising_edge(clk);
		inject_err		<= '0' after ADL;
	wait for LDL;
	wait until rising_edge(clk);
	wait until rising_edge(clk);
	assert err_cnt(0) = '1' 
	 report " <<<FAILURE>>>  err cnt not 1"
	 severity failure;	
		
		
		
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

