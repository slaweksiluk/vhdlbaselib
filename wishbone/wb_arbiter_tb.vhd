library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity wb_arbiter_tb is
end entity;

architecture bench of wb_arbiter_tb is


	constant DAT_WIDTH : integer := 8;
	constant ADR_WIDTH : natural := 32;
	constant SLAVES : natural := 2;
	constant ASSERT_WHEN_BUSY : string := "ERR";
	
	
	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal wbs_adr : std_logic_vector(ADR_WIDTH*SLAVES-1 downto 0);
	signal wbs_dat_i : std_logic_vector(DAT_WIDTH*SLAVES-1 downto 0);
	alias  dat0 	: std_logic_vector is wbs_dat_i((1 * DAT_WIDTH)-1 downto 0 * DAT_WIDTH);
	alias  dat1 	: std_logic_vector is wbs_dat_i((2 * DAT_WIDTH)-1 downto 1 * DAT_WIDTH);
	
	signal wbs_dat_o : std_logic_vector(DAT_WIDTH-1 downto 0);
	signal wbs_sel : std_logic_vector((DAT_WIDTH*SLAVES)/8-1 downto 0);
	
	signal wbs_cyc : std_logic_vector(SLAVES-1 downto 0);
	alias  cyc0 	: std_logic is wbs_cyc(0);
	alias  cyc1 	: std_logic is wbs_cyc(1);
	
	signal wbs_stb : std_logic_vector(SLAVES-1 downto 0);
	alias  stb0 	: std_logic is wbs_stb(0);
	alias  stb1 	: std_logic is wbs_stb(1);
	
	signal wbs_we : std_logic_vector(SLAVES-1 downto 0);
	signal wbs_ack : std_logic_vector(SLAVES-1 downto 0);
	alias  ack0 	: std_logic is wbs_ack(0);
	alias  ack1 	: std_logic is wbs_ack(1);
	
	signal wbs_rty : std_logic_vector(SLAVES-1 downto 0);
	signal wbs_err : std_logic_vector(SLAVES-1 downto 0);
	signal wbs_stall : std_logic_vector(SLAVES-1 downto 0);
	signal wbm_adr : std_logic_vector(ADR_WIDTH-1 downto 0);
	signal wbm_dat_i : std_logic_vector(DAT_WIDTH-1 downto 0);
	signal wbm_dat_o : std_logic_vector(DAT_WIDTH-1 downto 0);
	signal wbm_sel : std_logic_vector(DAT_WIDTH/8-1 downto 0);
	signal wbm_cyc : std_logic;
	signal wbm_stb : std_logic;
	signal wbm_we : std_logic;
	signal wbm_ack : std_logic;
	signal wbm_stall : std_logic;
	
	signal lock_req  : std_logic_vector(SLAVES-1 downto 0);
	signal lock_status : std_logic_vector(SLAVES-1 downto 0);
	alias  ls0 	: std_logic is lock_status(0);
	alias  ls1 	: std_logic is lock_status(1);
	
	
	signal start_test : std_logic:= '0';

	signal lr0, lr1  : std_logic:= '0';
	
	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
	
	constant lock : boolean := true;
	
begin
    lock_req(0) <= lr0;
	lock_req(1) <= lr1;
       
        
	uut : entity work.wb_arbiter
		generic map
		(
			ADL              => ADL,
			DAT_WIDTH        => DAT_WIDTH,
			ADR_WIDTH        => ADR_WIDTH,
			SLAVES           => SLAVES,
			USE_LOCK		 => lock,
			ASSERT_WHEN_BUSY => ASSERT_WHEN_BUSY
		)
		port map
		(
			clk       => clk,
			rst       => rst,
			wbs_adr   => wbs_adr,
			wbs_dat_i => wbs_dat_i,
			wbs_dat_o => wbs_dat_o,
			wbs_sel   => wbs_sel,
			wbs_cyc   => wbs_cyc,
			wbs_stb   => wbs_stb,
			wbs_we    => wbs_we,
			wbs_ack   => wbs_ack,
			wbs_rty   => wbs_rty,
			wbs_err   => wbs_err,
			wbs_stall => wbs_stall,
			lock_req  => lock_req,
			lock_status => lock_status,
			wbm_adr   => wbm_adr,
			wbm_dat_i => wbm_dat_i,
			wbm_dat_o => wbm_dat_o,
			wbm_sel   => wbm_sel,
			wbm_cyc   => wbm_cyc,
			wbm_stb   => wbm_stb,
			wbm_we    => wbm_we,
			wbm_ack   => wbm_ack,
			wbm_stall => wbm_stall
		);


