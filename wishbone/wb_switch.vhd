----------------------------------------------------------------------------------
-- Design Name: 
-- Module Name: wb_switch - wb_switch_arch
-- Description: 
-- Switching one Wishbone Slave to multiple Wishbone Masters(MASTERS 
--	parameter).
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Revision 0.02 - SlawekS TO DO:
-- * Add multiple slaved support
-- * Consider what will happe if two instantes with diffrent pkg params will be
--	used in the same project? Impossible in that configuration
-- * TB with WTE
-- * It would be worth to add diffrent addrress encoding eg:
--		-combinatorial logic for checking if input address is in desired range.
--		-contacante thhis info into slv
--		-perform case on the above slv

-- this is in fact one hot encoding...
---   for master_interface generate 
-- 		sel_slv(master_interface) = '1' when wbs_adr < offset_h(...) and wbs_adr > offset_l

-- * consider ade some pipelining after calculating addresses ranges...
-- * what if wb_slaves requires zero offset? It's even more usual than "common address space"
--	That feautrue will require some address decoding (there is no addr decoding now)
--	The simpplest solution is subtraction of device offset from adr befere passing
--	it to wb slave. In fact it colud be done:
--		a) before aoutput registers (worse implementation - huge comb logic without pipelining)
--		b) after output registers with another pipleining stage (better impelmentation,
		-- but it adds another cycle of delay between slave and master)
-- * conisder input of OFFSETS_ARR as indexes of on hot instead of generic values
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use IEEE.NUMERIC_STD.ALL;


library vhdlbaselib;
use vhdlbaselib.wb_switch_pkg.all;


entity wb_switch is
	Generic (  
		DAT_WIDTH                : natural     := 32;
		ADR_WIDTH                : natural     := 32;
		MASTERS                  : natural     := 2;
		OFFSETS_ARR				 : offsets_arr_t;
		SUB_ADR_OFFSET			 : boolean 		:= true
	);
	Port ( 
		clk : in STD_LOGIC;
		-- Wishbone slaves interface
		wbs_adr   : in std_logic_vector(ADR_WIDTH-1 downto 0);
		wbs_dat_i : in std_logic_vector(DAT_WIDTH-1 downto 0);
		wbs_dat_o : out std_logic_vector(DAT_WIDTH-1 downto 0);
		wbs_cyc   : in  std_logic;
		wbs_stb   : in  std_logic;
		wbs_we    : in  std_logic;
		wbs_ack   : out std_logic;
		wbs_rty   : out  std_logic;
		wbs_err   : out  std_logic;

		-- Wishbone masters interfaces
		wbm_adr   : out std_logic_vector(ADR_WIDTH-1 downto 0);
		wbm_dat_i : in std_logic_vector(DAT_WIDTH*MASTERS-1 downto 0);
		wbm_dat_o : out std_logic_vector(DAT_WIDTH-1 downto 0); -- it doesnt not have to be multiplexed
		wbm_cyc   : out std_logic;
		wbm_stb   : out std_logic_vector(MASTERS-1 downto 0);
		wbm_we    : out std_logic;
		wbm_ack   : in  std_logic_vector(MASTERS-1 downto 0);
		wbm_rty   : in  std_logic_vector(MASTERS-1 downto 0);
		wbm_err   : in  std_logic_vector(MASTERS-1 downto 0)
	);
end wb_switch;
architecture wb_switch_arch of wb_switch is


signal sel_c			: natural range 0 to MASTERS-1 := 0;
signal sel_r			: natural range 0 to MASTERS-1 := 0;


--signal wbs_adr_nat 		: natural range 0 to 2**(ADR_WIDTH-1) -1 := 0;
signal wbs_adr_nat 		: natural := 0;
signal stb_event 		: std_logic := '0';
signal wbs_ack_r		: std_logic := '0';
signal wbm_adr_c		: std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
signal wb_adr_non_exist_c		: std_logic := '0';


begin
	wbs_adr_nat <= to_integer(unsigned(wbs_adr));

	event_detector: entity vhdlbaselib.event_det
	generic map(
		EVENT_EDGE => "RISE",
		OUT_REG => false,
		SIM	=> false
	)
	port map(
		clk       => clk,
		sig       => wbs_stb,
		sig_event => stb_event
	);

-- offset decodnign example when OFFSETS_ARR = 0,4,8,16,...
-- adr 0	- 3 			wb0
-- adr 4	- 7				wb1
-- adr 8	- 15			wb2
-- adr 16	- ADR_WIDTH^2-1 err (no such addres range)

	sel_master_proc: process (stb_event, wbs_adr_nat, sel_r)
		variable index_match : natural;
	begin
		if stb_event = '1' then
			-- set default value for index match and sel to prevent latch insertion
			index_match := 0;
			sel_c		<= 0;		
			for index in 0 to MASTERS -1 loop
				index_match := index;
				sel_c 		<= index_match;				
				exit when (wbs_adr_nat < OFFSETS_ARR(index+1));
