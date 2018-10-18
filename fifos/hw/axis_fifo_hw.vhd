-- Slawomir Siluk slaweksiluk@gazeta.pl
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axis_fifo_hw is
Generic (
	DEPTH : positive := 1024;
	WIDTH : positive := 32
);
Port (
	clk : in std_logic;
	rst : in std_logic;

	s_axis_data	: in std_logic_vector(WIDTH-1 downto 0);
	s_axis_valid : in std_logic;
	s_axis_ready : out std_logic;
	m_axis_data : out std_logic_vector(WIDTH-1 downto 0);
	m_axis_valid : out std_logic;
	m_axis_ready : in std_logic
);
end axis_fifo_hw;
architecture top of axis_fifo_hw is
begin

	inst : entity work.axis_fifo
	generic map
	(
	  DEPTH => DEPTH
	)
	port map
	(
	  clk          => clk,
	  rst          => rst,
	  s_axis_data  => s_axis_data,
	  s_axis_valid => s_axis_valid,
	  s_axis_ready => s_axis_ready,
	  m_axis_data  => m_axis_data,
	  m_axis_valid => m_axis_valid,
	  m_axis_ready => m_axis_ready
	);

end top;
