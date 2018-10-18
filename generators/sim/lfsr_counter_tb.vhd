--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: lfsr_counter_tb.vhd
-- Language: VHDL
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY lfsr_counter_tb IS
END lfsr_counter_tb;
 
ARCHITECTURE behavior OF lfsr_counter_tb IS 
 

   --Inputs
   signal rst : std_logic := '0';
   signal clk : std_logic := '0';
   signal seed : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal rand : std_logic_vector(3 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.lfsr_counter PORT MAP (
          rst => rst,
          clk => clk,
          ce => '1',
          dout => rand,
          seed => seed
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin
		rst		<= '1';
		seed	<= "0101";
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		rst		<= '0';
		
      -- insert stimulus here 

      wait;
   end process;

END;
