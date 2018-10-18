--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: single_s_axis_sw_tb.vhd
-- Language: VHDL
-- Description: 
-- 	
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Test bench for uut revision 0.02 - without "on the fly" select changing. 
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.axis_test_env_pkg.all;


library xil_defaultlib;
use work.common_pkg.all;



entity single_s_axis_sw_tb is
end entity;

architecture bench of single_s_axis_sw_tb is



	constant MASTERS : natural := 2;
	constant WIDTH : natural := 8;
	signal clk : std_logic;
	signal rst : std_logic;
	signal m_data : std_logic_vector(MASTERS*WIDTH-1 downto 0);
	signal m_valid : std_logic_vector(MASTERS-1 downto 0);
	signal m_ready : std_logic_vector(MASTERS-1 downto 0);
	signal s_data : std_logic_vector(WIDTH-1 downto 0);
	signal s_valid : std_logic;
	signal s_ready : std_logic;
	signal master_sel : std_logic_vector(calc_width(MASTERS-1)-1 downto 0);

	-- Signlas for simulation
	signal s_data_nat		: natural := 0;
	signal LOOP_LEN			: natural := 8;
	signal m_data0			: natural := 0;
	signal m_data1			: natural := 0;

-- ATE
	constant MAX_TEST_LEN	: natural := 8;
	signal ATE_DONE0		: boolean := false;
	signal ATE_DONE1		: boolean := false;
	signal ate_s_valid		: std_logic := '0';
	signal ate_s_data		: std_logic_vector(WIDTH-1 downto 0);
	signal ate_s_ready		: std_logic := '0';
	signal ate_m_ready0		: std_logic := '0';
	signal ate_m_valid0		: std_logic := '0';
	signal ate_m_data0		: std_logic_vector(WIDTH-1 downto 0);
	signal ate_m_ready1		: std_logic := '0';
	signal ate_m_valid1		: std_logic := '0';
	signal ate_m_data1		: std_logic_vector(WIDTH-1 downto 0);
	
	constant CLK_PERIOD : time := 10 ns;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
	constant stop_clock : boolean := false;
	
begin

-- Execute test procedures
	-- SLAVE PROCS
	slave_proc: AXIS_SLAVE_STIM_PROC(clk, rst, ate_s_data, ate_s_valid, ate_s_ready);
	s_valid_proc: S_VALID_STIM_PROC(clk, rst, ate_s_ready, ate_s_valid);

--	-- MASTER 0 PROCS
--	master0_proc: AXIS_MASTER_STIM_PROC(ATE_DONE0, clk, rst, ate_m_data0, ate_m_valid0, ate_m_ready0);
--	m_ready0_proc: M_READY_STIM_PROC(clk, rst, ate_m_valid0, ate_m_ready0);
--	m_watchdog0_proc: MASTER_WATCHDOG_PROC(clk, rst, ate_m_data0, ate_m_valid0, ate_m_ready0);
	
	-- MASTER 1 PROCS
	master1_proc: AXIS_MASTER_STIM_PROC(ATE_DONE1, clk, rst, ate_m_data1, ate_m_valid1, ate_m_ready1,1);
	m_ready_proc: M_READY_STIM_PROC(clk, rst, ate_m_valid1, ate_m_ready1,1);
	m_watchdog1_proc: MASTER_WATCHDOG_PROC(clk, rst, ate_m_data1, ate_m_valid1, ate_m_ready1,1);
	
	
-- Signals assigment
	-- Slave ATE out
	s_valid		<= ate_s_valid after ADL;
	s_data		<= ate_s_data after ADL;
	-- Slave ATE in
	ate_s_ready	<= s_ready;
	
	-- Master 0 ATE in
		ate_m_valid0	<= m_valid(0);
		ate_m_data0		<= m_data(7 downto 0);
	-- Master 0 ATE out
		m_ready(0)	<= ate_m_ready0 after ADL;
	-- Master 1 ATE in
		ate_m_valid1	<= m_valid(1);
		ate_m_data1		<= m_data(15 downto 8);
	-- Master 1 ATE out
		m_ready(1)	<= ate_m_ready1 after ADL;	
	
	
