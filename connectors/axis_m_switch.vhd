--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_switch.vhd
-- Language: VHDL
-- Description: 
-- 		New generation axis switch S slaves to M masters. Using record
--		type to keep the axis signals. Currenlty one record with inout type - 
--		dirty but convinient solution.
--		# Switch control modes
--		1) Force mode - after sel is changed sel_r is changed in the samy cycle
--		NOT YET IMPLEMENTED 2) Keep mode - when sel is changed the data at SLAVE intarface is
--		the last data word which is routed to the previous sel destination. The
--		next data sample is routed the the current sel destination.
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;
use vhdlbaselib.axis_pkg.all;
use vhdlbaselib.axis_sw_pkg.all;



entity axis_m_switch is
	Generic ( 
		ADL			: time		:= 0 ps;
		FORCE_SEL	: boolean	:= true
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
		sel		: in std_logic_vector(0 downto 0);
    	
    	s_i		: in axis_s_i;
    	s_o		: out axis_s_o;
    	m_i		: in axis_m_i_arr;
    	m_o		: out axis_m_o_arr
    );
end axis_m_switch;
architecture Behavioral of axis_m_switch is

signal sel_r		: natural range 0 to SEL_NUM-1;


begin



-- Register master outputs
master_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		-- Zero all valid
		for i in 0 to SEL_NUM-1 loop
			m_o(0).valid	<= '0' after ADL;
			m_o(1).valid	<= '0' after ADL;
		end loop;
	elsif m_i(sel_r).ready = '1' then
		-- Set data
		m_o(sel_r).data	<= s_i.data after ADL;
		-- Zero & set all valid
		for i in 0 to SEL_NUM-1 loop
			m_o(i).valid	<= '0' after ADL;
		end loop;
		m_o(sel_r).valid	<= s_i.valid  after ADL;
		-- Zero & set all last
		for i in 0 to SEL_NUM-1 loop
			m_o(i).last	<= '0' after ADL;
		end loop;
		m_o(sel_r).last	<= s_i.last  after ADL;
	end if;
end if;
end process;


force_sel_gen: if FORCE_SEL generate
	s_o.ready		<= m_i(sel_r).ready;
	
	m_sel_proc: process(clk) begin
	if rising_edge(clk) then
		-- Conversion
		sel_r	<= to_integer(unsigned(sel))  after ADL;
	end if;
	end process;
end generate;


safe_sel_gen: if not FORCE_SEL generate
-- Detect sel change
assert false report "axis_m_switch safe sel not supp" severity failure;

---- If select change is detected set slave not ready to prevent from loading
---- valid data
--	s_o.ready		<= m_i(sel_r).ready when sel_stable else '0';
--	
--	fsm_proc: process(clk) begin
--	if rising_edge(clk) then
--		if rst = '1' then
--			state	<= IDLE_STATE;
--		
--		else
--			case state is
--			when IDLE_STATE =>
--				if sel_event = '1' then
--					state	<= NEXT_STATE;
--				end if;
--			
--			when NEXT_STATE =>
--				-- Old sample is transmitted when m_ready is high
--				if 
--				state		<= IDLE_STATE;
--			when others =>
--			end case;
--		end if;
--	end if;
--	end process;		

end generate;

		


end Behavioral;
