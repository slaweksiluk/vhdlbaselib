-- 2018 Slawomir Siluk slaweksiluk@gazeta.pl
-- Output sel is combinatorial signal. Example address map for three targets
-- each having three 8bit addresses
-- 0x00
-- 0x01   Sel0
-- 0x02
-- ---
-- 0x03
-- 0x04   Sel1
-- 0x05
-- ---
-- 0x06
-- 0x07   Sel3
-- 0x08
-- Now, addr setting fot this configuration are following
-- TARGETS_ADDR = 0x06 0x03
-- addr < 0x03 -> sel0
-- addr < 0x06 -> sel1
-- others      -> sel3

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity range_addr_decoder is
Generic (
	TARGETS_NUM : positive;
	TARGETS_ADDR : std_logic_vector
);
Port (
	addr : in std_logic_vector;
	sel : out natural range 0 to TARGETS_NUM-1
);
end range_addr_decoder;
architecture comb of range_addr_decoder is
	type addr_arr_t is array (0 to TARGETS_NUM-1 -1) of std_logic_vector(addr'range);
	function addr_arr_init (
		targets : positive;
		addresses : std_logic_vector;
		addr_width : positive
	) return addr_arr_t is
		variable v : addr_arr_t;
	begin
		assert addresses'length / addr_width = targets-1
		report "invalid width of TARGETS_ADDR vector passed to range_addr_decoder.vhd"&
		"addresses'length="&positive'image(addresses'length)&
		"addr'length="&positive'image(addr_width)&
		"targets="&positive'image(targets)
		severity failure;
		for i in 0 to TARGETS_NUM -2 loop
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
			exit when addr <= ADDR_ARR(i mod TARGETS_NUM);
		end loop;
	end process;


end comb;
