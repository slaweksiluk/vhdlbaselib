--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wb_test_env_pkg.vhd
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
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

library vhdlbaselib;
use vhdlbaselib.common_pkg.all;

package wb_test_env_pkg is

-- Common for s and m
	constant ADR_STORE_WIDTH	: natural := 1024;
	shared variable ADR_STORE	: std_logic_vector(ADR_STORE_WIDTH-1 downto 0);
	constant DAT_STORE_WIDTH	: natural := 1024;
	shared variable WBM_DAT_STORE	: std_logic_vector(DAT_STORE_WIDTH-1 downto 0);


	constant TIMEOUT	: time := 1000 ns;
	signal WTE_TRIG		: boolean := true;
	signal WTE_DONE		: boolean := true;
	shared variable	VERBOSE	: boolean := false;
	constant MAX_ADR_WIDTH	: natural := 32;
	constant MAX_DAT_WIDTH	: natural := 32;
	
	type interface_t is (WBM_E, WBS_E, BOTH_E);

-- Master specific
	type stim_mode_t is (SINGLE_PIPE_WR, SINGLE_PIPE_RD);	
	shared variable wbm_stim_mode		: stim_mode_t := SINGLE_PIPE_WR;


-- Slave specific
	shared variable WBS_ACK_DELAY	: natural := 0;
	constant MAX_WB_SLAVES	: natural := 4;
	type wbs_dat_store_arr_t is array (0 to MAX_WB_SLAVES-1) of std_logic_vector(DAT_STORE_WIDTH-1 downto 0);
	shared variable WBS_DAT_STORE	: wbs_dat_store_arr_t;
	shared variable WBS_MEM			: wbs_dat_store_arr_t;
	
	type ret_mode_t is (ACK_E, ERR_E, RTY_E);
	shared variable wbs_ret_mode		: ret_mode_t := ACK_E;	
	
	type wbs_mode_t is (STORE, MEM);
	shared variable wbs_mode	: wbs_mode_t := MEM;

--	-- signals for connecting slave module
--	--WBS_STIM(clk, rst, wte_wbs_cyc, wte_wbs_stb, wte_wbs_we, wte_wbs_adr, wte_wbs_dat_i, wte_wbs_dat_o, wte_wbs_ack, wte_err);
--	signal wte_wbs_cyc		: std_logic := '0';
--	signal wte_wbs_stb		: std_logic := '0';
--	signal wte_wbs_we		: std_logic := '0';
--	signal wte_wbs_adr		: std_logic_vector(MAX_ADR_WIDTH-1 downto 0) := (others => '0');
--	signal wte_wbs_dat_i	: std_logic_vector(MAX_DAT_WIDTH-1 downto 0) := (others => '0');
--	signal wte_wbs_dat_o	: std_logic_vector(MAX_DAT_WIDTH-1 downto 0) := (others => '0');
--	signal wte_wbs_ack		: std_logic := '0';
--	signal wte_wbs_err		: std_logic := '0';
--		


 		
procedure WBM_STIM(
	signal clk	: in  std_logic;
	signal rst	: in  std_logic;
	signal cyc	: out std_logic;
	signal stb  : out std_logic;
	signal we   : out std_logic;	
	signal adr  : out std_logic_vector;
	signal dat_i: in  std_logic_vector;
	signal dat_o: out std_logic_vector;
	signal ack 	: in  std_logic;
	signal err 	: in  std_logic;
	signal done : out boolean
);		
procedure SINGLE_PIPE_WR(
	adr		: in std_logic_vector;
	dat		: in std_logic_vector;
	signal trig	: out boolean;
	ret			: in ret_mode_t
);
procedure SINGLE_PIPE_WR(
	adr		: in std_logic_vector;
	dat		: in std_logic_vector;
	signal trig	: out boolean
);
procedure SINGLE_PIPE_WR(
	adr			: in natural;
	dat			: in natural;	
	signal trig	: out boolean;
	adr_width	: in natural;
	dat_width	: in natural
);
procedure SINGLE_PIPE_RD(
	adr			: in std_logic_vector;
	dat			: in std_logic_vector;	
	signal trig	: out boolean;
	ret			: in ret_mode_t	
);
procedure SINGLE_PIPE_RD(
	adr			: in std_logic_vector;
	dat			: in std_logic_vector;	
	signal trig	: out boolean
);
procedure SINGLE_PIPE_RD(
	adr			: in natural;
	dat			: in natural;	
	signal trig	: out boolean;
	adr_width	: in natural;
	dat_width	: in natural
);
procedure WBS_STIM(
	signal clk	: in  std_logic;
	signal rst	: in  std_logic;
	signal cyc	: in std_logic;
	signal stb  : in std_logic;
	signal we   : in std_logic;	
	signal adr  : in std_logic_vector;
	signal dat_i: in  std_logic_vector;
	signal dat_o: out std_logic_vector;
	signal ack 	: out  std_logic;
	signal err 	: out  std_logic;
	inst_id		: natural;
	max_adr		: natural	
);
procedure SET_WBS_STORE(
	dat			: in std_logic_vector;
	inst_id		: natural
);

