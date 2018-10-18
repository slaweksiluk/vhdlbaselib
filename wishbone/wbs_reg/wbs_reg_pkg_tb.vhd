--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbs_reg_pkg_tb.vhd
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
--use IEEE.NUMERIC_STD.ALL;
library xil_defaultlib;
use xil_defaultlib.wbs_reg_pkg.all;


entity wbs_reg_pkg_tb is
end wbs_reg_pkg_tb;
architecture wbs_reg_pkg_tb_arch of wbs_reg_pkg_tb is

constant ENUM_STRING : string := rs_items_t'image(rs_items_t'right);
constant STRING_NUM : string := "4";

begin

stim: process begin
--report "Test port_range fun for pos 0";
--report "Bit high: " & natural'image(port_range(0)'high);
--report "Bit low: " & natural'image(port_range(0)'low);

--report "Test port_range fun for pos 1";
--report "Bit high: " & natural'image(port_range(1)'high);
--report "Bit low: " & natural'image(port_range(1)'low);



--report "%%%%%%%%%%%%%%%%%%%%%Test port_h/l fun for pos 1";
--report "Bit high: " & natural'image(port_h(1));
--report "Bit low: " & natural'image(port_l(1));


--report "&&& test converting enum to string";
--report " Image of enum in report " & rs_items_t'image(rs_items_t'val(0));
--report " Image of const from enum in report " & ENUM_STRING;


--report " %%% items sting arr";
PRINT_ITEMS_STRING_ARR;

--report " %%% items att arr after aprsing from string arr";
PRINT_ITEMS_ATT_ARR;


wait;
end process;		


end wbs_reg_pkg_tb_arch;
