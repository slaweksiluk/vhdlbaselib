--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: perf_counter.vhd
-- Language: VHDL
-- Description: 
-- Counts number o valid, ready assertions during counted number of clock cycles.
-- Can be used calcualte interface performance
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;

entity perf_counter is
	Generic ( 
		ADL		: time	:= 0 ps;
		WIDTH	: natural := 32
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
    	valid	: in std_logic;
    	ready	: in std_logic;
    	
    	clk_cycles	: out std_logic_vector(WIDTH-1 downto 0);
    	data_cycles	: out std_logic_vector(WIDTH-1 downto 0)
    );
end perf_counter;
architecture perf_counter_arch of perf_counter is
type state_t is 	(
						IDLE_STATE,
						MEASURE_STATE,
						VALID_LOW_STATE
					);
signal state	: state_t := IDLE_STATE;
		
signal rst_cnt		: std_logic := '1';
signal save_cnt		: std_logic := '0';
signal clk_cnt			: std_logic_vector(WIDTH-1 downto 0);
signal data_cnt			: std_logic_vector(WIDTH-1 downto 0);
signal data_cnt_ce_c		: std_logic;


begin
	
fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state		<= IDLE_STATE after ADL;
		rst_cnt		<= '1' after ADL;
		save_cnt	<= '0' after ADL;
	else
		case state is
		when IDLE_STATE =>
			if valid = '1' and ready = '1' then
				state	<= MEASURE_STATE after ADL;
			end if;
		
		when MEASURE_STATE =>
			rst_cnt		<= '0'after ADL;
			if valid = '0' then
				save_cnt		<= '1' after ADL;
				state			<= VALID_LOW_STATE after ADL;
			end if;
			
		when VALID_LOW_STATE =>
			save_cnt		<= '0' after ADL;	
			if valid = '1' then
				state		<= MEASURE_STATE after ADL;
			end if;
			
		when others =>
		end case;
	end if;
end if;
end process;	

clk_cnt_inst : entity vhdlbaselib.counter
	generic map	(
		ADL   => ADL,
		WIDTH => WIDTH)
	port map
	(
		clk  => clk,
		sclr => rst_cnt,
		ce   => '1',
		q    => clk_cnt
	);
	
data_cnt_inst : entity vhdlbaselib.counter
	generic map	(
		ADL   => ADL,
		WIDTH => WIDTH)
	port map
	(
		clk  => clk,
		sclr => rst_cnt,
		ce   => data_cnt_ce_c,
		q    => data_cnt
	);
data_cnt_ce_c <= valid and ready;	
	
out_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		clk_cycles		<= (others => '0');
		data_cycles		<= (others => '0');
	elsif save_cnt = '1' then
		clk_cycles	<= clk_cnt after ADL;
		data_cycles	<= data_cnt after ADL;
	end if;
end if;
end process;
	



end perf_counter_arch;
