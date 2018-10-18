--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wrap_gen.vhd
-- Language: VHDL
-- Description: 
-- 		
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- TODO
-- Fix comma generation in instance port maps
--------------------------------------------------------------------------------
library std;
use std.textio.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_textio;
--use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;
use vhdlbaselib.wbs_reg_pkg.all;
use vhdlbaselib.wbs_reg_user_pkg.all;
--use vhdlbaselib.wb_test_env_pkg.all;
--use vhdlbaselib.common_pkg.all;
--use vhdlbaselib.txt_util.all;

entity wrap_gen is
end wrap_gen;
architecture wrap_gen_arch of wrap_gen is

function write_ln(
	 arg : string		
	) return natural is
	variable v : natural := 0;
begin
end function;

-- TEST!!!
--function att_init(
--		arg	: boolean
--	
--	) return boolean is
--variable v : natural := 0;
--	begin
--    for e in 0 to 1 loop
--    	attribute ih of e : constant is 1;
--    end loop;
--end function;

--	end loop;		
--end function;
--	
--	attribute ih	: natural;
--	constant E1		: registers_t := SW_INT_RESET_E;		
--    attribute ih of E1 : constant is 1;
----    attribute ih of registers_t : type is 1;
--    type registers_arr_t is array (0 to 1) of registers_t;
--    function reg_arr_init
--    attribute ih : natural;
----    attribute ih of 
--		return registers_arr_t is
--    	variable v : registers_arr_t;
--	begin
--		return v;
--    end function;
--    constant REGISTERS_ARR	: registers_arr_t := reg_arr_init;

    
begin
--x_proc: process begin
----	report "E1 att ih = "&natural'image(E1'ih);
--	report "test att  = "&natural'image(ex'test_att);
----    for e in 0 to 1 loop
----    	attribute ih of e : constant is 1;
----    end loop;
--wait;
--end process;
--generate_ro_array: if true generate
--	attribute test_att of GEN_CON : constant is 33;
--        begin
--end generate;
		
gen_proc: process 
	file in_file: TEXT;
	file out_file: TEXT;
    variable rdl:    LINE;
    variable wrl:    LINE;
    variable lch:	character;
    constant STOP_PATTERN 	: string := "--##";
    variable rd_str			: string(1 to 4);
    variable STOP_LINE		: line;

