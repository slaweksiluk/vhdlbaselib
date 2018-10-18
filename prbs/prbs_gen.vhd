--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: prbs_gen.vhd
-- Language: VHDL
-- Description: 
-- 	First data trnamistted is seed
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 	30/06/17 - Merged control signals (trig pulse and ce) into one ce
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity prbs_gen is
	Generic ( 
		ADL			: time		:= 0 ps;
		WIDTH 		: natural 	:= 32
	);
    Port (
    	clk			: in std_logic;
    	rst			: in std_logic;
    	ce			: in std_logic;
    	
    	seed		: in std_logic_vector(WIDTH-1 downto 0);
    	inject_err	: in std_logic;
    	
    	m_data		: out std_logic_vector(WIDTH-1 downto 0);
    	m_valid		: out std_logic;
    	m_ready		: in std_logic
    	
    );
end prbs_gen;
architecture prbs_gen_arch of prbs_gen is


function f_prbs_gen(
		seed_i : std_logic_vector(WIDTH-1 downto 0))
			return std_logic_vector is 
        variable v_lfsr : std_logic_vector(WIDTH-1 downto 0);
        variable v_temp : std_logic;
	        begin
        v_lfsr := seed_i;
        for i in 0 to WIDTH-1 loop
	        v_temp := v_lfsr(WIDTH-1) xor v_lfsr(6);
	        v_lfsr := v_lfsr(WIDTH-2 downto 0) & v_temp;
		end loop;
        return v_lfsr;
end function f_prbs_gen;

signal prbs_r		: std_logic_vector(WIDTH-1 downto 0);
signal seed_sent	: std_logic := '0';	


begin


prbs_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		prbs_r		<= (others => '0') after ADL;
		seed_sent		<= '0' after ADL;
	elsif m_ready = '1' and ce = '1' then
		if seed_sent = '1' then
			prbs_r		<= f_prbs_gen(prbs_r) after ADL;
		else
			prbs_r		<= seed after ADL;
			seed_sent	<= '1' after ADL;
		end if;
	end if;
end if;
end process;			

-- valid stim in separted file for tranmistting seed first
trig_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		m_valid		<= '0' after ADL;
	elsif m_ready = '1' then
		m_valid		<= ce after ADL;
	end if;
end if;
end process;	

--	m_valid <= not rst;
	m_data <= prbs_r when inject_err = '0' else not prbs_r;



end prbs_gen_arch;
