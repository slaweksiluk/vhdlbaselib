	-- Slawomir Siluk slaweksiluk@gazeta.pl
-- Simple no registered fall through implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axis_fall_through is
Port (
	clk : in std_logic;
	s_axis_data	: in std_logic_vector;
	s_axis_valid : in std_logic;
	s_axis_ready : out std_logic;
	m_axis_data : out std_logic_vector;
	m_axis_valid : out std_logic := '0';
	m_axis_ready : in std_logic
);
end axis_fall_through;
architecture behavioral of axis_fall_through is
	signal fwft : boolean := false;
	signal m_axis_valid_r : std_logic := '0';
	signal m_axis_ready_r : std_logic;
begin

delay: process(clk) begin
if rising_edge(clk) then
	if m_axis_ready = '1' or fwft then
		m_axis_valid_r <= s_axis_valid;
	end if;
	-- clear m valid r when consumed
	if m_axis_ready = '1' and m_axis_valid = '1' and fwft then
		m_axis_valid_r <= '0';
	end if;
	m_axis_ready_r <= s_axis_ready;
end if;
end process;

fwft_reg: process(clk) begin
if rising_edge(clk) then
	-- Fall through when not ready
	if m_axis_ready = '0' and s_axis_valid = '1' and m_axis_ready_r /= '1' and m_axis_valid_r /= '1' then
		fwft <= true;
		m_axis_data <= s_axis_data;
		m_axis_valid <= s_axis_valid;
	elsif m_axis_ready = '1' and not fwft then
		m_axis_data <= s_axis_data;
		m_axis_valid <= s_axis_valid;
	elsif m_axis_ready = '1' and fwft then
		fwft <= false;
		m_axis_valid <= '0';
	end if;
end if;
end process;

s_axis_ready <= m_axis_ready;

end behavioral;

