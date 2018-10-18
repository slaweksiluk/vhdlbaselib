-- Testbench created online at:
--   www.doulos.com/knowhow/perl/testbench_creation/
-- Copyright Doulos Ltd
-- SD, 03 November 2002

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

library xil_defaultlib;

entity pulse_sync_tb is
end;

architecture bench of pulse_sync_tb is


  signal clk_src: STD_LOGIC;
  signal sig_src: STD_LOGIC;
  signal clk_dst: STD_LOGIC;
  signal sig_dst: STD_LOGIC;

  constant src_clock_period: time := 9 ns;
  constant dst_clock_period: time := 17 ns;
  constant LDL 				: time := src_clock_period*5;
  signal stop_the_clock: boolean;

begin

  uut: entity xil_defaultlib.pulse_sync port map ( clk_src => clk_src,
                             sig_src => sig_src,
                             clk_dst => clk_dst,
                             sig_dst => sig_dst );

  stimulus: process
  begin
  		sig_src	<= '0';
	wait for LDL;
    -- Put initialisation code here
	report " <<<TEST 1>>> asserting sig_src for one cycle";
	wait until rising_edge(clk_src);
		sig_src		<= '1';
	wait until rising_edge(clk_src);
		sig_src		<= '0';
			
	wait until rising_edge(clk_dst);		
	wait until rising_edge(clk_dst) and sig_dst = '1';
	
	
	
	
	wait for LDL;
    -- Put initialisation code here
	report " <<<TEST 2>>> second sig src pulse";
	wait until rising_edge(clk_src);
		sig_src		<= '1';
	wait until rising_edge(clk_src);
		sig_src		<= '0';
			
	wait until rising_edge(clk_dst);		
	wait until rising_edge(clk_dst) and sig_dst = '1';	
	
	
	
			
	wait for LDL;
    stop_the_clock <= true;
    assert false report " <<<SUCCESS>> " severity failure;

    wait;
  end process;

  clocking_src: process
  begin
    while not stop_the_clock loop
      clk_src <= '0', '1' after src_clock_period / 2;
      wait for src_clock_period;
    end loop;
    wait;
  end process;

  clocking_dst: process
  begin
    while not stop_the_clock loop
      clk_dst <= '0', '1' after dst_clock_period / 2;
      wait for dst_clock_period;
    end loop;
    wait;
  end process;
end;