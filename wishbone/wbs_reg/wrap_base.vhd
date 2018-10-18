library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity wbs_reg_wrap is
        Generic ( 
                ADL : time := 0 ps                      
        );
    Port (
        clk                     : in std_logic;
        rst                     : in std_logic;
                wbs_cyc         : in std_logic;
                wbs_stb         : in std_logic;
                wbs_adr         : in std_logic_vector;
                wbs_we          : in std_logic;
                wbs_dat_i       : in std_logic_vector;
                wbs_dat_o       : out std_logic_vector;
                wbs_ack         : out std_logic;
                wbs_err         : out std_logic
--##
        
    );
end wbs_reg_wrap;
architecture rtl of wbs_reg_wrap is

begin
                
wbs_reg_inst : wbs_reg
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
--##            
                reg_o     => xxx,
                reg_i     => xxx
        );


end rtl;

