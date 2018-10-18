--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_cnt_gen.vhd
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

entity axis_cnt_gen is
	Generic ( 
		DATA_WIDTH	: natural := 8;
		USE_TRIG	: boolean := true);
    Port (
    	-- sys
    	clk		: in std_logic;
    	rst		: in std_logic;

		-- axis master
    	m_data		: out std_logic_vector(DATA_WIDTH-1 downto 0);
    	m_valid		: out std_logic;
    	m_ready		: in std_logic;
    	
    	-- ctrl
    	trig		: in std_logic
    );
end axis_cnt_gen;
architecture axis_cnt_gen_arch of axis_cnt_gen is


begin

no_trig_gen: if not USE_TRIG generate
	counter_inst : entity vhdlbaselib.counter
		generic map	(
			ADL   => 0 ps,
			WIDTH => DATA_WIDTH	)
		port map	(
			clk  => clk,
			sclr => rst,
			ce   => m_ready,
			q    => m_data
		);

	m_valid <= not rst;
end generate;


trig_gen: if USE_TRIG generate
type state_t is 	(
						IDLE_STATE,
						GEN_STATE
					);
signal state	: state_t := IDLE_STATE;
signal m_ready_cnt		: std_logic := '0';
		
begin
	counter_inst : entity vhdlbaselib.counter
		generic map	(
			ADL   => 0 ps,
			WIDTH => DATA_WIDTH	)
		port map	(
			clk  => clk,
			sclr => rst,
			ce   => m_ready_cnt,
			q    => m_data
		);


	fsm_proc: process(clk) begin
	if rising_edge(clk) then
		if rst = '1' then
			state	<= IDLE_STATE;
		else
			case state is
			when IDLE_STATE =>
				if trig = '1' then
					state	<= GEN_STATE;
				end if;
		
			when GEN_STATE =>
				state		<= GEN_STATE;
			when others =>
			end case;
		end if;
	end if;
	end process;
	
	m_ready_cnt <= m_ready when state = GEN_STATE else '0';
	m_valid		<= '1' when state = GEN_STATE else '0';
end generate;		

end axis_cnt_gen_arch;
