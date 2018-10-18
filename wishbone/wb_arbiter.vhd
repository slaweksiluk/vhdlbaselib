--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- 
-- Module Name: wb_arbiter.vhd
-- Language: VHDL
-- Description: 
-- Select between multpile slaves and one WB master interface. SLAVE 0 has the
--	highest priority
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--		WBM		WBM
--		 |		 |
--	+---------------+
--	+	 slave int	+
-- 	+	  ARBITER	+
--	+	master int	+
--	+----------------
--			 |
--			WBS

--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wb_arbiter is 
	Generic ( 
		ADL						: time 		:= 0 ps;
		DAT_WIDTH				: natural 	:= 8;
		ADR_WIDTH				: natural 	:= 32;
		SLAVES					: natural 	:= 2;
		USE_LOCK				: boolean	:= false;
		ASSERT_WHEN_BUSY		: string	:= "ERR"

	);
    Port (
    	clk		: in std_logic;
    	rst		: in std_logic;
    	
		-- Wishbone slaves interfaces
		wbs_adr   : in std_logic_vector(ADR_WIDTH*SLAVES-1 downto 0); 
		wbs_dat_i : in std_logic_vector(DAT_WIDTH*SLAVES-1 downto 0);
		wbs_dat_o : out std_logic_vector(DAT_WIDTH-1 downto 0);
		wbs_sel   : in std_logic_vector((DAT_WIDTH/8)*SLAVES-1 downto 0);
		wbs_cyc   : in std_logic_vector(SLAVES-1 downto 0);
		wbs_stb   : in std_logic_vector(SLAVES-1 downto 0);
		wbs_we    : in std_logic_vector(SLAVES-1 downto 0);
		wbs_ack   : out  std_logic_vector(SLAVES-1 downto 0);
		wbs_rty   : out  std_logic_vector(SLAVES-1 downto 0);
		wbs_err   : out  std_logic_vector(SLAVES-1 downto 0);
		wbs_stall : out  std_logic_vector(SLAVES-1 downto 0);  


		lock_req  : in std_logic_vector(SLAVES-1 downto 0);
		lock_status :out std_logic_vector(SLAVES-1 downto 0);	
		
		-- Wishbone master interface
		wbm_adr   : out std_logic_vector(ADR_WIDTH-1 downto 0);
		wbm_dat_i : in std_logic_vector(DAT_WIDTH-1 downto 0);
		wbm_dat_o : out std_logic_vector(DAT_WIDTH-1 downto 0);
		wbm_sel   : out std_logic_vector(DAT_WIDTH/8-1 downto 0);
		wbm_cyc   : out std_logic;
		wbm_stb   : out std_logic;
		wbm_we    : out std_logic;
		wbm_ack   : in  std_logic;
		wbm_stall : in  std_logic		
    );
end wb_arbiter;
architecture wb_arbiter_arch of wb_arbiter is

type state_t is 	(
						IDLE_STATE,
						WAITING,
						WB_CYC_STATE
					);
signal state	: state_t := IDLE_STATE;
			

signal wbs_busy_ack		: std_logic_vector(SLAVES-1 downto 0) := (others => '0');
signal wbs_busy_err		: std_logic_vector(SLAVES-1 downto 0);
signal wbs_busy_rty		: std_logic_vector(SLAVES-1 downto 0);
signal lock_req_i, lock_status_i		: std_logic_vector(SLAVES-1 downto 0):=(others => '0');

signal current_slave_nat		: natural range 0 to (2 ** SLAVES)-1 ; -- ?

signal current_slave: integer :=0;
signal waiting_cnt: integer :=0;
signal wbs_adr_i   : std_logic_vector(ADR_WIDTH*SLAVES-1 downto 0); 
signal wbs_dat_o_int : std_logic_vector(DAT_WIDTH-1 downto 0);	
begin
wbs_adr_i <= wbs_adr; 
lock_req_i <= lock_req;
lock_status <= lock_status_i;
wbs_dat_o <= wbs_dat_o_int;
-- Switch between busy ack: err or rty
err_ack_gen: IF ASSERT_WHEN_BUSY = "ERR" generate
	wbs_busy_err	<= wbs_busy_ack;	
	wbs_busy_rty	<= (others => '0');
end generate;
rty_ack_gen: IF ASSERT_WHEN_BUSY = "RTY" generate
	wbs_busy_err	<= (others => '0');	
	wbs_busy_rty	<= wbs_busy_ack;
end generate;
err_gen: IF ASSERT_WHEN_BUSY /= "ERR" and ASSERT_WHEN_BUSY /= "RTY" generate
	assert false 
	  report " [wb_arbiter.vhd]   Wrong ASSERT_WHEN_BUSY genric string. Sholud be RTY or ERR"
	  severity failure;
end generate;
	


