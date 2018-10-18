----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: dword_filler_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 7/10/15

----------------------------------------------------------------------------------


library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

library xil_defaultlib;
use xil_defaultlib.axis_test_env_pkg.all;

library xil_defaultlib;



entity dword_filler_tb is
end;

architecture bench of dword_filler_tb is

constant WIDTH	: natural := 128;

signal clk: STD_LOGIC;
signal rst: STD_LOGIC := '1';
signal s_data: STD_LOGIC_VECTOR (WIDTH-1 downto 0);
signal s_valid: STD_LOGIC;
signal s_keep: STD_LOGIC_VECTOR (WIDTH/8-1 downto 0);
signal s_ready: STD_LOGIC;

signal m_data: STD_LOGIC_VECTOR (WIDTH-1 downto 0);
--signal m_keep: STD_LOGIC_VECTOR (WIDTH/8-1 downto 0);
signal m_valid: STD_LOGIC;
signal m_ready: STD_LOGIC;

constant clock_period	: time := 10 ns;
constant ADL			: time := clock_period/5;
constant LDL			: time := clock_period*5;
signal stop_the_clock: boolean;


-- Wzordy danych
type DATA_ARRAY is array (499 downto 0) of std_logic_vector(31 downto 0);
constant NOT_VALID	: std_logic_vector(31 downto 0) := x"407fa71d";
shared variable DS		: DATA_ARRAY;

constant MAX_TEST_LEN		: natural := 50;
constant ITERS				: natural := 100;
constant SLAVE_WIDTH		: natural := WIDTH;
constant MASTER_WIDTH		: natural := WIDTH;
constant SLICE_WIDTH		: natural := 32;
constant MASTER_INST_ID		: natural := 1;
constant REV_OUT_SLICES		: boolean := false;
	

signal ate_s_valid		: std_logic := '0';
signal ate_s_data		: std_logic_vector(SLAVE_WIDTH-1 downto 0) := (others => '0');
signal ate_s_keep		: std_logic_vector(SLAVE_WIDTH/8-1 downto 0) := (others => '0');
signal ate_s_ready		: std_logic := '0';
signal ate_s_last		: std_logic := '0';
signal ate1_m_ready		: std_logic := '0';
signal ate1_m_valid		: std_logic := '0';
signal ate1_m_last		: std_logic := '0';
signal ate1_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => '0');
signal ate1_m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0) := (others => '0');
-- Triggers
signal ATE1_DONE		: boolean := false;

begin

  uut: entity xil_defaultlib.dword_filler 
  					generic map ( 
  								REV_OUT_SLICES => REV_OUT_SLICES,
  								ADL => ADL)
  					port map ( clk     => clk,
                               rst     => rst,
                               s_data  => s_data,
                               s_valid => s_valid,
                               s_ready => s_ready,
                               s_keep  => s_keep,
                               m_data  => m_data,
                               m_valid => m_valid,
                               m_ready => m_ready
                        );

  stimulus_slave: process 
variable s_tlen : natural := 0;
variable m_tlen : natural := 0;

  begin
	ATE_CFG.USE_MASTER_KEEP := false;
	ATE_CFG.S_KEEP_DEF_VAL := '0';
	wait for LDL;
		rst			<= '0';

-- SLAVE_STORE 127..0 = [a b c d]
-- for i=0:...
--	SS =  [3 2 1 0]
--  keep = 0111 => 	SS =  [6 5 4 3] [x 2 1 0]
--					MM = .[7 6 5 4]	[3 2 1 0]	
-- Brak jednego valid wewntrz pakietu jest niemozliwy w pcie ipcore ( zrodlo ... )

-- Scenarisz testu pierwszego (kolejene takty):
--	valid = 0000 brak
--	valid = 1111 pelny
--	valid = 0111 brak jednego
--	valid = 0001 jedno
--	valid = 0000 brak	
--	wait for LDL;
--	ATE_CFG.USE_SLAVE_KEEP := true;	
--	s_tlen := 3;
--	m_tlen := 2;
--	ATE_SET_TEST_LEN(SLAVE_E, s_tlen);
--	ATE_SET_TEST_LEN(MASTER_E, m_tlen);
--	FILL_SLAVE_KEEP_STORE(0, x"ffff");
--	FILL_SLAVE_KEEP_STORE(1, x"0fff");
--	FILL_SLAVE_KEEP_STORE(2, x"000f");
----	FILL_INC_STORE_AS_KEEP(SLAVE_E,12, 32); -- 12 slices, each is 32bit width
--	FILL_INC_STORE_AS_KEEP(SLAVE_E,s_tlen*4, SLICE_WIDTH, true, SLAVE_WIDTH); -- 12 slices, each is 32bit width
----	FILL_INC_STORE_AS_KEEP(MASTER_E,12, 32); -- 12 slices, each is 32bit width
--	FILL_INC_STORE(MASTER_E,MASTER_INST_ID,m_tlen*4,SLICE_WIDTH,true,MASTER_WIDTH); -- 12 slices, each is 32bit width

