--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbs_reg_user_pkg.vhd
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

package wbs_reg_user_pkg is

	constant ADDR_ALIGN	: natural := 4;
	
	type registers_t is (
	-- WO
		SW_INT_RESET_E,
		ADDR_SPACE_E,
		DMA_DOS_TRIG_E,
		UPS_EN_E,
		IRQ_TEST_TRIG_E,
	-- RW
		MRD_BURST_E,
		MRD_BASE_ADDR_L_E,
		MRD_BASE_ADDR_H_E,
		MWR_BASE_ADDR_L_E,
		MWR_BASE_ADDR_H_E,
		TEST_REG_E,
		BAR0_OFFSET_E,		
	-- RO
		DOS_TEST_DONE_E,
		DOS_TEST_RESULT_E,
		DOS_TEST_OVFS_E,
		UPS_TEST_RESULT_E,
		CPL_STATUS_E,
		USR_ACCESS_E
	);
--	attribute test_att : natural;
--	constant ex 	: registers_t := registers_t'Val(0);
--	attribute test_att of ex : constant is 33;
--	constant GEN_CON 	: registers_t := registers_t'Val(0);	
	
	constant MAX_ITEMS_NUM	: natural := registers_t'pos(registers_t'right) +1;
	
	type access_t is (
		RO,
		WO,
		RW,
		PULSE,
		RESERVED
	);
--	type reg_t is (
--		PULSE,
--		VALUE
--	)
	type rs_items_att_t is record
	  width			: natural;
	  access_mode	: access_t;
	  default		: natural;
--	  reg_type		: reg_t;
--	  name			: string(1 to 80);
	end record;
	type rs_items_att_arr_t is array (0 to MAX_ITEMS_NUM-1) of rs_items_att_t;
	
--	
-- Used RS_ITEMS_ATT_ARR with mannualy set fileds
--
	constant RS_ITEMS_ATT_ARR	: rs_items_att_arr_t :=
	(
		registers_t'pos(DMA_DOS_TRIG_E)			=> ( 1,	PULSE, 0),
		registers_t'pos(IRQ_TEST_TRIG_E)		=> ( 1,	PULSE, 0),
		registers_t'pos(SW_INT_RESET_E)			=> ( 1,	WO, 1),		
		registers_t'pos(UPS_EN_E)				=> ( 1,	WO, 0),		
		registers_t'pos(ADDR_SPACE_E)			=> ( 1,	WO, 1),		
		registers_t'pos(MRD_BASE_ADDR_L_E)		=> (32, RW, 0),
		registers_t'pos(MRD_BASE_ADDR_H_E)		=> (32, RW, 0),
		registers_t'pos(MWR_BASE_ADDR_L_E)		=> (32, RW, 0),
		registers_t'pos(MWR_BASE_ADDR_H_E)		=> (32, RW, 0),
		registers_t'pos(MRD_BURST_E)			=> (32,	RW, 0),
		registers_t'pos(DOS_TEST_DONE_E)		=> (1,	RO, 0),
		registers_t'pos(DOS_TEST_RESULT_E)		=> (32,	RO, 0),
		registers_t'pos(DOS_TEST_OVFS_E)		=> (32,	RO, 0),
		registers_t'pos(UPS_TEST_RESULT_E)		=> (32,	RO, 0),
		registers_t'pos(CPL_STATUS_E)			=> (32,	RO, 0),
		registers_t'pos(TEST_REG_E)				=> (32,	RW, 16#00AABBCC#),
		registers_t'pos(BAR0_OFFSET_E)			=> (32,	RW, 0),
		registers_t'pos(USR_ACCESS_E)			=> (32, RO, 16#00ADBEEF#)
	);

	-- Sim only
	function register_addr(
		 arg 	: natural;
		 offset	: std_logic_vector;		 
		 width	: natural
		) return std_logic_vector;
	function register_addr(
		 arg 	: natural;
		 offset	: natural;
		 width	: natural
		) return std_logic_vector;	

end wbs_reg_user_pkg;
package body wbs_reg_user_pkg is
	
	
--------------------------------------------------------------------------------
-- For simulation only
--------------------------------------------------------------------------------
-- function returning address of register on the basis of enumrate id (natural)
	function register_addr(
		 arg 	: natural;
		 offset	: std_logic_vector;
		 width	: natural
		) return std_logic_vector is
		variable off_nat : natural;
	begin
		off_nat	:= to_integer(unsigned(offset));
		return std_logic_vector(to_unsigned(arg*ADDR_ALIGN+off_nat, WIDTH));
	end function;	
	
	function register_addr(
		 arg 	: natural;
		 offset	: natural;
		 width	: natural
		) return std_logic_vector is
		variable off_nat : natural;
	begin
		return std_logic_vector(to_unsigned(arg*ADDR_ALIGN+offset, WIDTH));
	end function;		
	
	
end wbs_reg_user_pkg;