stymulus: if not lock generate
begin
	stim_slave : process	
		variable s : natural := 0;
		------------------------------------------------------
	--	variable seed1:integer:=844396720;  -- uniform procedure seed1
	--    variable seed2:integer:=821616997;  -- uniform procedure seed2
		 
	--    variable result : integer:=0;
	--    variable tmp_real : real;  -- return value from uniform procedure
	--    variable i:integer;
		
		-----------------------------------------------------
	begin


	-- Init
		-- slave
		wbs_cyc		<= (others => '0');
		wbs_stb		<= (others => '0');
		wbs_we		<= (others => '0');
	-----------------------------------------------------------
	--    for i in 0 to RamSize -1 loop
	--        uniform(seed1,seed2,tmp_real);
	--        result:=integer(tmp_real * real((2**DAT_WIDTH)-1));
	--        ram_src(i) <= std_logic_vector(to_unsigned(result,DAT_WIDTH));
				
	--    end loop;        
	-----------------------------------------------------------------        
		   
		   
		   
		wait for LDL;
		wait until rising_edge(clk);
			rst		<= '0';
		
		report " <<< SLAVE >>>   access at slave0";
		wait until rising_edge(clk);
			wbs_cyc(s)		<= '1';
			wbs_stb(s)		<= '1';
			
			wbs_dat_i       <=  x"0000A5";
		wait until rising_edge(clk);
			wbs_stb(s)		<= '0';
		wait until rising_edge(clk) and wbs_ack(s) = '1';
			wbs_cyc(s)		<= '0';
		wait for LDL;

		report " <<< SLAVE >>>   access at slave1";
		s := 1;
		wait until rising_edge(clk);
			wbs_cyc(s)		<= '1';
			wbs_stb(s)		<= '1';
			wbs_dat_i       <= x"00FE00";
		--wait until rising_edge(clk);
		wait until rising_edge(clk);
			wbs_stb(s)		<= '0';
		wait until rising_edge(clk) and wbs_ack(s) = '1';
			wbs_cyc(s)		<= '0';
			
		wait for LDL;	
		report " <<< SLAVE >>>   access at slave2";
				s := 2;
				wait until rising_edge(clk);
					wbs_cyc(s)        <= '1';
					wbs_stb(s)        <= '1';
					wbs_dat_i       <= x"A60000";
				wait until rising_edge(clk);
					wbs_stb(s)        <= '0';
				wait until rising_edge(clk) and wbs_ack(s) = '1';
					wbs_cyc(s)        <= '0';
		
		wait for LDL;
		
			report " <<< SLAVE >>>   access at slave12";
				
				wait until rising_edge(clk);
					wbs_cyc(2)        <= '1';
					wbs_stb(2)        <= '1';
					wbs_cyc(1)        <= '1';
					wbs_stb(1)        <= '1';
					wbs_dat_i       <= x"A642ED";
				wait until rising_edge(clk);
					wbs_stb(2)        <= '0';
					wbs_stb(1)        <= '0';
				wait until rising_edge(clk) and wbs_ack(1) = '1';
					wbs_cyc(2)        <= '0';
					wbs_cyc(1)        <= '0';
	 
		wait for LDL;
						
							report " <<< SLAVE >>>   access at slave01";
								
								wait until rising_edge(clk);
									wbs_cyc(0)        <= '1';
									wbs_stb(0)        <= '1';
									wbs_cyc(1)        <= '1';
									wbs_stb(1)        <= '1';
									wbs_dat_i       <= x"A642ED";
								wait until rising_edge(clk);
									wbs_stb(0)        <= '0';
									wbs_stb(1)        <= '0';
									
									wbs_cyc(2)        <= '1';
									wbs_stb(2)        <= '1';
								 
								wait until rising_edge(clk);
									wbs_stb(2)        <= '0';
								if wbs_ack(0) = '1' then
									wbs_cyc(0)        <= '0';
									wbs_cyc(1)        <= '0';  
								end if;    
								wait until rising_edge(clk) and wbs_ack(0) = '1';
									wbs_cyc(0)        <= '0';
									wbs_cyc(1)        <= '0';  
									wbs_cyc(2)        <= '0';   
									
			
					
		assert false
		 report " <<<SUCCESS>>> "
		 severity failure;
		wait;
	end process;
