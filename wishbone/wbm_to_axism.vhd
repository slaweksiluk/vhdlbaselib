--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wbm_to_axism.vhd
-- Language: VHDL
-- Description: 
-- 
-- * GENERAL
-- Triggering configuravle Wsihbone bus transaction via its master interface
-- and share received data via axis master interface. WB data is read in
-- Pipelined BLOCK READ cycles.
--
-- * FLOW CONTROl
-- As in piplined mode requested data must be accepted (cannot be suspended)
-- some flow control is needed. Behind te AXIS master interface there is fifo 
-- with prog_full flag defined as follow: 
--		PROG_FULL = FIFO_WRITE_DEPTH - WB_BLOCK_READ_LENGTH
-- Whre WB_BLOCK_READ_LENGTH is synthesis constant. FSM runs in loop:
-- 1) wait until PROG_FULL is low ( and additional csr flag is high)
-- 2) trigger Wishbone cycle
-- 3) wait till current block cycle is done
--
-- * WB ADDR
-- Addreses is as follow: 
--		WB_ADDR = DONE_BLOCK_READS * WB_BLOCK_READ_LENGTH + REQ_COUNTER_uns
-- Where MULT is another counter which is keepin track of req_counter equal to
-- WB_BLOCK_READ_LENGTH conditions. REQ_COUNTER_uns is counting every signle 
-- Wishbone reguest. Addresses are generated until MAX_WB_ADDR is reached.

-- Dependencies: 
-- 1. counter.vhd
-- Revision:
-- * Revision 0.01 - File Created
-- Additional Comments:
-- Currently, only multiplies of WB_BLOCK_READ_LENGTH are supported as
-- WB_MAX_ADDR. Passing diffrent value will couse rounding MAX_WB_ADDR to highest
-- multiply of WB_BLOCK_READ_LENGTH smaller than MAX_WB_ADDR. 
--------------------------------------------------------------------------------
--
-- Revision 0.02 25/05/16 Need to update to WB PIPELINED BLOCK read cycle with 
--	help of prog full fifo flag.
-- * WB master can NOT deassert STB during REQ phase. 
--
-- Revision 0.1 01/06/16 Finished and little tested
-- * wb_cyc is deasserted one cycle after ACK is deasserted. Its not possible
--	to deassert wb_cyc synchronously without one clk delay when addr_remainder
--	is equal to 1.
-- * Passed testes with changed WB_BLOCK_READ_LENGTH generic and max_wb_addr.

-- 17/06/16 Revision 0.03 Byte addr limit with axis master keep


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;
use vhdlbaselib.common_pkg.all;

entity wbm_to_axism is
	Generic (
		ADL						: time 		:= 0 ps;
		WB_WIDTH				: natural 	:= 32;
		WB_ADDR_WIDTH			: natural 	:= 30;		
		BYTE_ADDR_WIDTH			: natural 	:= 32;		
		AXIS_WIDTH				: natural 	:= 32;
		WB_BLOCK_READ_LENGTH	: natural 	:= 32
	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
		-- Wishbone master interface
		wb_adr   : out std_logic_vector(WB_ADDR_WIDTH-1 downto 0);
		wb_dat_i : in  std_logic_vector(WB_WIDTH-1 downto 0);
		wb_dat_o : out std_logic_vector(31 downto 0);
		wb_sel   : out std_logic_vector(3 downto 0);
		wb_cyc   : out std_logic;
		wb_stb   : out std_logic;
		wb_we    : out std_logic;
		wb_ack   : in  std_logic;
		wb_stall : in  std_logic;
		
		-- AXIS master interface
		axis_m_data		: out std_logic_vector(AXIS_WIDTH-1 downto 0);
		axis_m_keep		: out std_logic_vector(AXIS_WIDTH/8-1 downto 0);
		axis_m_valid	: out std_logic;
		axis_m_ready	: in std_logic;
		
		-- Others signals
		trig			: in std_logic;
		max_byte_addr	: in std_logic_vector(BYTE_ADDR_WIDTH-1 downto 0); 
		prog_full		: in std_logic
		
		
    );
end wbm_to_axism;
architecture wbm_to_axism_arch of wbm_to_axism is