--				exit when (wbs_adr_nat < OFFSETS_ARR(index+1)) or index = MASTERS-1;
			end loop;
			sel_c <= index_match;
		else
			index_match := sel_r;
			sel_c			<= sel_r;
		end if;
	end process;
	
	-- hold previous value of sel
	sel_r_proc: process(clk) begin
	if rising_edge(clk) then
		sel_r <= sel_c;
	end if;
	end process;
		
	
	check_adr_proc: process (wbs_adr_nat)
	begin  
		if wbs_adr_nat > OFFSETS_ARR(MASTERS)-1 then
			wb_adr_non_exist_c <= '1';
		else
			wb_adr_non_exist_c <= '0';
		end if;
	end process;	
		
	wb_conn_proc: process (clk) begin  
		if rising_edge(clk) then
			wbm_adr 	<= (others => '0');
			wbm_cyc     <= '0';
			wbm_stb     <= (others => '0');
			wbm_we      <= '0';
			wbs_rty 	<= '0';
			wbs_err 	<= '0';
				wbm_dat_o <= wbs_dat_i;
				wbs_dat_o <= wbm_dat_i(((sel_c+1) * DAT_WIDTH) -1 downto sel_c * DAT_WIDTH);
				wbm_adr  <= wbm_adr_c;

				wbm_cyc <= wbs_cyc;	
				if wbm_ack(sel_c) = '1' or wbs_ack_r = '1' then		
					wbm_cyc <= '0';
				end if;
				
				wbm_stb(sel_c)  <= wbs_stb;
				wbm_we		  <= wbs_we;
				if wb_adr_non_exist_c = '1' then
					wbs_rty 	<= '0';
					wbs_ack_r 	<= '0';
					wbs_err 	<= '1';					
				else				
					wbs_ack_r <= wbm_ack(sel_c);
					wbs_rty <= wbm_rty(sel_c);
					wbs_err <= wbm_err(sel_c);
				end if;
		end if;
	end process;
	
wbs_ack <= wbs_ack_r;


-- expexcted one hot array for off arr 0,4,8,16 and sel = 0,1,3
--	sel = 0 => ?
--	sel = 1 => arr = 4 => one hot clear 3
--	sel = 2 => arr = 8 => one hot clear 4

-- ex:
--	sel = 3 => arr = 16 => one hot clear 5




sub_adr_gen: if SUB_ADR_OFFSET generate
	signal wbm_adr_r		: std_logic_vector(ADR_WIDTH-1 downto 0) := (others => '0');
  -- Returns log of 2 of a natural number
  function log2_ceil(N : natural) return positive is
  begin
    if N <= 2 then
      return 1;
    elsif N mod 2 = 0 then
      return 1 + log2_ceil(N/2);
    else
      return 1 + log2_ceil((N+1)/2);
    end if;
  end;
	type one_hot_t is array (1 to MASTERS-1) of natural;
	function one_hot_arr_init(
		 arg : offsets_arr_t
		) return one_hot_t is
		variable v : one_hot_t;
	begin
		for i in 1 to MASTERS-1 loop
				v(i) := log2_ceil(arg(i));
		end loop;
		return v;
	end function;
	constant ONE_HOT_ARR : one_hot_t := one_hot_arr_init(OFFSETS_ARR);
begin
	-- assign zero to bit which is 1 at offset
--	dr_c(ONE_HOT_ARR(sel)) 			<= '0';

adr_proc: process(wbs_adr, sel_c, wbm_adr_r) begin
	-- default values is provious state (to prvent lateches)
	wbm_adr_c  <= wbm_adr_r;
	if sel_c = 0 then
		wbm_adr_c <= wbs_adr;
	else  
		wbm_adr_c(ONE_HOT_ARR(sel_c)-1 downto 0)	<= wbs_adr(ONE_HOT_ARR(sel_c)-1 downto 0); 
		wbm_adr_c(ONE_HOT_ARR(sel_c))			<= '0';
	end if;
end process;
	
wbm_adr_r_proc: process(clk) begin
	if rising_edge(clk) then
		wbm_adr_r <= wbm_adr_c;
	end if;
end process;
	 
end generate;


full_adr_gen: if not SUB_ADR_OFFSET generate	
	wbm_adr_c	<= wbs_adr;
end generate;

end wb_switch_arch;

