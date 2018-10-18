--------------------------------------------------------------------------------
-- Engineer: Sławomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: crc_gen.vhd
-- Language: VHDL
-- Description: 
-- AXIS wrapper dla generator crc
-- SLAVE - interfejs z danym do obliczenia CRC
-- MASTER - obliczone CRC
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Revision 0.02 22/01/16
-- Additional Comments: added m_last signal to indicate end of CRC
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library xil_defaultlib;

entity crc_gen is
  generic ( ADL		: time 	:= 500 ps;
			SLAVE_WIDTH     : natural := 8;
            MASTER_WIDTH    : natural := 16
		  );
  port (
  		clk  	: in std_logic;
  		rst  	: in std_logic;
  		s_data  : in std_logic_vector (SLAVE_WIDTH-1 downto 0);
        s_valid : in std_logic;
        s_last	: in std_logic;        
        s_ready : out std_logic;
        m_data  : out std_logic_vector (MASTER_WIDTH-1 downto 0);
		m_valid : out std_logic;
		m_last	: out std_logic;
        m_ready : in std_logic
       );
end crc_gen;
architecture crc_gen_arch of crc_gen is

type state_type is 	(
						IDLE_STATE,
						M_VALID_STATE,
						CLR_CRC_STATE						
					);
signal state	: state_type := IDLE_STATE;
signal rst_crc	: std_logic := '1';



begin


-- Instacjja rdzenia CRC
crc_gen_core_inst: entity work.crc_gen_core 
generic map ( ADL => ADL)
port map ( data_in => s_data,
		   crc_en  => s_valid,
		   rst     => rst_crc,
		   clk     => clk,
		   crc_out => m_data );
		   
---- Po pojawieniu sie sygnalu last oznaczjacego koniec
---- danych w nastpenym takcie trzeba wystawic m_valid
---- wysoko na jeden takt
--valid_proc: process(clk) begin
--if rising_edge(clk) then
--	if s_last = '1' then
--		m_valid		<= '1';
--	end if;
--end if;
--end process;


fsm_proc: process(clk) begin
if rising_edge(clk) then
	if rst = '1' then
		state	<= IDLE_STATE after ADL;
		s_ready	<= '0' after ADL;
		rst_crc	<= '1' after ADL;
		m_last	<= '0' after ADL;
	else
		case state is
		when IDLE_STATE =>
			rst_crc		<= '0' after ADL;
			s_ready		<= '1' after ADL;
			m_valid		<= '0' after ADL;
			if s_last = '1' then
				state		<= M_VALID_STATE after ADL;
				m_valid		<= '1' after ADL;
				s_ready		<= '0' after ADL;
			end if;
		
		when M_VALID_STATE =>
			if m_ready = '1' then
				state		<= CLR_CRC_STATE after ADL;
				m_valid		<= '0' after ADL;
				m_last		<= '1' after ADL;
			end if;
			
		when CLR_CRC_STATE =>
			rst_crc	<= '1' after ADL;
			state	<= IDLE_STATE after ADL;
			
		when others =>
		end case;
	end if;
end if;
end process;

end architecture crc_gen_arch; 



