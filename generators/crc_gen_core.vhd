-------------------------------------------------------------------------------
-- Copyright (C) 2009 OutputLogic.com
-- This source file may be used and distributed without restriction
-- provided that this copyright statement is not removed from the file
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
-- 
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
-------------------------------------------------------------------------------
-- CRC module for data(7:0)
--   lfsr(15:0)=1+x^11+x^15+x^16;
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library xil_defaultlib;

entity crc_gen_core is
		generic
		(
			ADL		: time 	:= 500 ps
		);
  port ( data_in : in std_logic_vector (7 downto 0);
    crc_en , rst, clk : in std_logic;
    crc_out : out std_logic_vector (15 downto 0));
end crc_gen_core;

architecture crc_gen_core_arch of crc_gen_core is
  signal lfsr_q: std_logic_vector (15 downto 0);
  signal lfsr_c: std_logic_vector (15 downto 0);
begin
    crc_out <= lfsr_q;

    lfsr_c(0) <= lfsr_q(8) xor lfsr_q(9) xor lfsr_q(10) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(14) xor data_in(0) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(6);
    lfsr_c(1) <= lfsr_q(9) xor lfsr_q(10) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(13) xor lfsr_q(15) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(7);
    lfsr_c(2) <= lfsr_q(10) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(13) xor lfsr_q(14) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(6);
    lfsr_c(3) <= lfsr_q(11) xor lfsr_q(12) xor lfsr_q(13) xor lfsr_q(14) xor lfsr_q(15) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
    lfsr_c(4) <= lfsr_q(12) xor lfsr_q(13) xor lfsr_q(14) xor lfsr_q(15) xor data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
    lfsr_c(5) <= lfsr_q(13) xor lfsr_q(14) xor lfsr_q(15) xor data_in(5) xor data_in(6) xor data_in(7);
    lfsr_c(6) <= lfsr_q(14) xor lfsr_q(15) xor data_in(6) xor data_in(7);
    lfsr_c(7) <= lfsr_q(15) xor data_in(7);
    lfsr_c(8) <= lfsr_q(0);
    lfsr_c(9) <= lfsr_q(1);
    lfsr_c(10) <= lfsr_q(2);
    lfsr_c(11) <= lfsr_q(3) xor lfsr_q(8) xor lfsr_q(9) xor lfsr_q(10) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(14) xor data_in(0) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(6);
    lfsr_c(12) <= lfsr_q(4) xor lfsr_q(9) xor lfsr_q(10) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(13) xor lfsr_q(15) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(7);
    lfsr_c(13) <= lfsr_q(5) xor lfsr_q(10) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(13) xor lfsr_q(14) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(6);
    lfsr_c(14) <= lfsr_q(6) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(13) xor lfsr_q(14) xor lfsr_q(15) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
    lfsr_c(15) <= lfsr_q(7) xor lfsr_q(8) xor lfsr_q(9) xor lfsr_q(10) xor lfsr_q(11) xor lfsr_q(13) xor lfsr_q(15) xor data_in(0) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(5) xor data_in(7);


    process (clk,rst) begin
      if (rst = '1') then
        lfsr_q <= b"1111111111111111" after ADL;
      elsif (clk'EVENT and clk = '1') then
        if (crc_en = '1') then
          lfsr_q <= lfsr_c after ADL;
        end if;
      end if;
    end process;
end architecture crc_gen_core_arch; 