--	
----	FILL_MASTER_STORE(0, UBYTE&UBYTE&x"0100");
----	FILL_MASTER_STORE(1, x"0302"&UBYTE&UBYTE);
----	ATE_CFG.VERIF_MASTER_LAST := false;
--	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " generation of sliced data accounting keep store value";
--		ATE_TRIG	<= not ATE_TRIG;		
--	wait on ATE1_DONE;	
--	
	
	

---- Scenarisz testu trzeciego - rzeczywiste zachowanie PCIe tj.
---- brak obnizen valid wewnatrz pakietu (kolejene takty):
--	--  valid = 0000 brak
--    --	valid = 0001 jedno
--    --	valid = 1111 pelny
--    --	valid = 1111 pelny
--    --	valid = 0111 trzy
	wait for LDL;
	ATE_CFG.USE_SLAVE_KEEP := true;	
	s_tlen := 4;
	m_tlen := 3;
	ATE_SET_TEST_LEN(SLAVE_E, s_tlen);
	ATE_SET_TEST_LEN(MASTER_E, m_tlen);
	FILL_SLAVE_KEEP_STORE(0, x"000f");
	FILL_SLAVE_KEEP_STORE(1, x"ffff");
	FILL_SLAVE_KEEP_STORE(2, x"ffff");
	FILL_SLAVE_KEEP_STORE(3, x"0fff");
	FILL_INC_STORE_AS_KEEP(SLAVE_E,s_tlen*4, SLICE_WIDTH, REV_OUT_SLICES, SLAVE_WIDTH); -- 12 slices, each is 32bit width
	FILL_INC_STORE(MASTER_E,MASTER_INST_ID,m_tlen*4,SLICE_WIDTH, not REV_OUT_SLICES,MASTER_WIDTH); -- 12 slices, each is 32bit width
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " generation of sliced data accounting keep store value";
		ATE_TRIG	<= not ATE_TRIG;		
	wait on ATE1_DONE;	

	for i in 1 to ITERS loop
		wait for LDL;
		ATE_CFG.M_READY_STIM_MODE := PRNG;
		report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID);
			ATE_TRIG	<= not ATE_TRIG;		
		wait on ATE1_DONE;		
		ATE_INCREMENT_SEED(SLAVE_E);
	end loop;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;


-- Scenarisz testu drugiego (kolejene takty):
    --	valid = 1111 pelny
    --	valid = 0111 brak jednego
    --	valid = 0011 dwa
    --	valid = 0111 trzy
    --	valid = 0000 brak
---- Brak jednego valid wewntrz pakietu jest niemozliwy w pcie ipcore ( zrodlo ... )    
--    wait for LDL;
--    report "   <<<TEST 2>>>   ";
--    wait until rising_edge(clk);
--    	s_valid	<= "1111" after ADL;
--    	s_data	<= DS(0) & DS(1) & DS(2) & DS(3) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid 	<= "0111" after ADL;
--		s_data	<= NOT_VALID & DS(4) & DS(5) & DS(6) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid 	<= "0011" after ADL;
--		s_data	<= NOT_VALID & NOT_VALID & DS(7) & DS(8) after ADL;		
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid 	<= "0111" after ADL;
--		s_data	<= NOT_VALID & DS(9) & DS(10) & DS(11) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid	<= "0000" after ADL;
--		s_data	<= 	NOT_VALID & NOT_VALID & NOT_VALID & NOT_VALID after ADL;    





--    wait for LDL;
--    report "   <<<TEST 3>>>   ";
--    wait until rising_edge(clk);
--    	s_valid	<= "0001" after ADL;
--    	s_data	<= NOT_VALID & NOT_VALID & NOT_VALID & DS(0) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid <= "1111" after ADL;
--		s_data	<= DS(1) & DS(2) & DS(3) & DS(4) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid <= "1111" after ADL;
--		s_data	<= DS(5) & DS(6) & DS(7) & DS(8) after ADL;		
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid <= "0111" after ADL;
--		s_data	<= NOT_VALID & DS(9) & DS(10) & DS(11) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid	<= "0000" after ADL;
--		s_data	<= 	NOT_VALID & NOT_VALID & NOT_VALID & NOT_VALID after ADL;        
--    

