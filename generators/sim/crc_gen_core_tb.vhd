-- Testbench created online at:
--   www.doulos.com/knowhow/perl/testbench_creation/
-- Copyright Doulos Ltd
-- SD, 03 November 2002

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

library work;
use work.common_pkg.all;

entity crc_tb is
end;

architecture bench of crc_tb is

  constant DATA_WIDTH	: natural := 1;
  constant CRC_WIDTH	: natural := 16;

  signal data_in: std_logic_vector (DATA_WIDTH-1 downto 0);
  signal data_valid: std_logic;
  signal crc_en , rst, clk: std_logic;
  signal crc_out: std_logic_vector (15 downto 0);
  signal crc_out_rev: std_logic_vector (15 downto 0);

  constant clock_period: time := 10 ns;
  constant LDL: time := 10 * clock_period;
  constant ADL: time := clock_period/5;

  signal stop_the_clock: boolean;

begin

  crc_out_rev		<= reverse_any_vector(crc_out);

  uut: entity work.crc_gen
  generic  map ( ADL => ADL)
  port map (  data_in => data_in,
			  data_valid => data_valid,
			  crc_en  => crc_en,
			  rst     => rst,
			  clk     => clk,
			  crc_out => crc_out );

  stimulus: process
  begin

	-- Put initialisation code here
		rst			<= '1';
		crc_en		<= '1';
		data_in(0)	<= '0';
		data_valid	<= '1';
		
		


	wait for LDL;
	-- Put test bench stimulus code here
	-- Test z zerami. Oczekiwany wynik: 1d0f
	wait until rising_edge(clk);
		rst			<= '0' after ADL;
	-- Czekaj 16 taktow na przejscie przez CRC
	for I in 1 to 16 loop
		wait until rising_edge(clk);
	end loop;
		data_valid	<= '0' after ADL;
		crc_en		<= '1' after ADL;
		
	-- Czekaj 16 taktow na zapisanie koncowego CRC
	for I in 1 to 18 loop
		wait until rising_edge(clk);
	end loop;
		
    stop_the_clock <= true;
    wait for LDL;
	wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;
