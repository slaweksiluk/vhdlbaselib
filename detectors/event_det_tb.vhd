library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity event_det_tb is
end entity;

architecture bench of event_det_tb is

	component event_det is
		generic
		(
			EVENT_EDGE : string := "BOTH";
			OUT_REG		: boolean := true
		);
		port
		(
			clk : in std_logic;
			sig : in std_logic;
			sig_event : out std_logic
		);
	end component;

	shared variable EVENT_EDGE : string(1 to 4) := "BOTH";
	signal OUT_REG : boolean := true;
	signal clk : std_logic;
	signal sig : std_logic;
	signal sig_event : std_logic;

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD * 0;
	
begin

	uut : event_det
		generic map
		(
			EVENT_EDGE => EVENT_EDGE,
			OUT_REG => OUT_REG
		)
		port map
		(
			clk       => clk,
			sig       => sig,
			sig_event => sig_event
		);

	stimulus : process begin
			sig		<= '1';
		wait for LDL;
		wait until rising_edge(clk);
			sig		<= '0';
		wait until rising_edge(clk) and sig_event = '1';
		report " BOTH OK";
		
		wait for LDL;
		EVENT_EDGE := "RISE";
		wait until rising_edge(clk);
			sig		<= '1';
		wait until rising_edge(clk) and sig_event = '1';
		report " RISE OK";

		wait for LDL;
		EVENT_EDGE := "FALL";
		wait until rising_edge(clk);
			sig		<= '0';
		wait until rising_edge(clk) and sig_event = '1';
		report " FALL OK";

		wait for LDL;
		EVENT_EDGE := "BOTH";
		OUT_REG <= false;
		wait until rising_edge(clk);
			sig		<= '1';
		wait until sig_event = '1';
		report " Not registered output ok";

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