constant REQ_COUNTER_WIDTH 		: natural := calc_width(WB_BLOCK_READ_LENGTH);
constant MAX_BLOCKS_IN_WB_ADDR 	: natural := (2**(WB_ADDR_WIDTH-1)) / WB_BLOCK_READ_LENGTH;
constant ADDR_COUNTER_WIDTH	: natural := calc_width(MAX_BLOCKS_IN_WB_ADDR);
constant WB_BLOCK_READ_LENGTH_WIDTH	: natural := calc_width(WB_BLOCK_READ_LENGTH);
constant WB_BLOCK_READ_LENGTH_UNS	: unsigned(WB_BLOCK_READ_LENGTH_WIDTH-1 downto 0)
 				:= to_unsigned(WB_BLOCK_READ_LENGTH, WB_BLOCK_READ_LENGTH_WIDTH);


type state_type is 	(
						IDLE_STATE,
						INIT_STATE,
						WB_REQ_STATE,
						WB_ACK_STATE
					);
signal state	: state_type := IDLE_STATE;

signal rst_req_counter		: std_logic := '1';
signal rst_ack_counter		: std_logic := '1';
signal rst_addr_counter		: std_logic := '1';
signal wb_stb_i				: std_logic := '0';
signal wb_cyc_i				: std_logic := '0';
signal req_counted			: boolean := false;
signal req_counted_r		: boolean := false;	
signal ack_counted			: boolean := false;
signal addr_counted			: boolean := false;
signal addr_counted_r		: boolean := false;
signal ce_req_counter		: std_logic := '0';
signal ce_ack_counter		: std_logic := '0';
signal ce_addr_counter		: std_logic := '0';
signal req_counter			: std_logic_vector(REQ_COUNTER_WIDTH-1 downto 0);
signal ack_counter			: std_logic_vector(REQ_COUNTER_WIDTH-1 downto 0);
signal addr_counter			: std_logic_vector(ADDR_COUNTER_WIDTH-1 downto 0);
signal req_counter_uns		: unsigned(REQ_COUNTER_WIDTH-1 downto 0);
signal ack_counter_uns		: unsigned(REQ_COUNTER_WIDTH-1 downto 0);
signal addr_counter_uns		: unsigned(ADDR_COUNTER_WIDTH-1 downto 0);
signal wb_addr_uns			: unsigned(WB_ADDR_WIDTH-1 downto 0);
signal max_wb_block_reads_uns : unsigned(WB_ADDR_WIDTH-1 downto 0);
signal max_wb_reads_uns 	: unsigned(ADDR_COUNTER_WIDTH downto 0);
signal max_adr_reached		: boolean := false;
signal max_adr_reached_c	: boolean := false;
signal addr_remainder		: unsigned(WB_BLOCK_READ_LENGTH_WIDTH-1 downto 0);
signal cnt_comp_val			: unsigned(WB_BLOCK_READ_LENGTH_WIDTH-1 downto 0);

signal req_counted_event_c	: boolean := false;
signal req_counted_event_r	: boolean := false;
signal zero_block_reads_c	: boolean := false;
signal zero_block_reads_r	: boolean := false;

signal max_wb_addr_uns_r	: unsigned(WB_ADDR_WIDTH-1 downto 0);
signal byte_rem_uns_r		: unsigned(2-1 downto 0);
signal max_byte_addr_uns	: unsigned(BYTE_ADDR_WIDTH-1 downto 0);




begin
--
-- AXIS BYTE KEPP LOGIC
--

-- Convert 
max_byte_addr_uns <= unsigned(max_byte_addr);

-- To get max_wb_addr_r it's neccesary to divide byte addr by 4
byte_proc: process(clk) begin
if rising_edge(clk) then
	max_wb_addr_uns_r <= resize(shift_right(max_byte_addr_uns, 2), WB_ADDR_WIDTH) after ADL;
end if;
end process;

-- Rest of bytes is 2 LSB of byte NUMBEER (ADDR +1)!
byte_rem_proc: process(clk) begin
if rising_edge(clk) then
	byte_rem_uns_r <= max_byte_addr_uns(1 downto 0) + 1 after ADL;
end if;
end process;