---- Scenarisz testu czwartego taki jak trzeciego, ale
---- dochodza test obnizania m_ready
--    wait for LDL;
--    report "   <<<TEST 4>>>   ";
--    wait until rising_edge(clk);
--    	s_valid	<= "0001" after ADL;
--    	s_data	<= NOT_VALID & NOT_VALID & NOT_VALID & DS(0) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid <= "1111" after ADL;
--		s_data	<= DS(1) & DS(2) & DS(3) & DS(4) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid <= "1111" after ADL;
--		s_data	<= DS(5) & DS(6) & DS(7) & DS(8) after ADL;		
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid <= "0111" after ADL;
--		s_data	<= NOT_VALID & DS(9) & DS(10) & DS(11) after ADL;
--	wait until rising_edge(clk) and s_ready = '1';
--		s_valid	<= "0000" after ADL;
--		s_data	<= 	NOT_VALID & NOT_VALID & NOT_VALID & NOT_VALID after ADL;      
    
    
    

--    stop_the_clock <= true;
    wait;
  end process;
  


-- Weryfikacja - interfejs master
--  verify_master: process begin
--  		m_ready		<= '1';
--		for I in 0 to 1 loop
--			wait until rising_edge(clk) and m_valid = '1';
--			assert (DS(I*4+0) & DS(I*4+1) & DS(I*4+2) & DS(I*4+3)) = m_data
--			 report "   <<< FAILURE TEST 1  >>> m_data not matching on index " & integer'image(I)
--			 severity failure;
--		end loop;
--		
--		for I in 0 to 2 loop
--			wait until rising_edge(clk) and m_valid = '1';
--			assert (DS(I*4+0) & DS(I*4+1) & DS(I*4+2) & DS(I*4+3)) = m_data
--			 report "   <<< FAILURE TEST 2  >>> m_data not matching on index " & integer'image(I)
--			 severity failure;
--		end loop;
--		
--		for I in 0 to 2 loop
--			wait until rising_edge(clk) and m_valid = '1';
--			assert (DS(I*4+0) & DS(I*4+1) & DS(I*4+2) & DS(I*4+3)) = m_data
--			 report "   <<< FAILURE TEST 3  >>> m_data not matching on index " & integer'image(I)
--			 severity failure;
--		end loop;
--		
---- Test obnizania m_ready		
--		for I in 0 to 2 loop
--			-- Obnieznenie na pierwszym slowie
--			if I = 0 then
--				wait until m_valid = '1';
--				m_ready	<= '0';
--				wait for LDL;
--				m_ready <= '1';
--			end if;

--			
--			wait until rising_edge(clk) and m_valid = '1';
--			assert (DS(I*4+0) & DS(I*4+1) & DS(I*4+2) & DS(I*4+3)) = m_data
--			 report "   <<< FAILURE TEST 4  >>> m_data not matching on index " & integer'image(I)
--			 severity failure;
--			 
--			-- Obnieznenie na ostatnim slowie
--			 if I = 1 then
--			 	m_ready	<= '0' after ADL;
--			 	wait for LDL;
--			 	m_ready <= '1' after ADL;
--			 end if;
--		end loop;						
--		
--		
--	wait for LDL;
--	assert false report "   <<<SUCCESS>>   " severity failure;
--  	end process;

--------------------------------------------------------------------------------
-- CUT HERE
--------------------------------------------------------------------------------
-- Execute test procedures
-- SLAVE PROCS
	slave_proc: ATE_S_STIM(clk, rst, ate_s_data, ate_s_keep, ate_s_valid, 
			ate_s_last, ate_s_ready);
 	ate1_s_wg: ATE_S_WATCHDOG(MASTER_WIDTH, clk, rst, ate_s_data, 
 			ate_s_keep, ate_s_valid, ate_s_ready, 1);
 		
			
-- MASTER1 PROCS
	ate1_master_proc: ATE_M_VERIF(ATE1_DONE, clk, rst, ate1_m_data, ate1_m_keep, 
			ate1_m_valid, ate1_m_last, ate1_m_ready, 1);
	ate1_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate1_m_valid, ate1_m_ready, 1);
	ate1_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate1_m_data, 
			ate1_m_valid, ate1_m_ready, 1);
 	ate1_m_wg: ATE_M_WATCHDOG(MASTER_WIDTH, clk, rst, ate1_m_data, 
 			ate1_m_keep, ate1_m_valid, ate1_m_ready, 1);
 	 	
 	
-- Signals assigment
	-- Slave ATE out
	s_valid		<= ate_s_valid after ADL;
--	s_last		<= ate_s_last after ADL;
	s_keep		<= ate_s_keep after ADL;
	s_data		<= ate_s_data after ADL;
	-- Slave ATE in
	ate_s_ready	<= s_ready;
	
	
	-- Master ATE1 in
	ate1_m_valid 	<= m_valid;
--	ate1_m_last		<= m_last;
	ate1_m_data		<= m_data;
	-- Master ATE1 out
	m_ready		<= ate1_m_ready after ADL;	 -- drive ready	
	
--------------------------------------------------------------------------------
-- END HERE
--------------------------------------------------------------------------------
  

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;
