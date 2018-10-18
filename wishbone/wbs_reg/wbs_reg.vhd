--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbs_reg.vhd
-- Language: VHDL
-- Description: 
-- 	
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- RW register imlementation
-- WB_WRITE WO -----+
--					|
-- WB WRITE RW -> reg_o_inter -> -reg_o	-> entity OUT
--					|
--			   	  reg_i_inter <--- reg_i <- entity IN
--					|
-- WB READ RW <-----+ [from reg_o_r]
--					|
-- WB_READ RO <-----+ [from reg_i]
-- Comments to above:
-- 	reg_o_r is identical to reg_o (separed to have possbility of readingh from out)
--	reg_i_inter is: reg_i when reg is RO, reg_o_inter when its RW

-- TO DO:
-- * make reg_i input real len (it it too big now) - RW registers do NOT use reg_i
--		It requires adding RO_ADDR_ARRAY with h/l indexes for reg_i input
-- DONE * keep registers orders and names in enumarete to avoid figtinh with string
--		in synthesis. Keep registers attributes ia regulat constant array of records
--		insteaf of parsing enumerate (indexed by enum pos att).
-- * consider to add idnetyfying enums by string to register_addr fun (string arguement)
--		(for sim only)
-- ALMOST DONE * add default post reset value feature (!!! - important)
--		Still need to add this functionality for RW registeres (reg_i_inter defaults)		
-- * add pulse signal options (currently event detector can be used instead)
-- * consider passing WRITE_ADDR_ARR and READ_ADDR_ARR as argyument to functions
--		instead fo keeping it as global constant in pkg. That wolud let use 
--		more generic functions
-- * consider using natural subtypes as indexes for diffrent arrays for better
--		function overloading
-- ALREADY DONE? * Ass possbility to set choose which registers has te be reseted. But isnt
--		it enough to set particualr reg_o_inter slices whose are connected to
--		reg_i_inter?

--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
library vhdlbaselib;
use vhdlbaselib.wbs_reg_pkg.all;
	

entity wbs_reg is
	Generic ( 
		ADL		: time := 0 ps	
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;

		-- Whishbone Slave Interface
		wbs_cyc	      : in  std_logic;
		wbs_stb       : in  std_logic;
		wbs_adr       : in  std_logic_vector;
		wbs_we        : in  std_logic;
		wbs_dat_i     : in  std_logic_vector;
		wbs_dat_o     : out std_logic_vector;
		wbs_ack       : out std_logic;
		wbs_err		: out std_logic;
			
		
		reg_o		: out std_logic_vector(REG_O_WIDTH-1 downto 0);
		reg_i		: in  std_logic_vector(REG_I_WIDTH-1 downto 0)
    	
    );
end wbs_reg;
architecture wbs_reg_arch of wbs_reg is

signal reg_i_inter		: std_logic_vector(REG_I_WIDTH-1 downto 0) := (others => '0');
signal reg_o_inter		: std_logic_vector(REG_O_WIDTH-1 downto 0) := (others => '0');
--signal pulse_toggle		: std_logic := '0';
--signal pulse_out		: std_logic := '0';

	

