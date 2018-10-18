--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbs_reg_tb.vhd
-- Language: VHDL
-- Description: 
-- 	
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Exampleregisters comnfiguration:
--	constant RS_ITEMS_ATT_ARR	: rs_items_att_arr_t := (
--		( 4, RO), adrA
--		( 4, RW), adrB
--		( 8, WO)  adrC
--	);
-- 
-- WB reads -> reg_i : RO, (RW register do not require reg_i input)
--				3..0 RO	 A (0x00)
--
-- WB writes -> reg_o: RW, WO
--				3.. 0 RW B (0x01)
--				11..4 WO C (0x02)

-- READ_ITEMS_NUM = 2
-- adrA
-- adrB

-- WRITE_ITEMS_NUM = 2
-- adrB
-- adrC

--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vhdlbaselib;
use vhdlbaselib.wbs_reg_pkg.all;
use vhdlbaselib.wbs_reg_user_pkg.all;
use vhdlbaselib.wb_test_env_pkg.all;
use vhdlbaselib.common_pkg.all;
use vhdlbaselib.txt_util.all;
	
entity wbs_reg_tb is
end entity;

architecture bench of wbs_reg_tb is

	constant WB_ADR_WIDTH	: natural := 32;
	constant WB_DAT_WIDTH	: natural := 32;
	constant WB_DAT_I_PAT	: std_logic_vector(32-1 downto 0) := x"01cdefcd";
	
	constant ADDR_ALIGN	: natural := 4;
	

	signal clk : std_logic;
	signal rst : std_logic := '1';
	signal wbs_cyc : std_logic := '0';
	signal wbs_stb : std_logic := '0';
	signal wbs_adr : std_logic_vector(WB_ADR_WIDTH-1 downto 0) := (others => '0');
	signal wbs_we : std_logic := '0';
	signal wbs_dat_i : std_logic_vector(WB_DAT_WIDTH-1 downto 0) := WB_DAT_I_PAT(WB_DAT_WIDTH-1 downto 0);
	signal wbs_dat_o : std_logic_vector(WB_DAT_WIDTH-1 downto 0);
	signal wbs_ack : std_logic := '0';
	signal wbs_err : std_logic := '0';
	signal reg_o : std_logic_vector(REG_O_WIDTH-1 downto 0);
	signal reg_i : std_logic_vector(REG_I_WIDTH-1 downto 0);

	constant CLK_PERIOD : time := 10 ns;
	constant stop_clock : boolean := false;
	constant LDL	: time := CLK_PERIOD * 10;
	constant ADL	: time := CLK_PERIOD / 5;
begin

	uut : entity vhdlbaselib.wbs_reg
		port map
		(
			clk       => clk,
			rst       => rst,
			wbs_cyc   => wbs_cyc,
			wbs_stb   => wbs_stb,
			wbs_adr   => wbs_adr,
			wbs_we    => wbs_we,
			wbs_dat_i => wbs_dat_i,
			wbs_dat_o => wbs_dat_o,
			wbs_ack   => wbs_ack,
			wbs_err		=> wbs_err,
			reg_o     => reg_o,
			reg_i     => reg_i
		);
PRINT_WRITE_ITEMS_ARR;
PRINT_READ_ITEMS_ARR;
stimulus : process	
	variable reg_num 			: natural := 0;
	variable reg_o_num			: natural := 0;
	variable reg_i_num			: natural := 0;
	variable wb_wr_data			: std_logic_vector(WB_DAT_WIDTH-1 downto 0);
	variable wb_rd_data_comp	: std_logic_vector(WB_DAT_WIDTH-1 downto 0);
	variable reg_i_data			: std_logic_vector(REG_I_WIDTH-1 downto 0) :=
		std_logic_vector(to_unsigned(5345236, REG_I_WIDTH));
	variable ret_mode			: ret_mode_t := ACK_E;	
begin

