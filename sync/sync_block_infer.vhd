-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- Description:
--		Inferred architecture for sync_block entity
-- 15/12/17 Divided into vendors specific architectures:
--		TODO Verify on HW with ISE and Vivado
--		TODO Experiment with attributes
--		TODO Consider two std_logic's signals instead of one sync
--		std_logic_vector

library ieee;
use ieee.std_logic_1164.all;

architecture infer of sync_block is
	signal sync : std_logic_vector(1 downto 0) := INITIALISE;

	-- RLOC is for placing FF as close as possible (in the same slice)
	-- ASYNC_REG is for sim only (never soa its infulance). In fact it shuold
	-- be set only for sync(0), but VHDL syntax deny it.
	-- Becasue of Xilinx bugs attributes are set for both sync signal and
	-- process labael.
	attribute RLOC                  : string;
	attribute SHREG_EXTRAC			: string;
    attribute ASYNC_REG               : string;
	attribute RLOC of sync : signal is "X0Y0";
	attribute RLOC of sync_proc: label is "X0Y0";
	attribute SHREG_EXTRAC of sync : signal is "FALSE";
	attribute SHREG_EXTRAC of sync_proc : label is "FALSE";
	attribute ASYNC_REG of sync : signal is "TRUE";
begin
sync_proc: process(clk) begin
	if rising_edge(clk) then
		sync <= sync(0) & data_in;
	end if;
end process;
end infer;
