--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wishbone_pkg.vhd
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

package wishbone_pkg is

constant WB_ADR_WIDTH	: natural := 32;
constant WB_DAT_WIDTH	: natural := 32;

type t_wishbone_master_out is record
	cyc : std_logic;
	stb : std_logic;
	adr : std_logic_vector(WB_ADR_WIDTH-1 downto 0);
	sel : std_logic_vector(WB_ADR_WIDTH/8-1 downto 0);
	we  : std_logic;
	dat   : std_logic_vector(WB_DAT_WIDTH-1 downto 0);
end record t_wishbone_master_out;

subtype t_wishbone_slave_in is t_wishbone_master_out;

type t_wishbone_slave_out is record
	ack   : std_logic;
	err   : std_logic;
	rty   : std_logic;
	stall : std_logic;
	int   : std_logic;
	dat   : std_logic_vector(WB_DAT_WIDTH-1 downto 0);
end record t_wishbone_slave_out;

subtype t_wishbone_master_in is t_wishbone_slave_out;

-- Array types
type t_arr_wishbone_master_out is array (natural range <>)
	of t_wishbone_master_out;
	
subtype t_arr_wishbone_slave_in is t_arr_wishbone_master_out;	

type t_arr_wishbone_slave_out is array (natural range <>)
	of t_wishbone_slave_out;
	
subtype t_arr_wishbone_master_in is t_arr_wishbone_slave_out;	

end wishbone_pkg;