end wb_test_env_pkg;
package body wb_test_env_pkg is
--------------------------------------------------------------------------------		
-- INTERNAL PROCEDURES
--------------------------------------------------------------------------------
procedure CHECK_RET(
	signal clk	: in  std_logic;
	signal ack 	: in  std_logic;
	signal err 	: in  std_logic
) is begin
	wait until rising_edge(clk) and (ack = '1' or err = '1') for TIMEOUT;
		-- Check for double assertion
		assert ((ack = '1' and err = '0') or (ack = '0' and err = '1') or (ack = '0' and err = '0'))
		  report " CHECK_RET: slave asserted moren than one ret (ack/err/rty)"
		  severity failure;
		
		if wbs_ret_mode = ACK_E then
			--report " ack: "&std_logic'image(ack)&" err: "&std_logic'image(err);
			assert err = '0'
			  report " WBM_STIM wbs asserted err instead of expected ack"
			  severity failure;
			assert ack = '1'
			  report " WBM_STIM ack timeout"
			  severity failure;
		end if;
		
		if wbs_ret_mode = ERR_E then
			assert err = '1'
			  report " WBM_STIM err timeout"
			  severity failure;
		end if;
end procedure;
procedure PRINT_TO_SCREEN(msg : string) is begin 
-- Print to output only if verbose
	if VERBOSE then
		report msg;
	end if;
end procedure;

procedure PRINT_TO_SCREEN(inter : interface_t; inst_id : natural; msg : string) is
	variable L : line;
