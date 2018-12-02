-- Slawomir Siluk slaweksiluk@gazeta.pl
-- TODO move wb cyc end detection to separate entity as it can be
-- usable in the other modules.
-- TODO there can be bug in ST_CYCLE_END. What if strobe is asserted at
-- when pending_acks is 1 and wb_acknowledge? For this test vunit
-- wb master bfm will need random strobe stim. Also, it will necessary
-- to add wb cycles variable test to this tb to detect it in diffrent
-- conditions
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;

entity wb_master_axis_master_bridge is
Generic (
	BUF_AVAIL_THRESHOLD : positive := 4;
	MAX_PENDING_REQUESTS : positive := 16
);
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

	-- AXIS master data interface
	m_axis_data : out std_logic_vector;
	m_axis_valid : out std_logic;
	m_axis_ready : in std_logic;

	-- Room in external buffer
	buf_room : natural;

	-- AXIS slave descriptor interface
	axis_desc_addr : in std_logic_vector;
	axis_desc_length : in std_logic_vector;
	axis_desc_valid : in std_logic;
	axis_desc_ready : out std_logic;

	-- Dbg out for coverage check
	pending_acks_dbg : out natural;
	state_cyc_end : out boolean
);
end wb_master_axis_master_bridge;
architecture beh of wb_master_axis_master_bridge is

type state_type is 	(
						ST_IDLE,
						ST_ISSUE_WB,
						ST_CYCLE_END,
						ST_NEW_DESC
					);
signal state	: state_type;
signal buffer_avail	: boolean := false;
signal wb_adr_uns : unsigned(wb_adr'range);
signal desc_last_addr : unsigned(wb_adr'range);
signal pending_acks : natural;
signal desc_load : boolean := false;
constant BYTES_PER_TRANSACTION : positive := wb_sel'length;
signal wb_cyc_l : std_logic := '0';
signal wb_stb_l : std_logic := '0';
signal wb_acknowledge : boolean := false;
signal wb_request : boolean := false;
signal buf_avail_count : natural;
signal max_requests_pending	: boolean := false;
signal cycle_finished	: boolean := false;

begin

fsm: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state	<= ST_IDLE;
		wb_cyc_l <= '0';
		wb_stb_l <= '0';
		desc_load <= false;
		axis_desc_ready <= '0';
	else
		case state is
		when ST_IDLE =>
			axis_desc_ready <= '0';
			if axis_desc_valid = '1' then
				state	<= ST_ISSUE_WB;
				desc_load <= true;
			end if;

		when ST_ISSUE_WB =>
			desc_load <= false;
			-- Issue as many wb requests as possible
			if wb_stall = '0' and buffer_avail then
				wb_cyc_l <= '1';
				wb_stb_l <= '1';
			elsif not buffer_avail or max_requests_pending then
				wb_stb_l <= '0';
			end if;
			-- Stop when desc last address is reached
			if wb_adr_uns = desc_last_addr and wb_request then
				wb_stb_l <= '0';
				state <= ST_CYCLE_END;
			end if;

		when ST_CYCLE_END =>
			if cycle_finished then
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

wb_cycle_end_det_inst : entity vhdlbaselib.wb_cycle_end_det
	generic map (
		MAX_PENDING => MAX_PENDING_REQUESTS
	) port map (
		clk                  => clk,
		rst                  => rst,
		wb_request           => wb_request,
		wb_acknowledge       => wb_acknowledge,
		cycle_finished       => cycle_finished,
		requests_pending     => pending_acks,
		max_requests_pending => max_requests_pending
	);
wb_request <= true when wb_cyc_l = '1' and wb_stb_l = '1' and wb_stall = '0' else false;
wb_acknowledge <= true when wb_ack = '1' else false;

-- There always have to be room for pending_acks in fifo. Track
-- the difference between pending_acks and output buffer room. When
-- this difference is bigger than some threhold (ideally = 1) then
-- raise buffer_avail flag
buf_avail: process(clk) begin
if rising_edge(clk) then
	buf_avail_count <= buf_room - pending_acks;
	if buf_avail_count > BUF_AVAIL_THRESHOLD then
		buffer_avail <= true;
	else
		buffer_avail <= false;
	end if;
end if;
end process;


m_axis_data <= wb_dat_i;
m_axis_valid <= wb_ack;
-- Flow control is based on buf_room input
-- ? <= m_axis_ready


-- Local to output assigments
wb_cyc <= wb_cyc_l;
wb_stb <= wb_stb_l;

-- Tied bits
wb_we <= '0';
wb_sel <= ((wb_sel'range) => '1');

-- Dng outputs for covarage
pending_acks_dbg <= pending_acks;
state_cyc_end <= true when state = ST_CYCLE_END else false;

end beh;
