----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name: tb_procedures - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package tb_procedures_pkg is
--  Stale do testow
	constant CPL_FMT_TYPE	: std_logic_vector(6 downto 0) := "0001010";
  	constant CPLD_FMT_TYPE	: std_logic_vector(6 downto 0) := "1001010";
  	constant MRD32_FMT_TYPE   : std_logic_vector(6 downto 0) := "0000000";
	
	constant BAR_ADDR : std_logic_vector(31 downto 8) := x"f45000";
 	
	constant SOF_RIGHT	: std_logic_vector(21 downto 0) := "01" & x"e4000";
	constant SOF_MID	: std_logic_vector(21 downto 0) := "01" & x"e4000";
	
	constant tied_to_gnd	: std_logic_vector(16 downto  0) := (others  => '0');
	constant EOF_RIGHT		: std_logic_vector(21 downto 0) := "10011" & tied_to_gnd;
	constant EOF_MID_RIGHT	: std_logic_vector(21 downto 0) := "10111" & tied_to_gnd;
--  	constant EOF_MID_LEFT	: std_logic_vector(21 downto 17) := "11" & x"60000";
  	constant EOF_MID_LEFT	: std_logic_vector(21 downto 0) := "11011" & tied_to_gnd;
  	constant EOF_LEFT		: std_logic_vector(21 downto 0) := "11111" & tied_to_gnd;
  	
  	constant NOFP			: std_logic_vector(21 downto 0) := "01" & x"e0000";
  	constant CONF_FRAME		: std_logic_vector(21 downto 0) := "11" & x"e4004";
  	constant MRD_CONF_FRAME	: std_logic_vector(21 downto 0) := "10" & x"e4004";

--  Identyfiaktory
  	constant EP_ID			: std_logic_vector(15 downto 0) := x"ee1d";
  	constant RP_ID			: std_logic_vector(15 downto 0) := x"0000";


--  Dane do tworzenia pakietow TLP
type DATA_ARRAY		is array (499 downto 0) of std_logic_vector(31 downto 0);
shared variable DATA_STORE	: DATA_ARRAY;

procedure PROC_TX_SYNCHRONIZE (
  first : in INTEGER;
  active : in INTEGER;
  last_call: in INTEGER;
  signal trn_lnk_up_n : in std_logic;
  signal trn_tdst_rdy_n : in std_logic;
  signal trn_clk : in std_logic

);

procedure PROC_TX_CPLD (
  tag                      : in std_logic_vector (7 downto 0);
  len                      : in std_logic_vector (9 downto 0);
  byte_count               : in std_logic_vector (11 downto 0);
  lower_addr               : in std_logic_vector (7 downto 0);
  comp_status              : in std_logic_vector (2 downto 0);
  signal trn_td_c          : out std_logic_vector(127 downto 0);
  signal trn_tuser         : out std_logic_vector(21 downto 0);
  signal trn_tvalid   	   : out std_logic;
  signal trn_lnk_up_n	   : in std_logic;
  signal trn_tdst_rdy_n	   : in std_logic;
  signal trn_clk 		   : in std_logic
);

procedure PROC_TX_MRD32 (
  tag                      : in std_logic_vector (7 downto 0);
  addr	 	               : in std_logic_vector (31 downto 0);
  signal trn_td_c          : out std_logic_vector(127 downto 0);
  signal trn_tuser         : out std_logic_vector(21 downto 0);
  signal trn_tvalid   	   : out std_logic;
  signal trn_tlast   	   : out std_logic;
  signal trn_tkeep   	   : out std_logic_vector(15 downto 0);
  signal trn_lnk_up_n	   : in std_logic;
  signal trn_tdst_rdy_n	   : in std_logic;
  signal trn_clk 		   : in std_logic
);

procedure PROC_GEN_PULSE(
		signal clk	: in std_logic;
		DEL : in time;
		signal sig : out std_logic
	);



end package tb_procedures_pkg;



-- Package Body

package body tb_procedures_pkg is


