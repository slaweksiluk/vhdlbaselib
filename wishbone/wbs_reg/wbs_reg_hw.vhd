--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbs_reg_hw.vhd
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
library xil_defaultlib;
use xil_defaultlib.wbs_reg_pkg.all;
	

entity wbs_reg_hw is
	Generic ( 
		WIDTH	: natural := 32
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
		wbs_cyc	      : in  std_logic;
		wbs_stb       : in  std_logic;
		wbs_adr       : in  std_logic_vector(WIDTH-1 downto 0);
		wbs_we        : in  std_logic;
		wbs_dat_i     : in  std_logic_vector(WIDTH-1 downto 0);
		wbs_dat_o     : out std_logic_vector(WIDTH-1 downto 0) := (others => '0');
		wbs_ack       : out std_logic;
		wbs_err		: out std_logic;
		
		reg_o		: out std_logic_vector(REG_O_WIDTH-1 downto 0);
		reg_i		: in  std_logic_vector(REG_I_WIDTH-1 downto 0)   	
    );
end wbs_reg_hw;
architecture wbs_reg_hw_arch of wbs_reg_hw is


begin

	wbs_reg_inst : entity xil_defaultlib.wbs_reg
	port map
	(
		clk       => clk,
		rst       => rst,
		wbs_cyc   => wbs_cyc,
		wbs_stb   => wbs_stb,
		wbs_adr   => wbs_adr,
		wbs_we    => wbs_we,
		wbs_dat_i => wbs_dat_i,
		wbs_dat_o => wbs_dat_o,
		wbs_ack   => wbs_ack,
		wbs_err   => wbs_err,
		reg_o     => reg_o,
		reg_i     => reg_i
	);



end wbs_reg_hw_arch;
