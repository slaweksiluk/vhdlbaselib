-- Slawomir Siluk slaweksiluk@gazeta.pl

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;
use vhdlbaselib.wishbone_pkg.all;
use vhdlbaselib.wishbone_array_pkg.t_arr_wishbone_master_in;
use vhdlbaselib.wishbone_array_pkg.t_arr_wishbone_master_out;

entity wb_demux is
	Generic ( 
		MASTERS_NUM		: positive
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	sel		: in natural range 0 to MASTERS_NUM-1;

    	-- Single wb slave
    	wbs_i	: in t_wishbone_slave_in;
    	wbs_o	: out t_wishbone_slave_out;

		-- Multiple wb masters
    	wbm_i	: in t_arr_wishbone_master_in(0 to MASTERS_NUM-1);
    	wbm_o	: out t_arr_wishbone_master_out(0 to MASTERS_NUM-1)

    );
end wb_demux;
architecture full_regs of wb_demux is
begin

conn_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
	else
	-- slave -> master
		-- Only strobe signal should be multiplexed, the rest is common
		if wbm_i(sel).stall = '0' then
			for i in 0 to MASTERS_NUM-1 loop
				wbm_o(i).cyc <= '0';
				wbm_o(i).stb <= '0';
				wbm_o(i).adr <= wbs_i.adr;
				wbm_o(i).sel <= wbs_i.sel;
				wbm_o(i).we  <= wbs_i.we;
				wbm_o(i).dat <= wbs_i.dat;
			end loop;
			wbm_o(sel).cyc <= wbs_i.cyc;
			wbm_o(sel).stb <= wbs_i.stb;
		end if;
	-- master -> slave
		-- Stall cannot be registered, hence split record
		wbs_o.ack <= wbm_i(sel).ack;
		wbs_o.err <= wbm_i(sel).err;
		wbs_o.rty <= wbm_i(sel).rty;
		wbs_o.int <= wbm_i(sel).int;
		wbs_o.dat <= wbm_i(sel).dat;
	end if;
end if;
end process;
wbs_o.stall <= wbm_i(sel).stall;

end full_regs;
