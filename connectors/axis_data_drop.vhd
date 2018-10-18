--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_data_drop.vhd
-- Language: VHDL
-- Description: 
-- 		Module redirect slave to master. If it gets drop_pulse signal
--		asseted then it's recived slaves input data, but doesn't redirect it 
--		to the master interface.
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

entity axis_data_drop is
	Generic ( 
		ADL		: time := 0 ps			
	);
    Port (	
    	clk				: in std_logic;
    	rst				: in std_logic;
		drop_pulse		: in std_logic;
		
		s_data		: in std_logic_vector;
		s_valid		: in std_logic;
		s_last		: in std_logic;
		s_ready		: out std_logic;
		
		m_data		: out std_logic_vector;
		m_valid		: out std_logic;
		m_last		: out std_logic;
		m_ready		: in std_logic
    );
end axis_data_drop;
architecture axis_data_drop_arch of axis_data_drop is
type state_t is 	(
						IDLE_STATE,
						DROP_STATE
					);
signal state	: state_t := IDLE_STATE;
signal ready_sel		: std_logic;		

begin
	
s_ready <= m_ready when ready_sel = '0' else '1';
	
fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state		<= IDLE_STATE;
		m_valid		<= '0';
		ready_sel	<= '0';
	else
		case state is
		when IDLE_STATE =>
			if m_ready = '1' then
				m_data		<= s_data;
				m_valid		<= s_valid;
				m_last		<= s_last;
			end if;
			if drop_pulse = '1' then
				ready_sel	<= '1';
				m_valid		<= '0';
				state		<= DROP_STATE;
			end if;
		
		when DROP_STATE =>
--			if s_valid = '1' and s_last = '1' and m_ready = '1' then
--			Its not necessary to check m_ready condition as s_ready is tied to '1'
			if s_valid = '1' and s_last = '1' then
				state		<= IDLE_STATE;
				ready_sel	<= '0';
			end if;
			
		when others =>
		end case;
	end if;
end if;
end process;	

end axis_data_drop_arch;
