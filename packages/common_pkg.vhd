--------------------------------------------------------------------------------
-- Module Name: common_pkg.vhd
-- Language: VHDL
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;
use IEEE.math_real.all;


package common_pkg is

function reverse_bytes( din : in std_logic_vector) return std_logic_vector;
function reverse_slices(
	din 		: in std_logic_vector;
	SLICE_WIDTH : in positive
	 ) return std_logic_vector;
function reverse_any_vector (a: in std_logic_vector) return std_logic_vector;
function To_Boolean(L: std_logic) return Boolean;
function To_Std_Logic(L: boolean) return std_logic;
function to_std_logic(
	 arg : natural
) return std_logic;
function divFun(L: natural; R: natural) return natural;
function calc_width(x: positive) return positive;
function calc_width(
	width1: natural;
	width2: natural
) return natural;
function mso_index(
	 arg : std_logic_vector
	) return natural;
function calc_len(
	 arg : natural
	) return natural;
function To_SLV(n : natural; l : natural) return std_logic_vector;
function To_Nat(s : std_logic_vector) return natural;
function to_natural( s : std_logic ) return natural;
function slice_range(
		s_pos 		: natural;
		s_width		: positive
) return std_logic_vector;
function sih(
		s_pos 		: natural;
		s_width		: positive
	)
return natural;
function sil(
		s_pos 		: natural;
		s_width		: positive
	)
return natural;
function add_uns(
		 arg1 : std_logic_vector;
		 arg2 : std_logic_vector
) return unsigned;
	function add_slv(
		 arg1 : std_logic_vector;
		 arg2 : std_logic_vector
) return std_logic_vector;
--function calc_sum_width(
--	 arg1 : std_logic_vector;
--	 arg2 : std_logic_vector
--	) return natural;
--function calc_sum_width(
--	 arg1 : natural;
--	 arg2 : natural
--	) return natural;
function ceil_2_pow_n(
	 arg 	: natural
	) return natural;
--  function or_reduce(V : std_logic_vector)
--    return std_ulogic;
function to_01(a: in std_logic_vector)
	return std_logic_vector;
function axi_st_mask(keep : std_logic_vector)
	return std_logic_vector;
function axi_st_zero_mask(
	 data : std_logic_vector;
	 keep : std_logic_vector
) return std_logic_vector;
function axi_st_reduce_keep(
	 data_width : positive range 32 to 128;
	 slice_width : positive range 8 to 32;
	 keep : std_logic_vector
) return std_logic_vector;
function axis_keep_width(
	data_width		: positive
)	return positive;
function max(LEFT, RIGHT: INTEGER) return INTEGER;
impure function rand_natural(
	 min : natural;
	 max : natural
) return natural;

function or_reduce(V : std_ulogic_vector) return std_ulogic;
function and_reduce(V : std_ulogic_vector) return std_ulogic;

end common_pkg;
package body common_pkg is

function To_SLV(n : natural; l : natural) return std_logic_vector is
begin
return std_logic_vector(to_unsigned(n,l));
end function To_SLV;

function To_Nat(s : std_logic_vector) return natural is
begin
return to_integer(unsigned(s));
end function To_Nat;

-- log2(64) = 5.9999999 instead of 6. Thats why small value is added to log2 res
-- it seems bug... Need to pass it to vhdl working group
function calc_width(x: positive) return positive is
	constant D : boolean := false;
	variable r : real;
	variable l : real;
	variable f : real;
begin
--return natural(ceil(log2(real(x + 1))));
--octave:6> floor(log2(64))+1
--ans =  7
--octave:7> floor(log2(63))+1
--ans =  6
	r := real(x);
	l := log2(r) + 0.000000001;
	f := floor(l);
	if D then
		report "r"&real'image(r);
		report "l"&real'image(l);
		report "f"&real'image(f);
	end if;

	return positive(f+1.0);
--	return positive(floor(log2(real(x)))) +1;
--	return natural(floor(log2(real(x))+1.0));
end function calc_width;

-- calc width form widths
function calc_width(
	width1: natural;
	width2: natural
) return natural is
	variable w_big : natural;
	variable w_small : natural;
begin
--log(a+b)=log(a*(1+b/a))=log(a) + log(1+b/a) when a>b
--log(1+b/a) = log(1+(2^b-1)/(2^a-1))) ~= log(1+2^b/2^a) = log(1+ 2^(b-a)) = log(1+1/2^(a-b))
--if width1 > width2 then
--	w_big := width1;
--	w_small := width2;
--else
--	w_big := width2;
--	w_small := width1;
--end if;
--return w_big + calc_width(1 + 1/(2**(w_big-w_small))) -1;
if width1 > width2 then
	return width1+1;
else
	return width2+1;
end if;
end function calc_width;

-- clac with of
function calc_width(
	 arg1 : std_logic_vector;
	 arg2 : std_logic_vector
	) return natural is
begin
	return calc_width(2**(arg1'length)-1 + 2**(arg2'length)-1);
