library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library vhdlbaselib;
entity wbs_reg_wrap is
Generic (
    ADL : time := 0 ps
);
Port (
            clk : in std_logic;
            rst : in std_logic;
            wbs_cyc         : in std_logic;
            wbs_stb         : in std_logic;
            wbs_adr         : in std_logic_vector;
            wbs_we          : in std_logic;
            wbs_dat_i       : in std_logic_vector;
            wbs_dat_o       : out std_logic_vector;
            wbs_ack         : out std_logic;
            wbs_err         : out std_logic;
            sw_int_reset_e : out std_logic;
            addr_space_e : out std_logic;
            dma_dos_trig_e : out std_logic;
            ups_en_e : out std_logic;
            irq_test_trig_e : out std_logic;
            mrd_burst_e : out std_logic_vector(31 downto 0);
            mrd_base_addr_l_e : out std_logic_vector(31 downto 0);
            mrd_base_addr_h_e : out std_logic_vector(31 downto 0);
            mwr_base_addr_l_e : out std_logic_vector(31 downto 0);
            mwr_base_addr_h_e : out std_logic_vector(31 downto 0);
            test_reg_e : out std_logic_vector(31 downto 0);
            bar0_offset_e : out std_logic_vector(31 downto 0);
            dos_test_done_e : in std_logic;
            dos_test_result_e : in std_logic_vector(31 downto 0);
            dos_test_ovfs_e : in std_logic_vector(31 downto 0);
            ups_test_result_e : in std_logic_vector(31 downto 0);
            cpl_status_e : in std_logic_vector(31 downto 0);
            usr_access_e : in std_logic_vector(31 downto 0)
    );
end wbs_reg_wrap;
architecture rtl of wbs_reg_wrap is
begin
wbs_reg_inst : entity vhdlbaselib.wbs_reg
        generic map
        (
                ADL => ADL
        )
        port map
        (
                clk       => clk,
                rst       => rst,
                wbs_cyc   => wbs_cyc,
                wbs_stb   => wbs_stb,
                wbs_adr   => wbs_adr,
                wbs_we    => wbs_we,
                wbs_dat_i => wbs_dat_i,
                wbs_dat_o => wbs_dat_o,
                wbs_ack   => wbs_ack,
                wbs_err   => wbs_err,
    reg_i(224)          => dos_test_done_e,
    reg_i(256 downto 225)          => dos_test_result_e,
    reg_i(288 downto 257)          => dos_test_ovfs_e,
    reg_i(320 downto 289)          => ups_test_result_e,
    reg_i(352 downto 321)          => cpl_status_e,
    reg_i(384 downto 353)          => usr_access_e,
    reg_i(31 downto 0)          => (others => '0'),
    reg_i(63 downto 32)          => (others => '0'),
    reg_i(95 downto 64)          => (others => '0'),
    reg_i(127 downto 96)          => (others => '0'),
    reg_i(159 downto 128)          => (others => '0'),
    reg_i(191 downto 160)          => (others => '0'),
    reg_i(223 downto 192)          => (others => '0'),
    reg_o(0)          => sw_int_reset_e,
    reg_o(1)          => addr_space_e,
    reg_o(2)          => dma_dos_trig_e,
    reg_o(3)          => ups_en_e,
    reg_o(4)          => irq_test_trig_e,
    reg_o(36 downto 5)          => mrd_burst_e,
    reg_o(68 downto 37)          => mrd_base_addr_l_e,
    reg_o(100 downto 69)          => mrd_base_addr_h_e,
    reg_o(132 downto 101)          => mwr_base_addr_l_e,
    reg_o(164 downto 133)          => mwr_base_addr_h_e,
    reg_o(196 downto 165)          => test_reg_e,
    reg_o(228 downto 197)          => bar0_offset_e
);
end rtl;
