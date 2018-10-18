--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: event_det.vhd
-- Language: VHDL
-- Description: 
-- 	Parametrized module for detecting events (value change) on signals.
--	EVENT_EDGE determine on which edges sig_event signal is high. Possbile values:
--	"RISE" - rising edge
--	"FALL" - falling edge
--	"BOTH" - rising and falling edge
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- 21/03/16 Revision - 0.02 Sim fix
-- Additional Comments: Events are not generated when input signal is not 01 vlaue
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
--library xil_;

entity event_det is
	Generic ( 
		ADL			: time	:= 0 ps;
		EVENT_EDGE	: string := "BOTH";
		OUT_REG		: boolean := true;
		SIM			: boolean := true
	);
    Port (
    	clk				: in std_logic;
    	sig				: in std_logic;
    	sig_event		: out std_logic
    	
    );
end event_det;
architecture event_det_arch of event_det is

signal sig_r		: std_logic := '0';
signal sig_event_c		: std_logic := '0';


begin

-- Check EVENT EDGE GENERIC
assert EVENT_EDGE = "BOTH" or EVENT_EDGE = "RISE" or EVENT_EDGE = "FALL"
  report "   [event_det.vhd] bad EVENT_EDGE generic value. Possbile values: BOTH, RISE, FALL."
  severity failure;

synth_gen: if not SIM generate
	both_gen: if EVENT_EDGE = "BOTH" generate
		sig_event_c <= '1' when sig /= sig_r else '0';
	end generate;

	rise_gen: if EVENT_EDGE = "RISE" generate
		sig_event_c <= '1' when (sig /= sig_r) and sig = '1' else '0';
	end generate;

	fall_gen: if EVENT_EDGE = "FALL" generate
		sig_event_c <= '1' when (sig /= sig_r) and sig = '0' else '0';
	end generate;
end generate;

sim_gen: if SIM generate
	both_gen: if EVENT_EDGE = "BOTH" generate
		sig_event_c <= '1' when sig /= sig_r  
				and not Is_X(sig) and not Is_X(sig_r) else '0';
	end generate;

	rise_gen: if EVENT_EDGE = "RISE" generate
		sig_event_c <= '1' when (sig /= sig_r) and sig = '1' 
				and not Is_X(sig) and not Is_X(sig_r) else '0';
	end generate;

	fall_gen: if EVENT_EDGE = "FALL" generate
		sig_event_c <= '1' when (sig /= sig_r) and sig = '0' 
				and not Is_X(sig) and not Is_X(sig_r)  else '0';
	end generate;
end generate;



sig_r_proc: process(clk) begin
if rising_edge(clk) then
	sig_r <= sig after ADL;
end if;
end process;


out_reg_gen: if OUT_REG generate 	
	event_proc: process(clk) begin
	if rising_edge(clk) then
		sig_event <= sig_event_c after ADL;
	end if;
	end process;
end generate;

out_comb_gen: if not OUT_REG generate
	sig_event <= sig_event_c;
end generate;



end event_det_arch;