-- keep is loaded when max_adr_reached AND ack_counted
keep_proc: process(clk) begin
if rising_edge(clk) then
	if rst_addr_counter = '1' then
		axis_m_keep	<= (others => '1') after ADL;
	elsif ack_counted and max_adr_reached then
		case byte_rem_uns_r is
			when "00" =>
				axis_m_keep	<= "1111" after ADL;
			when "01" =>
				axis_m_keep	<= "0001" after ADL;
			when "10" =>
				axis_m_keep	<= "0011" after ADL;
			when "11" =>
				axis_m_keep <= "0111" after ADL;
			when others =>
		end case;	
	end if;
end if;
end process;

-- ADD this


-- FSM is controling counter resets signals and wb cyc, stb
fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
--	assert false
--	report "MAX_BLOCKS_IN_WB_ADDR: "  & natural'image(MAX_BLOCKS_IN_WB_ADDR)
--	severity note;
		state	<= IDLE_STATE after ADL;
		rst_addr_counter		<= '1' after ADL;
	else
		case state is
		when IDLE_STATE =>
			if trig = '1' then
				state			<= INIT_STATE after ADL;
			end if;
			
		
		when INIT_STATE =>
			-- Set compare value for REQ and ACK counters
				
			if addr_counted_r or zero_block_reads_r then
--				if byte_rem_uns_r = 0 then
	 				cnt_comp_val	<= addr_remainder after ADL;
-- 				else
--	 				cnt_comp_val	<= addr_remainder + 1 after ADL;
-- 				end if;
			else
				cnt_comp_val	<= WB_BLOCK_READ_LENGTH_UNS after ADL;
			end if;
		
			wb_cyc_i		<= '0' after ADL;
			if prog_full = '0' and wb_stall = '0' then
				rst_req_counter <= '0' after ADL;
				rst_ack_counter <= '0' after ADL;
				rst_addr_counter		<= '0' after ADL;
				wb_stb_i		<= '1' after ADL;
				wb_cyc_i		<= '1' after ADL;
				state			<= WB_REQ_STATE after ADL;
			end if;		
		
		when WB_REQ_STATE =>
			if req_counted and wb_stall = '0' then
				rst_req_counter <= '1' after ADL;
				wb_stb_i		<= '0' after ADL;
				state			<= WB_ACK_STATE after ADL;
			end if;

		when WB_ACK_STATE =>
			wb_stb_i		<= '0' after ADL;
			-- ACK finished and max_wb_adr reached
			if ack_counted and max_adr_reached then
				rst_addr_counter<= '1' after ADL;
				rst_ack_counter	<= '1' after ADL;
				wb_cyc_i		<= '0' after ADL;
				state			<= IDLE_STATE after ADL;
			-- Only ACK finished
			elsif ack_counted then
				rst_addr_counter<= '0' after ADL;
				rst_ack_counter	<= '1' after ADL;
				wb_cyc_i		<= '0' after ADL;
				state			<= INIT_STATE after ADL;
			end if;
		end case;
	end if;
end if;
end process;


-- Logic for calulating compare values for ACK and REG cnt
	-- Load remiander when ful block reading is finished