--
end generate;

-- ************************************************************************************************************
-- ************************************************************************************************************
-- ************************************************************************************************************
gen_z_lockiem: if lock generate

begin


	stim_slave : process	
		variable s : integer := 0;
		variable s2 : integer := 0;
		begin
		wbs_adr		<= (others => '0');
		start_test <= '0';
		rst		<= '1';
		wait for 100 ns;
		rst		<= '0';
		wait for 100 ns;
		start_test <= '1';
			 
		wait;	
	end process;	
	
	
	Proc_s0: process
	variable s : integer := 0;
	begin
		lr0<= '0';
		cyc0		<= '0';
		stb0 <= '0';
		dat0       <=  x"00";
		wait until start_test = '1';
		wait for 10 ns;
		lr0<= '1';
		wait until ls0='1';
		report " <<< SLAVE 0>>> 1 bajt";
		wait until rising_edge(clk);
		cyc0		<= '1';
		stb0		<= '1';
		dat0       <=  x"A5";
		wait until rising_edge(clk);
		stb0		<= '0';
		wait until rising_edge(clk) and ack0 = '1';
		cyc0		<= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);

		if ls0='0' then
			wait until ls0='1';
		end if;	
		report " <<< SLAVE0 >>>  2 bajt";
		wait until rising_edge(clk);
		cyc0		<= '1';
		stb0		<= '1';
		dat0       <=  x"A5";
		wait until rising_edge(clk);
		stb0		<= '0';
		wait until rising_edge(clk) and ack0 = '1';
		
		cyc0		<= '0';
		lr0<= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		lr0<= '1';
		wait until ls0='1';
		report " <<< SLAVE 0>>> 3 bajt";
		wait until rising_edge(clk);
		cyc0		<= '1';
		stb0		<= '1';
		dat0       <=  x"5b";
		wait until rising_edge(clk);
		stb0		<= '0';
		wait until rising_edge(clk) and ack0 = '1';
		cyc0		<= '0';
		lr0<= '0';
		wait for LDL;
		wait;
	end process;

	Proc_s1: process
	variable s : integer := 1;
	begin
		lr1<= '0';
		cyc1		<= '0';
		stb1 <= '0';
		dat1       <=  x"00";
		wait until start_test = '1';
		wait for 10 ns;
		lr1<= '1';
		wait until ls1='1';
		report " <<< SLAVE 1>>>   access at slave1";
		wait until rising_edge(clk);
		cyc1		<= '1';
		stb1		<= '1';
		dat1       <=  x"FB";
		wait until rising_edge(clk);
		stb1		<= '0';
		wait until rising_edge(clk) and wbs_ack(s) = '1';
		cyc1		<= '0';
		lr1<= '0';
		wait for LDL;
		wait;
	end process;

	
end generate;




verif_master: process begin
-- INIT
	wbm_ack		<= '0';
	wbm_stall	<= '0';
	
	
	wait until rising_edge(clk) and wbm_cyc = '1' and wbm_stb = '1';
		wbm_ack	<= '1';
		report " <<< otrzymany bajt";
	wait until rising_edge(clk);
		wbm_ack	<= '0';
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


