begin
	report "[STIM] print uut in reigster indexes";
	for e in registers_t loop
		if RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode /= PULSE and RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode /= WO then	
			report	natural'image(reg_i_range(registers_t'pos(e))'high)&" downto "&
					natural'image(reg_i_range(registers_t'pos(e))'low)& 
					" "&registers_t'image(e);
		end if;
	end loop;
	
	report "[STIM] print uut out reigster indexes";
	for e in registers_t loop
		if RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode /= RO then
			report	natural'image(reg_o_range(registers_t'pos(e))'high)&" downto "&
					natural'image(reg_o_range(registers_t'pos(e))'low)& 
					" "&registers_t'image(e);
		end if;
	end loop;
	
	report "### Write wrap file ###";
	file_open (out_file, "wbs_reg_wrap.vhd", WRITE_MODE);
	
	write(wrl, String'("library IEEE;"));
    writeline(out_file, wrl);
    write(wrl, String'("use IEEE.STD_LOGIC_1164.ALL;"));
    writeline(out_file, wrl);
	write(wrl, String'("library vhdlbaselib;"));
    writeline(out_file, wrl);    
    write(wrl, String'("entity wbs_reg_wrap is"));
    writeline(out_file, wrl);
    write(wrl, String'("Generic ("));
	writeline(out_file, wrl);
    write(wrl, String'("    ADL : time := 0 ps"));
    writeline(out_file, wrl);
    write(wrl, String'(");"));
	writeline(out_file, wrl);    
    write(wrl, String'("Port ("));
    writeline(out_file, wrl);
    write(wrl, String'("            clk : in std_logic;"));
    writeline(out_file, wrl);
    write(wrl, String'("            rst : in std_logic;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_cyc         : in std_logic;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_stb         : in std_logic;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_adr         : in std_logic_vector;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_we          : in std_logic;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_dat_i       : in std_logic_vector;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_dat_o       : out std_logic_vector;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_ack         : out std_logic;"));
    writeline(out_file, wrl);
    write(wrl, String'("            wbs_err         : out std_logic;")); 
	writeline(out_file, wrl);			
	
-- Generate input registers:
-- name	: in std_logic_vector(1 downto 0);
-- name	: in std_logic;
	report " write entity reg in/out ports";
	for e in registers_t loop
-- INPUT
		if is_in_port(e) then		
			-- std_logic
			if RS_ITEMS_ATT_ARR(registers_t'pos(e)).width = 1 then
				write(wrl, "            "&registers_t'image(e)&" : in std_logic");
				-- last elemnt;
				if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
					write(wrl, String'(";"));
				end if;			
			else
			-- std_logic vector
				write(wrl, "            "&registers_t'image(e)&
					" : in std_logic_vector("&
					natural'image(RS_ITEMS_ATT_ARR(registers_t'pos(e)).width-1)&
					" downto 0)");
				-- last elemnt;
				if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
					write(wrl, String'(";"));
				end if;										
			end if;		
			writeline(out_file, wrl);
		end if;			
-- OUTPUT			
		if is_out_port(e) then
			-- std_logic
			if RS_ITEMS_ATT_ARR(registers_t'pos(e)).width = 1 then
				write(wrl, "            "&registers_t'image(e)&" : out std_logic");
				-- last elemnt;
				if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
					write(wrl, String'(";"));
				end if;			
			else
			-- std_logic vector
				write(wrl, "            "&registers_t'image(e)&
					" : out std_logic_vector("&
					natural'image(RS_ITEMS_ATT_ARR(registers_t'pos(e)).width-1)&
					" downto 0)");
				-- last elemnt;
				if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
					write(wrl, String'(";"));
				end if;										
			end if;		
			writeline(out_file, wrl);						
		end if;  		   	
	end loop;
		
	write(wrl, String'("    );"));
    writeline(out_file, wrl);							
	write(wrl, String'("end wbs_reg_wrap;"));
	writeline(out_file, wrl);							
	write(wrl, String'("architecture rtl of wbs_reg_wrap is"));
    writeline(out_file, wrl);							
	write(wrl, String'("begin"));
    writeline(out_file, wrl);							            
	write(wrl, String'("wbs_reg_inst : entity vhdlbaselib.wbs_reg"));
	writeline(out_file, wrl);							
	write(wrl, String'("        generic map"));
	writeline(out_file, wrl);							
	write(wrl, String'("        ("));
	writeline(out_file, wrl);							
	write(wrl, String'("                ADL => ADL"));
	writeline(out_file, wrl);							
	write(wrl, String'("        )"));
	writeline(out_file, wrl);							
	write(wrl, String'("        port map"));
	writeline(out_file, wrl);							
	write(wrl, String'("        ("));
	writeline(out_file, wrl);							
	write(wrl, String'("                clk       => clk,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                rst       => rst,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_cyc   => wbs_cyc,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_stb   => wbs_stb,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_adr   => wbs_adr,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_we    => wbs_we,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_dat_i => wbs_dat_i,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_dat_o => wbs_dat_o,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_ack   => wbs_ack,"));
	writeline(out_file, wrl);							
	write(wrl, String'("                wbs_err   => wbs_err,"));
	writeline(out_file, wrl);							

		
-- Generate instance port maps:
--		reg_i(0)     		=> logic_sig,
--		reg_i(1 dowto 0)	=> slv_sig,
-- INPUT wired
		for e in registers_t loop
			if is_in_port(e) then		
				-- std_logic
				if RS_ITEMS_ATT_ARR(registers_t'pos(e)).width = 1 then
					write(wrl, "    reg_i("&natural'image(reg_i_index(registers_t'pos(e)))&
					")          => "&registers_t'image(e));
				    -- last elemnt;
				    if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
				        write(wrl, String'(","));
			        end if;						
				else
				-- std_logic vector
		            write(wrl, "    reg_i("&natural'image(reg_i_range(registers_t'pos(e))'high)&
		            " downto "&natural'image(reg_i_range(registers_t'pos(e))'low)&
		            ")          => "&registers_t'image(e));
				    -- last elemnt;
				    if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
				        write(wrl, String'(","));
			        end if;		                
				end if;
				writeline(out_file, wrl);
			end if;
		end loop;
		for e in registers_t loop		
-- INPUT tied to gnd (RW)
			if is_in_port_gnd(e) then		
				-- std_logic
				if RS_ITEMS_ATT_ARR(registers_t'pos(e)).width = 1 then
					write(wrl, "    reg_i("&natural'image(registers_t'pos(e))&
					")          => '0'");
				    -- last elemnt;
				    if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
				        write(wrl, String'(","));
			        end if;						
				else
				-- std_logic vector
		            write(wrl, "    reg_i("&natural'image(reg_i_range(registers_t'pos(e))'high)&
		            " downto "&natural'image(reg_i_range(registers_t'pos(e))'low)&
		            ")          => (others => '0')");
				    -- last elemnt;
				    if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
				        write(wrl, String'(","));
			        end if;		                
				end if;
				writeline(out_file, wrl);
			end if;
		end loop;														
-- OUTPUTS
		for e in registers_t loop						
			if is_out_port(e) then
				-- std_logic
				if RS_ITEMS_ATT_ARR(registers_t'pos(e)).width = 1 then
					write(wrl, "    reg_o("&natural'image(registers_t'pos(e))&
					")          => "&registers_t'image(e));
				    -- last elemnt;
				    if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
				        write(wrl, String'(","));
			        end if;						
				else
				-- std_logic vector
		            write(wrl, "    reg_o("&natural'image(reg_o_range(registers_t'pos(e))'high)&
		            " downto "&natural'image(reg_o_range(registers_t'pos(e))'low)&
		            ")          => "&registers_t'image(e));
				    -- last elemnt;
				    if registers_t'pos(e) /= registers_t'pos(registers_t'right)  then
				        write(wrl, String'(","));
			        end if;		                
				end if;
				writeline(out_file, wrl);									
			end if;
		end loop;
		
	write(wrl, String'(");"));
	writeline(out_file, wrl);							
	write(wrl, String'("end rtl;"));
	writeline(out_file, wrl);				
	
	
	
	
	
wait for 100 ns;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;

end wrap_gen_arch;
