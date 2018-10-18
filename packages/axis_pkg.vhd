--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: axis_pkg.vhd
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package axis_pkg is
constant WIDTH	: natural := 32;

type axi_st is record
	data			: std_logic_vector(WIDTH-1 downto 0);
	keep			: std_logic_vector(WIDTH/8-1 downto 0);
	valid			: std_logic;
	last			: std_logic;
	ready			: std_logic;
end record;

type axis_s_i is record
	data			: std_logic_vector(WIDTH-1 downto 0);
	keep			: std_logic_vector(WIDTH/8-1 downto 0);
	valid			: std_logic;
	last			: std_logic;
end record;

type axis_s_o is record
	ready			: std_logic;
end record;

type axis_m_o is record
	data			: std_logic_vector(WIDTH-1 downto 0);
	keep			: std_logic_vector(WIDTH/8-1 downto 0);
	valid			: std_logic;
	last			: std_logic;
end record;

type axis_m_i is record
	ready			: std_logic;
end record;

end axis_pkg;
--package body axis_pkg is
--	
--end axis_pkg;
