library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prbs_chk_tb is
end entity;

architecture bench of prbs_chk_tb is


	constant WIDTH : natural := 32;
	constant ERR_CNT_WIDTH : natural := 4;
	signal clk : std_logic;
	signal rst : std_logic;
	signal seed : std_logic_vector(WIDTH-1 downto 0);
	signal s_data : std_logic_vector(WIDTH-1 downto 0);
	signal s_valid : std_logic;
	signal s_ready : std_logic;

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
begin

	uut : entity work.prbs_chk
		generic map
		(
			WIDTH         => WIDTH,
			ERR_CNT_WIDTH => ERR_CNT_WIDTH
		)
		port map
		(
			clk     => clk,
			rst     => rst,
			seed    => seed,
			s_data  => s_data,
			s_valid => s_valid,
			s_ready => s_ready
		);

	stimulus : process
	begin
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

