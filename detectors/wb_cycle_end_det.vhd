-- 2018 Slawomir Siluk slaweksiluk@gazeta.pl
-- Detects end of pipelined wishbone cycle
-- Flags max_requests_pending and cycle_finished are combinatorial outputs
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wb_cycle_end_det is
Generic (
	 MAX_PENDING : positive := 4
);
Port (
	clk : in std_logic;
	rst	: in std_logic;

	wb_request : in boolean;
	wb_acknowledge : in boolean;

	cycle_finished : out boolean;
	requests_pending : out natural;
	max_requests_pending : out boolean
);
end wb_cycle_end_det;
architecture beh of wb_cycle_end_det is

signal pending : natural range 0 to MAX_PENDING;
signal got_wb_request : boolean := false;
signal max_requests_pending_c : boolean := false;

begin

-- Keep track the number of pending ack (requests issued, but acks
-- not yet received)
pending_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		pending <= 0;
	else
		if wb_request and wb_acknowledge then
			pending <= pending;
		elsif wb_request then
			pending <= pending +1;
		elsif wb_acknowledge then
			pending <= pending -1;
		end if;
	end if;
end if;
end process;

max_requests_pending_c <= true when
	(pending = MAX_PENDING-1 and wb_request	and not wb_acknowledge)	or
	(pending = MAX_PENDING) or
	(pending = MAX_PENDING and not wb_request and wb_acknowledge)
	else false;

max_requests_pending <= max_requests_pending_c;

got_wb_request_proc: process(clk) begin
if rising_edge(clk) then
	if cycle_finished or rst = '1' then
		got_wb_request <= false;
	elsif wb_request then
		got_wb_request <= true;
	end if;
end if;
end process;

cycle_finished <= true when pending = 1 and wb_acknowledge and not wb_request and
	got_wb_request else false;

requests_pending <= pending;

end beh;
