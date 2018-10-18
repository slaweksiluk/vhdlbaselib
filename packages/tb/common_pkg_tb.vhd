--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: common_pkg_tb.vhd
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
use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;
use vhdlbaselib.common_pkg.all;
	

entity common_pkg_tb is
--	Generic ( 
--			
--	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic
    );
end common_pkg_tb;
architecture common_pkg_tb_arch of common_pkg_tb is

signal vin		: std_logic_vector(32-1 downto 0) := x"01234567";
signal vin2		: std_logic_vector(24-1 downto 0) := x"012345";

signal vout		: std_logic_vector(32-1 downto 0);
signal vout2		: std_logic_vector(24-1 downto 0);

constant CLK_PERIOD	: time := 10 ns;
constant LDL	: time := CLK_PERIOD * 10;
constant ADL	: time := CLK_PERIOD / 5;
	

constant CONV_ARG	: natural := 3;
signal conv_res		: natural;

signal add1			: std_logic_vector(3 downto 0);
signal add2			: std_logic_vector(4 downto 0);
signal add_res		: unsigned(5 downto 0);

signal add12			: std_logic_vector(31 downto 0);
signal add22			: std_logic_vector(10 downto 0);
signal add_res2			: unsigned(32 downto 0);

constant PACKET_LEN	   		: natural := 32;
constant PACKET_LEN_WIDTH	: natural := calc_width(PACKET_LEN);

type rand_occ_arr is array (0 to 4) of natural;

begin

process 
variable r_min : natural;
variable r_max : natural;
variable rand_nat : natural;
variable rnd_iters : natural;
variable r_occures : rand_occ_arr;
begin
	wait for 10 ns;
	report "TEST1 reverse bytes fun";
	vout <= reverse_bytes(vin);
	wait for 10 ns;
	assert vout = x"67452301"
	 report " <<<FAILURE>>> "
	 severity failure;
	
	
	wait for 10 ns;
	report "TEST2 reverse bytes fun";
	vout2 <= reverse_bytes(vin2);
	wait for 10 ns;
	assert vout2 = x"452301"
	 report " <<<FAILURE>>> "
	 severity failure;	
		
	wait for 10 ns;
	report "TEST3 reverse bytes fun";
	vout2 <= reverse_bytes(x"010203");
	wait for 10 ns;
	assert vout2 = x"030201"
	 report " <<<FAILURE>>> "
	 severity failure;	
	 
	 
	-- test const conv first
	report "const width_calc";	
	assert PACKET_LEN_WIDTH = 6 report "const conv result="&natural'image(PACKET_LEN_WIDTH) &" expected "&natural'image(6)	
	severity failure;
	 
	wait for LDL;
	report "calc_width(3)";
		conv_res <= calc_width(CONV_ARG);
	wait for 0 ps;
	assert conv_res = 2 report " calc width fail " severity failure;
	
	wait for LDL;
	report "calc_width(63)";
		conv_res <= calc_width(63);
	wait for 0 ps;
	assert conv_res = 6 report " calc width fail " severity failure;		
	
	wait for LDL;
	report "calc_width(4)";
		conv_res <= calc_width(4);
	wait for 0 ps;
	wait for LDL;
	assert conv_res = 3 report " calc width fail " severity failure;	

	wait for LDL;
	report "calc_width(32)";
		conv_res <= calc_width(32);
	wait for 0 ps;
	assert conv_res = 6 report "result="&natural'image(conv_res) &" expected "&natural'image(6)
	severity failure;	
	
	wait for LDL;
	report "calc_width(64)";
		conv_res <= calc_width(64);
	wait for 0 ps;
	assert conv_res = 7 report "result="&natural'image(conv_res) &" expected "&natural'image(7)
	severity failure;	
	
	

	wait for LDL;
	wait for LDL;
