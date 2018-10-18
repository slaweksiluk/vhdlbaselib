--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: tx_axi_packet_tb.vhd
-- Language: VHDL
-- Description: 
-- 		
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- !!! TB is depdent on TRIG_MODE_PULSE generic. It's necessary to run tb two
--	times: with TRIG_MODE_PULSE true and false.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

library xil_defaultlib;
use xil_defaultlib.common_pkg.all;
use xil_defaultlib.axis_test_env_pkg.all;

entity tx_axi_packet_tb is
end;

architecture bench of tx_axi_packet_tb is


  
-- Stale do symulacji  			  
  constant DATA_WIDTH	    : natural := 8;
  constant PACKET_LEN	    : natural := 32;
  constant PACKET_NUM	    : natural := 2;
  constant PACKET_LEN_WIDTH	: natural := calc_width(PACKET_LEN);
  constant TRIG_MODE_PULSE	: boolean := false;

  
-- Sygnaly do symulacji
  signal  S_VALID_TEST	: boolean := false;
  signal  M_READY_TEST	: boolean := false;
  signal  M_READY_I		: natural := 3;

  signal clk: STD_LOGIC;
  signal rst: STD_LOGIC;
  signal s_data: STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
  signal s_valid: STD_LOGIC := '0';
  signal s_ready: STD_LOGIC;
  signal m_data: STD_LOGIC_VECTOR (DATA_WIDTH-1 downto 0);
  signal m_valid: STD_LOGIC	:= '0';
  signal m_ready: STD_LOGIC;
  signal m_last: STD_LOGIC;
  signal trigger: STD_LOGIC;
  signal packet_len_s		: std_logic_vector(PACKET_LEN_WIDTH-1 downto 0) := (others => '0');
  
-- Sygnaly konwersji
  signal s_data_nat	: natural;
  signal m_data_nat	: natural;
  
-- Czasy
  constant PERIOD		: time	  := 10 ns;
  constant ADL			: time := period / 5;
  constant LDL			: time := period * 5;	
  
-- ATE
constant SLAVE_WIDTH	: natural := DATA_WIDTH;
constant MASTER_WIDTH	: natural := DATA_WIDTH;
signal ate_s_valid		: std_logic := '0';
signal ate_s_data		: std_logic_vector(SLAVE_WIDTH-1 downto 0) := (others => 'U');
signal ate_s_keep		: std_logic_vector(SLAVE_WIDTH/8-1 downto 0) := (others => 'U');
signal ate_s_ready		: std_logic := '0';
signal ate_s_last		: std_logic := '0';
signal ate1_m_ready		: std_logic := '0';
signal ate1_m_valid		: std_logic := '0';
signal ate1_m_last		: std_logic := '0';
signal ate1_m_data		: std_logic_vector(MASTER_WIDTH-1 downto 0) := (others => 'U');
signal ate1_m_keep		: std_logic_vector(MASTER_WIDTH/8-1 downto 0) := (others => 'U');
-- Triggers
signal ATE1_DONE		: boolean := false;
constant LFSR_SHIFTS	: natural := 32;

	
begin

						   


stimulus: process begin
	packet_len_s <=	 std_logic_vector(to_unsigned(PACKET_LEN, PACKET_LEN_WIDTH));	
-- Initial
	if TRIG_MODE_PULSE then
		trigger		<= '0' after ADL;
	else
		trigger		<= '1' after ADL;
	end if;
	
-- Preapre slave and master stores
	for I in 0 to PACKET_LEN*2-1 loop
		FILL_STORE(SLAVE_E, 1, I, std_logic_vector(to_unsigned(I, DATA_WIDTH)));
	end loop;

	for I in 0 to PACKET_LEN*2-1 loop
		FILL_STORE(MASTER_E, 1, I, std_logic_vector(to_unsigned(I, DATA_WIDTH)));
	end loop;

		ATE_INIT;
		ATE_CFG.VERIF_MASTER_LAST := true;
		FILL_MASTER_LAST_STORE(PACKET_NUM, PACKET_LEN);
		ATE_RESET_USER_VECTOR(BOTH_E);
--		ATE_MASTER_TIMEOUT := 5 us;
--		lfsr_state(SLAVE_LFSR_ID) := x"0f0f0f0f";
		rst		<= '1';
	wait for LDL;
	wait until rising_edge(clk);
		rst		<= '0';
	wait until rising_edge(clk);


-- TEST - trivial
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, PACKET_LEN);	
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;
	if TRIG_MODE_PULSE then
		trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;		
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (trivial) triggering. Waiting for DONE event...";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE1_DONE'event;