end function;
--
---- input are summed variables widths
--function calc_sum_width(
--	 arg1 : natural;
--	 arg2 : natural
--	) return natural is
--begin
--	return calc_width(2**(arg1)-1 + 2**(arg2)-1);
--end function;
function calc_len(
	 arg : natural
	) return natural is
begin
	return 2**arg -1;
end function;


function divFun(L: natural; R: natural) return natural is
begin
if L > R then
	return(L/R);
else
	return(R/L);
end if;
end function divFun;

function To_Std_Logic(L: boolean) return std_logic is
begin
if L = true then
return('1');
else
return('0');
end if;
end function To_Std_Logic;

function to_std_logic(
	 arg : natural
	) return std_logic is
begin
	if arg = 0 then
		return '0';
	else
		return '1';
	end if;
end function;


function To_Boolean(L: std_logic) return Boolean is
begin
if L = '1' then
return(true);
else
return(false);
end if;
end function To_Boolean;

function reverse_any_vector (a: in std_logic_vector)
return std_logic_vector is
  variable result: std_logic_vector(a'RANGE);
  alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
begin
  for i in aa'RANGE loop
    result(i) := aa(i);
  end loop;
  return result;
end; -- function reverse_any_vector

function reverse_bytes( din : in std_logic_vector) return std_logic_vector is
	variable ret 		: std_logic_vector(din'length-1 downto 0);
	variable din_v 		: std_logic_vector(din'length-1 downto 0);
	variable bytes_num 	: natural;
begin
	-- Change to -> downto if neccessry
--	if din'ASCENDING then
--		report "ASCENDING";
		din_v := din;
--	end if;

	-- Check if reverse is possible
	assert ((din'length) mod 8) = 0
		report "reverse_bytes() function error: input vector length is not multpily of 8bits"
		severity failure;

	-- Calcualte size in bytes
	bytes_num := din_v'length / 8;

	for I in 1 to bytes_num loop
		ret(I*8-1 downto (I-1)*8) := din_v((bytes_num-I+1)*8-1 downto (bytes_num-I)*8);
	end loop;
	return ret;
end;

function reverse_slices(
	din 		: in std_logic_vector;
	SLICE_WIDTH : in positive
	 ) return std_logic_vector is
	variable ret 			: std_logic_vector(din'length-1 downto 0);
	variable din_v 			: std_logic_vector(din'length-1 downto 0);
	variable slices_num 	: natural;
begin
	-- Change to -> downto if neccessry
--	if din'ASCENDING then
--		report "ASCENDING";
		din_v := din;
--	end if;

	-- Check if reverse is possible
	assert ((din'length) mod SLICE_WIDTH) = 0
		report "reverse_slices() function error: input vector length is not multpily of SLICE_WIDTH"
		severity failure;

	-- Calcualte size in bytes
	slices_num := din_v'length / SLICE_WIDTH;

	for I in 1 to slices_num loop
		ret(I*SLICE_WIDTH-1 downto (I-1)*SLICE_WIDTH) := din_v((slices_num-I+1)*SLICE_WIDTH-1 downto (slices_num-I)*SLICE_WIDTH);
	end loop;

	return ret;
end;




function to_natural( s : std_logic ) return natural is
begin
  if s = '1' then
    return 1;
  else
    return 0;
  end if;
end function;





-- sim only function for returning slv range on the basis of:
--	slice position
--	slice width
	-- internal function
	function slice_range_slv(
		pos_h	: natural;
		pos_l	: natural
	)
	return std_logic_vector is
		variable v : std_logic_vector(pos_h downto pos_l) := (others => '0');
	begin
		return v;
	end function;


	-- user function. Somtimes return sigsigv in vivado...
	function slice_range(
		s_pos 		: natural;
		s_width		: positive
	)
	return std_logic_vector is
		variable pos_h : natural := 0;
		variable pos_l : natural := 0;
		variable v		: std_logic_vector(0 downto 0);
	begin
--		assert s_width > 1
--		report "[common_pkg.vhd] slice_range() width < 2"
--		severity warning;
		if s_width = 1 then
			return v;
		end if;

		pos_h := (s_pos+1)*s_width-1;
		pos_l := s_pos*s_width;
		return slice_range_slv(pos_h, pos_l);
	end function;

	-- Slice Index High
	function sih(
		s_pos 		: natural;
		s_width		: positive
	)
	return natural is
	begin
		return (s_pos+1)*s_width-1;
	end function;
	-- Slice Index Low
	function sil(
		s_pos 		: natural;
		s_width		: positive
	)
	return natural is
	begin
		return s_pos*s_width;
	end function;


	function ret_max(
		 arg1 : natural;
		 arg2 : natural
		) return natural is
	begin
		if arg1 > arg2 then
			return arg1;
		else
			return arg2;
		end if;
	end function;


	function add_uns(
		 arg1 : std_logic_vector;
		 arg2 : std_logic_vector
		) return unsigned is
		variable v1 : unsigned(arg1'range);
		variable v2 : unsigned(arg2'range);
		variable max_width : natural;
	begin
		max_width := ret_max(arg1'length, arg2'length) +1;
		v1 := unsigned(arg1);
		v2 := unsigned(arg2);
		return resize(v1, max_width) + resize(v2, max_width);
	end function;

	function add_slv(
		 arg1 : std_logic_vector;
		 arg2 : std_logic_vector
		) return std_logic_vector is
	begin
		return std_logic_vector(add_uns(arg1, arg2));
	end function;

-- function takes number as argumet and returns the closes power of 2^n
-- which is bigger than giver arg e.g:
-- input 11 (example number of registers) res n = 4 2^4 = 16
-- input 16 (example number of registers) res n = 4 2^4 = 16
-- input 17 (example number of registers) res n = 5 2^5 = 32
	function ceil_2_pow_n(
		 arg 	: natural;
		 n		: natural
		) return natural is
		variable null_ret : natural;
	begin
--		assert n <= natural'right
--			report "[ceil_2_pow_n() n bigger than nat range]"
--			severity failure;
		if arg mod 2 = 0 then
			if (arg-1) / 2**n = 0 then
				return 2**n;
			else
				return ceil_2_pow_n(arg,n+1);
			end if;
		else
			if arg / 2**n = 0 then
				return 2**n;
			else
				return ceil_2_pow_n(arg,n+1);
			end if;
		end if;
	end function;

	function ceil_2_pow_n(
		 arg 	: natural
		) return natural is
	begin
		return ceil_2_pow_n(arg,1);
	end function;

  function or_reduce(V : std_ulogic_vector)
    return std_ulogic is
    variable result : std_ulogic;
  begin
    for i in V'range loop
      if i = V'left then
        result := V(i);
      else
        result := result or V(i);
      end if;
      exit when result = '1';
    end loop;
    return result;
  end or_reduce;

  function and_reduce(V : std_ulogic_vector)
	return std_ulogic is
	variable result : std_ulogic;
  begin
	for i in V'range loop
	  if i = V'left then
		result := V(i);
	  else
		result := result and V(i);
	  end if;
	  exit when result = '0';
	end loop;
	return result;
end and_reduce;

function to_01(a: in std_logic_vector)
return std_logic_vector is
  variable result: std_logic_vector(a'RANGE);
begin
  for i in a'RANGE loop
  	if (a(i)) = '1' then
		result(i) := '1';
	else
		result(i) := '0';
	end if;
  end loop;
  return result;
end;

-- Retruns vector with 1 at valid positons and 0 for invalid. The vector length
-- is equal to data word width (= keep_width*8)
function axi_st_mask(
	keep		: std_logic_vector
)	return std_logic_vector is
	variable t	: std_logic_vector(keep'length*8-1 downto 0);
begin
	for i in keep'reverse_range loop
		if keep(i) = '0' then
			t(slice_range(i,8)'range) := (others => '0');
		else
			t(slice_range(i,8)'range) := (others => '1');
		end if;
	end loop;
	return t;
end axi_st_mask;

-- Sets '0' at position with mask equal to 0 (data may be invalid there)
function axi_st_zero_mask(
	 data : std_logic_vector;
	 keep : std_logic_vector
) return std_logic_vector is
	variable keep_mask: std_logic_vector(data'range);
	variable r: std_logic_vector(data'range);
begin
	keep_mask := axi_st_mask(keep);
	for j in data'range loop
		if keep_mask(j) = '0' then
			r(j) := '0';
		else
			r(j) := data(j);
		end if;
	end loop;
	return r;
end function;

function axi_st_reduce_keep(
	 data_width : positive range 32 to 128;
	 slice_width : positive range 8 to 32;
	 keep : std_logic_vector
	) return std_logic_vector is
	constant  v : positive := data_width/slice_width;
	variable ret: std_logic_vector(v-1 downto 0) := (others => '0');
begin
	for i in 0 to v-1 loop
		assert and_reduce(slice_range(i, v)) = or_reduce(slice_range(i, v))
			report "common_pkg.vhd axs_st_reduce_keep() non consistent keep"
			severity failure;
		ret(i) := and_reduce(slice_range(i, v));
	end loop;
	return ret;
end function;

-- Caclutes keep signal width with respect to non 8bit multiplie values
function axis_keep_width(
	data_width		: positive
)	return positive is
	variable v	: real range 1.0 to real(data_width/8) + 1.0;
begin
	v := ceil((real(data_width) / 8.0));
	return integer(v);
end axis_keep_width;

-- return the index of '1' first from left
function mso_index(
	 arg : std_logic_vector
	) return natural is
	variable v : natural := 0;
begin

	assert or_reduce(arg) = '1'
		report "common_pkg.vhd mso_index() input vecotor is null"
		severity failure;
	for i in arg'range loop
		v := i;
		exit when arg(i) = '1';
	end loop;
	return v;
end function;


function max(LEFT, RIGHT: INTEGER) return INTEGER is
begin
  if LEFT > RIGHT then return LEFT;
  else return RIGHT;
    end if;
  end;


impure function rand_natural(
	 min : natural;
	 max : natural
) return natural is
	variable re_rnd : real;
	constant re_min : real := real(min);
	constant re_max : real := real(max+1);
begin
	return natural(trunc(re_rnd*(re_max-re_min)+re_min));
end function;



end common_pkg;
