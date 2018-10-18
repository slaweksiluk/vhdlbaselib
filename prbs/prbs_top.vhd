--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: prbs_top.vhd
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

entity prbs_top is
	Generic (
		ADL				: time := 0 ps; 
		WIDTH 			: natural := 32;
		ERR_CNT_WIDTH 	: natural := 32			
	);
    Port (
    	clk			: in std_logic;
    	rst			: in std_logic;
    	trig		: in std_logic;
    	inject_err	: in std_logic;
    	sync		: out std_logic;
    	err_cnt		: out std_logic_vector(WIDTH-1 downto 0)
    	
    );
end prbs_top;
architecture prbs_top_arch of prbs_top is


constant seed	: std_logic_vector(WIDTH-1 downto 0) := x"aabbccdd";

signal data		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
signal valid		: std_logic := '0';
signal ready		: std_logic := '0';


begin
	
	
	
prbs_gen_inst : entity work.prbs_gen
	generic map
	(
		ADL		=> ADL,
		WIDTH => WIDTH
	)
	port map
	(
		clk        => clk,
		rst        => rst,
		seed       => seed,
		trig       => trig,
		inject_err => inject_err,
		m_data     => data,
		m_valid    => valid,
		m_ready    => ready
	);

		
prbs_chk_inst : entity work.prbs_chk
	generic map
	(
		ADL			=> ADL,
		WIDTH         => WIDTH,
		ERR_CNT_WIDTH => WIDTH
	)
	port map
	(
		clk     => clk,
		rst     => rst,
		seed    => seed,
		trig    => trig,
		sync    => sync,
		err_cnt => err_cnt,
		s_data  => data,
		s_valid => valid,
		s_ready => ready
	);

		


end prbs_top_arch;