slave_store_gen: for I in 0 to MAX_TEST_LEN-1 generate -- fill data store for slave
	signal data	: std_logic_vector(WIDTH-1 downto 0);
begin
	data	<= std_logic_vector(to_unsigned(I+1, data'length));
	FILL_SLAVE_STORE(I, data);
end generate;

master_store_gen: for I in 0 to MAX_TEST_LEN-1 generate -- fill data store for slave
	signal data	: std_logic_vector(WIDTH-1 downto 0);
begin
	data	<= std_logic_vector(to_unsigned(I+1, data'length));
	FILL_MASTER_STORE(I, data);
end generate;

		
	uut : entity work.single_s_axis_sw
		generic map
		(
			ADL		=> ADL,
			MASTERS => MASTERS,
			WIDTH   => WIDTH
		)
		port map
		(
			clk        => clk,
			rst        => rst,
			m_data     => m_data,
			m_valid    => m_valid,
			m_ready    => m_ready,
			s_data     => s_data,
			s_valid    => s_valid,
			s_ready    => s_ready,
			master_sel => master_sel
		);


stimulus_slave : process begin
		rst			<= '1';
		master_sel	<= "1";
		S_VALID_STIM_MODE := TIED_TO_VCC;
		M_READY_STIM_MODE := USER_VECTOR;
		ATE_SET_TEST_LEN(MAX_TEST_LEN, "B");
		FILL_M_READY_USR_VEC(0, '0');

	wait for 100 ns;
	rst		<= '0';

--
-- TEST 1
--
	wait for LDL;
	report " <<< TEST 1 >>> TEST1";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE_DONE1'event;
	
	
--
-- TEST 2
--
	wait for LDL;
	S_VALID_STIM_MODE := PRNG;
	M_READY_STIM_MODE := TIED_TO_VCC;
	report " <<< TEST 2 >>> TEST2";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE_DONE1'event;	

--
-- TEST 3
--
	wait for LDL;
	S_VALID_STIM_MODE := TIED_TO_VCC;
	M_READY_STIM_MODE := PRNG;
	report " <<< TEST 3 >>> TEST3";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE_DONE1'event;	
	
--
-- TEST 4
--
	wait for LDL;
	S_VALID_STIM_MODE := PRNG;
	M_READY_STIM_MODE := PRNG;
	report " <<< TEST 4 >>> TEST4";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE_DONE1'event;			
	
--	wait until rising_edge(clk);
----		master_sel	<= "1";
--	ATE_TRIG	<= not ATE_TRIG;		
--	wait until ATE_DONE1'event;
				
		
--	wait for LDL;
--	report " <<<SLAVE>>> Switching to master 1";
--	wait until rising_edge(clk);
--		master_sel	<= "1";
--	for I in 1 to LOOP_LEN loop
--		wait until rising_edge(clk) and s_ready = '1';
--			s_valid		<= '1';			
--			s_data_nat	<= s_data_nat + 1;
--	end loop;	
--	wait until rising_edge(clk) and s_ready = '1';
--		s_data_nat	<= 0;		
--		s_valid		<= '0';
--		


----
---- TEST 2
----		
--	wait for LDL;
--	report " <<<SLAVE>>> TEST2 - deasserting m_ready";
--	report " <<<SLAVE>>> Switching to master 0";	
--	wait until rising_edge(clk);
--		master_sel	<= "0";			
--	for I in 1 to LOOP_LEN loop
--		wait until rising_edge(clk) and s_ready = '1';
--			s_valid		<= '1';			
--			s_data_nat	<= s_data_nat + 1;
--	end loop;	
--	wait until rising_edge(clk) and s_ready = '1';
--		s_data_nat	<= 0;
--		s_valid		<= '0';
--		
--		
--	wait for LDL;
--	report " <<<SLAVE>>> Switching to master 1";
--	wait until rising_edge(clk);
--		master_sel	<= "1";
--	for I in 1 to LOOP_LEN loop
--		wait until rising_edge(clk) and s_ready = '1';
--			s_valid		<= '1';			
--			s_data_nat	<= s_data_nat + 1;
--	end loop;	
--	wait until rising_edge(clk) and s_ready = '1';
--		s_data_nat	<= 0;		
--		s_valid		<= '0';		
		
	
	wait for LDL;
	assert false
	 report " <<<SUCCESS>>> "
	 severity failure;
	wait;
end process;

-- Conversion s_data to std_logic_vector
--s_data	<= std_logic_vector(to_unsigned(s_data_nat, s_data'length));
	



-- Converts m_data to nat for easy comparison
--m_data0	<= to_integer(unsigned(m_data(7 downto 0)));
--m_data1	<= to_integer(unsigned(m_data(15 downto 8)));


--verify_master : process begin

----
---- TEST 1
----
--		m_ready		<= "00";
--	wait for LDL;
--	wait until rising_edge(clk);
--		m_ready(0)		<= '1';
--	
--	report "   <<<MASTER>>> TEST 1: verify master0";
--	for I in 1 to LOOP_LEN loop
--		-- Master0 data
--		wait until rising_edge(clk) and m_valid(0)='1';
--		assert m_data0 = I
--		 report " <<<FAILURE>>> TEST1: m_data0 not matching on index " & 
--		 												integer'image(I)
--		 severity failure;
--	end loop;
--	wait until rising_edge(clk);
--		m_ready(0)	<= '0';
--	



--	wait for LDL;
--	wait until rising_edge(clk);
--		m_ready(1)		<= '1';
--	
--	report "   <<<MASTER>>> TEST1: verify master1";
--	for I in 1 to LOOP_LEN loop
--		-- Master0 data
--		wait until rising_edge(clk) and m_valid(1)='1';
--		assert m_data1 = I
--		 report " <<<FAILURE>>> TEST1: m_data1 not matching on index " & 
--		 												integer'image(I)
--		 severity failure;
--	end loop;
--		wait until rising_edge(clk);
--		m_ready(1)	<= '0';
--		
----
---- TEST 2
----
--		m_ready		<= "00";
--	wait for LDL;
--	wait until rising_edge(clk);
--		m_ready(0)		<= '1';
--	
--	report "   <<<MASTER>>> TEST 2: verify master0 with ready deasserting";
--	for I in 1 to LOOP_LEN loop
--		-- Master0 data
--		wait until rising_edge(clk) and m_valid(0)='1';
--		assert m_data0 = I
--		 report " <<<FAILURE>>> TEST2: m_data0 not matching on index " & 
--		 												integer'image(I)
--		 severity failure;
--		 
--		 if I = 3 then
--		 		m_ready(0)	<= '0';
--		 	wait for LDL;
--		 	wait until rising_edge(clk);
--		 		m_ready(0)	<= '1';
--	 	end if;
--	end loop;
--	wait until rising_edge(clk);
--		m_ready(0)	<= '0';
--	


--	wait for LDL;
--	wait until rising_edge(clk);
--		m_ready(1)		<= '1';
--	
--	report "   <<<MASTER>>> TEST2: verify master1";
--	for I in 1 to LOOP_LEN loop
--		-- Master0 data
--		wait until rising_edge(clk) and m_valid(1)='1';
--		assert m_data1 = I
--		 report " <<<FAILURE>>> TEST2: m_data1 not matching on index " & 
--		 												integer'image(I)
--		 severity failure;
--	end loop;
--		wait until rising_edge(clk);
--		m_ready(1)	<= '0';		
--			

--	wait for LDL;
--	assert false
--	 report " <<<SUCCESS>>> "
--	 severity failure;
--	wait;
--	
--end process;

	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

