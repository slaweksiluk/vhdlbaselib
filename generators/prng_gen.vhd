--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: prng_gen.vhd
-- Language: VHDL
-- Description: 
-- Pseudo random generator based on LFSR with AXIS Master interface.
-- Dependencies: 
-- 	* lfsr_counter.vhd

-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- 11/03/16 - Revision 0.02 - Added trigger signal
-- Additional comments:
-- Data is being generated when trigger signal pulse is detected. Added FSM to
-- control signals.
-- TO DO - stop data gen (counter?).
--
-- 18/03/16 - Revision 0.03 - Added counter
-- Additional comments:
-- Number of generated DWs is now limited by gen_limit input, when cont_mode is set 
-- to '0'. In the other case data is being generated continuously.
-- mode[] encoding:
-- 00 - continuous. Data is geneated until module is reseted.
-- 1- - limit without auto rst. As above, but after reaching limit counter is
--	stopped at last DW. It can be returned to first DW mannualy or gen_limit can
--	be increased to continue generation.
--	 		rst		ce
--	lfsr	0		0
--	cnt		0		0
-- 01 - limit with auto rst. Generator is working until number of generated DWs 
--	is equal to gen_limit[] input. Then counter is cleared and module is presnting
--	first value (seed).
--	 		rst		ce
--	lfsr	1		-
--	cnt		1		-

-- 22/03/16 - Revision 0.04 - Written TB
-- Additional comments:
-- DATA_TO_GENERATE = gen_limit[LIMIT_WIDTH-1 downto 9] + 1
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;

entity prng_gen is
	Generic (
		WIDTH		: natural 	:= 32;
		ADL			: time 		:= 0 ps;
		USE_TRIG	: boolean	:= false;
		LIMIT_WIDTH	: natural	:= 4;
		MODE_WIDTH	: natural	:= 2
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
    	-- Master interface
    	m_data		: out std_logic_vector(WIDTH-1 downto 0);
    	m_valid		: out std_logic;
    	m_ready		: in std_logic;
    	seed		: in std_logic_vector(WIDTH-1 downto 0);
    	trig		: in std_logic;
    	mode		: in std_logic_vector(MODE_WIDTH-1 downto 0);
    	gen_limit	: in std_logic_vector(LIMIT_WIDTH-1 downto 0)	
    );
end prng_gen;
architecture prng_gen_arch of prng_gen is

	type state_t is 	(
							IDLE_STATE,
							INIT_STATE,
							CONT_STATE,
							LIMIT_AR_STATE,
							LIMIT_STATE,
							W4_LIMIT_CHANGE_STATE
						);
	signal state	: state_t := IDLE_STATE;
		
	signal fsm_trig		: std_logic := '0';
	signal rst_lfsr_r	: std_logic := '1';
	signal ce_lfsr_r	: std_logic := '0';
	
	signal m_valid_r	: std_logic := '0';
		
	signal rst_cnt_c	: std_logic := '1';
	signal rst_cnt_r	: std_logic := '1';
	signal ce_cnt_c		: std_logic := '0';
	signal ce_cnt_r		: std_logic := '0';
	
	signal gen_limit_nat	: natural range 0 to (2**LIMIT_WIDTH)-1;
	signal cnt_val_nat		: natural range 0 to (2**LIMIT_WIDTH)-1;
	signal cnt_val			: std_logic_vector(LIMIT_WIDTH-1 downto 0);
	
	
	
	signal cnt_limit	: boolean := false;
	signal cnt_lt_limit	: boolean := false;
	
		
begin
	
trig_gen: if USE_TRIG generate
	fsm_trig <= trig;
end generate;

no_trig_gen: if not USE_TRIG generate
	fsm_trig <= '1';