fsm_proc: process(clk) 
variable busy :std_logic := '0';
begin
if rising_edge(clk) then
	if rst = '1' then
		state	<= IDLE_STATE;
		wbm_stb		<= '0';
		wbm_cyc		<= '0';
		wbs_busy_ack <= (others => '0');
		lock_status_i<= (others => '0');
	else
	   wbs_busy_ack <= (others => '0');
	   --wbm_dat_o	<= (others => '0');

	   wbm_cyc <= '0';
	   wbm_stb		<= '0';
	   lock_status_i<= (others => '0');
		case state is
		when IDLE_STATE =>
		
			if USE_LOCK then
			---------------------------------
				busy := '0';
				--lock_status_i<= (others => '0');
				--lock_status_i<= (others => '0');
				if lock_req_i /= std_logic_vector(to_unsigned(0, SLAVES)) then
				--else
					for indx in 0 to SLAVES-1 loop
						if lock_req_i(indx) = '1' and busy = '0' and wbs_cyc(indx) = '0' and wbs_stb(indx) = '0' then
							busy := '1';
							lock_status_i(indx)<= '1';
							current_slave_nat <= indx;
							state <= WAITING;
							waiting_cnt <= 5;
						end if;
					end loop;
				end if;
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^		
			else
				busy := '0';
				for S in 0 to SLAVES-1 loop
					if wbs_cyc(S) = '1' and wbs_stb(S) = '1' then
						 if busy = '0' then
							  wbm_cyc <= '1';
							  wbm_stb		<= '1';
							  --wbm_dat_o	<= wbs_dat_i((S+1)*DAT_WIDTH-1 downto S*DAT_WIDTH);
									current_slave_nat <= S;
									--current_slave <= S+50;
									state	<= WB_CYC_STATE;
									busy := '1';

							  else
									wbs_busy_ack(S) <= '1';
							  end if;
					end if;
				end loop;			
			end if;
		when WAITING =>	 -- waiting for wb_cyc
		-----------------------------------------------------------------------
			lock_status_i(current_slave_nat)<= '1';
			if waiting_cnt >0 and lock_req_i(current_slave_nat) = '1' then
				waiting_cnt <= waiting_cnt -1;
				if wbs_cyc(current_slave_nat) = '1' then
					wbm_cyc <= wbs_cyc(current_slave_nat);
					wbm_stb <= wbs_stb(current_slave_nat);
					state	<= WB_CYC_STATE;
					
				end if;
			else
				state <= IDLE_STATE;
				--lock_status_i(current_slave_nat)<= '0';
			end if;
		--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^	
		when WB_CYC_STATE =>
			if USE_LOCK then
			------------------------------------------------------------------------
				if lock_req_i(current_slave_nat) = '1' then
					wbm_cyc <= wbs_cyc(current_slave_nat);
					wbm_stb <= wbs_stb(current_slave_nat);
					lock_status_i(current_slave_nat)<= '1';	
				else
					state <= IDLE_STATE;
					lock_status_i(current_slave_nat)<= '0';
					report " <<< lock_status_i(current_slave_nat)<= '0';";
				end if;
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^	
			
			else

				wbm_cyc <= '1';
				wbm_stb        <= '0';
				--wbm_dat_o	<= wbs_dat_i((current_slave_nat+1)*DAT_WIDTH-1 downto current_slave_nat*DAT_WIDTH);  
				--wbs_ack <= ack_i;
				if wbs_cyc(current_slave_nat) = '0' and wbs_stb(current_slave_nat) = '0' then
				   state <= IDLE_STATE;
					wbm_cyc <= '0';
					
										 --exit when true;
				end if;	
				--wbs_busy_ack(S) <= wbm_ack;
				
				for S in 0 to SLAVES-1 loop
				    if S/= current_slave_nat and wbs_cyc(S) = '1' and wbs_stb(S) = '1' then
				        wbs_busy_ack(S) <= '1';
				   end if;
				end loop;
				--current_slave <= current_slave +50;		
			end if;
		when others =>
		end case;
	end if;
end if;
end process;				


conn_proc: process(clk) begin
if rising_edge(clk) then
-- Master
	wbm_adr		<= wbs_adr((current_slave_nat+1)*ADR_WIDTH-1 downto current_slave_nat*ADR_WIDTH);
--	wbm_dat_o	<= wbs_dat_i((current_slave_nat+1)*DAT_WIDTH-1 downto current_slave_nat*DAT_WIDTH);
	wbm_sel		<= wbs_sel((current_slave_nat+1)*(DAT_WIDTH/8)-1 downto current_slave_nat*(DAT_WIDTH/8));
	--wbm_cyc	<= wbs_cyc(current_slave_nat);
	--wbm_stb		<= wbs_stb(current_slave_nat);
	wbm_we		<= wbs_we(current_slave_nat);
-- Slave
	wbm_dat_o	<= wbs_dat_i((current_slave_nat+1)*DAT_WIDTH-1 downto current_slave_nat*DAT_WIDTH); 
	
    wbs_ack     <= (others => '0');
    wbs_err     <= (others => '0');
    wbs_rty     <= (others => '0');
    wbs_stall   <= (others => '0');
    
	wbs_dat_o <= wbm_dat_i;
	wbs_ack(current_slave_nat)	<= wbm_ack;
	wbs_err							<= wbs_busy_err;
	wbs_rty							<= wbs_busy_rty;
	wbs_stall(current_slave_nat)	<= wbm_stall;
end if;
end process;
	



end wb_arbiter_arch;