begin 
-- Print prefix
	write (L, String'("[ "));
	if inter = WBM_E then
		write(L, String'("WB MASTER "));
	elsif inter = WBS_E then
		write(L, String'(" WB SLAVE "));
	else
		assert false 
		  report "ATE PRINT_TO_SCREEN_PROC() wrong interface. Shuold be WBM_E or WBS_E" 
		  severity failure;
	end if;
	
	-- Pring instance ID
	if inst_id /= 0 then
		write(L, natural'image(inst_id));
	end if;
	write (L, String'(" ]   "));
	
-- Print msg
	write(L, msg);
	
-- Print to output only if verbose
	if VERBOSE then
		writeline(output, L);
	end if;
end procedure;

--impure function check_store(
--		inter 		: interface_t;
--		len		 	: natural;
--		inst_id		: natural
--	) 
--	return	boolean is
--begin
--	for i in 0 to len-1 loop
--		if inter = WBS_E then
--			assert WBS_DAT_STORE(inst_id)(i) /= 'U'
--				report "there is 'U' in WBS_DAT_STORE. Compare result will be always false"
--				severity warning;
--				return false;
--		elsif inter = WBM_E then
--			assert WBM_DAT_STORE(inst_id)(i) /= 'U'
--				report "there is 'U' in WBM_DAT_STORE. Compare result will be always false"
--				severity warning;
--				return false;			
--		end if;
--	end loop;
--	return true;
--end function;

--------------------------------------------------------------------------------		
-- MASTER USER PROCEDURES
--------------------------------------------------------------------------------
procedure WBM_STIM(
	signal clk	: in  std_logic;
	signal rst	: in  std_logic;
	signal cyc	: out std_logic;
	signal stb  : out std_logic;
	signal we   : out std_logic;	
	signal adr  : out std_logic_vector;
	signal dat_i: in  std_logic_vector;
	signal dat_o: out std_logic_vector;
	signal ack 	: in  std_logic;
	signal err 	: in  std_logic;
	signal done : out boolean
) is
	
begin
	PRINT_TO_SCREEN("WBM_STIM proc STARTED");
	wait until rising_edge(clk) and rst = '0';
	PRINT_TO_SCREEN("WBM_STIM proc rst deasserted");
	wait on WTE_TRIG;
	PRINT_TO_SCREEN("WBM_STIM proc triggered");
	wait until rising_edge(clk);
	case wbm_stim_mode is

	when SINGLE_PIPE_WR =>
			cyc		<= '1';
			stb		<= '1';
			we		<= '1';
			adr		<= ADR_STORE(adr'range);
			dat_o	<= WBM_DAT_STORE(dat_o'range);
		wait until rising_edge(clk);
			stb		<= '0';		
			CHECK_RET(clk, ack, err);
			cyc		<= '0';
	
	when SINGLE_PIPE_RD =>
			cyc		<= '1';
			stb		<= '1';
			we		<= '0';
			adr		<= ADR_STORE(adr'range);
		wait until rising_edge(clk);
			stb		<= '0';		
			CHECK_RET(clk, ack, err);
			-- verif data only in slace ACK return mode
			if wbs_ret_mode = ACK_E then
				assert dat_i = WBM_DAT_STORE(dat_i'range)
					report " [WBM_STIM]   fail data mismatch"
					severity failure;
			end if;
			cyc		<= '0';
	end case;
	done	<= not WTE_DONE;
	PRINT_TO_SCREEN("WBM_STIM proc FINISHED");
end procedure;

procedure SINGLE_PIPE_WR(
	adr		: in std_logic_vector;
	dat		: in std_logic_vector;
	signal trig	: out boolean;
	ret			: in ret_mode_t
) is begin
	wbm_stim_mode := SINGLE_PIPE_WR;
	ADR_STORE(adr'range)	:= adr;
	WBM_DAT_STORE(dat'range)	:= dat;
	wbs_ret_mode			:= ret;
	trig 					<= not WTE_TRIG;
	PRINT_TO_SCREEN("SINGLE_PIPE TRIGGERED, wait on done");
	wait on WTE_DONE;
end procedure;
procedure SINGLE_PIPE_WR(
	adr			: in std_logic_vector;
	dat			: in std_logic_vector;	
	signal trig	: out boolean
) is begin
	SINGLE_PIPE_WR(adr, dat, trig, ACK_E);
end procedure;
procedure SINGLE_PIPE_WR(
	adr			: in natural;
	dat			: in natural;	
	signal trig	: out boolean;
	adr_width	: in natural;
	dat_width	: in natural
) is begin
	SINGLE_PIPE_WR(
		std_logic_vector(to_unsigned(adr, adr_width)),
		std_logic_vector(to_unsigned(dat, dat_width)),
		trig, ACK_E);
end procedure;

procedure SINGLE_PIPE_RD(
	adr			: in std_logic_vector;
	dat			: in std_logic_vector;	
	signal trig	: out boolean;
	ret			: in ret_mode_t
) is begin
	wbm_stim_mode := SINGLE_PIPE_RD;
	ADR_STORE(adr'range)	:= adr;
	WBM_DAT_STORE(dat'range)	:= dat;	
	wbs_ret_mode			:= ret;
	trig 					<= not WTE_TRIG;
	PRINT_TO_SCREEN("SINGLE_PIPE TRIGGERED, wait on done");
	wait on WTE_DONE;
end procedure;

procedure SINGLE_PIPE_RD(
	adr			: in std_logic_vector;
	dat			: in std_logic_vector;	
	signal trig	: out boolean
) is begin
	SINGLE_PIPE_RD(adr, dat, trig, ACK_E);
end procedure;

procedure SINGLE_PIPE_RD(
	adr			: in natural;
	dat			: in natural;	
	signal trig	: out boolean;
	adr_width	: in natural;
	dat_width	: in natural
) is begin
	SINGLE_PIPE_RD(
		std_logic_vector(to_unsigned(adr, adr_width)),
		std_logic_vector(to_unsigned(dat, dat_width)), 
		trig, ACK_E);
end procedure;

--------------------------------------------------------------------------------		
-- SLAVE USER PROCEDURES
--------------------------------------------------------------------------------
procedure WBS_STIM(
	signal clk	: in  std_logic;
	signal rst	: in  std_logic;
	signal cyc	: in std_logic;
	signal stb  : in std_logic;
	signal we   : in std_logic;	
	signal adr  : in std_logic_vector;
	signal dat_i: in  std_logic_vector;
	signal dat_o: out std_logic_vector;
	signal ack 	: out  std_logic;
	signal err 	: out  std_logic;
	inst_id		: natural;
	max_adr		: natural	
) is
	variable dat_width	: natural := dat_i'length;
	variable adr_nat	: natural; 
begin

	PRINT_TO_SCREEN("WBS_STIM proc STARTED");
	wait until rising_edge(clk) and rst = '0';
	PRINT_TO_SCREEN("WBS_STIM proc rst deasserted");
	wait until rising_edge(clk) and cyc = '1' and stb = '1' for TIMEOUT;
		assert cyc = '1' and stb = '1'
			report " [WBS_STIM "&natural'image(inst_id)&" ]   timeout"
			severity failure;

		
		for d in 1 to WBS_ACK_DELAY loop
			wait until rising_edge(clk);
		end loop;
	
	adr_nat := to_integer(unsigned(adr));
	
		-- check if address is not x	
		assert not Is_X(adr)
			report " [WBS_STIM "&natural'image(inst_id)&" ]   adr is X val"
		  severity failure;		
	
		-- check if address is now bigger than allowed slave range
		assert adr_nat <= max_adr
			report " [WBS_STIM "&natural'image(inst_id)&" ]   adr bigger than allowed"
			severity failure;
						
		case WBS_MODE is
		when STORE =>
			-- compare the address
			assert adr = ADR_STORE(adr'range)
				report " [WBS_STIM]   addr mismatch"
				severity failure;	
		
--			assert check_store(WBS_E, dat_i'length-1)
--				severity error;
			
			-- if wbm is reading then set dat_o
			if we = '0' then
				dat_o	<= WBS_DAT_STORE(inst_id)(dat_o'range);
			-- if wbm is writing then check dat_i
			else
				assert dat_i = WBS_DAT_STORE(inst_id)(dat_i'range)
					report " [WBS_STIM]   fail data mismatch"
					severity failure;
			end if;
			
		when MEM =>
			-- if wbm is reading then set dat_o
			if we = '0' then
				report " wbs detect read at add "&integer'image(adr_nat);
				dat_o	<= WBS_MEM(inst_id)(dat_width*(adr_nat+1)-1 downto dat_width*adr_nat);
			-- if wbm is writing then set memory
			elsif we = '1' then
				WBS_MEM(inst_id)(dat_width*(adr_nat+1)-1 downto dat_width*adr_nat) := dat_i;
			else
				assert true severity failure;
			end if;
			
		when others =>
			assert true
				report "[WBS_STIM] unsupported mode"
				severity failure;
		end case;			
			
		ack		<= '1';
	wait until rising_edge(clk);
		ack		<= '0';
	PRINT_TO_SCREEN("WBS_STIM proc FINISHED");
end procedure;


procedure SET_WBS_STORE(
	dat			: in std_logic_vector;
	inst_id		: natural
) is begin
	assert wbs_mode = STORE
		report "[SET_WBS_STORE] setting wbs store while WBS not in STORE mode"
		severity failure;
	WBS_DAT_STORE(inst_id)(dat'range) := dat;	
end procedure;

--procedure SINGLE_PIPE_WR(
--	adr		: in std_logic_vector;
--	dat		: in std_logic_vector
--) is begin
--	ADR_STORE(adr'range)	:= adr;
--	DAT_STORE(dat'range)	:= dat;
--	wbs_ret_mode			:= ret;
--	trig 					<= not WTE_TRIG;
--	PRINT_TO_SCREEN("SINGLE_PIPE TRIGGERED, wait on done");
--	wait on WTE_DONE;
--end procedure;


end wb_test_env_pkg;
