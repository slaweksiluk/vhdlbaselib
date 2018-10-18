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

library vhdlbaselib;
use vhdlbaselib.axis_pkg.all;
	

package axis_sw_pkg is

constant SEL_NUM	: natural := 2;
type axis_m_i_arr is array (0 to SEL_NUM-1) of axis_m_i; 
type axis_m_o_arr is array (0 to SEL_NUM-1) of axis_m_o; 


end axis_sw_pkg;
--package body axis_pkg is
--	
--end axis_pkg;
