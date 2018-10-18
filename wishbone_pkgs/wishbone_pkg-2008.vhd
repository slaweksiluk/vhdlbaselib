-- 2018 Slawomir Siluk  slaweksiluk@gazeta.pl
library ieee;
use ieee.std_logic_1164.all;

package wishbone_pkg is

type t_wishbone_master_out is record
	cyc : std_logic;
	stb : std_logic;
	adr : std_logic_vector;
	sel : std_logic_vector;
	we  : std_logic;
	dat : std_logic_vector;
end record t_wishbone_master_out;

subtype t_wishbone_slave_in is t_wishbone_master_out;

type t_wishbone_slave_out is record
	ack   : std_logic;
	err   : std_logic;
	rty   : std_logic;
	stall : std_logic;
	int   : std_logic;
	dat   : std_logic_vector;
end record t_wishbone_slave_out;

subtype t_wishbone_master_in is t_wishbone_slave_out;

end wishbone_pkg;