constant REG_O_DEFAULT_SLV	: std_logic_vector(REG_O_WIDTH-1 downto 0) := reg_o_default;
constant WB_DEF	: std_logic_vector(wbs_dat_i'range) := (others => '0');



begin

write_proc: process(clk) begin
	if rising_edge(clk) then
		for R in 0 to WRITE_ITEMS_NUM-1 loop
			-- Reset to zero all pulse registers
			if is_pulse(r) then
				reg_o_inter(reg_o_index(r)) <= '0' after ADL;
			end if;	
		end loop;
		if rst = '1' then
--			reg_o_inter <= (others => '0')  after ADL;
			reg_o_inter <= REG_O_DEFAULT_SLV after ADL;
		elsif wbs_cyc = '1' and wbs_stb = '1' and wbs_we = '1' then
			for R in 0 to WRITE_ITEMS_NUM-1 loop
				if wr_addr_match(wbs_adr, R) then
					-- vivado error below, function return range not supp?
					--reg_o(port_range(R)'range) <= wbs_dat_i(reg_range(R)'range);
					-- more complicated but working
--					report " %%% write proc: writing index h "&natural'image(port_h(R))&" index l "&natural'image(port_l(R));
--					report " %%% write proc: writing addr R "&natural'image(R);
					reg_o_inter(port_h(R) downto port_l(R)) <= wbs_dat_i(item_width(R)-1 downto 0)  after ADL;
					--eport " %%% write proc: writing index h "&natural'image(port_h(R))&" index l "&natural'image(port_l(R));
					--report " %%% write proc: writing addr R "&natural'image(R);
					if is_pulse(r) then
						-- assign '1'
						reg_o_inter(reg_o_index(r))				<= '1' after ADL;		
					else
						reg_o_inter(port_h(R) downto port_l(R)) <= wbs_dat_i(item_width(R)-1 downto 0)  after ADL;
					end if;
				end if;		
			end loop;
		end if;
	end if;
end process;			
			
-- pulser
--event_det_inst : entity xil_defaultlib.event_det
--	generic map	(
--		ADL        => ADL,
--		EVENT_EDGE => "BOTH",
--		OUT_REG    => false,
--		SIM        => true
--	) port map (
--		clk       => clk,
--		sig       => pulse_toggle,
--		sig_event => pulse_out
--	);
			

read_proc: process(clk) 
	variable w : natural;
	variable h : natural;
	variable l : natural;
begin
	if rising_edge(clk) then
		if rst = '1' then
			wbs_dat_o		<= WB_DEF  after ADL;
		elsif wbs_cyc = '1' and wbs_stb = '1' and wbs_we = '0' then
			for R in 0 to READ_ITEMS_NUM-1 loop
				w := rd_item_width(r);
				h := rd_port_h(r);
				l := rd_port_l(r);
				if rd_addr_match(wbs_adr, R) then
					-- Assign data
--					wbs_dat_o(rd_item_width(R)-1 downto 0) <= reg_i_inter(rd_port_h(R) downto rd_port_l(R));	
					wbs_dat_o		<= WB_DEF  after ADL;
					wbs_dat_o(w-1 downto 0) <= reg_i_inter(h downto l)  after ADL;	
				end if;				
			end loop;
		end if;			
	end if;
end process;


-- Generate the reg_i. Loop on
i_inter_loop_gen: for r in 0 to READ_ITEMS_NUM-1 generate
	if_rw_gen: if is_rw_rd_ind(r) generate
		-- RW regsiter is sourced by internal feedback
		reg_i_inter(rd_port_h(R) downto rd_port_l(R)) <= reg_o_inter(o_inter_h(R) downto o_inter_l(R));	
	end generate;
--end generate;


	if_ro_gen: if is_ro_rd_ind(r) generate
		-- RO regsiter is sourced by external reg_i
		-- TO DO: reg_i can be smaller than req_i_inter
		-- rd_port_h/l functions need to be replaced with reg_i_range
		reg_i_inter(rd_port_h(R) downto rd_port_l(R)) <= reg_i(rd_port_h(R) downto rd_port_l(R));	
--		reg_i_inter(rd_port_h(R) downto rd_port_l(R)) <= reg_i(reg_i_range(r)'range);	

	end generate;
end generate;



-- Direct connection for reg_o with for WB WR
reg_o	<= reg_o_inter;




ack_proc: process(clk) 
variable flag_ack : boolean := false;
	begin
if rising_edge(clk) then
	wbs_ack		<= '0'  after ADL;
	wbs_err		<= '0'  after ADL;	
	if rst = '1' then
		wbs_ack		<= '0'  after ADL;
		wbs_err		<= '0'	 after ADL;
		flag_ack	:= false;
	elsif wbs_cyc = '1' and wbs_stb = '1' then
-- READ
		if wbs_we = '0' then
			flag_ack	:= false;					
			for R in 0 to READ_ITEMS_NUM-1 loop
				if rd_addr_match(wbs_adr, R) then
	 				wbs_ack		<= '1'  after ADL;
	 				flag_ack	:= true;
--	 				report "    %%% ACK PROC: rd addr match!";
				end if;
			end loop;
			-- Addres not found on the read iterms list return err
			if not flag_ack then		
				wbs_err <= '1'  after ADL;
			end if;			
		else 
-- WRITE
			flag_ack	:= false;					
			for R in 0 to WRITE_ITEMS_NUM-1 loop
				if wr_addr_match(wbs_adr, R) then
	 				wbs_ack		<= '1'  after ADL;
	 				flag_ack	:= true;
				end if;
			end loop;
			if not flag_ack then		
				wbs_err <= '1'  after ADL;
			end if;	
		end if;
	end if;
end if;
end process;	



end wbs_reg_arch;
