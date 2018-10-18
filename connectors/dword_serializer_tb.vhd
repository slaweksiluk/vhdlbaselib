-- Testbench created online at:
--   www.doulos.com/knowhow/perl/testbench_creation/
-- Copyright Doulos Ltd
-- SD, 03 November 2002
library xil_defaultlib;
--use xil_defaultlib.pcie_pkg.all;



library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;



entity dword_serializer_tb is
end;

architecture bench of dword_serializer_tb is



  signal clk: STD_LOGIC;
  signal rst: STD_LOGIC;
  signal s_data: STD_LOGIC_VECTOR (127 downto 0);
  signal s_valid: STD_LOGIC_VECTOR(3 downto 0);
  signal s_ready: STD_LOGIC;
  signal m_data: STD_LOGIC_VECTOR (31 downto 0);
  signal m_valid: STD_LOGIC;
  signal m_ready: STD_LOGIC;


-- Stale do testow
  constant PATTERN1	: std_logic_vector(31 downto 0) := x"da7a1111";
  constant PATTERN2	: std_logic_vector(31 downto 0) := x"da7a2222";
  constant PATTERN3	: std_logic_vector(31 downto 0) := x"da7a3333";
  constant PATTERN4	: std_logic_vector(31 downto 0) := x"da7a4444";
  constant PATTERN5	: std_logic_vector(31 downto 0) := x"da7a5555";
  constant PATTERN6	: std_logic_vector(31 downto 0) := x"da7a6666";
  constant PATTERN7	: std_logic_vector(31 downto 0) := x"da7a7777";
  constant PATTERN8	: std_logic_vector(31 downto 0) := x"da7a8888";

  constant clock_period	: time := 10 ns;
  constant ADL			: time := clock_period/5;
  constant LDL			: time := clock_period*5;
  signal stop_the_clock: boolean;

begin

  uut: entity xil_defaultlib.dword_serializer 
  		port map ( clk     => clk,
				   rst     => rst,
				   m_data  => m_data,
				   m_valid => m_valid,
				   m_ready => m_ready,
				   s_data  => s_data,
				   s_valid => s_valid,
				   s_ready => s_ready );

 

stimulus_slave: process
  begin
  
    -- Put initialisation code here
		s_data	<= (others => '0');
   	 	s_valid	<= "0000";

        					
    -- Put test bench stimulus code here
	wait for LDL;
	report "<<<   SLAVE   >>>   deassert rst";
		rst	<= '0';
	wait for LDL;
-- ready musi byc wysoko
		assert s_ready = '1' report "<<<   SLAVE   >>>   ready not asserted" severity failure;
	
	report "<<   SLAVE   >>>   TEST 1 one dword valid";
-- Test z waznym tylko jednym slowem
	wait until rising_edge(clk);
		s_data(31 downto 0) <= PATTERN1 after ADL;
		s_valid	<= "0001" after ADL;
		wait until rising_edge(clk);
	s_data(31 downto 0) <= (others => '0') after ADL;
	s_valid	<= "0000" after ADL;




-- Test z waznym jednym slowem, potem dwoma...
	wait for LDL;
	report "<<<   SLAVE   >>>   TEST 2. one, then two dwords valid";
	wait until rising_edge(clk);
		s_data(31 downto 0) <= PATTERN1 after ADL;
		s_valid	<= "0001" after ADL;
	wait until rising_edge(clk) and s_ready = '1';	
		s_data(31 downto 0) <= PATTERN2 after ADL;
		s_data(63 downto 32) <= PATTERN3 after ADL;
		s_valid	<= "0011" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_data	<= (others => '0');
		s_valid	<= "0000";





-- Test z waznym czteram slowami. Po ready na narastajacym zegarze, 3 slowa
	wait for LDL;
	report "<<<   SLAVE   >>>   TEST 3. Four dwords valid";
	wait until rising_edge(clk);
		s_data(31 downto 0) 	<= PATTERN1 after ADL;
		s_data(63 downto 32) 	<= PATTERN2 after ADL;
		s_data(95 downto 64) 	<= PATTERN3 after ADL;
		s_data(127 downto 96) 	<= PATTERN4 after ADL;
		s_valid					<= "1111" after ADL;
	wait until rising_edge(clk) and s_ready = '1';	
	report "<<<   SLAVE   >>> TEST3. Test 3 valids, after 4 valids";
		s_data(31 downto 0) 	<= PATTERN5 after ADL;
		s_data(63 downto 32)	<= PATTERN6 after ADL;
		s_data(95 downto 64) 	<= PATTERN7 after ADL;
		s_valid					<= "0111" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
