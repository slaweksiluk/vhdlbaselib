-- 2018 Slawomir Siluk slaweksiluk@gazeta.pl
-- Output sel is combinatorial signal. In case of setting addr input
-- which not exists in TARGETS_ADDR generic, last target is selected ( sel =
-- TARGETS_NUM-1)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity single_addr_decoder is
Generic (
	TARGETS_NUM : positive;
	TARGETS_ADDR : std_logic_vector
);
Port (
	addr : in std_logic_vector;
	sel : out natural range 0 to TARGETS_NUM-1
);
end single_addr_decoder;
architecture comb of single_addr_decoder is
	type addr_arr_t is array (0 to TARGETS_NUM-1) of std_logic_vector(addr'range);
	function addr_arr_init (
		targets : positive;
		addresses : std_logic_vector;
		addr_width : positive
	) return addr_arr_t is
		variable v : addr_arr_t;
	begin
		assert addresses'length / addr_width = targets
		report "invalid width of TARGETS_ADDR vector passed to single_addr_decoder.vhd"&
		"addresses'length="&positive'image(addresses'length)&
		"addr'length="&positive'image(addr_width)&
		"targets="&positive'image(targets)
		severity failure;
		for i in 0 to targets -1 loop
			v(i) := addresses((i+1)*addr_width-1 downto i*addr_width);
		end loop;
		return v;
	end function;
	constant ADDR_ARR : addr_arr_t := addr_arr_init(TARGETS_NUM, TARGETS_ADDR, addr'length);
begin

	decode_proc: process (addr)
	begin
		for i in 0 to TARGETS_NUM-1 loop
			sel <= i;
			exit when addr = ADDR_ARR(i);
		end loop;
	end process;


end comb;
