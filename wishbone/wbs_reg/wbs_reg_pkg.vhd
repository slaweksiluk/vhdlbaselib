--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbs_reg_pkg.vhd
-- Language: VHDL
-- Description: 
-- 	
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:

--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library vhdlbaselib;
use vhdlbaselib.wbs_reg_user_pkg.all;


package wbs_reg_pkg is
	constant ITEMS_NUM		: natural;
	constant READ_ITEMS_NUM		: natural;
	constant WRITE_ITEMS_NUM	: natural;
	constant REG_O_WIDTH		: natural;	
	constant REG_I_WIDTH		: natural;
	-- co]py addr align constant from user pkg to be visible everywhere
	-- not working with GHDL?
--	constant ADDR_ALIGN			: natural := ADDR_ALIGN;
		
	
	function port_range(pos : natural) return std_logic_vector;
	function reg_o_range(i : natural) return std_logic_vector;
	function reg_o_index(i : natural) return natural;
	function reg_i_range(i : natural) return std_logic_vector;
	function reg_i_index(i : natural) return natural;
	function reg_range(pos : natural) return std_logic_vector;
	function port_h(pos : natural) return natural;
	function port_l(pos : natural) return natural;
	function item_width(pos : natural) return natural;
	function rd_port_h(pos : natural) return natural;
	function rd_port_l(pos : natural) return natural;
	function rd_item_width(pos : natural) return natural;
	function is_rw(
		pos : natural
		) return boolean;
	function is_ro(
		pos : natural
		) return boolean;
	function o_inter_h(
		 arg :  natural
		) return natural;
	function o_inter_l(
		 arg :  natural
		) return natural;
	function is_rw_rd_ind(
		arg : natural
		) return boolean;
	function is_ro_rd_ind(
		arg : natural
		) return boolean;
	function is_pulse(
		pos : natural
		) return boolean;
	function is_pulse_common_ind(
		pos : natural
		) return boolean;
	function reg_o_default
		return std_logic_vector;
	function is_in_port_gnd(
		 e : registers_t
		) return boolean;
	function is_in_port(
		 e : registers_t
		) return boolean;		
	function is_out_port(
		 e : registers_t
		) return boolean;
		
	procedure PRINT_READ_ITEMS_ARR;
	procedure PRINT_WRITE_ITEMS_ARR;
	procedure PRINT_ITEMS_ATT_ARR;		
	function reg_width return natural;
	function rd_addr_match(
	 wb_adr 		: std_logic_vector;
	 loop_index 	: natural) 
	 return boolean;
	function wr_addr_match(
	 wb_adr 		: std_logic_vector;
	 loop_index 	: natural) 
	 return boolean;
	function readable(i : natural ) return boolean;
	function writable(i : natural ) return boolean;