end generate;

	
lfsr_counter_inst : entity work.lfsr_counter
	generic map
	(
		ADL   => ADL,
		WIDTH => WIDTH
	)
	port map
	(
		rst  => rst_lfsr_r,
		clk  => clk,
		ce   => ce_lfsr_r,
		dout => m_data,
		seed => seed
	);			

fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state	<= IDLE_STATE after ADL;
		m_valid_r <= '0' after ADL;
		rst_lfsr_r <= '1' after ADL;
	else
		case state is
		when IDLE_STATE =>
			rst_lfsr_r		<= '1' after ADL;
			rst_cnt_r		<= '1' after ADL;
			if fsm_trig = '1' then
				state		<= INIT_STATE after ADL;
			end if;
			
		when INIT_STATE =>
			if m_ready = '1' then
				rst_lfsr_r	<= '0' after ADL;
				rst_cnt_r	<= '0' after ADL;
				ce_lfsr_r	<= m_ready after ADL;
				m_valid_r	<= '1' after ADL;
			
				case mode is
					-- Cont
					when "00" =>
						state <= CONT_STATE after ADL;
					-- Limit + AR
					when "01" =>
						state <= LIMIT_AR_STATE after ADL;
					when others =>
						state <= LIMIT_STATE after ADL;
				end case;
			end if;
		
		when CONT_STATE =>
			ce_lfsr_r	<= m_ready after ADL;
			-- Do nothing, juest generate data forever
		
		when LIMIT_AR_STATE =>
			ce_lfsr_r	<= m_ready after ADL;
			-- Reset stuff, return to waiting for trigger
			if cnt_limit then
				rst_lfsr_r	<= '1' after ADL;
				rst_cnt_r	<= '1' after ADL;
				m_valid_r	<= '0' after ADL;
				ce_lfsr_r	<= '0' after ADL;
				state 		<= IDLE_STATE after ADL;
			end if;
			
		when LIMIT_STATE =>
			ce_lfsr_r	<= m_ready after ADL;
			if cnt_limit then
				-- Stop lfsr
				ce_lfsr_r <= '0' after ADL;
				-- Deassert valid to stop cnt
				m_valid_r <= '0' after ADL;
				-- Instead of reseting go to waiting state
				state <= W4_LIMIT_CHANGE_STATE after ADL; 
			end if;
		
		when W4_LIMIT_CHANGE_STATE =>
			ce_lfsr_r		<= '0' after ADL;
			m_valid_r		<= '0' after ADL;
			if cnt_lt_limit then
				-- Start generation again
				ce_lfsr_r	<= '0' after ADL;
				m_valid_r	<= '1' after ADL;
				state 		<= LIMIT_STATE after ADL;
			end if;
			
		end case;
	end if;
end if;
end process;	

ce_cnt_c <= '1' when m_ready = '1' and m_valid_r = '1' else '0';	

cnt_limit <= true when cnt_val_nat = gen_limit_nat-1 and ce_cnt_c = '1' else false;

cnt_lt_limit <= true when cnt_val_nat < gen_limit_nat else false;


--
-- Limit cnt
--
counter_inst : entity work.counter
	generic map
	(
		ADL   => ADL,
		WIDTH => LIMIT_WIDTH
	)
	port map
	(
		clk  => clk,
		sclr => rst_cnt_c,
		ce   => ce_cnt_r,
		q    => cnt_val
	);
-- ce logic
ce_proc: process(clk) begin
if rising_edge(clk) then
	ce_cnt_r <= ce_cnt_c;
end if;
end process;

---- rst logic
rst_cnt_c <= '1' when (rst = '1' or rst_cnt_r = '1') or (cnt_limit and (mode = "00" or mode = "01")) else '0';
--rst_lfsr_c <= rst_cnt_c;


-- Conversions
	cnt_val_nat	<= to_integer(unsigned(cnt_val));
	gen_limit_nat	<= to_integer(unsigned(gen_limit));
	

-- Outpus assigment
	m_valid <=  m_valid_r;

end prng_gen_arch;
