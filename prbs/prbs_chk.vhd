--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: prbs_chk.vhd
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;

entity prbs_chk is
	Generic (
		ADL				: time		:= 0 ps; 
		WIDTH 			: natural := 32;
		ERR_CNT_WIDTH 	: natural := 4	
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
    	seed		: in std_logic_vector(WIDTH-1 downto 0);
    	trig		: in std_logic;
    	sync		: out std_logic;
    	err_cnt		: out std_logic_vector(ERR_CNT_WIDTH-1 downto 0);
    	
		s_data		: in std_logic_vector(WIDTH-1 downto 0);
		s_valid		: in std_logic;
		s_ready		: out std_logic
		
    );
end prbs_chk;
architecture prbs_chk_arch of prbs_chk is

	signal err_cnt_ce_r		: std_logic := '0';
--	signal err_cnt			: std_logic_vector(ERR_CNT_WIDTH-1 downto 0);
	signal data_match		: boolean := false;
	signal data_local		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal valid_local		: std_logic := '0';
	signal ready_local		: std_logic := '0';
	
	type state_t is 	(
							IDLE_STATE,
							RUN_STATE
						);
	signal state	: state_t := IDLE_STATE;
	signal ce		: std_logic := '0';	
	signal init_pulse		: std_logic := '0';
	
begin

	
	
-- Local PRBS generator for comparation
prbs_gen_inst : entity work.prbs_gen
	generic map
	(
		ADL		=> ADL,
		WIDTH	=> WIDTH
	)
	port map
	(
		clk     => clk,
		rst     => rst,
		seed    => seed,
		ce		=> ce,
		inject_err	=> '0',
		m_data  => data_local,
		m_valid => valid_local,
		m_ready => ready_local
	);
-- turn on prbs gen every time valid data is received 
ready_local <= s_valid or init_pulse;
--ready_local <= '1' when data_match or state = RUN_STATE else '0';

ce_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		ce	<= '0' after ADL;
	elsif trig = '1' then
		ce <= '1' after ADL;
	end if;
end if;
end process;

ce_edet_inst : entity vhdlbaselib.event_det
	generic map(
		EVENT_EDGE => "RISE",
		OUT_REG    => true,
		SIM        => true)
	port map(
		clk       => clk,
		sig       => ce,
		sig_event => init_pulse);
	


fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state	<= IDLE_STATE after ADL;
		sync	<= '0' after ADL;
	else
		case state is
		when IDLE_STATE =>
			if data_match then
				state		<= RUN_STATE after ADL;
			end if;
		
		when RUN_STATE =>
			sync		<= '1' after ADL;
			
			if s_valid = '1' and valid_local = '1' then 
				if data_match then
					err_cnt_ce_r <= '0' after ADL;
				else
					err_cnt_ce_r <= '1' after ADL;
				end if;
			else
					err_cnt_ce_r <= '0' after ADL;				
			end if;
		when others =>
		end case;
	end if;
end if;
end process;

-- Compare data from local and exteranl prbs
--data_match <= true when data_local = s_data and s_valid = '1' and valid_local = '1' else false;
data_match <= true when data_local = s_data else false;



-- Error counter
counter_inst : entity vhdlbaselib.counter
	generic map	(
		ADL   => ADL,
		WIDTH => ERR_CNT_WIDTH	)
	port map	(
		clk  => clk,
		sclr => rst,
		ce   => err_cnt_ce_r,
		q    => err_cnt	);



s_ready		<= '1';



end prbs_chk_arch;
