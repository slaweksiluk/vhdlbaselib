--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: sync_block.vhd
-- Language: VHDL
-- Description: Used on signals crossing from one clock domain to
--              another, this is a flip-flop pair, with both flops
--              placed together with RLOCs into the same slice.  Thus
--              the routing delay between the two is minimum to safe-
--              guard against metastability issues.
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:

-- 10/06/16 Revision 0.02 - Removed WIDTH generic
-- Additional Comments:
--	This module is not indended to synch more than 1bit width signals!
-- 10/06/16 Revision 0.03 - Added RLOC
-- Additional Comments:
--	Just as experiment
-- 15.12.17 Divided into vendors specific architectures:
--		TODO Check if architecture and enitity in separated files are supported
--		by ISE and Vivado synthesis tools.
--		TODO Conisder 'configuration' keyword usage (if it is supported).

library ieee;
use ieee.std_logic_1164.all;

entity sync_block is
	generic (
		INITIALISE 	: std_logic_vector(1 downto 0) := (others => '0')
	);
	port (
	    clk         : in  std_logic;        -- clock to be sync'ed to
	    data_in     : in  std_logic;        -- Data to be 'synced'
	    data_out    : out std_logic	        -- synced data
	);   
end sync_block;