-- 6 pazdziernika 2015
-- Tutaj sprawdzam co sie stanie jak bedzie od razu podejdyncz dword (nowy pakiet)
	report "<<<   SLAVE   >>> TEST4. Test 1 valid (new packet), after 4 valids";
		s_data(31 downto 0) 	<= PATTERN8 after ADL;
		s_valid					<= "0001" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_data		<= (others => '0') after ADL;
		s_valid		<= "0000" after ADL;



-- Test na oko, czy gyd s_valid = "111" to czeka 3 takty - test udany
	wait for LDL;
	report " PAARTICLA TEST ";
	wait until rising_edge(clk);
		s_data(31 downto 0) 	<= PATTERN1 after ADL;
		s_data(63 downto 32)	<= PATTERN2 after ADL;
		s_data(95 downto 64) 	<= PATTERN3 after ADL;
		s_valid					<= "0111" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_data(31 downto 0) 	<= PATTERN4 after ADL;
		s_valid					<= "0001" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_data					<= (others => '0') after ADL;
		s_valid					<= "0000" after ADL;	
			
							
--	wait for LDL;
--	report "<<<MASTER>>>   SUCCESS" severity failure;
--    stop_the_clock <= true;
    wait;
  end process;
  
  
stimulus_master: process
  begin
		m_ready		<= '1';
	wait until rising_edge(clk) and m_valid = '1';
  	assert  m_data = PATTERN1 report "<<<   MASTER   >>>   TEST 1 FAIL. Data not equal PATTERN 1" severity failure;
  	
  	
	wait until rising_edge(clk)and m_valid = '1';
  	assert m_data = PATTERN1 report "<<<   MASTER   >>>   TEST 2 FAIL. Data not equal PATTERN 1" severity failure;	
	wait until rising_edge(clk)and m_valid = '1';
  	assert m_data = PATTERN2 report "<<<   MASTER   >>>   TEST 2 FAIL. Data not equal PATTERN 2" severity failure;	 
	wait until rising_edge(clk)and m_valid = '1';
  	assert m_data = PATTERN3 report "<<<   MASTER   >>>   TEST 2 FAIL. Data not equal PATTERN 3" severity failure;
  	
	
	
--Slowa 1,2,3,4
	wait until rising_edge(clk) and m_valid = '1';
  	assert m_data = PATTERN1 report "<<<   MASTER   >>>   TEST 3 FAIL. Data not equal PATTERN 1" severity failure;	
  	wait until rising_edge(clk) and m_valid = '1';
  	assert m_data = PATTERN2 report "<<<   MASTER   >>>   TEST 3 FAIL. Data not equal PATTERN 2" severity failure;	 
  	wait until rising_edge(clk) and m_valid = '1';
  	assert m_data = PATTERN3 report "<<<   MASTER   >>>   TEST 3 FAIL. Data not equal PATTERN 3" severity failure;
  	report "<<<SLAVE>>>   deasserting m_ready after 3th DWORD";
		m_ready		<= '0' after ADL;
	wait for LDL;
		m_ready		<= '1' after ADL;
	wait until rising_edge(clk) and m_valid = '1';
  	assert m_data = PATTERN4 report "<<<   MASTER   >>>   TEST 3 FAIL. Data not equal PATTERN 4" severity failure;

--Slowa 5,6,7
	wait until rising_edge(clk) and m_valid = '1';
  	assert m_data = PATTERN5 report "<<<   MASTER   >>>   TEST 3 FAIL. Data not equal PATTERN 5" severity failure;	
  	wait until rising_edge(clk) and m_valid = '1';
  	assert m_data = PATTERN6 report "<<<   MASTER   >>>   TEST 3 FAIL. Data not equal PATTERN 6" severity failure;	 
  	wait until rising_edge(clk) and m_valid = '1';
  	assert m_data = PATTERN7 report "<<<   MASTER   >>>   TEST 3 FAIL. Data not equal PATTERN 7" severity failure;
  	
--Slowa 8
  		wait until rising_edge(clk) and m_valid = '1';
  	  	assert m_data = PATTERN8 report "<<<   MASTER   >>>   TEST 4 FAIL. Data not equal PATTERN 8" severity failure;	  	
  	
  	
	wait for 5*LDL;
	assert false report "<<<SUCCESS>>" severity failure;		  
  stop_the_clock <= true;
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