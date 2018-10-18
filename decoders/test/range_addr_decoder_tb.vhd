library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity range_addr_decoder_tb is
--generic (
--	runner_cfg : string
--);
end entity;

architecture bench of range_addr_decoder_tb is

	constant TARGETS_NUM : positive := 2;
	constant TARGETS_ADDR : std_logic_vector := x"00000000";
	signal addr : std_logic_vector(32-1 downto 0);
	signal sel : natural range 0 to TARGETS_NUM-1;

	constant stop_clock : boolean := false;
begin

	uut : entity work.range_addr_decoder
		generic map
		(
			TARGETS_NUM  => TARGETS_NUM,
			TARGETS_ADDR => TARGETS_ADDR
		)
		port map
		(
			addr => addr,
			sel  => sel
		);

	stimulus : process
	begin
	wait for 10 ns;
	assert false
	 report " <<<SUCCESS>>> "
	 severity failure;
	wait;
	end process;

end architecture;