--comp_val_proc: process(clk) begin
--if rising_edge(clk) then
--	if rst_addr_counter = '1' then
--		cnt_comp_val	<= WB_BLOCK_READ_LENGTH_UNS after ADL;
--	elsif ce_comp_val then
--		cnt_comp_val	<= addr_remainder after ADL;
--	end if;
--end if;
--end process;
	-- Calculate remiander
	addr_remainder		<= resize((max_wb_addr_uns_r+1) - 
							(max_wb_block_reads_uns * WB_BLOCK_READ_LENGTH_UNS), 
							addr_remainder'length);
	
	
-- Logic for detection of max_wb_block_reads_uns equal =
zero_block_proc: process(clk) begin
if rising_edge(clk) then
	zero_block_reads_r	<= zero_block_reads_c after ADL;
end if;
end process;
zero_block_reads_c	<= true when max_wb_block_reads_uns = 0 else false;

	



-- Addr limit reached flag
max_addr_proc: process(clk) begin
if rising_edge(clk) then
	if rst_addr_counter = '1' then
		max_adr_reached <= false after ADL;
	elsif wb_cyc_i = '1' and wb_stb_i = '1' then
		max_adr_reached <= max_adr_reached_c after ADL;
	end if;
end if;
end process;	
max_adr_reached_c	<= true when (wb_addr_uns = max_wb_addr_uns_r) 
	else false;

--
-- REQ counter inst
--
req_counter_inst : entity vhdlbaselib.counter
	generic map
	(
		ADL   => ADL,
		WIDTH => REQ_COUNTER_WIDTH
	)
	port map
	(
		clk  => clk,
		sclr => rst_req_counter,
		ce   => ce_req_counter,
		q    => req_counter
	);
-- CE logic for req counter
ce_req_counter <= '1' when wb_stb_i = '1' and wb_cyc_i = '1' and wb_stall = '0'
														else '0';
-- Counting done logic
req_counter_uns	<= unsigned(req_counter);	
req_counted <= true when req_counter_uns = cnt_comp_val-1 and 
												ce_req_counter = '1' else false;
 
--
-- ACK counter inst
--
ack_counter_inst : entity vhdlbaselib.counter
	generic map
	(
		ADL   => ADL,
		WIDTH => REQ_COUNTER_WIDTH
	)
	port map
	(
		clk  => clk,
		sclr => rst_ack_counter,
		ce   => ce_ack_counter,
		q    => ack_counter
	);
-- CE logic for ack counter
ce_ack_counter <= '1' when wb_cyc_i = '1' and wb_ack = '1' else '0';
-- ack counting done logic			
ack_counter_uns	<= unsigned(ack_counter);
-- Here it's not neccesart to look at ce_ack_counter signal as ack is asserted
-- without gaps					
ack_counted <= 	
--				true when ack_counter_uns = 1 and addr_remainder = 1 else 
				true when ack_counter_uns = cnt_comp_val-1 and ce_ack_counter = '1'
				else false;




--
-- ADDR counter inst
--
addr_counter_inst : entity vhdlbaselib.counter
	generic map
	(
		ADL   => ADL,
		WIDTH => ADDR_COUNTER_WIDTH
	)
	port map
	(
		clk  => clk,
		sclr => rst_addr_counter,
		ce   => ce_addr_counter,
		q    => addr_counter
	);
	
	
-- Detecion of rising edge of req_counted flag
req_e_det_proc: process(clk) begin
if rising_edge(clk) then
	req_counted_event_r <= req_counted_event_c after ADL;
	req_counted_r 		<= req_counted after ADL;
end if;
end process;
req_counted_event_c <= true when req_counted /= req_counted_r and
												req_counted = true else false;

-- CE logic for addr counter
ce_addr_counter <= '1' when req_counted_event_r else '0';
-- Calc how many block reads is needed to reach max_wb_addr
max_wb_block_reads_uns <= (max_wb_addr_uns_r+1) / WB_BLOCK_READ_LENGTH_UNS; 
-- Addr counting done logic			
addr_counter_uns <= unsigned(addr_counter);
addr_counted <= true when addr_counter_uns = (max_wb_block_reads_uns-1) and 
											ce_addr_counter = '1' else false;
-- Register addr_counted
adr_cnted_proc: process(clk) begin
if rising_edge(clk) then
	if rst_addr_counter = '1' then
		addr_counted_r	<= false after ADL;
	elsif addr_counted then
		addr_counted_r	<= true after ADL;
	end if;
end if;
end process;											
											
																						
																						
-- Wishbone address calculation 
-- WB_ADDR = DONE_BLOCK_READS * WB_BLOCK_READ_LENGTH + REQ_COUNTER_uns
wb_addr_uns <= resize(addr_counter_uns * to_unsigned(WB_BLOCK_READ_LENGTH, 
					wb_addr_uns'length) + req_counter_uns, wb_addr_uns'length);
wb_addr_proc: process(clk) begin
if rising_edge(clk) then
	wb_adr	<= std_logic_vector(wb_addr_uns) after ADL;
end if;
end process;


-- Outputs assigments
-- CYC & STB delayed
cyc_stb_out_proc: process(clk) begin
if rising_edge(clk) then
	wb_cyc	<= wb_cyc_i after ADL;
	wb_stb	<= wb_stb_i after ADL;
end if;
end process;

wb_we	<= '0';
wb_dat_o <= (others => '0');
wb_sel		<= (others => '1');
out_proc: process(clk) begin
if rising_edge(clk) then
	axis_m_data <= wb_dat_i after ADL;
	axis_m_valid <= wb_ack after ADL;
end if;
end process;



 														
end wbm_to_axism_arch;