--	report "TEST calc_width width as inputs";
--		conv_res <= calc_width(2,3);
--	wait for 0 ps;
--	assert conv_res = 4 report " calc width fail " severity failure;	
--	
--	wait for LDL;
--	report "TEST calc_width width as inputs";
--		conv_res <= calc_width(3,2);
--	wait for 0 ps;
--	assert conv_res = 4 report " calc width fail " severity failure;
--	
--	
--		wait for LDL;
--	report "TEST calc_width width as inputs";
--		conv_res <= calc_width(4,5);
--	wait for 0 ps;
--	assert conv_res = 6 report " calc width fail " severity failure;				
	
	wait for LDL;
	report "[add_uns] testing slv full '1'";
	-- add 4 bit (15 max) + 5 bit  (31 max) = 46 (6bit)
	add1	<= (others => '1');	
	add2	<= (others => '1');	
	wait for 0 ps;
	add_res <= add_uns(add1,add2);
	wait for 0 ps;
	assert add_res = 46
		report "add res not matching"
		severity failure;


	wait for LDL;
	report "[add_uns] testing slv general";
	add12	<= std_logic_vector(to_unsigned(5347, add12'length));
	add22	<= std_logic_vector(to_unsigned(29, add22'length));
	wait for 0 ps;
	add_res2 <= add_uns(add12,add22);
	wait for 0 ps;
	assert add_res2 = 5347+29
		report "add res not matching"
		severity failure;
		
		
	wait for LDL;
	wait for LDL;
	report " [ceil_2_pow_n] testing ";
	assert ceil_2_pow_n(5) = 8
		report "val for arg 5 is: "&natural'image(ceil_2_pow_n(8))
		severity failure;

	report " [ceil_2_pow_n] testing ";
	assert ceil_2_pow_n(4) = 4
		report "val for arg 4 is: "&natural'image(ceil_2_pow_n(4))
		severity failure;

	report " [ceil_2_pow_n] testing ";
	assert ceil_2_pow_n(3) = 4
		report "val for arg  3 is: "&natural'image(ceil_2_pow_n(3))
		severity failure;		

	report " [ceil_2_pow_n] testing ";
	assert ceil_2_pow_n(6) = 8
		report "val for arg  6 is: "&natural'image(ceil_2_pow_n(6))
		severity failure;			
	
	report " [ceil_2_pow_n] testing ";
	assert ceil_2_pow_n(8) = 8
		report "val for arg  8 is: "&natural'image(ceil_2_pow_n(8))
		severity failure;	

	report " [ceil_2_pow_n] testing ";
	assert ceil_2_pow_n(9) = 16
		report "val for arg  16 is: "&natural'image(ceil_2_pow_n(9))
		severity failure;	
		
		
	
	
		
	report "   [ STIM ] testing rand range 0..3 natural gen";
		r_min := 0;
		r_max := 3;
	for i in 1 to 10 loop
		rand_nat := rand_natural(r_min, r_max);
		report natural'image(rand_nat);
		assert rand_nat >= r_min and rand_nat <= r_max 
		report " FAIL: rnd not in range"
		severity failure;
	end loop;
		
		
	report "   [ STIM ] testing rand range 1..3 natural gen";
	r_min := 1;
	r_max := 3;
	for i in 1 to 10 loop
		rand_nat := rand_natural(r_min, r_max);
		report natural'image(rand_nat);
		assert rand_nat >= r_min and rand_nat <= r_max 
		report " FAIL: rnd not in range"
		severity failure;
	end loop;
		
		
	report "   [ STIM ] testing rand range 1..4 natural gen";
	r_min := 1;
	r_max := 4;
	for i in 1 to 10 loop
		rand_nat := rand_natural(r_min, r_max);
		report natural'image(rand_nat);
		assert rand_nat >= r_min and rand_nat <= r_max 
		report " FAIL: rnd not in range"
		severity failure;
	end loop;
		
		
	rnd_iters := 100000;
	report "   [ STIM ] estimating statistic of unform nat random gen ITERS = "
	&natural'image(rnd_iters);
	r_occures := (others => 0);
	r_min := 0;
	r_max := 4;
	for i in 1 to rnd_iters loop
		rand_nat := rand_natural(r_min, r_max);
		assert rand_nat >= r_min and rand_nat <= r_max 
		report " FAIL: rnd not in range"
		severity failure;
		for j in 0 to r_max loop
			if j = rand_nat then
				r_occures(j) := r_occures(j) +1;
			end if;
		end loop;
	end loop;

	for i in 0 to r_max loop
		report "Occurences: "&natural'image(r_occures(i));
	end loop;
	
		
	rnd_iters := 100000;
	report "   [ STIM ] estimating statistic of unform nat random gen ITERS = "
	&natural'image(rnd_iters);
	r_occures := (others => 0);
	r_min := 1;
	r_max := 4;
	for i in 1 to rnd_iters loop
		rand_nat := rand_natural(r_min, r_max);
		assert rand_nat >= r_min and rand_nat <= r_max 
		report " FAIL: rnd not in range"
		severity failure;
		for j in 0 to r_max loop
			if j = rand_nat then
				r_occures(j) := r_occures(j) +1;
			end if;
		end loop;
	end loop;

	for i in 0 to r_max loop
		report "Occurences: "&natural'image(r_occures(i));
	end loop;
	
	
	report "   [ STIM ] Testing axis_keep_width function";
	-- Argument is datab us width
	assert  axis_keep_width(33) = 5 severity failure;
	assert  axis_keep_width(32) = 4 severity failure;
	assert  axis_keep_width(31) = 4 severity failure;
	assert  axis_keep_width(25) = 4 severity failure;
	assert  axis_keep_width(24) = 3 severity failure;
	assert  axis_keep_width(16) = 2 severity failure;
	assert  axis_keep_width(15) = 2 severity failure;
				
wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;


end process;

end common_pkg_tb_arch;