-- TEST - DOUBLE packet
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, PACKET_LEN*2);	
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
	if TRIG_MODE_PULSE then
		trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;		
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (DOUBLE packet) triggering. Waiting for DONE event...";
		ATE_TRIG	<= not ATE_TRIG;
	if TRIG_MODE_PULSE then
		wait until rising_edge(clk) and m_valid = '1' and m_ready = '1' and m_last = '1';
		-- expect no m_valid here
		wait until rising_edge(clk);
		assert m_valid = '0' report "[ FAIL ] expected valid deassertion between packets" severity failure;		
		wait for PERIOD;
			trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;			
	wait until ATE1_DONE'event;
			

for I in 1 to LFSR_SHIFTS loop 
	report " [   STIM   ]   LFSR shift iter" & natural'image(I);
							
-- Testy z PRNG trigger high
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, PACKET_LEN);		
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := TIED_TO_VCC;	
	if TRIG_MODE_PULSE then
		trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;		
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (valid PRNG) triggering. Waiting for DONE event...";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE1_DONE'event;	


	wait for LDL;
	ATE_CFG.S_VALID_STIM_MODE := TIED_TO_VCC;
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
	if TRIG_MODE_PULSE then
		trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;		
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (ready PRNG) triggering. Waiting for DONE event...";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE1_DONE'event;		
	
	wait for LDL;
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
	if TRIG_MODE_PULSE then
		trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;		
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (double PRNG) triggering. Waiting for DONE event...";
		ATE_TRIG	<= not ATE_TRIG;		
	wait until ATE1_DONE'event;
	
	wait for LDL;
	ATE_SET_TEST_LEN(BOTH_E, PACKET_LEN*2);	
	ATE_CFG.S_VALID_STIM_MODE := PRNG;
	ATE_CFG.M_READY_STIM_MODE := PRNG;	
	if TRIG_MODE_PULSE then
		trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;		
	report " [STIM]   TEST" & natural'image(ATE_M_TEST_ID) & " (DOUBLE packet) triggering. Waiting for DONE event...";
		ATE_TRIG	<= not ATE_TRIG;
	if TRIG_MODE_PULSE then
		wait until rising_edge(clk) and m_valid = '1' and m_ready = '1' and m_last = '1';
		-- expect no m_valid here
		wait until rising_edge(clk);
		assert m_valid = '0' report "[ FAIL ] expected valid deassertion between packets" severity failure;
		wait for PERIOD;
			trigger		<= '1' after ADL, '0' after PERIOD+ADL;
	end if;			
	wait until ATE1_DONE'event;									

-- SHIFT lfsr
	ATE_SHIFT_LFSR(BOTH_E);
end loop;


wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;
  
-- SLAVE PROCS
	slave_proc: ATE_S_STIM(clk, rst, ate_s_data, ate_s_keep, ate_s_valid, 
			ate_s_last, ate_s_ready);
 	ate1_s_wg: ATE_S_WATCHDOG(MASTER_WIDTH, clk, rst, ate_s_data, 
 			ate_s_keep, ate_s_valid, ate_s_ready, 1);
			
			
-- MASTER1 PROCS
	ate1_master_proc: ATE_M_VERIF(ATE1_DONE, clk, rst, ate1_m_data, ate1_m_keep, 
			ate1_m_valid, ate1_m_last, ate1_m_ready, 1);
	ate1_m_ready_proc: M_READY_STIM_PROC(clk, rst, ate1_m_valid, 
			ate1_m_ready, 1);
	ate1_m_watchdog_proc: MASTER_WATCHDOG_PROC(clk, rst, ate1_m_data, 
			ate1_m_valid, ate1_m_ready, 1);
 	ate1_m_wg: ATE_M_WATCHDOG(MASTER_WIDTH, clk, rst, ate1_m_data, 
 			ate1_m_keep, ate1_m_valid, ate1_m_ready, 1);
 	
	
-- Signals assigment
	-- Slave ATE out
	s_valid		<= ate_s_valid after ADL;
	s_data		<= ate_s_data after ADL;
	-- Slave ATE in
	ate_s_ready	<= s_ready;
	
	
	-- Master ATE1 in - listen only
	ate1_m_valid 	<= m_valid;
	ate1_m_last		<= m_last;
	ate1_m_data		<= m_data;
	m_ready			<= ate1_m_ready after ADL;	



uut: entity xil_defaultlib.tx_axi_packet
    generic map ( ADL               => ADL,
               DATA_WIDTH          => DATA_WIDTH,
               PACKET_LEN_WIDTH     => PACKET_LEN_WIDTH,
               TRIG_MODE_PULSE		=> TRIG_MODE_PULSE
           )
    port map ( clk         => clk,
               rst         => rst,
               s_data      => s_data,
               s_valid     => s_valid,
               s_ready     => s_ready,
               m_data      => m_data,
               m_valid     => m_valid,
               m_ready     => m_ready,
               m_last      => m_last,
               trigger     => trigger,
               packet_len  => packet_len_s
            );
                                   
   -- Clock process definitions
USER_CLK_process: process  begin
	CLK <= '0';
	wait for period/2;
	CLK <= '1';
	wait for period/2;                
end process;	

end;
  
