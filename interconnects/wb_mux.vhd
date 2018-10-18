--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wb_mux.vhd
-- Language: VHDL
-- Description: 
-- 		Connects n wb slaves to one wb master as chosen by externel sel sig
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- TODO use architecture instead of generate
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;
use vhdlbaselib.wishbone_array_pkg.all;
--use vhdlbaselib.wishbone_pkg.all;
--use vhdlbaselib.wishbone_array_pkg.t_arr_wishbone_slave_in;
--use vhdlbaselib.wishbone_array_pkg.t_arr_wishbone_slave_out;

entity wb_mux is
	Generic ( 
		SLAVES_NUM		: positive;
-- TODO generic archs:
--		+FULL_REGS
--		WBS_O_REGS
--		WBM_O_REGS 
--		+NO_REGS		
		ARCH			: string := "FULL_REGS"		
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	sel		: in natural range 0 to SLAVES_NUM-1;
    	
    	-- Multi wb slaves		
    	wbs_i	: in t_arr_wishbone_slave_in(0 to SLAVES_NUM-1);
    	wbs_o	: out t_arr_wishbone_slave_out(0 to SLAVES_NUM-1);    	

		-- Single wb master
    	wbm_i	: in t_wishbone_master_in;
    	wbm_o	: out t_wishbone_master_out

    );
end wb_mux;
architecture wb_mux_arch of wb_mux is
begin

assert ARCH = "FULL_REGS" or ARCH = "NO_REGS"
	report "wb_mux.vhd: invalid arch. Please set FULL_REGS or NO_REGS"
	severity failure;

full_regs_arch_gen: if ARCH = "FULL_REGS" generate
	signal valid_cycle	: boolean := false;
begin
conn_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		for i in 0 to SLAVES_NUM-1 loop
			wbs_o(i).ack <= '0';
		end loop;
		wbm_o.cyc <= '0';
		wbm_o.stb <= '0';
		valid_cycle <= false;
	else
		-- Always transfer to slave
		wbs_o(sel)	<= wbm_i;
		-- Transfer to master when valid cycle
		if (wbs_i(sel).cyc = '1' and wbs_i(sel).stb = '1') or valid_cycle then
			wbm_o 		<= wbs_i(sel);
			valid_cycle	<= true;
		end if;
		-- Stop cyc when there was ack
		if wbm_i.ack = '1' then
			valid_cycle <= false;
			wbm_o.cyc <= '0';
		end if;
	end if;
end if;
end process;
end generate;



no_regs_arch_gen: if ARCH = "NO_REGS" generate
begin
	-- NO_REGS architecture
-- WB Slave -> Master. Direction connection here (input multiplexing, no latch
-- risk)
wbm_o	<= wbs_i(sel);

-- WB Master -> Slave. Output multiplexing. Need make sure no latches
-- are inferred. Outputs has to be always driven. Forunately they are always
-- one clock period length
conn_proc: process(wbm_i, sel) begin
	for i in 0 to SLAVES_NUM-1 loop
		if i = sel  then
			wbs_o(i) <= wbm_i;
		else
			wbs_o(i).ack <= '0';
			wbs_o(i).err <= '0';
			wbs_o(i).rty <= '0';
			wbs_o(i).stall <= '0';
			wbs_o(i).int <= '0';
			wbs_o(i).dat <= (others => '0');
		end if;
	end loop;
end process;
end generate;

end wb_mux_arch;