-- GHDL playing	
--	 constant SW_INT_RESET_INDEX	: natural := reg_o_index(registers_t'pos(SW_INT_RESET_E));
end wbs_reg_pkg;
package body wbs_reg_pkg is
	

-- Number of items in user enum
	function items_num_init
		return natural is
		variable v : natural := 0;
	begin
		for i in 0 to MAX_ITEMS_NUM-1 loop
			v := i;
			exit when RS_ITEMS_ATT_ARR(i).width = 0;
		end loop;
	return v;	
	end function;
	constant ITEMS_NUM	: natural := MAX_ITEMS_NUM;
--	constant ITEMS_NUM	: natural := items_num_init;





--
-- Array of record with items attributes
--
--

	procedure PRINT_ITEMS_ATT_ARR is begin
		report " %%% PRINT_ARR ";	
		for i in 0 to ITEMS_NUM-1 loop
			report " width: "&natural'image(RS_ITEMS_ATT_ARR(i).width);
			report " acces mode: "&access_t'image(RS_ITEMS_ATT_ARR(i).access_mode);
			if RS_ITEMS_ATT_ARR(i).access_mode = WO then
				report " have WO";
			end if;
			if RS_ITEMS_ATT_ARR(i).access_mode = RW then
				report " have RW";
			end if;
			if RS_ITEMS_ATT_ARR(i).access_mode = RO then
				report " have RO";
			end if;
			if RS_ITEMS_ATT_ARR(i).access_mode = PULSE then
				report " have PULSE";
			end if;
		end loop;
	end procedure;

	
-- Record with R/W specific data
	type rw_record_t is record
		enum_pos	: natural;
		addr		: natural;
		width		: natural;
		high		: natural;
		low			: natural;
		access_mode	: access_t;
		name		: string(1 to 10);
		default		: natural;
	end record;
	
-- Stuff for calcuting read items number
	function read_items_num_init return natural is
		variable read_items : natural := 0;
	begin
	
		for i in 0 to ITEMS_NUM-1 loop
			if RS_ITEMS_ATT_ARR(i).access_mode = (RO) or RS_ITEMS_ATT_ARR(i).access_mode = (RW) then
				read_items := read_items +1;
			end if;
		end loop;
		return read_items;
	end function;
	constant READ_ITEMS_NUM	: natural := read_items_num_init;

-- Stuff for calcuting write items number
	function write_items_num_init return natural is
		variable items : natural := 0;
	begin
	
		for i in 0 to ITEMS_NUM-1 loop
			if writable(i) then
				items := items +1;
			end if;
		end loop;
		return items;
	end function;
	constant WRITE_ITEMS_NUM	: natural := write_items_num_init;	


	-- generic arr of record - the seame size for Read and write
	type rw_record_arr_t is array (0 to ITEMS_NUM-1) of rw_record_t;
--	subtype read_record_arr_t is rw_record_arr_t range 0 to READ_ITEMS_NUM-1;
--	subtype write_record_arr_t is rw_record_arr_t range 0 to WRITE_ITEMS_NUM-1;

-- Constant array with addresses for READ

	function set_rw_record(
		arr		: rw_record_arr_t;
		arr_i	: natural;
		rs_arr	: rs_items_att_arr_t;
		i		: natural
	) return rw_record_t is
		variable ret_rec : rw_record_t;
	begin
		ret_rec.enum_pos := i;
		ret_rec.addr 	:= i * ADDR_ALIGN;
		ret_rec.width 	:= rs_arr(i).width;
		ret_rec.access_mode	:= rs_arr(i).access_mode;
--		ret_rec.name	:= rs_arr(i).name;
		ret_rec.default	:= rs_arr(i).default;
		if arr_i = 0 then
			ret_rec.high 	:= rs_arr(i).width -1;
			ret_rec.low 	:= 0;
		else
			ret_rec.high 	:= arr(arr_i-1).high + rs_arr(i).width;
			ret_rec.low 	:= arr(arr_i-1).high +1;			
		end if;
		return ret_rec;		
	end function;		


	function read_record_arr_init return rw_record_arr_t is
		variable arr : rw_record_arr_t;
		variable arr_i : natural := 0;
	begin
		for i in 0 to ITEMS_NUM-1 loop
			if readable(i) then
				arr(arr_i) := set_rw_record(arr, arr_i, RS_ITEMS_ATT_ARR, i);
				-- incerment small array size
				arr_i := arr_i +1;
			end if;
		end loop;
		return arr;
	end function;	
	constant READ_ADDR_ARR 	: rw_record_arr_t := read_record_arr_init;
	
	function write_record_arr_init return rw_record_arr_t is
		variable arr : rw_record_arr_t;
		variable arr_i : natural := 0;
	begin
		for i in 0 to ITEMS_NUM-1 loop
			if writable(i) then
				arr(arr_i) := set_rw_record(arr, arr_i, RS_ITEMS_ATT_ARR, i);
				-- incerment small array size
				arr_i := arr_i +1;
			end if;
		end loop;
		return arr;
	end function;	
	constant WRITE_ADDR_ARR 	: rw_record_arr_t := write_record_arr_init;	

	
	function print_rw_record(
		 arg : rw_record_t
		) return boolean is
		variable v : natural := 0;
	begin
		report " addr: "&natural'image(arg.addr);
		report " width: "&natural'image(arg.width);
		report " high: "&natural'image(arg.high);
		report " low: "&natural'image(arg.low);	
		return true;
	end function;
	procedure PRINT_WRITE_ITEMS_ARR is 
		variable dummy : boolean;
	begin
		for i in 0 to WRITE_ITEMS_NUM-1 loop
			report " %%% PRINT_WRITE_ITEMS_ARR index" &natural'image(i);
			dummy := print_rw_record(WRITE_ADDR_ARR(i));
		end loop;
	end procedure;
	procedure PRINT_READ_ITEMS_ARR is 
		variable dummy : boolean;
	begin
		for i in 0 to READ_ITEMS_NUM-1 loop
			report " %%% PRINT_READ_ITEMS_ARR index" &natural'image(i);
			dummy := print_rw_record(READ_ADDR_ARR(i));
		end loop;
	end procedure;
	
	
-- internal function for checking aligment. ret true when ok. used in rd/wr_addr_match
	function check_aligment(
		 arg : std_logic_vector
		) return boolean is
		variable v : natural := 0;
	begin
		v	:= to_integer(unsigned(arg));
		if v mod ADDR_ALIGN = 0 then
			return true;
		else	
			return false;
		end if;
	end function;
		

	function rd_addr_match(
		 wb_adr 		: std_logic_vector;
		 loop_index 	: natural
		) return boolean is
		variable arr_item : std_logic_vector(wb_adr'range);
		variable wb_adr_nat : natural;
	begin
		assert check_aligment(wb_adr)
			report "[wbs_reg_pkg] rd_addr_match() wrong wb_adr align"
			severity failure;
		arr_item := std_logic_vector(to_unsigned(READ_ADDR_ARR(loop_index).addr, wb_adr'length));
		if arr_item = wb_adr then
			return true;
		else
			return false;
		end if;		
	end function;

	function wr_addr_match(
		 wb_adr 		: std_logic_vector;
		 loop_index 	: natural
		) return boolean is
		variable arr_item : std_logic_vector(wb_adr'range);
	begin
		assert check_aligment(wb_adr)
			report "[wbs_reg_pkg] wr_addr_match() wrong wb_adr align"
			severity failure;	
		arr_item := std_logic_vector(to_unsigned(WRITE_ADDR_ARR(loop_index).addr, wb_adr'length));
		if arr_item = wb_adr then
			return true;
		else
			return false;
		end if;		
	end function;


-- Retrun enum as slv address	
	function reg_adr_slv( 
		enum_pos 	: natural;
		width	 	: natural
			) return std_logic_vector is
		variable result : natural;
	begin
		return 	std_logic_vector(to_unsigned(enum_pos, width));
					
	end function;
	
	function index_high(pos : natural) return natural is
		variable pos_h : natural := 0;
	begin
		for I in 0 to pos loop
			pos_h := pos_h + RS_ITEMS_ATT_ARR(I).width;
		end loop;
		pos_h := pos_h-1;
--		report "port_pos_h() pos_h" & natural'image(pos_h);
		return pos_h;
	end function;	
	
	
-- Indxing functions for writing
	function port_h(pos : natural) return natural is
	begin
		return WRITE_ADDR_ARR(pos).high;
	end function;
		function port_l(pos : natural) return natural is
	begin
		return WRITE_ADDR_ARR(pos).low;	
	end function;
	function item_width(pos : natural) return natural is	begin
		return WRITE_ADDR_ARR(pos).width;	
	end function;
	
	
-- Indxing functions for reading
	function rd_port_h(pos : natural) return natural is
	begin
		return READ_ADDR_ARR(pos).high;
	end function;
	function rd_port_l(pos : natural) return natural is
	begin
		return READ_ADDR_ARR(pos).low;	
	end function;	
	function rd_item_width(pos : natural) return natural is	begin
		return READ_ADDR_ARR(pos).width;	
	end function;	
	
	
	function port_range(	
		pos_h	: natural;
		pos_l	: natural
			) return std_logic_vector is 
		variable v : std_logic_vector(pos_h downto pos_l) := (others => '0');						
			begin
--			report "port_range() pos_h" & natural'image(pos_h) &"pos_l"&natural'image(pos_l);
			return v;
	end function;
	
	function port_range(pos : natural) return std_logic_vector is
		variable pos_h : natural := 0;
		variable pos_l : natural := 0;
	begin
		for I in 0 to pos loop
			pos_h := pos_h + RS_ITEMS_ATT_ARR(I).width;
		end loop;
		
		pos_l := pos_h - RS_ITEMS_ATT_ARR(pos).width;
		pos_h := pos_h -1;
		return port_range(pos_h, pos_l);
	end function;
	
--------------------------------------------------------------------------------
-- Below internal fuinction is returning slv ih range given by naturals
--------------------------------------------------------------------------------
	function slv_range(	
		pos_h	: natural;
		pos_l	: natural
			) return std_logic_vector is 
		variable v : std_logic_vector(pos_h downto pos_l) := (others => '0');						
		begin
			return v;
	end function;		
	
--------------------------------------------------------------------------------
-- Functions for calculating reg_o boundaries for instnantation
--------------------------------------------------------------------------------
	function reg_o_range(i : natural) return std_logic_vector is
		variable ind_h : natural := 0;
		variable ind_l : natural := 0;
	begin
		for r in 0 to WRITE_ITEMS_NUM-1 loop
			ind_h := WRITE_ADDR_ARR(r).high;
			ind_l := WRITE_ADDR_ARR(r).low;
			exit when WRITE_ADDR_ARR(r).enum_pos = i;
		end loop;
--		assert ind_h /= ind_l
--			report " [wbs_reg_pkg]  reg_o_range fun err - ind h equal to ind l, hence reg_o_index() should be used"
--			severity failure;			
		return slv_range(ind_h, ind_l);
	end function;

	function reg_o_index(i : natural) return natural is
		variable ind_h : natural := 0;
		variable ind_l : natural := 0;
	begin
		for r in 0 to WRITE_ITEMS_NUM-1 loop
			ind_h := WRITE_ADDR_ARR(r).high;
			ind_l := WRITE_ADDR_ARR(r).low;
			exit when WRITE_ADDR_ARR(r).enum_pos = i;
		end loop;
		assert ind_h = ind_l
			report " [wbs_reg_pkg]  reg_o_index fun err - ind h not equal ind l, hence reg_o_rannge() should be used"
			severity failure;
		return ind_h;
	end function;
	
	
	
--------------------------------------------------------------------------------
-- Functions for calculating reg_i boundaries for instnantation
--------------------------------------------------------------------------------
	function reg_i_range(i : natural) return std_logic_vector is
		variable ind_h : natural := 0;
		variable ind_l : natural := 0;
	begin
		for r in 0 to READ_ITEMS_NUM-1 loop
			ind_h := READ_ADDR_ARR(r).high;
			ind_l := READ_ADDR_ARR(r).low;
			exit when READ_ADDR_ARR(r).enum_pos = i;
		end loop;
--		assert ind_h /= ind_l
--			report " [wbs_reg_pkg.vhd]  reg_i_range fun err - ind h equal to ind l, hence reg_i_index() should be used"
--			severity failure;		
		return slv_range(ind_h, ind_l);
	end function;

	function reg_i_index(i : natural) return natural is
		variable ind_h : natural := 0;
		variable ind_l : natural := 0;
	begin
		for r in 0 to READ_ITEMS_NUM-1 loop
			ind_h := READ_ADDR_ARR(r).high;
			ind_l := READ_ADDR_ARR(r).low;
			exit when READ_ADDR_ARR(r).enum_pos = i;
		end loop;
		assert ind_h = ind_l
			report " [wbs_reg_pkg]  reg_i_index fun err - ind h not equal ind l, hence reg_i_rannge() should be used"
			severity failure;
		return ind_h;
	end function;	
	









	function reg_range(pos : natural) return std_logic_vector is
		variable v : std_logic_vector((RS_ITEMS_ATT_ARR(pos).width)-1 downto 0);								
	begin
		return v;	
	end function;
	
--	function reg_o_width return natural is
--		variable w : natural :=0;
--	begin
--		for I in 0 to READ_ITEMS_NUM-1  loop
--			w := w + RS_ITEMS_ATT_ARR(I).width;
--		end loop;		
--		return w;	
--	end function;

	function reg_width return natural is
		variable w : natural :=0;
	begin
		for I in 0 to ITEMS_NUM-1  loop
			w := w + RS_ITEMS_ATT_ARR(I).width;
		end loop;		
		return w;	
	end function;
	
	
	function readable(i : natural ) return boolean is
	begin
		if RS_ITEMS_ATT_ARR(i).access_mode = RO or RS_ITEMS_ATT_ARR(i).access_mode = (RW) then
			return true;
		else
			return false;
		end if;	
	end function;
	
	function writable(i : natural ) return boolean is
	begin
		if RS_ITEMS_ATT_ARR(i).access_mode = WO or 
		RS_ITEMS_ATT_ARR(i).access_mode = RW or 
		RS_ITEMS_ATT_ARR(i).access_mode = PULSE then
			return true;
		else
			return false;
		end if;	
	end function;	
	
-- Calcualte width of entity output register	
	function reg_o_width_init
		return natural is
		variable v : natural := 0;
	begin
		v := WRITE_ADDR_ARR(WRITE_ITEMS_NUM-1).high +1;
		return v;
	end function;
	constant REG_O_WIDTH	: natural := reg_o_width_init;


-- Calcualte width of entity input register	
	function reg_i_width_init
		return natural is
		variable v : natural := 0;
	begin
		v := READ_ADDR_ARR(READ_ITEMS_NUM-1).high +1;
		return v;
	end function;
	constant REG_I_WIDTH	: natural := reg_i_width_init;	
	
--	
--	function width( pos : natural) return natural is
--	begin
--		return RS_ITEMS_ATT_ARR(pos).width;
--	end function;	
--	
--	function get_range( enum_ps : natural
--						) return range is begin
--						
--	end function;

	function is_ro_rd_ind(
		arg : natural
		) return boolean is
		variable ind : natural := 0;
	begin
		if READ_ADDR_ARR(arg).access_mode = RO then
			return true;
		else
			return false;
		end if;	
	end function;
	
	function is_rw_rd_ind(
		arg : natural
		) return boolean is
		variable ind : natural := 0;
	begin
		if READ_ADDR_ARR(arg).access_mode = RW then
			return true;
		else
			return false;
		end if;	
	end function;						
		
	function is_ro(
		pos : natural
		) return boolean is
	begin
		if 	RS_ITEMS_ATT_ARR(pos).access_mode = RO then
			return true;
		else
			return false;
		end if;
	end function;
	
	function is_rw(
		pos : natural
		) return boolean is
	begin
		if 	RS_ITEMS_ATT_ARR(pos).access_mode = RW then
			return true;
		else
			return false;
		end if;
	end function;
	
	
-- is pulse return fun
	function is_pulse(
		pos : natural
		) return boolean is
	begin
		if 	WRITE_ADDR_ARR(pos).access_mode = PULSE then
			return true;
		else
			return false;
		end if;
	end function;

	function is_pulse_common_ind(
		pos : natural
		) return boolean is
	begin
		if 	RS_ITEMS_ATT_ARR(pos).access_mode = PULSE then
			return true;
		else
			return false;
		end if;
	end function;
	
-- This function is getting ITEM_ID (in read items) and returns high index of WRITE ITEMS array 
-- which has the smae ITEM ID as given argument. 
--reg_i_inter(rd_port_h(R) downto rd_port_l(R)) <= reg_o_inter(o_inter_h(R) downto o_inter_l(R));	
	function o_inter_h(
		 arg :  natural
		) return natural is
		variable ret : natural := 0;
	begin
		-- Loop in write items until finds the same addr
		for i in 0 to WRITE_ITEMS_NUM-1 loop
			-- Compare the itemd id in argument with those i WRITE_ADDR_ARR
			ret := WRITE_ADDR_ARR(i).high;
			exit when WRITE_ADDR_ARR(i).addr = READ_ADDR_ARR(arg).addr;
		end loop;
		return ret;
	end function;

-- As above for index low
	function o_inter_l(
		 arg :  natural
		) return natural is
		variable ret : natural := 0;
	begin
		-- Loop in write items until finds the same addr
		for i in 0 to WRITE_ITEMS_NUM-1 loop
			-- Compare the itemd id in argument with those i WRITE_ADDR_ARR
			ret := WRITE_ADDR_ARR(i).low;
			exit when WRITE_ADDR_ARR(i).addr = READ_ADDR_ARR(arg).addr;
		end loop;
		return ret;		
	end function;		


-- function returing vector with deafault reg_o configuration
	function reg_o_default
		return std_logic_vector is
		variable v : std_logic_vector(REG_O_WIDTH-1 downto 0);
	begin
		for s in 0 to WRITE_ITEMS_NUM-1 loop
			-- using reg_o_range function below is causing vivado simulatro internal excepion during compilation
			v(port_h(s) downto port_l(s)) := std_logic_vector(to_unsigned(WRITE_ADDR_ARR(s).default, WRITE_ADDR_ARR(s).width));
		end loop;
		return v;
	end function;
	
-- Group of function to decide if to pot port to i/o if port inst in wrapper
-- generator. Possible values
--		RO,
--		WO,
--		RW,
--		PULSE,
--		RESERVED
	-- Register is output port / port map when it is WO RW PULSE type
	function is_out_port(
		 e : registers_t
		) return boolean is
	begin
 		 return RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode = WO or				
 		 	RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode = RW or				
 		 	RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode = PULSE;				
	end function;
	-- Register is in input port / port map when it is RO type only.
	function is_in_port(
		 e : registers_t
		) return boolean is
	begin
 		 return RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode = RO;				
	end function;
	-- Register is in input port map tied to gnd when it is RW
	function is_in_port_gnd(
		 e : registers_t
		) return boolean is
	begin
 		 return RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode = RW;				
	end function;			
		

end wbs_reg_pkg;