--************************************************************
--    Proc : PROC_TX_SYNCHRONIZE
--    Inputs : first_, last_call_
--    Outputs : None
--    Description : Synchronize with tx clock and handshake signals
--*************************************************************/

procedure PROC_TX_SYNCHRONIZE (

  first : in INTEGER;
  active : in INTEGER;
  last_call: in INTEGER;
  signal trn_lnk_up_n : in std_logic;
  signal trn_tdst_rdy_n : in std_logic;
  signal trn_clk : in std_logic

) is

  variable last  : INTEGER;

begin

  assert (trn_lnk_up_n = '0')
    report "TX Trn interface is MIA"
    severity failure;

  wait until (trn_clk'event and trn_clk = '1');

  if ((trn_tdst_rdy_n = '1') and (first = 1)) then

    while (trn_tdst_rdy_n = '1') loop

      wait until (trn_clk'event and trn_clk = '1');

    end loop;

  end if;

  if (active = 1) then

--   PROC_READ_DATA(first, last, trn_td_c, trn_trem_n_c);

  end if;

  if (last_call = 1) then

--    PROC_PARSE_FRAME;

  end if;

end PROC_TX_SYNCHRONIZE;




--************************************************************
--  Proc : PROC_TX_COMPLETION_DATA_
--  Inputs : Tag, Tc, Length, Completion Status
--  Outputs : Transaction Tx Interface Signaling
--  Description : Generates a Completion with Data TLP
--*************************************************************/

procedure PROC_TX_CPLD (

  tag                      : in std_logic_vector (7 downto 0);
  len                      : in std_logic_vector (9 downto 0);
  byte_count               : in std_logic_vector (11 downto 0);
  lower_addr               : in std_logic_vector (7 downto 0);
  comp_status              : in std_logic_vector (2 downto 0);
  signal trn_td_c          : out std_logic_vector(127 downto 0);
  signal trn_tuser         : out std_logic_vector(21 downto 0);
  signal trn_tvalid   	   : out std_logic;
  signal trn_lnk_up_n	   : in std_logic;
  signal trn_tdst_rdy_n	   : in std_logic;
  signal trn_clk 		   : in std_logic

) is

  variable length : std_logic_vector(9 downto 0);
  variable i : INTEGER;
  variable index : INTEGER;
  variable rest : INTEGER;
  variable int_length : INTEGER;
  variable unsigned_length : unsigned(9 downto 0);

begin
    length := len;

  PROC_TX_SYNCHRONIZE(0, 0, 0, trn_lnk_up_n, trn_tdst_rdy_n, trn_clk);

  trn_td_c	<=	DATA_STORE(0) & 
				EP_ID & 		-- req_id
				tag &			-- tag 
				lower_addr & 	-- lower addr
				--  64bity
				RP_ID &			-- comp id
				comp_status &	--  status
				'0' &			--  bcm
				byte_count &	--  byte count
				--  32 bity
				'0' & 			-- R
				CPLD_FMT_TYPE &
				x"88" & 		-- R,TC,R,Att,R,TH 	
				"000000" &		-- TD,EP,Att,AT
				len; 			-- Length 	
				--  32bity		

  trn_tuser 	<= SOF_RIGHT;
  trn_tvalid	<= '1';

  if (length /= "0000000001") then
    PROC_TX_SYNCHRONIZE(1, 1, 0, trn_lnk_up_n, trn_tdst_rdy_n, trn_clk);

    unsigned_length := unsigned(length);
    int_length := to_integer( unsigned_length);
    i := int_length -1;
    index := 0;
    
    while i /= 0 loop                         
		rest := i mod 4;

--  Ostatni
	if i/4 = 0 then
		i := 0;
		case rest is
		when 0 =>
			trn_td_c	<= DATA_STORE(index+4) &
                           DATA_STORE(index+3) &
                           DATA_STORE(index+2) &
                           DATA_STORE(index+1);
			trn_tuser 	<= EOF_LEFT;
		when 3 =>
			trn_td_c	<= x"704fa11d" &
                           DATA_STORE(index+3) &
                           DATA_STORE(index+2) &
                           DATA_STORE(index+1);		
			trn_tuser 	<= EOF_MID_LEFT;
		when 2 =>
			trn_td_c	<= x"704fa11d" &
                           x"704fa11d" &
                           DATA_STORE(index+2) &
                           DATA_STORE(index+1);				
			trn_tuser 	<= EOF_MID_RIGHT;
		when 1 =>
			trn_td_c	<= x"704fa11d" &
                           x"704fa11d" &
                           x"704fa11d" &
                           DATA_STORE(index+1);			
			trn_tuser 	<= EOF_RIGHT;
		end case;

--  Srodek pakietu
	else
		i := rest;
		trn_tuser 	<= NOFP;
		trn_td_c	<= DATA_STORE(index+4) &
					   DATA_STORE(index+3) &
					   DATA_STORE(index+2) &
					   DATA_STORE(index+1);
	end if;
		index := index + 4;
		PROC_TX_SYNCHRONIZE(0, 1, 0, trn_lnk_up_n, trn_tdst_rdy_n, trn_clk);

	end loop;

--  Length = 1
  else
    PROC_TX_SYNCHRONIZE(1, 1, 1, trn_lnk_up_n, trn_tdst_rdy_n, trn_clk);
  end if;
  
  trn_tvalid	<= '0';	
  trn_tuser 	<= NOFP;
end PROC_TX_CPLD;





--************************************************************
--  Proc : PROC_TX_MRD32
--  Description : Generates one MRD32 TLP used to read conf regs
--*************************************************************/

procedure PROC_TX_MRD32 (
  tag                      : in std_logic_vector (7 downto 0);
  addr	 	               : in std_logic_vector (31 downto 0);
  signal trn_td_c          : out std_logic_vector(127 downto 0);
  signal trn_tuser         : out std_logic_vector(21 downto 0);
  signal trn_tvalid   	   : out std_logic;
  signal trn_tlast   	   : out std_logic;
  signal trn_tkeep   	   : out std_logic_vector(15 downto 0);
  signal trn_lnk_up_n	   : in std_logic;
  signal trn_tdst_rdy_n	   : in std_logic;
  signal trn_clk 		   : in std_logic
) is
begin
  PROC_TX_SYNCHRONIZE(0, 0, 0, trn_lnk_up_n, trn_tdst_rdy_n, trn_clk);
  trn_td_c	<=	x"66666666" &
				addr & 	-- lower addr
			--  64 bity
				RP_ID &			-- req id
				tag &			-- tag
				x"0f" &			-- be
			--  32 bity
				'0' & 			-- R
				MRD32_FMT_TYPE &
				x"88" & 		-- R,TC,R,Att,R,TH 	
				"000000" &		-- TD,EP,Att,AT
				"0000000001"; 			-- Length 	
			--  32bity		

  trn_tuser 	<= MRD_CONF_FRAME;
  trn_tvalid	<= '1';
  trn_tlast		<= '1';
  trn_tkeep		<= x"0fff";
  
  
  PROC_TX_SYNCHRONIZE(0, 0, 0, trn_lnk_up_n, trn_tdst_rdy_n, trn_clk);
  trn_tuser 	<= NOFP;
  trn_tvalid	<= '0';
  trn_tlast		<= '0';
  trn_tkeep		<= x"0000";
end PROC_TX_MRD32;

--********************************************************************
--  Proc: PROC_GEN_PULSE
--  Desc: generates one high signal pulse synch to input clk
--   delayed for DELAY from clk edges
--********************************************************************
procedure PROC_GEN_PULSE(
		signal clk	: in std_logic;
		DEL : in time;
		signal sig : out std_logic
	) is
begin 
		wait until rising_edge(clk);
	sig	<= '1' after DEL;
		wait until rising_edge(clk);
	sig	<= '0' after DEL;
	
end PROC_GEN_PULSE;


end package body tb_procedures_pkg;