report " WRITE_ITEMS_NUM = "&natural'image(WRITE_ITEMS_NUM);
report " READ_ITEMS_NUM = "&natural'image(READ_ITEMS_NUM);

	wait for LDL;
		rst		<= '0';
	wait for LDL;
	
	report " [STIM]   test writing all registers";
	for I in 0 to ITEMS_NUM-1 loop
		wb_wr_data := std_logic_vector(to_unsigned(i, WB_DAT_WIDTH));
		ret_mode := ACK_E;
		if not writable(i) then
			ret_mode := ERR_E;
		end if;	
		reg_num := I*ADDR_ALIGN;
		wait for LDL;
		SINGLE_PIPE_WR(
			std_logic_vector(to_unsigned(reg_num, WB_ADR_WIDTH)), 
			wb_wr_data, 
			WTE_TRIG,
			ret_mode
		);
		if ret_mode = ACK_E then
			-- check the data value only in RW R0 mode. In PULSE assert '1'
			if is_pulse_common_ind(i) then
				wb_wr_data(0) := '1';
			end if;
				assert reg_o(port_h(reg_o_num) downto port_l(reg_o_num)) = wb_wr_data(item_width(reg_o_num)-1 downto 0)
				  report " [STIM]   FAIL: reg" & natural'image(I) & "data mismatch"
				  severity failure;
			-- but always increment writable index number
			reg_o_num := reg_o_num+1;
		end if;
	end loop;
	
	wait for LDL;
	wait for LDL;
	report " [STIM]   test reading all registers";
	reg_i <= reg_i_data(reg_i'range);
	wait for 0 ps;
	for I in 0 to ITEMS_NUM-1 loop
	report "   Loop " & natural'image(i);	
		ret_mode := ACK_E;
		if not readable(i) then
			report "   reading not readable reg. Exepecter ERR ACK";
			ret_mode := ERR_E;
		end if;
		reg_num := I*ADDR_ALIGN;
		-- Is readable loop on all items index
		if readable(i) then
			-- Insided loop on READ ITEMS index
			if is_rw(i) then
				report "   reading RW register";
				-- Take comparation data from reg_o
				wait for 0 ps;				
				wb_rd_data_comp(rd_item_width(reg_i_num)-1 downto 0) :=  reg_o(o_inter_h(reg_i_num) downto o_inter_l(reg_i_num));
				wb_rd_data_comp(WB_DAT_WIDTH-1 downto rd_item_width(reg_i_num)) := (others => '0') ;				
			-- RO reg	
			else
				report "   reading RO register";
				-- Takie comparation data form reg_i			
				wb_rd_data_comp(rd_item_width(reg_i_num)-1 downto 0) :=  reg_i(rd_port_h(reg_i_num) downto rd_port_l(reg_i_num));
				wb_rd_data_comp(WB_DAT_WIDTH-1 downto rd_item_width(reg_i_num)) := (others => '0') ;
			end if;
			report " data for comparation " & hstr(wb_rd_data_comp)&" at reg_i_num "&natural'image(reg_i_num);
			reg_i_num := reg_i_num +1;				
		end if;
		wait for LDL;
		SINGLE_PIPE_RD(
			std_logic_vector(to_unsigned(reg_num, WB_ADR_WIDTH)),
			wb_rd_data_comp,
			WTE_TRIG,
			ret_mode
		);
	end loop;
	wait for LDL;
	
	report "[STIM] print uut out reigster indexes";
	for e in registers_t loop
		if RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode /= RO then
			report	natural'image(reg_o_range(registers_t'pos(e))'high)&" downto "&
					natural'image(reg_o_range(registers_t'pos(e))'low)& 
					" "&registers_t'image(e);
		end if;
	end loop;
	
	report "[STIM] print uut in reigster indexes";
	for e in registers_t loop
		if RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode /= PULSE and RS_ITEMS_ATT_ARR(registers_t'pos(e)).access_mode /= WO then	
			report	natural'image(reg_i_range(registers_t'pos(e))'high)&" downto "&
					natural'image(reg_i_range(registers_t'pos(e))'low)& 
					" "&registers_t'image(e);
		end if;
	end loop;	
wait for LDL;
assert false
 report " <<<SUCCESS>>> "
 severity failure;
wait;
end process;


--procedure WBM_STIM(
--	clk		: in  std_logic;
--	rst		: in  std_logic;
--	cyc	    : out std_logic;
--	stb     : out std_logic;
--	we      : out std_logic;	
--	adr     : out std_logic_vector;
--	dat_i   : in  std_logic_vector;
--	dat_o   : out std_logic_vector;
--	ack     : in  std_logic
--) is
WBM_STIM(clk, rst, wbs_cyc, wbs_stb, wbs_we, wbs_adr, wbs_dat_o, wbs_dat_i, wbs_ack, wbs_err, WTE_DONE);


	generate_clk : process
	begin
		while not stop_clock loop
			clk <= '0', '1' after CLK_PERIOD / 2;
			wait for CLK_PERIOD;
		end loop;
		wait;
	end process;

end architecture;

