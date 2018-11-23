-- Slawomir Siluk slaweksiluk@gazeta.pl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;

entity wb_master_axis_slave_bridge is
--Generic (
--	BUF_AVAIL_THRESHOLD : positive := 4
--);
Port (
	clk		: in std_logic;
	rst		: in std_logic;

	-- Wishbone master interface
	wb_adr : out std_logic_vector;
	wb_dat_i : in  std_logic_vector;
	wb_dat_o : out std_logic_vector;
	wb_sel : out std_logic_vector;
	wb_cyc : out std_logic;
	wb_stb : out std_logic;
	wb_we : out std_logic;
	wb_ack : in  std_logic;
	wb_stall : in  std_logic;

	-- AXIS slave data interface
	s_axis_data : in std_logic_vector;
	s_axis_valid : in std_logic;
	s_axis_ready : out std_logic;

	-- AXIS slave descriptor interface
	axis_desc_addr : in std_logic_vector;
	axis_desc_length : in std_logic_vector;
	axis_desc_valid : in std_logic;
	axis_desc_ready : out std_logic

);
end wb_master_axis_slave_bridge;
architecture beh of wb_master_axis_slave_bridge is

type state_type is 	(
						ST_IDLE,
						ST_ISSUE_WB,
						ST_CYCLE_END,
						ST_NEW_DESC
					);
signal state : state_type;
signal wb_adr_uns : unsigned(wb_adr'range);
signal desc_last_addr : unsigned(wb_adr'range);
signal pending_acks : natural;
signal desc_load : boolean := false;
constant BYTES_PER_TRANSACTION : positive := wb_sel'length;
signal wb_cyc_l : std_logic := '0';
signal wb_stb_l : std_logic := '0';
signal wb_acknowledge : boolean := false;
signal wb_request : boolean := false;

begin

fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state	<= ST_IDLE;
		desc_load <= false;
		wb_cyc_l <= '0';
		wb_stb_l <= '0';
		axis_desc_ready <= '0';
	else
		case state is
		when ST_IDLE =>
			if axis_desc_valid = '1' then
				state	<= ST_ISSUE_WB;
				desc_load <= true;
			end if;

		when ST_ISSUE_WB =>
			desc_load <= false;
			-- Issue as many wb requests as possible
			if wb_stall = '0' then
				wb_cyc_l <= '1';
				wb_stb_l <= s_axis_valid;
			end if;
			-- Stop when desc last address is reached
			if wb_adr_uns = desc_last_addr and wb_request then
				wb_stb_l <= '0';
				state <= ST_CYCLE_END;
			end if;

		when ST_CYCLE_END =>
			if pending_acks = 1 and wb_acknowledge then
				wb_cyc_l <= '0';
				state <= ST_NEW_DESC;
				axis_desc_ready <= '1';
			end if;

		when ST_NEW_DESC =>
			state <= ST_IDLE;
			axis_desc_ready <= '0';

		when others =>
		end case;
	end if;
end if;
end process;

--axis_desc_ready <= '1' when desc_load else '0';

-- Address logic. Load base address when new descriptor is present,
-- then increment it avery time wb_request is issuedw
addr_proc: process(clk)
	variable desc_len : unsigned(axis_desc_length'range);
	variable desc_addr : unsigned(axis_desc_addr'range);
begin
if rising_edge(clk) then
	if desc_load then
		desc_len := unsigned(axis_desc_length);
		desc_addr := unsigned(axis_desc_addr);
		wb_adr_uns <= desc_addr;
		desc_last_addr <= desc_addr + desc_len -(1*wb_sel'length);
	elsif wb_request then
		wb_adr_uns <= wb_adr_uns + BYTES_PER_TRANSACTION;
	end if;
end if;
end process;
wb_adr <= std_logic_vector(wb_adr_uns);

wb_request <= true when wb_cyc_l = '1' and wb_stb_l = '1' and wb_stall = '0' else false;
wb_acknowledge <= true when wb_ack = '1' else false;

-- Keep track the number of pending ack (requests issued, but acks
-- not yet received)
pending_acks_proc: process(clk) begin
if rising_edge(clk) then
	if wb_request and wb_acknowledge then
		pending_acks <= pending_acks;
	elsif wb_request then
		pending_acks <= pending_acks +1;
	elsif wb_acknowledge then
		pending_acks <= pending_acks -1;
	end if;
end if;
end process;

wb_dat_o <= s_axis_data;
-- ? <= s_axis_valid; driven by fsm
s_axis_ready <= '1' when wb_request else '0';

-- Local to output assigments
wb_cyc <= wb_cyc_l;
wb_stb <= wb_stb_l;

-- Tied bits
wb_we <= '1';
wb_sel <= ((wb_sel'range) => '1');

end beh;
