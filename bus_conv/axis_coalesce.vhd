-- 2018 Slawomir Siluk slaweksiluk@gazeta.pl
-- Simple implementation:
--  - master ready routed directly to slaves (it sholud be deasserted
--  after valid is received)
--  - widths of all streams in s_data are the same e.g 3x32bit, which makes
--  s_data'length = m_data'length
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_misc.ALL;

entity axis_coalesce is
Generic (
	TARGETS : positive := 2;
	DATA_WIDTH : positive := 8
);
Port (
	clk		: in std_logic;
	rst		: in std_logic;
	s_data	: in std_logic_vector(TARGETS*DATA_WIDTH-1 downto 0);
	s_valid	: in std_logic_vector;
	s_ready	: out std_logic_vector;
	m_data	: out std_logic_vector;
	m_valid	: out std_logic;
	m_ready	: in std_logic
);
end axis_coalesce;
architecture rtl of axis_coalesce is

signal got_valid : std_logic_vector(s_valid'range);
signal got_data : std_logic_vector(m_data'range);
signal all_valid : std_logic;

begin

ready_gen: for i in s_ready'range generate
	s_ready(i) <= m_ready;
end generate;


collect_gen: for i in s_valid'range generate
	collect_proc: process(clk) begin
	if rising_edge(clk) then
		if s_valid(i) = '1' then
			got_valid(i) <= '1';
			got_data((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) <=
					s_data((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH);
		end if;
		if all_valid = '1' then
			got_valid(i) <= '0';
		end if;
	end if;
	end process;
end generate;

valid_proc: process(clk) begin
if rising_edge(clk) then
	all_valid <= and_reduce(got_valid);
	if all_valid = '1' then
		all_valid <= '0';
	end if;
end if;
end process;

-- Outputs assignments
m_valid <= all_valid;
m_data <= got_data;

end rtl;
