-- Testbench created online at:
--   www.doulos.com/knowhow/perl/testbench_creation/
-- Copyright Doulos Ltd
-- SD, 03 November 2002

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity connector_tb is
end;




architecture bench of connector_tb is


constant	S_AXIS_W		: natural := 4;
constant	M_AXIS_W		: natural := 4;


  component connector
  	Generic(ADL				: time	:= 500 ps;
  			S_AXIS_W		: natural := 128;
  			S_AXIS_READY_N	: boolean := false;
  			M_AXIS_W		: natural := 128;
  			M_AXIS_VALID_N	: boolean := false		
  		);
  	Port ( clk : in STD_LOGIC;
             rst : in STD_LOGIC;
             s_valid 	: in STD_LOGIC;
             s_data		: in STD_LOGIC_VECTOR(S_AXIS_W-1 downto 0);
             s_ready 	: out STD_LOGIC;
             m_ready	: in STD_LOGIC;
             m_data		: out STD_LOGIC_VECTOR(M_AXIS_W-1 downto 0);
             m_valid	: out STD_LOGIC);
  end component;

  signal clk: STD_LOGIC;
  signal rst: STD_LOGIC;
  signal s_valid: STD_LOGIC;
  signal s_data: STD_LOGIC_VECTOR(S_AXIS_W-1 downto 0);
  signal s_ready: STD_LOGIC;
  signal m_ready: STD_LOGIC;
  signal m_data: STD_LOGIC_VECTOR(M_AXIS_W-1 downto 0);
  signal m_valid: STD_LOGIC;

  constant clock_period: time := 10 ns;
  constant ADL: time := 500 ps;
  constant LDL: time := 50 ns;
  signal stop_the_clock: boolean;

begin

  -- Insert values for generic parameters !!
  uut: connector generic map ( ADL            => ADL,
                               S_AXIS_W       => S_AXIS_W,
                               S_AXIS_READY_N => false,
                               M_AXIS_W       => M_AXIS_W,
                               M_AXIS_VALID_N => false)
                    port map ( clk            => clk,
                               rst            => rst,
                               s_valid        => s_valid,
                               s_data         => s_data,
                               s_ready        => s_ready,
                               m_ready        => m_ready,
                               m_data         => m_data,
                               m_valid        => m_valid );

  stimulus_slave_interface: process
  begin
  
    -- Put initialisation code here
    	rst			<= '1';
		s_valid		<= '0';
		s_data		<= (others =>'0');

    -- Put test bench stimulus code here
	report "<<<TEST>>>   slave, deassert reset";
    wait for LDL;
    	rst			<= '0';
	wait for LDL;
    	
    	
    report "<<<TEST>>>   slave writes A";
    wait for LDL;
	wait until rising_edge(clk);
		s_valid		<= '1' after ADL;
		s_data		<= x"A" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_valid		<= '0' after ADL;
		s_data		<= (others => '0') after ADL;

	
	
    report "<<<TEST>>>   slave writes B, then C, then D";
		wait for LDL;
	wait until rising_edge(clk);
		s_valid		<= '1' after ADL;
		s_data		<= x"B" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_valid		<= '1' after ADL;
		s_data		<= x"C" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_valid		<= '1' after ADL;
		s_data		<= x"D" after ADL;	
	wait until rising_edge(clk) and s_ready = '1';
		s_valid		<= '0' after ADL;
		s_data		<= x"0" after ADL;	
		
		
		
    report "<<<TEST>>>   slave writes B, then C, then D";
		wait for LDL;
	wait until rising_edge(clk);
		s_valid		<= '1' after ADL;
		s_data		<= x"B" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_valid		<= '1' after ADL;
		s_data		<= x"C" after ADL;
	wait until rising_edge(clk) and s_ready = '1';
		s_valid		<= '1' after ADL;
		s_data		<= x"D" after ADL;	
	wait until rising_edge(clk) and s_ready = '1';
		s_valid		<= '0' after ADL;
		s_data		<= x"0" after ADL;	
--    stop_the_clock <= true;
    wait;
  end process;
  
  
   stimulus_master_interface: process
  begin
 -- Put initialisation code here
	m_ready	<= '0';


	wait for LDL;
 	report "<<<TEST>>>   master, asserts ready";
 		m_ready	<= '1' after ADL;
	wait until rising_edge(clk) and m_valid = '1';
	assert m_data = x"A"
	report "<<<FAIL>>> master, invalid data"
	severity failure;





 	report "<<<TEST>>>   master, ready deassertion just after m_valid";
	wait until rising_edge(m_valid);
		m_ready	<= '0' after ADL;
	wait for LDL;
		m_ready	<= '1' after ADL;
	wait until rising_edge(clk) and m_valid = '1';
		assert m_data = x"B"
		report "<<<FAIL>>> master, invalid data - B"
		severity failure;		
	wait until rising_edge(clk) and m_valid = '1';
		assert m_data = x"C"
		report "<<<FAIL>>> master, invalid data - C"
		severity failure;	
	wait until rising_edge(clk) and m_valid = '1';
		assert m_data = x"D"
		report "<<<FAIL>>> master, invalid data - D"
		severity failure;		
 	
 	

 	report "<<<TEST>>>   master, ready deassertion just after s_valid";
	wait until rising_edge(s_valid);
		m_ready	<= '0' after ADL;
	wait for LDL;
		m_ready	<= '1' after ADL;
	wait until rising_edge(clk) and m_valid = '1';
		assert m_data = x"B"
		report "<<<FAIL>>> master, invalid data - B"
		severity failure;		
	wait until rising_edge(clk) and m_valid = '1';
		assert m_data = x"C"
		report "<<<FAIL>>> master, invalid data - C"
		severity failure;	
	wait until rising_edge(clk) and m_valid = '1';
		assert m_data = x"D"
		report "<<<FAIL>>> master, invalid data - D"
		severity failure;	

 	

	wait for LDL;
	assert false report "<<<SUCCESS>>>" severity failure;
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
  