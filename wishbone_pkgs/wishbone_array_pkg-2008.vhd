-- 2018 Slawomir Siluk  slaweksiluk@gazeta.pl
library ieee;
use ieee.std_logic_1164.all;

--library vhdlbaselib;
--use vhdlbaselib.wishbone_pkg.all;

package wishbone_array_pkg is
--	generic (
constant adr_width : positive range 32 to 64 := 32;
constant dat_width : positive range 8 to 64 := 32;
--	);

type t_wishbone_master_out is record
	cyc : std_logic;
	stb : std_logic;
	adr : std_logic_vector(adr_width-1 downto 0);
	sel : std_logic_vector(dat_width/8-1 downto 0);
	we  : std_logic;
	dat : std_logic_vector(dat_width-1 downto 0);
end record t_wishbone_master_out;

subtype t_wishbone_slave_in is t_wishbone_master_out;

type t_wishbone_slave_out is record
	ack   : std_logic;
	err   : std_logic;
	rty   : std_logic;
	stall : std_logic;
	int   : std_logic;
	dat   : std_logic_vector(dat_width-1 downto 0);
end record t_wishbone_slave_out;

subtype t_wishbone_master_in is t_wishbone_slave_out;

--subtype t_wishbone_master_out_constr is t_wishbone_master_out(
--	adr(31 downto 0),
--	sel(3 downto 0),
--	dat(31 downto 0)
--);

-- Array types
type t_arr_wishbone_master_out is array (natural range <>) of t_wishbone_master_out;

subtype t_arr_wishbone_slave_in is t_arr_wishbone_master_out;

type t_arr_wishbone_slave_out is array (natural range <>) of t_wishbone_slave_out;

subtype t_arr_wishbone_master_in is t_arr_wishbone_slave_out;

end wishbone_array_pkg;
