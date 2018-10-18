-- Slawomir Siluk slaweksiluk@gazeta.pl
-- TODO
-- * reset
-- * fwft

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library vhdlbaselib;

entity axis_fifo is
Generic (
	DEPTH : positive := 32;
	FWFT : boolean := false
);
Port (
	clk : in std_logic;
	rst : in std_logic;

	count : out natural;
	room : out natural;
	full : out std_logic;
	empty : out std_logic;

	s_axis_data	: in std_logic_vector;
	s_axis_valid : in std_logic;
	s_axis_ready : out std_logic;
	m_axis_data : out std_logic_vector;
	m_axis_valid : out std_logic := '0';
	m_axis_ready : in std_logic
);
end axis_fifo;
architecture behavioral of axis_fifo is

	type mem_t is array (0 to DEPTH-1) of std_logic_vector(m_axis_data'range);
	signal mem : mem_t;
	signal wr_ptr : natural range 0 to DEPTH-1 := 0;
	signal rd_ptr : natural range 0 to DEPTH-1 := 0;
	signal fifo_full : boolean := false;
	signal fifo_empty : boolean := true;
	signal fifo_count : natural range 0 to DEPTH := 0;
	signal s_axis_ready_l : std_logic := '0';
	signal m_axis_valid_l : std_logic := '0';
	signal wr_en : boolean := false;
	signal rd_en : boolean := false;
	signal axis_local_ready : std_logic;

	function next_wr_free(
		wr_ptr : natural;
		rd_ptr : natural
	) return boolean is
	begin
		if (wr_ptr +1) mod DEPTH = rd_ptr then
			return false;
		else
			return true;
		end if;
	end function;

	function rd_valid(
		wr_ptr : natural;
		rd_ptr : natural;
		valid : std_logic;
		ready : std_logic
	) return boolean is
	begin
		if rd_ptr < wr_ptr then
			if rd_ptr = wr_ptr -1 and valid = '1' and ready = '1' then
				return false;
			else
				return true;
			end if;
		else
			return false;
		end if;
	end function;

begin

	wr_ptr_proc: process(clk)
	begin
	if rising_edge(clk) then
		-- Increment wr pointer when data is accepted
		if wr_en then
			wr_ptr <= (wr_ptr +1) mod DEPTH;
		end if;
	end if;
	end process;

	s_ready_proc: process(clk)
	begin
	if rising_edge(clk) then
		-- Cannot get new data when next pointer is occupied by read
		if next_wr_free(wr_ptr, rd_ptr) and not fifo_full then
			s_axis_ready_l <= '1';
		else
			s_axis_ready_l <= '0';
		end if;
	end if;
	end process;

	wr_en <= true when (s_axis_valid and s_axis_ready_l) = '1' else false;
	rd_en <= true when (m_axis_valid_l and axis_local_ready) = '1' else false;

	count_proc: process(clk)
	begin
	if rising_edge(clk) then
		if wr_en and rd_en then
			fifo_count <= fifo_count;
		elsif wr_en then
			fifo_count <= fifo_count +1;
		elsif rd_en then
			fifo_count <= fifo_count -1;
		end if;
	end if;
	end process;

	fifo_full <= true when fifo_count = DEPTH else false;
	fifo_empty <= true when fifo_count = 0 else false;

	rd_ptr_proc: process(clk)
	begin
	if rising_edge(clk) then
		-- Increment rd pointer when data is accepted
		if rd_en then
			rd_ptr <= (rd_ptr +1) mod DEPTH;
		end if;
	end if;
	end process;

	m_axis_valid_l <= '0' when fifo_empty else '1';

	memwr_proc: process(clk) begin
	if rising_edge(clk) then
		if wr_en then
			mem(wr_ptr) <= s_axis_data;
		end if;
	end if;
	end process;

	classic_fifo_gen: if not FWFT generate
	memrd_proc: process(clk) begin
		if rising_edge(clk) then
			if axis_local_ready = '1' then
				m_axis_data <= mem(rd_ptr);
				m_axis_valid <= m_axis_valid_l;
			end if;
		end if;
		end process;
	axis_local_ready <= m_axis_ready;
	end generate;

	fwft_fifo_gen: if FWFT generate
		signal axis_fwft_data : std_logic_vector(m_axis_data'range);
		signal axis_fwft_valid : std_logic;
		signal axis_fwft_ready : std_logic;
	begin
		axis_fall_through_inst : entity vhdlbaselib.axis_fall_through
		port map (
			clk          => clk,
			s_axis_data  => axis_fwft_data,
			s_axis_valid => axis_fwft_valid,
			s_axis_ready => axis_fwft_ready,
			m_axis_data  => m_axis_data,
			m_axis_valid => m_axis_valid,
			m_axis_ready => m_axis_ready
		);
		axis_fwft_data <= mem(rd_ptr);
		axis_fwft_valid <= m_axis_valid_l;
		axis_local_ready <= axis_fwft_ready;
	end generate;

	s_axis_ready <= s_axis_ready_l;

-- Auxilarry outputs
	-- Full and empty registered
	flags_out_proc: process(clk) begin
	if rising_edge(clk) then
		if fifo_full then
			full <= '1';
		else
			full <= '0';
		end if;
		if fifo_empty then
			empty <= '1';
		else
			empty <= '0';
		end if;
		-- Registered output
		count <= fifo_count;
		room <= DEPTH - fifo_count;
	end if;
	end process;
end behavioral;
