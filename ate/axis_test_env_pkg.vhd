--------------------------------------------------------------------------------
-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
--
-- Module Name: axis_test_env_pkg.vhd
-- Language: VHDL
-- Description:
-- 	Generic mpodule for testing entities with AXI Stream like interface.
-- TEST STORE is just long std_logic_vector eg 1000 elements. User is filling
-- it with custom DATA_PATTER widt customizable WORD_WIDTH. THERE is indpendent
--	s_valid and m_ready are driven by output bit of PRNG thanks to it random
--	changes of tohe falgs are tested.
--
-- store width for
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Revision 0.02 - Multi-master with common data store; better logging
--
-- TO DO LIST:
--	DONE* multi-master (DONE)
--	DONE* consider test ID auto increment option
--		* Reconsider the way that test are numearated again -- curenlty it seems it's
--			only usefull for navigatin in ate master log file.
--		* use clock_period as value for TIMEOUT error insetad of fixed time
--		* multi-slave
--	DONE* multi-master with independent data stores
--		* data store in file option for long tests
--	DONE* add optional LAST signal stim proc for slave
--	DONE* s_keep stim
--		* PRNG keep store fill procedure
--	DONE* Optional LAST verif for master
--		* Add MASTER MODE flag and chekc it to prevent error when despite some
--			master is listening only, it drives m_ready (instantianted M_READY_STIM_PROC)
--			by mistake
--	DONE* Check if it's allowed or needed to deassert s_valid EVEN readt was not
--			asserted. In the other words for the time being s_valid can be asserted
--			ant after some time deasserted, but during this time ready was not
--			asserted any time! This look like valid data being 'disappered'...
--			I can imgaine it's somtimes possible, but it's rather very rare, and
--			should be added as a option
--	DONE* It is good to have constannts as input of ATE_WATCHDOG? Will
--			it work when slave interface singal will change? Need to verif...
--			Verified when developing wb_test_env_pkg. It good to use input cons
--			when "wait until ..." constructs are not used. ATE_WATCHDOG
--			is triggered every time its input constant changaes - so it's
--			completly fine to use it that way
--		* Consider adding to ATE_CFG.MASTER_QUIT_TEST or ATE_WATCHDOG
--			option for detect changes on AXIS bus when when currently not any
--			test is being performed (possble data lost/coruption)
--		* Better way of changing internal lfsr_state. Currently lfsr state is
--			the same after 32 shiftss
--	DONE / PROCESSING	* Inteligent accounting on keep at master side. For example master had
--			received (where U is keep 0) 0xUU0100, 0x0302UU. It sholud be possible
--			to set the store only to 0x03020100 without using '-' dont cares
--			to fill the pleces where expected keep will be '0'. This sholud be
--			additional mode: m_store_keep_mode = DONT_CARE_FOR_KEEP_LOW,
--			IGNORE_DATA_FOR_KEEP_LOW
--	STATUS	Implemented counter pattern mode in master which is working good.
--		 	Need to implement the proper calculation of test length (number of
--			keepded data words, not number of words in general)
--		* When default m_ready is set '1' (it colud be necessary when master
--			interface is shared between ATE and some other entities) it colud
--			happen that there will be some valid transaction ommited by ATE_M_VERIF
--			To prevent it i'm adding flag in ATE_WAIT_ON_TRIG which will tell
--			to ATE_M_WATCHDOG that ATE_M_VERIF is waiting for another triggger
--			hence there sholud not be any transactions on the master interface.
--			Described solution is not so great becasue it will asserting errors
--			when there are transactions expected by user add master interface.
--			It seems there is no simple solution to prevent such a problem
--			when m ready def val is '1'. Fortunatelty such a behaviour is only
--			possible when m ready def val is '1'.
--			Maybe some workaroun wolud be to set m ready '1' only when need to
--			perform some beyond ATE transaction.
--		* Need to think about some protection against wrong triggering by user.
--			Such a problem appeared in tx_axi_packet_tb.vhd where it casued doubling
--			the data word which is ATE bug. It's taking long time to detemine
--			the source of problems like that. Possible implementation colud
--			be based on the some variable/array with enums BEFORE_TRIGGER,
--			IN_PROGRESS, DONE. On the basis of it it will be easy to detemine
--			if it's valid to start another test. It would be also good to
--			make every test counter independet for both master and slaves.
--			This is in genernal good idea to change the trigerring scheme. From
--			signals-event driven to some enum type with state eg:
--			ATE_STATE_IDLE_STATE
--			ATE_CONFIGURED_STATE
--			ATE_STATE_RUNNING_STATE
--			ATE_TEST_DONE_STATE
--			Partially implement as ATE_STATE_IDLE and ATE_STATE_RUN
--		* Print to log file current non-default ATE_CFG settings
--		* Always inform user when keep is tied to GND during transactions. Even
--			when keep is  not used in theory it has to be set to '1'
--		* Add record interface to procedures
--		* Add sompe protection against generating data by UUT mastger interface
--			after test is finished. Now the m_valid signal state is checkec only
--			one cyhcle after finished  test - it's not enough. The additinal
--			checker colud be placed in ATE_MASTER_WATCHDOG() proc. For example
--			it colud report all occurnces of test data in ATE_STATE_IDLE and
--			optionally stop the test with failure status

-- 15/06/16 Revision 0.03 - added s_valid USER_VECTOR stim
-- 15/06/17 Revision 0.05 - added s_valid USER_VECTOR stim
-- 29/06/16 Revision 0.06 - s_valid stimulus is now in ATE_S_STIM
-- 30/06/16 Revision 0.07 - m_last optional verif added
-- 14/06/16	Revision 0.08 - s_last store stim added and tested
-- 18/07/16	Revision 0.09 - Added new FULL_PRNG mode for s_valid which is old
--	old behaviour. Default is PRNG mode where s_valid is never deasserted witohout
--	any s_ready deassertion - there is no dissapperaing data.
-- 13/09/16 Revision 0.10 - Added ATE_WATCHDOG without slave interface.
--	Also added varable for disabling master store verification.
-- 28/10/16 Revision 0.11 - separated trigers for master and slave and in general
--	improved trigerring scheme
--	Also added TEST ID AUTO INCREMENT as default option for master only
-- 22/25/17 Revision 0.12 - Added simple state (shared variables) based control

--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;
--use ieee.std_logic_misc.std_match;

library std;
use std.textio.all;

library vhdlbaselib;
use vhdlbaselib.common_pkg.all;
use vhdlbaselib.txt_util.all;
use vhdlbaselib.axis_pkg.all;



package axis_test_env_pkg is

-- Interfaces type
	type interface_t is (MASTER_E, SLAVE_E, BOTH_E);

-- Number of possible instances of master ate
	constant ATE_MAX_INST				: natural := 6;
	shared variable SLAVES_ACTIVE_NUM	: natural := 1;
	shared variable MASTERS_ACTIVE_NUM	: natural := 1;

	subtype inst_t is positive range 1 to ATE_MAX_INST;

-- Type for keeping stop stim flag
	type master_inst_t is array (1 to ATE_MAX_INST) of boolean;
	shared variable stop_m_ready_stim	: master_inst_t := (others => true);


-- LFSR types
	constant LFSR_WIDTH						: natural := 32;
	constant LFSR_STATES_NUM				: natural := 2;
	type lfsr_state_t is array (1 to LFSR_STATES_NUM) of std_logic_vector(LFSR_WIDTH-1 downto 0);
	shared variable lfsr_state				: lfsr_state_t := (x"0f0f0f0f", x"f0f0f0f0");
	constant SLAVE_LFSR_ID	: natural := 1;
	constant MASTER_LFSR_ID	: natural := 2;

-- Stores
	constant STORE_WIDTH				: natural := 1024*1024;
	constant SLAVE_STORE_WIDTH			: natural := STORE_WIDTH;
	shared variable slave_store			: std_logic_vector(SLAVE_STORE_WIDTH-1 downto 0);
	constant SLAVE_KEEP_STORE_WIDTH		: natural := SLAVE_STORE_WIDTH / 8;
	shared variable slave_keep_store	: std_logic_vector(SLAVE_KEEP_STORE_WIDTH-1 downto 0) := (others => '1');
	shared variable slave_last_store	: std_logic_vector(SLAVE_STORE_WIDTH-1 downto 0) := (others => '0');

	constant MASTER_STORE_WIDTH			: natural := STORE_WIDTH;
	type store_t is array (1 to ATE_MAX_INST) of std_logic_vector(MASTER_STORE_WIDTH-1 downto 0);
	shared variable master_store 		: store_t;
	shared variable master_last_store 	: std_logic_vector(MASTER_STORE_WIDTH-1 downto 0)  := (others => '0');

-- Temporary constatn with default index of store - if its not in arg yet
	constant TEMP_DEF_MASTER_STORE_ID	: natural := 1;


-- vec containg stimulus defined by user
	constant M_READY_USR_VEC_WIDTH	: natural := 1024;
	shared variable m_ready_usr_vec : std_logic_vector(0 to M_READY_USR_VEC_WIDTH-1) := (others => '1');
	constant S_VALID_USR_VEC_WIDTH	: natural := 1024;
	shared variable s_valid_usr_vec	: std_logic_vector(0 to S_VALID_USR_VEC_WIDTH-1) := (others => '1');


-- This types are dediceted to choose type of stimulus used in procedures
	type stim_mode_t is (TIED_TO_VCC, PRNG, USER_VECTOR, FULL_PRNG);
	type s_last_stim_mode_t is (LAST_STORE, TEST_END);
--m_store_keep_mode = DONT_CARE_FOR_KEEP_LOW, IGNORE_DATA_FOR_KEEP_LO
--	type store_keep_mode is (DONT_CARE_AT_KEEP_LOW, IGNORE_DATA_AT_KEEP_LOW);

---- trigers for TB
--	type trig_mode_t is (COMMON, SEPARATE, COMMON_INST, SEPARATE_INST);
--	signal ATE_TRIG				: boolean := false;
--	signal ATE_TRIG_MASTER		: boolean := false;
--	signal ATE_TRIG_MASTER1		: boolean := false;
--	signal ATE_TRIG_MASTER2		: boolean := false;
--	signal ATE_TRIG_SLAVE		: boolean := false;

--
-- New ATE control
--
	type ate_state_enum_t is (
		ATE_STATE_IDLE,
--		ATE_STATE_READY,
		ATE_STATE_RUN);
	type ate_state_t is array(1 to ATE_MAX_INST) of ate_state_enum_t;
	shared variable ATE_M_STATE			: ate_state_t := (others => ATE_STATE_IDLE);
	shared variable ATE_S_STATE			: ate_state_t := (others => ATE_STATE_IDLE);
	constant ATE_STATE_SYNC_INTERVAL	: time := 1 ns;

--
-- There are diffrent possbile sources of simulation data
--
	type ate_data_source_t is (
		STORE_DATA_SOURCE,
		CNT_PAT_DATA_SOURCE,
		FILE_DATA_SOURCE,
		NULL_DATA_SOURCE
	);

-- Beyond the triggers there is ACTIVE flag which is by default TRUE,
-- but can be set FALSE to disable specific instance of master verif
--	type active_t is array (1 to ATE_MAX_INST) of boolean;
--	shared variable MASTER_ACTIVE	: active_t := (others => true);

-- Test ID for logging to file
	shared variable ATE_M_TEST_ID 		: natural := 1;

	constant LOG_MAX_BIT_WIDTH			: natural := 32;

-- Its needed to incrmenet  test id only once in the last ATE_M_VERIF. Hence
-- need to track the biggest inst id of ATE_M_VERIF. I assume thats the last
-- master in the pipeline, hence it sholudi incremnt test id
	shared variable ATE_LAST_MASTER_INST	: natural := 0;

-- String with label cannot be unconstrained
	constant LABEL_WIDTH	: natural := 16;


-- Record with all configuration variables for user
	type common_cfg_t is record
		VERBOSE						: boolean;
		INTEGRITY_SEVERITY_LEV		: severity_level;
		CHECK_FOR_X_STATES 			: boolean;
		CHECK_KEEP0_VALID1 			: boolean;
		MAGIC_NUM					: natural;
		TEST_ID_AUTO_INC			: boolean;
	end record;

	type master_cfg_t is record
		M_READY_STIM_MODE			: stim_mode_t;
		MASTER_TEST_LEN				: positive;
		MASTER_STORE_LEN			: positive;
		MASTER_TIMEOUT 				: time;
		MASTER_QUIT_TEST			: boolean;
	 	MASTER_QUIT_TEST_SEV		: severity_level;
		MASTER_DATA_SOURCE			: ate_data_source_t;
		M_READY_DEF_VAL				: std_logic;
		VERIF_MASTER_LAST			: boolean;
		USE_MASTER_KEEP				: boolean;
		MASTER_SLICE_WIDTH			: positive;
		CURRENT_TEST				: positive;
		CURRENT_TRANSACTION			: natural;
		INSTANCE_LABEL				: string(1 to LABEL_WIDTH);
	end record;
	type master_cfg_arr_t is array (1 to ATE_MAX_INST) of master_cfg_t;

	type slave_cfg_t is record
		S_VALID_STIM_MODE			: stim_mode_t;
		S_LAST_STIM_MODE			: s_last_stim_mode_t;
		SLAVE_TEST_LEN				: positive;
		SLAVE_STORE_LEN				: positive;
		SLAVE_DATA_SOURCE			: ate_data_source_t;
		S_KEEP_DEF_VAL				: std_logic;
		VERIF_S_VALID_INTEGRITY 	: boolean;
		USE_SLAVE_KEEP				: boolean;
		CURRENT_TEST				: positive;
		CURRENT_TRANSACTION			: natural;
		INSTANCE_LABEL				: string(1 to LABEL_WIDTH);
	end record;
	type slave_cfg_arr_t is array (1 to ATE_MAX_INST) of slave_cfg_t;

-- Default configuration of varaibles
	constant ATE_COMMON_CFG_DEF 	: common_cfg_t :=
		(
			VERBOSE					=> false,
			INTEGRITY_SEVERITY_LEV	=> failure,
-- Check for X states after reset
			CHECK_FOR_X_STATES		=> true,
			CHECK_KEEP0_VALID1		=> true,
			TEST_ID_AUTO_INC		=> true,
			MAGIC_NUM				=> 16#77ccbb00#
		);

	constant ATE_MASTER_CFG_DEF 	: master_cfg_t :=
		(
			M_READY_STIM_MODE 		=> TIED_TO_VCC,
			MASTER_TEST_LEN			=> 4,
			MASTER_STORE_LEN		=> 4,
			MASTER_TIMEOUT			=> 1000 ns,
			MASTER_QUIT_TEST		=> true,
			MASTER_QUIT_TEST_SEV	=> failure,
			MASTER_DATA_SOURCE		=> STORE_DATA_SOURCE,
			M_READY_DEF_VAL			=> '0',
			VERIF_MASTER_LAST		=> false,
			USE_MASTER_KEEP			=> false,
			MASTER_SLICE_WIDTH		=> 8,
			CURRENT_TEST			=> 1,
			CURRENT_TRANSACTION		=> 0,
			INSTANCE_LABEL			=> "MASTER INSTANCE "
		);

	constant ATE_SLAVE_CFG_DEF 	: slave_cfg_t :=
		(
			S_VALID_STIM_MODE 		=> TIED_TO_VCC,
			S_LAST_STIM_MODE		=> TEST_END,
			SLAVE_TEST_LEN			=> 4,
			SLAVE_STORE_LEN			=> 4,
			SLAVE_DATA_SOURCE		=> STORE_DATA_SOURCE,
			S_KEEP_DEF_VAL			=> '0',
			VERIF_S_VALID_INTEGRITY	=> true,
			USE_SLAVE_KEEP			=> false,
			CURRENT_TEST			=> 1,
			CURRENT_TRANSACTION		=> 0,
			INSTANCE_LABEL			=> "SLAVE  INSTANCE "
		);

-- record to bu used in TB
	shared variable ATE_COMMON_CFG : common_cfg_t := ATE_COMMON_CFG_DEF;
	shared variable ATE_SLAVE_CFG : slave_cfg_arr_t := (others => ATE_SLAVE_CFG_DEF);
	shared variable ATE_MASTER_CFG : master_cfg_arr_t := (others => ATE_MASTER_CFG_DEF);


-- variables for storing state of ATE_WATCHDOG. Needed becasue it impossible
-- to retain internal variables states in procedures. Using internal
--- while ture loop is not a good solution
	constant MAX_DATA_WIDTH				: natural := 128;
	shared variable wg_check_flag		: boolean := false;
	shared variable wg_data_v			: std_logic_vector(MAX_DATA_WIDTH-1 downto 0);
	shared variable wg_valid_ready_wait : boolean;

-- Make some subtypes for knowd data widths
	subtype data_t	is std_logic_vector(MAX_DATA_WIDTH-1 downto 0);

-- record with identifiers useed internally to pass data for e.g printing to screen
	type id_t is record
		inter	: interface_t;
		inst	: inst_t;
		test	: positive;
		trans	: natural;
	end record;


-- Record with unconstrained arrays are supported since VHDL 2008 :(
-- Record type for AXIS interface both M and S
--	type axi_st_t is record
--		data	: std_logic_vector;
--		valid	: std_logic;
--		ready	: std_logic;
--		last	: std_logic;
--		keep	: std_logic_vector;
--	end record;

-------------------------------------------------------------------------------
--  SLAVE  --------------------------------------------------------------------
-------------------------------------------------------------------------------
procedure ATE_S_STIM(
	--constant LOWER_VALID	: boolean;
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal s_data		: out std_logic_vector;
	signal s_keep		: out std_logic_vector;
	signal s_valid		: out std_logic;
	signal s_last		: out std_logic;
	signal s_ready		: in std_logic;
	inst_id				: inst_t
);
procedure ATE_S_STIM(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal s			: inout axi_st;
	inst_id				: inst_t
);
procedure FILL_S_VALID_USR_VEC(
	INDEX	: natural;
	DATA	: std_logic
);
procedure FILL_SLAVE_KEEP_STORE(
	INDEX	: natural;
	DATA	: std_logic_vector
);
procedure FILL_SLAVE_LAST_STORE(
	NUMBER	: natural;
	OFFSET  : natural
);
procedure RESET_SLAVE_LAST_STORE;
procedure ATE_S_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal s_data		: in std_logic_vector;
	signal s_keep		: in std_logic_vector;
	signal s_valid		: in std_logic;
	signal s_ready		: in std_logic;
	inst_id		: natural );
procedure ATE_S_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal s	: in axi_st;
	inst_id		: natural
);

-------------------------------------------------------------------------------
--  MASTER  -------------------------------------------------------------------
-------------------------------------------------------------------------------

procedure ATE_M_VERIF(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m_data		: in std_logic_vector;
	signal m_keep		: in std_logic_vector;
	signal m_valid		: in std_logic;
	signal m_last		: in std_logic;
	signal m_ready		: in std_logic;
	inst_id				: natural
);
procedure ATE_M_VERIF(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m			: in axi_st;
	inst_id				: natural
);
procedure M_READY_STIM_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m_valid		: in std_logic;
	signal m_ready		: out std_logic;
	inst_id				: natural
);
procedure M_READY_STIM_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m			: inout axi_st;
	inst_id				: natural
);

procedure MASTER_WATCHDOG_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m_data		: in std_logic_vector;
	signal m_valid		: in std_logic;
	signal m_ready		: in std_logic;
	inst_id				: natural
);
procedure MASTER_WATCHDOG_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m			: in axi_st;
	inst_id				: natural
);

impure function read_master_store(
	INDEX	: natural;
	WIDTH	: natural
) return std_logic_vector;
procedure CLONE_MASTER_STORE(
	INDEX	: natural;
	WIDTH	: natural
);
procedure FILL_M_READY_USR_VEC(
	INDEX	: natural;
	DATA	: std_logic
);
procedure FILL_MASTER_LAST_STORE(
	NUMBER	: natural;
	OFFSET  : natural
);
procedure FILL_LAST_STORE(
	inter	: interface_t;
	NUMBER	: natural;
	OFFSET  : natural
);
procedure FILL_LAST_STORE(
	inter	: interface_t;
	NUMBER	: natural;
	OFFSET  : natural;
	LAST	: natural
);
procedure RESET_MASTER_LAST_STORE;
procedure ATE_M_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal m_data		: in std_logic_vector;
	signal m_keep		: in std_logic_vector;
	signal m_valid		: in std_logic;
	signal m_ready		: in std_logic;
	inst_id		: natural );
procedure ATE_M_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal m	: in axi_st;
	inst_id		: natural
);



-------------------------------------------------------------------------------
--  MASTER & SLAVE ------------------------------------------------------------
-------------------------------------------------------------------------------
procedure FILL_STORE(
	inter	: interface_t;
	inst	: natural;
	INDEX	: natural;
	DATA	: std_logic_vector;
	WIDTH	: positive
);
procedure FILL_STORE(
	inter	: interface_t;
	inst	: natural;
	INDEX	: natural;
	DATA	: std_logic_vector
);
procedure FILL_STORE(
	inter	: interface_t;
	inst	: natural;
	INDEX	: natural;
	DATA	: natural;
	WIDTH	: natural
);
procedure FILL_STORE(
	inter	: interface_t;
	INDEX	: natural;
	DATA	: std_logic_vector;
	WIDTH	: positive
);
procedure FILL_STORES(
	inter	: interface_t;
	INDEX	: natural;
	DATA	: std_logic_vector
);
procedure FILL_STORES(
	inter	: interface_t;
	INDEX	: natural;
	DATA	: natural;
	WIDTH	: positive
);
procedure FILL_ALL_STORE(
	inter	: interface_t;
	inst	: natural;
	LENGTH		: natural;
	DATA		: std_logic_vector
);
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high
);
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high
);
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high;
	INV_SLICE		: boolean;
	DATA_WIDTH		: positive range 32 to positive'high
);
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high;
	INV_SLICE		: boolean;
	DATA_WIDTH		: positive range 32 to positive'high
);
procedure FILL_INC_STORE(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: natural;
	SLICE_WIDTH		: positive;
	INV_SLICE		: boolean;
	DATA_WIDTH		: positive
);
procedure FILL_INC_STORE(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: natural;
	DATA_WIDTH		: positive
);
procedure FILL_INC_STORE(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: natural;
	DATA_WIDTH		: positive;
	SLICE_WIDTH		: positive;
	INV_SLICES		: boolean;
	START_VALUE		: natural
);
procedure PUSH_TO_STORE(
	inter		: interface_t;
	inst		: positive;
	num			: positive;
	off			: positive;
	width		: positive
);
procedure UNIFY_STORES( source : interface_t);
procedure ATE_INCREMENT_SEED(
	inter 		: interface_t
);
procedure ATE_INCREMENT_SEED(
	inter 		: interface_t;
	value		: positive
);
procedure ATE_SET_SEED(
	inter 		: interface_t;
	value		: std_logic_vector(LFSR_WIDTH-1 downto 0)
);
procedure ATE_SET_TIMEOUT(
	t 			: time
);
procedure ATE_SET_VERIF_MASTER_LAST(
	a 			: boolean
);
procedure ATE_SET_MASTER_QUIT_TEST(
	enable		: boolean;
	sev			: severity_level
);
procedure ATE_SET_USE_LAST(
	inter		: interface_t;
	inst		: inst_t;
	arg			: boolean
);
procedure ATE_SET_USE_LAST(
	inter		: interface_t;
	arg			: boolean
);
procedure ATE_SET_USE_KEEP(
	inter		: interface_t;
	inst		: inst_t;
	arg			: boolean
);
procedure ATE_SET_USE_KEEP(
	inter		: interface_t;
	arg			: boolean
);
procedure ATE_SET_DATA_SOURCE(
	inter		: interface_t;
	inst		: inst_t;
	arg			: ate_data_source_t
);
procedure ATE_SET_DATA_SOURCE(
	inter		: interface_t;
	arg			: ate_data_source_t
);
procedure ATE_SET_STIM_MODE(
	inter	: interface_t;
	inst	: inst_t;
	mode	: stim_mode_t
);
procedure ATE_SET_STIM_MODE(
	inter	: interface_t;
	mode	: stim_mode_t
);
procedure ATE_SET_TEST_LEN(
	inter	: interface_t;
	inst	: inst_t;
	len		: positive
);
procedure ATE_SET_TEST_LEN(
	inter : interface_t;
	len	: positive
);
procedure ATE_SET_TEST_LEN(
	inter	: interface_t;
	inst	: inst_t;
	len		: positive;
	store_len	: positive
);
procedure ATE_SET_TEST_LEN(
	inter 	: interface_t;
	len		: positive;
	store_len	: positive;
	null_arg	: boolean
);
procedure ATE_SHIFT_LFSR(
	inter 		: interface_t
);
procedure ATE_RESET_USER_VECTOR(
	inter 		: interface_t
);
procedure UNIFY_STORES(
	source			: interface_t;
	master_width	: natural;
	slave_width 	: natural
);

--
-- ATE Control user interface
--
procedure ATE_USER_INIT(
	slaves_active 	: natural;
	masters_active 	: natural
);
procedure ATE_USER_SET_STATE(
	state		: ate_state_enum_t
);
procedure ATE_USER_WAIT_ON_STATE(
	inter		: interface_t;
	inst		: natural;
	state		: ate_state_enum_t
);
procedure ATE_USER_WAIT_ON_STATE(
	state		: ate_state_enum_t
);
procedure ATE_USER_WAIT_ON_STATE(
	inter		: interface_t;
	state		: ate_state_enum_t
);
procedure ATE_USER_SET_STATE(
	inter		: interface_t;
	state		: ate_state_enum_t
);
procedure ATE_USER_SET_STATE(
	inter		: interface_t;
	inst		: natural;
	state		: ate_state_enum_t
);
impure function ate_user_check_state(
	inter		: interface_t;
	inst		: natural;
	state		: ate_state_enum_t
) return boolean;

-------------------------------------------------------------------------------
--  MISC  ---------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Log files
file slave_file 	: TEXT open write_mode is "ate_slave.log";
file master1_file 	: TEXT open write_mode is "ate_master1.log";
file master2_file 	: TEXT open write_mode is "ate_master2.log";

--procedure PRINT_TO_SCREEN_PROC(inter : interface_t; inst_id : natural; msg : string);
procedure ATE_SET_ATE_VERBOSE(arg : boolean);
procedure ATE_SET_DEFAULT;


end axis_test_env_pkg;
-------------------------------------------------------------------------------
--  PKG body  -----------------------------------------------------------------
-------------------------------------------------------------------------------
package body axis_test_env_pkg is


-- custom min for workaround ghdl bug
function custom_min(
	 a : natural;
	 b : natural
	) return natural is
begin
	if a < b then
		return a;
	else
		return b;
	end if;
end function;


--------------------------------------------------------------------------------
-- Internal
--------------------------------------------------------------------------------
-- Shift lfsr and return random bit
impure function rand_bit(LFSR_STATE_ID 	: natural) return std_logic is
	variable lfsr	: std_logic_vector(LFSR_WIDTH-1 downto 0);
	variable d0		: std_logic;
begin
	lfsr	:= lfsr_state(LFSR_STATE_ID);
	d0		:= lfsr(LFSR_WIDTH-1) xor lfsr(LFSR_WIDTH-2);
	lfsr_state(LFSR_STATE_ID) := lfsr(LFSR_WIDTH-2 downto 0) & d0;
	return lfsr(LFSR_WIDTH-1);
end function;

procedure FAIL_WRONG_INTERFACE(
	caller_name	: string) is
begin
	assert false
		report " [ FAILURE ] bad interface passed to "&caller_name
		severity failure;
end procedure;

function fail_msg(
	id		: id_t;
	msg		: string;
	caller_name : string
)	return string is
begin
	case id.inter is
	when SLAVE_E =>
		return
			"[Slave"&natural'image(id.inst)&
			" Test"&natural'image(id.test)&
			" Trans"&natural'image(id.trans)&"] "&
			" " & msg & ". Called by: "&caller_name;
	when MASTER_E =>
		return
			"[Master"&natural'image(id.inst)&
			" Test"&natural'image(id.test)&
			" Trans"&natural'image(id.trans)&"] "&
			" " & msg & ". Called by: "&caller_name;
	when others =>
		return
			"[Master/Slave"&natural'image(id.inst)&
			" Test"&natural'image(id.test)&
			" Trans"&positive'image(id.trans)&"] "&
			" " & msg & ". Called by: "&caller_name;
	end case;
end function;

function fail_msg_data(
	data 	: std_logic_vector;
	store	: std_logic_vector;
	i		: natural
)	return string is
	constant data_nat		: natural := to_integer(unsigned(data(custom_min(30, data'length-1) downto 0)));
	constant store_nat		: natural := to_integer(unsigned(store(custom_min(30, store'length-1) downto 0)));
begin
	return
		"Got=" &  integer'image(data_nat) & " 0x" & hstr(data)&
		" Expected: store(" & natural'image(i) & ")="
		&integer'image(store_nat)&" 0x"&hstr(store);
end function;


function log_prefix(
	 time_en	: boolean;
	 msg		: string
	) return line is
	variable l : line;
begin
	if time_en then
		write (L, String'("[ "));
		write (L, now);
		write (L, String'(" ]  "));
	end if;
	write (L, msg);
	return l;
end function;

procedure WRITE_TO_FILE(
	id			: id_t;
	variable a	: line
) is
	variable l : line;
begin
	l := a;

	case id.inter is
		when MASTER_E =>
			case id.inst is
				when 1 => writeline(master1_file, l);
				when 2 => writeline(master2_file, l);
				when others => assert false
						report fail_msg(id, "master inst bigger than max", "WRITE_TO_FILE")
						severity failure;
			end case;
		when SLAVE_E =>
			writeline(slave_file, l);
		when others => FAIL_WRONG_INTERFACE("WRITE_TO_FILE");
	end case;
end WRITE_TO_FILE;

-- Writes line to log withou argument
procedure WRITE_LOG_PROC (
	id			: id_t;
	text_string	: string;
	time_en		: boolean) is
	variable L      : line;

begin
	l := log_prefix(time_en, text_string);
	WRITE_TO_FILE(id, l);
end WRITE_LOG_PROC;

-- Writing line to log with arg
procedure WRITE_LOG_PROC (
	id			: id_t;
	text_string	: string;
	time_en		: boolean;
	arg			: std_logic_vector
) is
	variable L      : line;
begin
	l := log_prefix(time_en, text_string);

	-- Log arguments
	-- As binary value -- TO DO
	if arg'length <= LOG_MAX_BIT_WIDTH then
		write(L, arg);
	end if;
	write(L, String'("   0x"));
	-- As hex value
--	hwrite(L, slv_zero_pad(arg));
	hwrite(L, hex_align(arg));
	write(L, String'("   "));
	-- As decimal value
	if Is_X(arg) then
		write(L, 0);
	else
--		write(L, integer'image(to_integer(unsigned(arg(custom_min(30, arg'length-1) downto 0)))));
	end if;

	WRITE_TO_FILE(id, l);
end WRITE_LOG_PROC;


procedure PRINT_TO_SCREEN_PROC(inter : interface_t; inst_id : natural; msg : string) is
	variable L : line;
begin
-- Print prefix
	write (L, String'("[ "));
	if inter = MASTER_E then
		write(L, String'("MASTER "));
	elsif inter = SLAVE_E then
		write(L, String'("SLAVE "));
	else
		assert false
		  report "ATE PRINT_TO_SCREEN_PROC() wrong interface. Shuold be MASTER_E or SLAVE_E"
		  severity failure;
	end if;

	-- Pring instance ID
	if inst_id /= 0 then
		write(L, natural'image(inst_id));
	end if;
	write (L, String'(" ]   "));

-- Print msg
	write(L, msg);

-- Print to output only if ATE_CFG.VERBOSE
	if ATE_COMMON_CFG.VERBOSE then
		writeline(output, L);
	end if;
end procedure;

impure function check_store(
		inst		: positive;
		STORE_LEN 	: natural;
		WIDTH 		: natural;
		label_txt	: string)
		return	boolean is
	variable m_store	: std_logic_vector(WIDTH-1 downto 0);
begin
	for I in 0 to STORE_LEN-1 loop
		m_store := master_store(inst)((WIDTH)*(I+1)-1 downto (WIDTH)*I);
		for B in 0 to WIDTH-1 loop
			assert m_store(B) /= 'U'
			 report label_txt
			 severity warning;
		end loop;
	end loop;
	return true;
end function;

procedure ATE_USER_INIT(
	slaves_active 	: natural;
	masters_active 	: natural
	) is
	variable id_s							: id_t;
	variable id_m							: id_t;
	variable L      : line;
begin
	id_s.inter := SLAVE_E;
	id_s.inst	:= 1;
	id_s.test := 1;
	id_m.inter := MASTER_E;
	id_m.inst	:= 1;
	id_m.test := 1;

-- Set the number of active slaves and masters
	assert slaves_active <= ATE_MAX_INST
	report fail_msg(id_s, "desired number of ATE slave interface is bigger  than global ATE_MAX_INST", "ATE_INIT")
	severity failure;

	assert masters_active <= ATE_MAX_INST
	report fail_msg(id_m, "desired number of ATE masters interface is bigger  than global ATE_MAX_INST", "ATE_INIT")
	severity failure;

	SLAVES_ACTIVE_NUM := slaves_active;
	MASTERS_ACTIVE_NUM := masters_active;

	-- LOG header
	WRITE_LOG_PROC(id_m, "### X.Y   X - ATE master instance ID; Y - test ID", false);
	-- Initialze the random seed generator

end procedure;


--function fill_string(msg : string; number : natural)
--	return string is
--
--begin

--function check_01(
--	data	: std_logic_vector
--) return boolean is

--begin
--	for I in 0 to data'length-1 loop
--		if data(I) /= '0' and data(I) /= '1' then
--			return false;
--		end if;
--	end loop;
--	return	true;
--end function;
--procedure ATE_WAIT_ON_TRIG(
--	id		: id_t
--) is
--begin
--	case id.inter is
--	when MASTER_E =>
--		case id.inst is
--			when 1 => wait on ATE_TRIG, ATE_TRIG_MASTER, ATE_TRIG_MASTER1;
--			when 2 => wait on ATE_TRIG, ATE_TRIG_MASTER, ATE_TRIG_MASTER2;
--			when others => assert false
--					report fail_msg(id, "master inst bigger than expected",
--					id'instance_name) severity failure;
--		end case;
--	when SLAVE_E =>
--		wait on ATE_TRIG, ATE_TRIG_SLAVE;
--	when others =>
--		FAIL_WRONG_INTERFACE(id'instance_name);
--	end case;
--end procedure;

--
-- ATE state-based control
--

-- interal porcedures:
procedure FAIL_WRONG_STATE(
	id				: id_t;
	state			: ate_state_enum_t;
	caller_name		: string;
	sev_level		: severity_level
) is
begin
	assert false
		report fail_msg(id, " no expected state: "&ate_state_enum_t'image(state), caller_name)
		severity sev_level;
end procedure;


procedure ATE_WAIT_UNTIL_STATE(
	id			: id_t; -- who is waiting?
	state	: ate_state_enum_t -- on waht it is wating?
) is
begin
--	wait for ATE_STATE_SYNC_INTERVAL;

	case id.inter is
	when SLAVE_E =>
		while ATE_S_STATE(id.inst) /= state loop
			wait for ATE_STATE_SYNC_INTERVAL;
		end loop;
	when MASTER_E =>
		while ATE_M_STATE(id.inst) /= state loop
			wait for ATE_STATE_SYNC_INTERVAL;
		end loop;
	when BOTH_E =>
		while ATE_S_STATE(id.inst) /= state loop
			wait for ATE_STATE_SYNC_INTERVAL;
		end loop;
		while ATE_M_STATE(id.inst) /= state loop
			wait for ATE_STATE_SYNC_INTERVAL;
		end loop;
	when others =>
		FAIL_WRONG_INTERFACE("ATE_WAIT_UNTIL_STATE");
	end case;
end procedure;

procedure ATE_CHANGE_STATE(
	id			: id_t; -- for who is that change?
	state	: ate_state_enum_t -- what is that change?
) is
begin
	case id.inter is
	when SLAVE_E =>
		ATE_S_STATE(id.inst) := state;
	when MASTER_E =>
		ATE_M_STATE(id.inst) := state;
	when BOTH_E =>
		ATE_S_STATE(id.inst) := state;
		ATE_M_STATE(id.inst) := state;
	when others =>
		FAIL_WRONG_INTERFACE("ATE_CHANGE_STATE");
	end case;
end procedure;

function assert_state_msg(
	 cur_state 		: ate_state_enum_t;
	 exp_cur_state	: ate_state_enum_t;
	 next_state 	: ate_state_enum_t
) return string is
	variable v : natural := 0;
begin
	return
	" current state is: "&ate_state_enum_t'image(cur_state)&
	" ,but the desired next state is: "&ate_state_enum_t'image(next_state)&
	" in taht case the current state should be: "&ate_state_enum_t'image(exp_cur_state);
end function;


procedure ATE_ASSERT_STATE(
	id					: id_t;
	exp_cur_state		: ate_state_enum_t;
	next_state			: ate_state_enum_t;
	sev_level			: severity_level;
	caller				: string
) is
begin
	case id.inter is
	when SLAVE_E =>
		assert ATE_S_STATE(id.inst) = exp_cur_state
		report fail_msg(id, assert_state_msg(ATE_S_STATE(id.inst), exp_cur_state, next_state), caller)
		severity sev_level;
	when MASTER_E =>
		assert ATE_M_STATE(id.inst) = exp_cur_state
		report fail_msg(id, assert_state_msg(ATE_M_STATE(id.inst), exp_cur_state, next_state), caller)
		severity sev_level;
	when BOTH_E =>
		assert ATE_S_STATE(id.inst) = exp_cur_state
		report fail_msg(id, assert_state_msg(ATE_S_STATE(id.inst), exp_cur_state, next_state), caller)
		severity sev_level;
		assert ATE_M_STATE(id.inst) = exp_cur_state
		report fail_msg(id, assert_state_msg(ATE_M_STATE(id.inst), exp_cur_state, next_state), caller)
		severity sev_level;
	when others =>
		FAIL_WRONG_INTERFACE("ATE_CHANGE_STATE");
	end case;
end procedure;

-- external procedures
procedure ATE_WAIT_ON_STATE(
	id			: id_t; -- who is waiting?
	state	: ate_state_enum_t -- on waht it is wating?
) is
begin
	case state is
	-- user can wait on idle state
	when ATE_STATE_IDLE =>
		-- If waiting on IDLE state then the current state has to be RUN
		--ATE_ASSERT_STATE(id, ATE_STATE_RUN, state, failure, "ATE_WAIT_ON_STATE");
		-- Real waiting below
		ATE_WAIT_UNTIL_STATE(id, state);

	--ate master and slave nedd to wait until ATE_STATE_RUN state
	when ATE_STATE_RUN =>
		-- If waiting on RUN state then the current state has to be CFG
		ATE_ASSERT_STATE(id, ATE_STATE_IDLE, state, failure, "ATE_WAIT_ON_STATE");
		ATE_WAIT_UNTIL_STATE(id, state);
	when others =>
	end case;
end procedure;


procedure ATE_SET_STATE(
	id			: id_t; -- for who is that change?
	state		: ate_state_enum_t -- what is that change?
) is
begin
	case state is
	--ate master and slave may need to set ATE_STATE_IDLE state
	when ATE_STATE_IDLE =>
		-- If setting IDLE state then the current state has to be RUN
		ATE_ASSERT_STATE(id, ATE_STATE_RUN, state, failure, "ATE_SET_STATE");
		-- Real changing below
		ATE_CHANGE_STATE(id, state);

	-- user can set run state
	when ATE_STATE_RUN =>
		-- If setting RUN state then the current state has to be CFG
		ATE_ASSERT_STATE(id, ATE_STATE_IDLE, state, failure, "ATE_SET_STATE");
		ATE_CHANGE_STATE(id, state);
	when others =>

	end case;
end procedure;

--
-- ATE state control user interface external procedures
--

-- set ate state READY or RUN for all instanced of all interfaces
procedure ATE_USER_SET_STATE(
	state		: ate_state_enum_t
) is
variable id : id_t;
begin
	id.inter := BOTH_E;
	id.test := 1;
	-- User can only set READY and RUN sate
	assert state = ATE_STATE_RUN
	report fail_msg(id, " user can only set ATE_STATE_RUN ",
	"ATE_USER_WAIT_ON_STATE") severity failure;

	for i in 1 to SLAVES_ACTIVE_NUM loop
		id.inter := SLAVE_E;
		id.inst	:= i;
		ATE_SET_STATE(id, state);
	end loop;

	for i in 1 to MASTERS_ACTIVE_NUM loop
		id.inter := MASTER_E;
		id.inst	:= i;
		ATE_SET_STATE(id, state);
	end loop;
end procedure;

-- set state for specific instance
procedure ATE_USER_SET_STATE(
	inter		: interface_t;
	inst		: natural;
	state		: ate_state_enum_t
) is
variable id : id_t;
begin
	id.inter := inter;
	id.test := 1;
	-- User can only set RUN sate
	assert state = ATE_STATE_RUN
	report fail_msg(id, " user can only set ATE_STATE_RUN ",
	"ATE_USER_WAIT_ON_STATE") severity failure;
	id.inst	:= inst;
	ATE_SET_STATE(id, state);
end procedure;

-- set state for specific interfaces
procedure ATE_USER_SET_STATE(
	inter		: interface_t;
	state		: ate_state_enum_t
) is
variable id 		: id_t;
variable max_inst 	: positive;
begin
	id.inter := inter;
	id.test := 1;

	-- User can only set RUN sate
	assert state = ATE_STATE_RUN
	report fail_msg(id, " user can only set ATE_STATE_RUN ",
	"ATE_USER_WAIT_ON_STATE") severity failure;

	case inter is
	when MASTER_E =>
		for i in 1 to MASTERS_ACTIVE_NUM loop
			id.inst	:= i;
			ATE_SET_STATE(id, state);
		end loop;
	when SLAVE_E =>
		for i in 1 to SLAVES_ACTIVE_NUM loop
			id.inst	:= i;
			ATE_SET_STATE(id, state);
		end loop;
	when BOTH_E =>
		ATE_USER_SET_STATE(state);
	end case;
end procedure;

-- Waiting on chosen instance and interface
procedure ATE_USER_WAIT_ON_STATE(
	inter		: interface_t;
	inst		: natural;
	state		: ate_state_enum_t
) is
	variable id : id_t;
begin
	wait for 10 ns;
	id.inter := inter;
	id.test := 1;
	id.inst	:= inst;
	-- User can only wait on IDLE state
	assert state = ATE_STATE_IDLE
	report fail_msg(id, " user can only wait on ATE_STATE_IDLE", "ATE_USER_WAIT_ON_STATE")
	severity failure;

	-- Wait on state now
	ATE_WAIT_ON_STATE(id, state);
end procedure;
procedure ATE_USER_WAIT_ON_STATE(
	state		: ate_state_enum_t
) is
begin
	ATE_USER_WAIT_ON_STATE(MASTER_E, 1, state);
end procedure;
procedure ATE_USER_WAIT_ON_STATE(
	inter		: interface_t;
	state		: ate_state_enum_t
) is
begin
	for i in 1 to SLAVES_ACTIVE_NUM loop
		ATE_USER_WAIT_ON_STATE(inter, i, state);
	end loop;
end procedure;

impure function ate_user_check_state(
	inter		: interface_t;
	inst		: natural;
	state		: ate_state_enum_t
) return boolean is
	variable id : id_t;
begin
	id.inter := inter;
	id.test := ATE_M_TEST_ID;
	id.inst	:= inst;
	assert state = ATE_STATE_IDLE
	report fail_msg(id, " user can only wait on ATE_STATE_IDLE", "ate_user_check_state")
	severity failure;
	case inter is
	when SLAVE_E =>
		if ATE_S_STATE(id.inst) = state then
			return true;
		else
			return false;
		end if;
	when MASTER_E =>
		if ATE_M_STATE(id.inst) = state then
			return true;
		else
			return false;
		end if;
	when BOTH_E =>
		if ATE_S_STATE(id.inst) = state and ATE_M_STATE(id.inst) = state then
			return true;
		else
			return false;
		end if;
	when others =>
		FAIL_WRONG_INTERFACE("ate_user_check_state");
	end case;

end function;



procedure ATE_SET_DEFAULT is begin
	ATE_COMMON_CFG := ATE_COMMON_CFG_DEF;
	ATE_MASTER_CFG := (others => ATE_MASTER_CFG_DEF);
	ATE_SLAVE_CFG := (others => ATE_SLAVE_CFG_DEF);
	ATE_RESET_USER_VECTOR(BOTH_E);
	RESET_MASTER_LAST_STORE;
	RESET_SLAVE_LAST_STORE;
end procedure;

-- Setting arg inst id as the last master inst (which is setting ATE_M_TEST_ID),
-- its bigger than current ATE_M_TEST_ID. Returns the current value of ATE_LAST_MASTER_INST
procedure SET_LAST_MASTER(
	 inst_id : natural ) is
	variable v : natural := 0;
begin
	v := max(ATE_LAST_MASTER_INST, inst_id);
	ATE_LAST_MASTER_INST := v;
end procedure;

-- Incrementing test is
procedure INC_TEST_ID(
 	inst_id	: natural) is
begin
	if ATE_COMMON_CFG.TEST_ID_AUTO_INC and (inst_id = ATE_LAST_MASTER_INST)then
		ATE_M_TEST_ID := ATE_M_TEST_ID +1;
	end if;
end procedure;

impure function and_reduce_keep(
	 i 			: natural;
	 keep_slice : positive
	) return std_logic is
begin
	return and_reduce(slave_keep_store((I+1)*keep_slice-1 downto I*keep_slice));
end function;


function keep_valid_data(
	 data : std_logic_vector;
	 keep : std_logic_vector

) return std_logic_vector is
	variable mask 		: std_logic_vector(data'range);
	variable index	: natural;
begin
	mask := axi_st_mask(keep);
	for i in data'range loop
		index := i;
		exit when mask(i) = '1';
	end loop;
	return data(index downto 0);
end function;

function keep_invalid_data(
	 data : std_logic_vector;
	 keep : std_logic_vector

) return std_logic_vector is
	variable mask : std_logic_vector(data'range);
	variable index	: natural;
begin
	mask := axi_st_mask(keep);
	for i in data'range loop
		index := i;
		exit when mask(i) = '1';
	end loop;
	return data(data'high downto index+1);
end function;
		function slice_inc_data(
		INVERT			: boolean;
		DATA_WIDTH		: positive range 8 to positive'high;
		SLICE_WIDTH		: positive range 8 to positive'high;
		d				: natural;
		fixed_j			: natural
	) return natural is
	-- variables for inverted order
	-- n = number of slices in data DATA_WIDTH / SLICE_WIDTH
	-- d is variable for filling the store
	-- !!! d_inv = j-m-1, where
	-- !!! m = d mod n	 => index in slice from 0 to n-1
	-- !!! j = n(d/n +1) => current	data word from n 2n 3n
	constant n			: positive := DATA_WIDTH / SLICE_WIDTH;
	variable d_inv		: natural;
	variable m 			: natural range 0 to DATA_WIDTH / SLICE_WIDTH -1;
	variable j			: positive range n to positive'high;
begin
	if INVERT then
		j := fixed_j;
		m := d mod n;
		d_inv := j-m-1;
		return d_inv;
	else
		return d;
	end if;
end function;
function slice_inc_data(
		INVERT			: boolean;
		DATA_WIDTH		: positive range 8 to positive'high;
		SLICE_WIDTH		: positive range 8 to positive'high;
		d				: natural
	) return natural is
begin
	-- !!! j = n(d/n +1) => current	data word from n 2n 3n
	return slice_inc_data(INVERT, DATA_WIDTH, SLICE_WIDTH, d, (d/(DATA_WIDTH/SLICE_WIDTH) +1)*(DATA_WIDTH/SLICE_WIDTH));
end function;

procedure ASSIGN_TO_STORE(
	inter			: interface_t;
	inst			: positive;
	store			: std_logic_vector(STORE_WIDTH-1 downto 0)
) is begin
	case inter is
		when MASTER_E =>
			master_store(inst) := store;
		when SLAVE_E =>
			slave_store := store;
		when BOTH_E =>
			master_store(inst) := store;
			slave_store := store;
		when others =>
			FAIL_WRONG_INTERFACE("ASSIGN_TO_STORE");
	end case;
end procedure;
procedure ASSIGN_TO_LAST_STORE(
	inter			: interface_t;
	inst			: positive;
	store			: std_logic_vector(STORE_WIDTH-1 downto 0)
) is begin
	case inter is
		when MASTER_E =>
			master_last_store	:= (others => '0');
			master_last_store 	:= store;
		when SLAVE_E =>
			slave_last_store	:= (others => '0');
			slave_last_store 	:= store;
		when BOTH_E =>
			master_last_store	:= (others => '0');
			slave_last_store	:= (others => '0');
			master_last_store 	:= store;
			slave_last_store 	:= store;
		when others =>
			FAIL_WRONG_INTERFACE("ASSIGN_TO_STORE");
	end case;
end procedure;

impure function ret_store(
	 inter 	: interface_t;
	 inst	: positive
	) return std_logic_vector is
	variable v : natural := 0;
begin
	case inter is
		when MASTER_E =>
			return master_store(inst);
		when SLAVE_E =>
			return slave_store;
		when others =>
			FAIL_WRONG_INTERFACE("ret_store");
	end case;
end function;

--------------------------------------------------------------------------------
-- External master and slave procedures
--------------------------------------------------------------------------------
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high;
	INV_SLICE		: boolean;
	DATA_WIDTH		: positive range 32 to positive'high
) is
	variable d		: natural;
	variable store		: std_logic_vector(STORE_WIDTH-1 downto 0);
	variable null_val	: std_logic;
	variable id			: id_t;
	variable keep_slice	: natural;
	variable null_s		: natural := 0;
	constant n			: positive := DATA_WIDTH / SLICE_WIDTH;
	variable data_word	: std_logic_vector(DATA_WIDTH-1 downto 0);
	constant KEEP_WIDTH	: natural := DATA_WIDTH/8;
	variable keep		: std_logic_vector(KEEP_WIDTH-1 downto 0);
begin
	id.inter := inter;
	id.inst	:= inst;
	id.test := ATE_M_TEST_ID;

	assert (SLICE_WIDTH mod 8) = 0
		report fail_msg(id, "SLICE_WIDTH arg is not multiply of 8",
		"FILL_INC_STORE_AS_KEEP")
		severity failure;

	keep_slice := SLICE_WIDTH/8;

	case inter is
	when MASTER_E =>
		null_val := '-';
	when SLAVE_E =>
		null_val := 'U';
	when others =>
		FAIL_WRONG_INTERFACE("FILL_INC_STORE_AS_KEEP");
	end case;

	for I in 0 to LENGTH-1 loop
		-- check if in the current slice there are only '1'
--		if keep_slice = 1 and slave_keep_store(I) = '1' then
--			store((I+1)*SLICE_WIDTH-1 downto I*SLICE_WIDTH)
--					:= std_logic_vector(to_unsigned(d, SLICE_WIDTH));
--			d := d+1;
		if and_reduce_keep(I, keep_slice) = '1' then
			store((I+1)*SLICE_WIDTH-1 downto I*SLICE_WIDTH)
					:= std_logic_vector(to_unsigned(d, SLICE_WIDTH));
			d := d+1;
		else
			store((I+1)*SLICE_WIDTH-1 downto I*SLICE_WIDTH)
					:= (others => null_val);
		end if;
	end loop;

	if INV_SLICE then
		-- for each data word strip the data with invalid keep. Inverse it
		-- and writing it back to store
		-- Iterate on the number of slices
		for i in 0 to LENGTH/n -1 loop
			if and_reduce_keep(i, KEEP_WIDTH) = '0' then
				keep := slave_keep_store((I+1)*KEEP_WIDTH-1 downto I*KEEP_WIDTH);
				data_word := store((I+1)*DATA_WIDTH-1 downto I*DATA_WIDTH);
				data_word := keep_invalid_data(data_word, keep) & reverse_slices(keep_valid_data(data_word, keep), SLICE_WIDTH);
				store((I+1)*DATA_WIDTH-1 downto I*DATA_WIDTH) := data_word;
			else
				keep := slave_keep_store((I+1)*KEEP_WIDTH-1 downto I*KEEP_WIDTH);
				data_word := store((I+1)*DATA_WIDTH-1 downto I*DATA_WIDTH);
				data_word := reverse_slices(data_word, SLICE_WIDTH);
				store((I+1)*DATA_WIDTH-1 downto I*DATA_WIDTH) := data_word;
			end if;
		end loop;
	end if;

	case inter is
	when MASTER_E =>
		master_store(inst) := store;
	when SLAVE_E =>
		slave_store	:= store;
	when others =>
		FAIL_WRONG_INTERFACE("INV_SLICE");
	end case;
end procedure;
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high;
	INV_SLICE		: boolean;
	DATA_WIDTH		: positive range 32 to positive'high
) is
begin
	for i in 1 to ATE_MAX_INST loop
		FILL_INC_STORE_AS_KEEP(inter, i, length, slice_width, inv_slice, data_width);
	end loop;
end procedure;
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high
) is begin
	FILL_INC_STORE_AS_KEEP(inter, inst, LENGTH, SLICE_WIDTH, false, SLICE_WIDTH*4);
end procedure;
procedure FILL_INC_STORE_AS_KEEP(
	inter			: interface_t;
	LENGTH			: positive;
	SLICE_WIDTH		: positive range 8 to positive'high
) is begin
	for i in 1 to ATE_MAX_INST loop
		FILL_INC_STORE_AS_KEEP(inter, i, LENGTH, SLICE_WIDTH, false, SLICE_WIDTH*4);
	end loop;
end procedure;

procedure FILL_INC_STORE(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: natural;
	SLICE_WIDTH		: positive;
	INV_SLICE		: boolean;
	DATA_WIDTH		: positive
) is
	variable store : std_logic_vector(STORE_WIDTH-1 downto 0);
begin
	for I in 0 to LENGTH-1 loop
		store((I+1)*SLICE_WIDTH-1 downto I*SLICE_WIDTH) := std_logic_vector(
				to_unsigned(slice_inc_data(INV_SLICE, DATA_WIDTH, SLICE_WIDTH, i),
				SLICE_WIDTH));
	end loop;
	ASSIGN_TO_STORE(inter, inst, store);
end procedure;
procedure FILL_INC_STORE(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: natural;
	DATA_WIDTH		: positive) is
begin
	FILL_INC_STORE(inter, inst, LENGTH, DATA_WIDTH, DATA_WIDTH, false, 0);
end procedure;
-- |  DATA   |
-- | a b c d |
--	 |
--	 SLICE
-- LENGTH is the number of DATA's
procedure FILL_INC_STORE(
	inter			: interface_t;
	inst			: positive;
	LENGTH			: natural;
	DATA_WIDTH		: positive;
	SLICE_WIDTH		: positive;
	INV_SLICES		: boolean;
	START_VALUE		: natural
) is
	variable store : std_logic_vector(STORE_WIDTH-1 downto 0);
	variable temp_data	: std_logic_vector(DATA_WIDTH-1 downto 0);
begin
	for I in 0 to LENGTH-1 loop
		if INV_SLICES then
			temp_data := std_logic_vector(to_unsigned(i +START_VALUE , DATA_WIDTH));
		else
			temp_data := reverse_slices(std_logic_vector(to_unsigned(i +START_VALUE, DATA_WIDTH)), SLICE_WIDTH);
		end if;
		store((I+1)*DATA_WIDTH-1 downto I*DATA_WIDTH) := temp_data;
	end loop;
	ASSIGN_TO_STORE(inter, inst, store);
end procedure;

-- TODO what if width < data'length?
procedure FILL_STORE(
	inter	: interface_t;
	inst	: natural;
	INDEX	: natural;
	DATA	: std_logic_vector;
	WIDTH	: positive
) is
	variable data_v						: std_logic_vector(width-1 downto 0);
begin
	data_v := std_logic_vector(resize(unsigned(data), width));
	case inter is
		when MASTER_E =>
			master_store(inst)((INDEX+1)*(WIDTH)-1 downto INDEX*(WIDTH)) := DATA_v;
		when SLAVE_E =>
			slave_store((INDEX+1)*(WIDTH)-1 downto INDEX*(WIDTH)) := DATA_v;
		when BOTH_E =>
			master_store(inst)((INDEX+1)*(WIDTH)-1 downto INDEX*(WIDTH)) := DATA_v;
			slave_store((INDEX+1)*(WIDTH)-1 downto INDEX*(WIDTH)) := DATA_v;
		when others =>
			FAIL_WRONG_INTERFACE("FILL_STORE");
	end case;
end procedure;
procedure FILL_STORE(
	inter	: interface_t;
	inst	: natural;
	INDEX	: natural;
	DATA	: std_logic_vector
) is begin
	FILL_STORE(inter, inst, index, data, data'length);
end procedure;
procedure FILL_STORE(
	inter	: interface_t;
	inst	: natural;
	INDEX	: natural;
	DATA	: natural;
	WIDTH	: natural
) is
begin
	FILL_STORE(inter, inst, index, std_logic_vector(to_unsigned(data, width)));
end procedure;
procedure FILL_STORE(
	inter	: interface_t;
	INDEX	: natural;
	DATA	: std_logic_vector;
	WIDTH	: positive
) is
begin
	for i in 1 to ATE_MAX_INST loop
		FILL_STORE(inter, i, index, data, width);
	end loop;
end procedure;

procedure FILL_STORES(
	inter	: interface_t;
	INDEX	: natural;
	DATA	: std_logic_vector
) is
begin
	case inter is
	when MASTER_E =>
		for i in 1 to MASTERS_ACTIVE_NUM loop
			FILL_STORE(inter, i, index, data, data'length);
		end loop;
	when SLAVE_E =>
		for i in 1 to SLAVES_ACTIVE_NUM loop
			FILL_STORE(inter, i, index, data, data'length);
		end loop;
	when BOTH_E	 =>
		for i in 1 to SLAVES_ACTIVE_NUM loop
			FILL_STORE(inter, i, index, data, data'length);
		end loop;
		for i in 1 to MASTERS_ACTIVE_NUM loop
			FILL_STORE(inter, i, index, data, data'length);
		end loop;
	end case;
end procedure;
procedure FILL_STORES(
	inter	: interface_t;
	INDEX	: natural;
	DATA	: natural;
	WIDTH	: positive
) is
begin
	FILL_STORES(inter, index, std_logic_vector(to_unsigned(data, width)));
end procedure;

procedure FILL_ALL_STORE(
	inter		: interface_t;
	inst		: natural;
	LENGTH		: natural;
	DATA		: std_logic_vector) is
	variable store : std_logic_vector(STORE_WIDTH-1 downto 0);
begin
	for I in 0 to LENGTH-1 loop
		store((I+1)*(DATA'length)-1 downto I*(DATA'length)) := DATA;
	end loop;

	ASSIGN_TO_STORE(inter, inst, store);
end procedure;

-- input a b c a b c
-- result a b c 0 a b c 0
-- num - number to zeros to push (2 above)
-- off - number of slices of data betwwen each zero pushed
-- width - width of each data slice. data sliace above is every a , b ,c letter
--  Descritpipn of variables used
--  shifter out slice(t)
--   |
-- | a b c 0 | a b c 0 |
--    |		   | |
--	  |        | slice
--   block(b)  |
-- |		result(r)  |
procedure PUSH_TO_STORE(
	inter		: interface_t;
	inst		: positive;
	num			: positive;
	off			: positive;
	width		: positive
	) is
	constant DATA_WIDTH	: natural := (num*off)*width;
	constant D	: boolean := false;
	variable store		: std_logic_vector(STORE_WIDTH-1 downto 0);
	variable data	 : std_logic_vector(DATA_WIDTH-1 downto 0);
	variable s		: std_logic_vector((off+1)*width-1 downto 0); --shifted
	variable r		: std_logic_vector(num*(off+1)*width-1 downto 0); -- result
	variable b		: std_logic_vector(off*width-1 downto 0); -- block
	variable t		: std_logic_vector(width-1 downto 0); -- t (shifted aout first slice)
begin
	-- Get specific store
	store := ret_store(inter, inst);
	-- Working on data needed, not all store. Additional word on the beggining
	-- which will b
	data := store(data'range);

	if D then
		report "data w="&natural'image(data'length);
		report "s width="&natural'image(s'length);
		report "r width="&natural'image(r'length);
		report "data="&hstr(data);
	end if;

	for i in 0 to num-1 loop
		-- shift each block one time. Take one slice from another block which
		-- will be shifted out
		b := data((i+1)*off*width-1 downto i*off*width);
--		t := b(3*width-1 downto 2*width);
		t := b(off*width-1 downto (off-1)*width);
		s := t & std_logic_vector(unsigned(b) sll width);
		-- write shifet block to result vector which is one slice bigger than
		-- in data
		r((i+1)*(off+1)*width-1 downto i*(off+1)*width) := s;

		if D then
			report "i="&natural'image(i);
			report "t="&hstr(t);
			report "s="&hstr(s);
			report "r="&hstr(r);
		end if;
	end loop;
	FILL_STORE(inter, inst,0, r);
end procedure;


-------------------------------------------------------------------------------
-- External, SLAVE only
-------------------------------------------------------------------------------
-- Main Slave interface
procedure ATE_S_STIM(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal s_data		: out std_logic_vector;
	signal s_keep		: out std_logic_vector;
	signal s_valid		: out std_logic;
	signal s_last		: out std_logic;
	signal s_ready		: in std_logic;
	inst_id				: inst_t ) is
	variable store_data	: std_logic_vector(s_data'range);
	variable keep_mask	: std_logic_vector(s_data'range);
	variable store_keep	: std_logic_vector(s_keep'range);
	variable s_valid_v		: std_logic := '0';
	variable usr_vec_idx	: natural 	:= 0;
	variable id			: id_t;
	constant DATA_DEF	: std_logic_vector(s_data'range) := (others => 'X');
	constant KEEP_DEF	: std_logic_vector(s_keep'range) := (others => ATE_SLAVE_CFG(inst_id).S_KEEP_DEF_VAL);
begin
	id.inter := SLAVE_E;
	id.inst	:= 1;
	id.test := 1;


	-- Assign X to indicate invalid data
		s_data(s_data'range)	<= DATA_DEF;
		s_keep	<= KEEP_DEF;
		s_last	<= '0';
		s_valid	<= '0';
		s_valid_v := '0';

	-- Procedure is waiting for trigger signal
	PRINT_TO_SCREEN_PROC(SLAVE_E, id.inst, "waiting for ATE_STATE_RUN state...");
	ATE_WAIT_ON_STATE(id, ATE_STATE_RUN);
	PRINT_TO_SCREEN_PROC(SLAVE_E, id.inst, "entered ATE_STATE_RUN state, starting stimulus");

	WRITE_LOG_PROC(id, "slave"&natural'image(id.inst)& " test: "&
			natural'image(ATE_M_TEST_ID)&"   Content of data store:", false);
	for I in 0 to ATE_SLAVE_CFG(id.inst).SLAVE_TEST_LEN-1 loop
		WRITE_LOG_PROC(id, ("STORE[" & integer'image(I) & "]   "), false,
				slave_store((s_data'length)*((i mod ATE_SLAVE_CFG(id.inst).SLAVE_STORE_LEN)+1)-1
				downto (s_data'length)*(i mod ATE_SLAVE_CFG(id.inst).SLAVE_STORE_LEN)));
	end loop;

	-- Wait for reset deassertion
	wait until rising_edge(clk) and rst = '0';

	--
	-- MAIN LOOP
	--
	for I in 0 to ATE_SLAVE_CFG(id.inst).SLAVE_TEST_LEN-1 loop
		-- Setting LAST flag
		if (I = ATE_SLAVE_CFG(id.inst).SLAVE_TEST_LEN-1) and ATE_SLAVE_CFG(id.inst).S_LAST_STIM_MODE = TEST_END then
			s_last	<= '1';
		elsif ATE_SLAVE_CFG(id.inst).S_LAST_STIM_MODE = LAST_STORE then
			s_last	<= slave_last_store(I);
		end if;

		--
		-- [NEW] Determine the s_valid_v value on the basis of the MODE
		-- INIT
			case ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE is
			when TIED_TO_VCC =>
					s_valid_v := '1';
			when PRNG =>
					s_valid_v	:= rand_bit(SLAVE_LFSR_ID);
			when FULL_PRNG =>
					s_valid_v	:= rand_bit(SLAVE_LFSR_ID);
			when USER_VECTOR =>
					s_valid_v	:= s_valid_usr_vec(usr_vec_idx);
					usr_vec_idx := usr_vec_idx + 1;
			when others =>
				assert false
				report " [SLAVE]   unsupported s_valid stim mode"
				severity failure;
			end case;
		-- [NEW] END

		store_data := slave_store((s_data'length)*((i mod ATE_SLAVE_CFG(id.inst).SLAVE_STORE_LEN)+1)-1
			downto (s_data'length)*(i mod ATE_SLAVE_CFG(id.inst).SLAVE_STORE_LEN));
		s_data	<= store_data;
		store_keep := slave_keep_store((s_keep'length)*(I+1)-1 downto (s_keep'length)*I);
		s_keep	<= store_keep;
		s_valid	<= s_valid_v;
		-- Data is accpted every time eady is high
--		if ((ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE = TIED_TO_VCC) or (ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE = PRNG)) and (s_valid_v = '1') then
		if (ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE = TIED_TO_VCC)  then
			wait until rising_edge(clk) and s_ready = '1';
		end if;


--		if ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE = FULL_PRNG or ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE = USER_VECTOR then
		if ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE /= TIED_TO_VCC then
			-- But if valid was not high it neccessary to set it
			if s_valid_v /= '1' then
				while true loop
					case ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE is
					when PRNG =>
						PRINT_TO_SCREEN_PROC(SLAVE_E, 0, "PRNG s_valid POST clk & s_ready");
							s_valid_v	:= rand_bit(SLAVE_LFSR_ID);
					when FULL_PRNG =>
						PRINT_TO_SCREEN_PROC(SLAVE_E, 0, "FULL_PRNG s_valid POST clk & s_ready");
							s_valid_v	:= rand_bit(SLAVE_LFSR_ID);
					when USER_VECTOR =>
						PRINT_TO_SCREEN_PROC(SLAVE_E, 0, "USER_VECTOR s_valid POST clk & s_ready");
							s_valid_v	:= s_valid_usr_vec(usr_vec_idx);
							usr_vec_idx := usr_vec_idx + 1;
					when others =>
						assert false
						report " [SLAVE]   unsupported s_valid stim mode"
						severity failure;
					end case;
					s_valid <= s_valid_v;
					if ATE_SLAVE_CFG(id.inst).S_VALID_STIM_MODE = PRNG and s_valid_v = '1' then
						wait until rising_edge(clk) and s_ready = '1';
						exit when true;
					else
						wait until rising_edge(clk);
						exit when s_valid_v = '1' and s_ready = '1';
					end if;
				end loop; -- valid wait for high LOOP
			-- if valid was high just wait for ready
			else
				wait until rising_edge(clk) and s_ready = '1';
			end if;
		end if;

		-- Check if values in store are defined (accounting keep value)
		if ATE_SLAVE_CFG(id.inst).USE_SLAVE_KEEP then
			store_data := axi_st_zero_mask(store_data, store_keep);
		end if;
		assert not Is_X(store_data)
			report fail_msg(id, "Data in store is X", "ATE_S_STIM")
			severity failure;
	end loop; -- MAIN loop

	-- Assign X to indicate invalid data
	s_data	<= DATA_DEF;
	s_keep	<= KEEP_DEF;
	s_last		<= '0';
	s_valid_v	:= '0';
	s_valid		<= '0';
	-- Stimulus finished
--	report " [SLAVE]   stimulus finished";
	PRINT_TO_SCREEN_PROC(SLAVE_E, 0, "going back to ATE_STATE_IDLE...");
	ATE_SET_STATE(id, ATE_STATE_IDLE);

end procedure;
procedure ATE_S_STIM(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal s			: inout axi_st;
	inst_id				: inst_t ) is
begin
	ATE_S_STIM(clk, rst, s.data, s.keep, s.valid, s.last, s.ready, inst_id);
end procedure;
procedure FILL_S_VALID_USR_VEC(
	INDEX	: natural;
	DATA	: std_logic
) is begin
	s_valid_usr_vec(index) := data;
end procedure;

procedure FILL_SLAVE_KEEP_STORE(
	INDEX	: natural;
	DATA	: std_logic_vector
) is begin
	slave_keep_store((INDEX+1)*(DATA'length)-1 downto INDEX*(DATA'length)) := DATA;
end procedure;

procedure FILL_SLAVE_LAST_STORE(
	NUMBER	: natural;
	OFFSET  : natural
) is begin
	for N in 1 to NUMBER loop
		slave_last_store(N*OFFSET-1) := '1';
	end loop;
end procedure;
procedure RESET_SLAVE_LAST_STORE is begin
	slave_last_store	:= (others => '0');
end procedure;
--function ate_prng_slave_keep_store(
--	KEEP_WIDTH				: natural;
--	combinations 		: std_logic_vector
--
--)
--

-------------------------------------------------------------------------------
--  MASTER  -------------------------------------------------------------------
-------------------------------------------------------------------------------
impure function read_master_store(
	INDEX	: natural;
	WIDTH	: natural
) return std_logic_vector is begin
	return master_store(TEMP_DEF_MASTER_STORE_ID)((INDEX+1)*(WIDTH)-1 downto INDEX*(WIDTH));
end function;
procedure CLONE_MASTER_STORE(
	INDEX	: natural;
	WIDTH	: natural
) is begin
	for I in 1 to INDEX+1 loop
		master_store(TEMP_DEF_MASTER_STORE_ID)((I+INDEX+1)*(WIDTH)-1 downto (I+INDEX)*(WIDTH))
			:= master_store(TEMP_DEF_MASTER_STORE_ID)((I)*(WIDTH)-1 downto (I-1)*(WIDTH));
	end loop;
end procedure;
procedure UNIFY_STORES( source : interface_t) is begin
	if source = MASTER_E then
		slave_store := master_store(TEMP_DEF_MASTER_STORE_ID);
	elsif source = SLAVE_E then
		master_store(TEMP_DEF_MASTER_STORE_ID) := slave_store;
	else
		assert false
		  report "UNIFY_STORES proc wrong interface. Shuold be MASTER_E or SLAVE_E"
		  severity failure;
	end if;
end procedure;
procedure UNIFY_STORES(
	source			: interface_t;
	master_width	: natural;
	slave_width 	: natural
) is
	variable width_ratio : natural;
begin
	-- Master bigger -> slave is the source
	if master_width > slave_width then
		width_ratio := master_width / slave_width;
		for S in 0 to (SLAVE_STORE_WIDTH / MASTER_WIDTH) -1 loop
			master_store(TEMP_DEF_MASTER_STORE_ID)((S+1)*MASTER_WIDTH-1 downto S*MASTER_WIDTH) :=
				reverse_bytes(slave_store((S+1)*MASTER_WIDTH-1 downto S*MASTER_WIDTH));
		end loop;
	end if;
--
--	elsif slave_width > master_width then
--		width_ratio := master_width / slave_width;
--
--	if source = MASTER_E then
--		slave_store := master_store;
--	elsif source = SLAVE_E then
--		master_store := slave_store;
--	else
--		assert false
--		  report "UNIFY_STORES proc wrong interface. Shuold be MASTER_E or SLAVE_E"
--		  severity failure;
--	end if;
end procedure;
--procedure FILL_STORES_INC_DATA(
--	LENGTH		: natural;
--	START_DATA	: natural;
--	SLAVE_WIDTH	: natural;
--	MASTER_WIDTH : natural
--) is
--	variable width_ratio : natural;
--	variable temp		: std_logic_vector;
--begin

--if MASTER_WIDTH > SLAVE_WIDTH then
----	width_ratio := MASTER_WIDTH / SLAVE_WIDTH;

--	-- Fill smaller store
--	for I in 0 to LENGTH-1 loop
--		slave_store((I+1)*(DATA'length)-1 downto I*(DATA'length)) := START_DATA+I;
--	end loop;
--
--	-- Fill biget store on the basis of smaller stre
--	for I in 0 to LENGTH/width_ratio-1 loop
--		master_store((I+1)*MASTER_WIDTH-1 downto I*MASTER_WIDTH) :=
--			reverse_bytes( 	slave_store((I+1)*MASTER_WIDTH-1 downto I*MASTER_WIDTH));
--	end loop;
--end if;

--end procedure;

procedure FILL_M_READY_USR_VEC(
	INDEX	: natural;
	DATA	: std_logic
) is begin
	m_ready_usr_vec(index) := data;
end procedure;
-- Set the n NUMBER of ones with gap equal to OFFSET:
-- N = 3 O = 2 => 10  10  10
-- N = 3 O = 3 => 100 100 100
-- N = 1 0 = 3 =>         100
-- LAST it the additional last offset diffrent than previous offsets
procedure FILL_MASTER_LAST_STORE(
	NUMBER	: natural;
	OFFSET  : natural
) is begin
	master_last_store	:= (others => '0');
	for N in 1 to NUMBER loop
		master_last_store(N*OFFSET-1) := '1';
	end loop;
end procedure;
procedure FILL_LAST_STORE(
	inter	: interface_t;
	NUMBER	: natural;
	OFFSET  : natural
) is
	variable store: std_logic_vector(STORE_WIDTH-1 downto 0) := (others => '0');
begin
	for N in 1 to NUMBER loop
		store(N*OFFSET-1) := '1';
	end loop;
	ASSIGN_TO_LAST_STORE(inter, 1, store);
--	case inter is
--	when MASTER_E =>
--		master_last_store	:= (others => '0');
--		for N in 1 to NUMBER loop
--			master_last_store(N*OFFSET-1) := '1';
--		end loop;
--	when SLAVE_E =>
--		slave_last_store	:= (others => '0');
--		for N in 1 to NUMBER loop
--			slave_last_store(N*OFFSET-1) := '1';
--		end loop;
--	when BOTH_E =>
--		master_last_store	:= (others => '0');
--		for N in 1 to NUMBER loop
--			master_last_store(N*OFFSET-1) := '1';
--		end loop;
--		slave_last_store	:= (others => '0');
--		for N in 1 to NUMBER loop
--			slave_last_store(N*OFFSET-1) := '1';
--		end loop;
--	end case;
end procedure;
procedure FILL_LAST_STORE(
	inter	: interface_t;
	NUMBER	: natural;
	OFFSET  : natural;
	LAST	: natural
) is
	variable store: std_logic_vector(STORE_WIDTH-1 downto 0) := (others => '0');
begin
	for N in 1 to NUMBER loop
		store(N*OFFSET-1) := '1';
	end loop;
	store(NUMBER*OFFSET-1 + LAST) := '1';
	ASSIGN_TO_LAST_STORE(inter, 1, store);
end procedure;
procedure RESET_MASTER_LAST_STORE is begin
	master_last_store	:= (others => '0');
end procedure;
procedure RESET_LAST_STORE(
	inter	: interface_t
) is
begin
	case inter is
		when MASTER_E =>
			master_last_store	:= (others => '0');
		when SLAVE_E =>
			slave_last_store	:= (others => '0');
		when BOTH_E =>
			master_last_store	:= (others => '0');
			slave_last_store	:= (others => '0');
		when others =>
			FAIL_WRONG_INTERFACE("ASSIGN_TO_STORE");
	end case;
end procedure;
procedure ATE_M_VERIF(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m_data		: in std_logic_vector;
	signal m_keep		: in std_logic_vector;
	signal m_valid		: in std_logic;
	signal m_last		: in std_logic;
	signal m_ready		: in std_logic;
	inst_id				: natural ) is
	variable last_nat	: natural := 0;
	variable last_store_nat	: natural := 0;
	variable store_slv	: std_logic_vector(m_data'high downto m_data'low);
	variable compare_data	: std_logic_vector(m_data'high downto m_data'low);
	variable keep_mask	: std_logic_vector(m_data'range);
	variable m_data_v	: std_logic_vector(m_data'range);
	variable id			: id_t;
	variable store_h	: natural;
	variable store_l	: natural;
	constant DAT_SL_RATIO	: positive := m_data'length / ATE_MASTER_CFG(inst_id).MASTER_SLICE_WIDTH;
	variable reduced_keep	: std_logic_vector(DAT_SL_RATIO -1 downto 0);
	variable cnt_pat_index	: natural range 0 to ATE_MASTER_CFG(inst_id).MASTER_TEST_LEN*DAT_SL_RATIO-1;
--	constant M_SLICE_WIDTH	: integer range 1 to MAX_DATA_WIDTH-1 := ATE_MASTER_CFG(inst_id).MASTER_SLICE_WIDTH;
	-- for file reading
	file f     			: text;
	variable l          : line;
	variable v_data_read  : integer;
begin
	-- Assign def value for ready stim stop
	stop_m_ready_stim(inst_id) := true;



	SET_LAST_MASTER(inst_id);
	id.inter := MASTER_E;
	id.inst	 := inst_id;
	id.test  := ATE_M_TEST_ID;

	PRINT_TO_SCREEN_PROC(MASTER_E, inst_id, "waiting for ATE_STATE_RUN state...");
	ATE_WAIT_ON_STATE(id, ATE_STATE_RUN);

	-- Wait for reset deassertion
	wait until rising_edge(clk) and rst = '0';
	-- Enable generation of s_valid signal
	stop_m_ready_stim(inst_id) := false;

	if ATE_MASTER_CFG(inst_id).MASTER_DATA_SOURCE = FILE_DATA_SOURCE then
		file_open (f, "master_store.dat", READ_MODE);
		readline(f, l);
	end if;

	-- Test loop
	for I in 0 to ATE_MASTER_CFG(inst_id).MASTER_TEST_LEN-1 loop
		id.trans := i;
		wait until rising_edge(clk) and m_valid = '1' and m_ready = '1';
		-- Check for non-std values in m_data. Mask invalid bits with usage of
		-- keep  signal.

		if ATE_MASTER_CFG(inst_id).USE_MASTER_KEEP then
			keep_mask := axi_st_mask(m_keep);
			for j in m_data'range loop
				if keep_mask(j) = '0' then
					m_data_v(j) := '0';
				elsif keep_mask(j) = '1' then
					m_data_v(j) := m_data(j);
				else
					assert false
					report " <<< FAILURE >>> inst: " & natural'image(inst_id) & "  |  test: " &
					natural'image(ATE_M_TEST_ID) &
					"Non 01 keep value"
					severity failure;
				end if;
			end loop;
		else
			m_data_v := m_data;
		end if;

		-- Check for non-std values in m_data.
		assert not Is_X(m_data_v)
		  report " <<< FAILURE >>> " & natural'image(inst_id) & "." &
		  natural'image(ATE_M_TEST_ID) &
		  "m_data is non '0' neither '1' value."
		  severity failure;
		-- Convert to natural for viewing
--		data <= slave_store((m_data'length)*(I+1)-1 downto (m_data'length)*I);
		last_nat	:= to_natural(m_last);
		store_h := (m_data_v'length)*((I mod ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN)+1)-1;
		store_l := (m_data_v'length)*(I mod ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN);
		store_slv	:= master_store(id.inst)( store_h downto store_l);
		last_store_nat	:= to_natural(master_last_store(I));


		-- Compare received val with master store. Using std_match instead of
		-- = operator to support for '-' (dont care) values in master store
--		report " <<< DBG >>> iteration: "	& integer'image(I);
		case ATE_MASTER_CFG(inst_id).MASTER_DATA_SOURCE is
		when STORE_DATA_SOURCE =>
			assert std_match(store_slv, m_data_v)
				report fail_msg(id, fail_msg_data(m_data_v, store_slv, i), "ATE_M_VERIF")
				severity failure;

		when FILE_DATA_SOURCE =>
			hread(l, compare_data);
--			report "file hread: "&hstr(compare_data);
			store_h := (m_data_v'length)*((I mod ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN)+1)-1;
			store_l := (m_data_v'length)*(I mod ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN);
			master_store(id.inst)( store_h downto store_l) := compare_data;
			assert std_match(compare_data, m_data_v)
				report fail_msg(id, fail_msg_data(m_data_v, compare_data, i), "ATE_M_VERIF")
				severity failure;

		when CNT_PAT_DATA_SOURCE =>
			if ATE_MASTER_CFG(inst_id).USE_MASTER_KEEP then
	--			assert std_match(m_data_v(),)
				-- Verif only sliced valid (keeped) data with counter paatern
				reduced_keep := axi_st_reduce_keep(m_data_v'length, ATE_MASTER_CFG(inst_id).MASTER_SLICE_WIDTH, m_keep);
				-- Start loop from right to left.
				-- TO DO: it sholud be configurable
				for j in reduced_keep'reverse_range loop
	--			for j in 0 to reduced_keep'length-1 loop
					if reduced_keep(j) = '1' then
						assert std_match(std_logic_vector(to_unsigned(cnt_pat_index + ATE_COMMON_CFG.MAGIC_NUM,
						ATE_MASTER_CFG(inst_id).MASTER_SLICE_WIDTH)),
						-- Below works
	--					m_data_v(slice_range(j, ATE_MASTER_CFG(inst_id).MASTER_SLICE_WIDTH)'range))
						m_data_v(sih(j, ATE_MASTER_CFG(inst_id).MASTER_SLICE_WIDTH) downto sil(j, ATE_MASTER_CFG(inst_id).MASTER_SLICE_WIDTH)))
						report fail_msg(id, fail_msg_data(m_data_v, store_slv, i), "ATE_M_VERIF")
						severity failure;
						cnt_pat_index := cnt_pat_index+1;
					end if;
				end loop;
			elsif not ATE_MASTER_CFG(inst_id).USE_MASTER_KEEP then
				assert false
				report fail_msg(id, "not supp", "ATE_M_VERIF")
				severity failure;
			end if;

		when NULL_DATA_SOURCE =>
			-- dont compare data
		end case;
		-- Check for last signal
		if ATE_MASTER_CFG(inst_id).VERIF_MASTER_LAST then
			assert m_last = master_last_store(I)
			report fail_msg(id, "last="&integer'image(last_nat)&
					", expected "&integer'image(last_store_nat),
					"ATE_M_VERIF")
			severity failure;
		end if;
	end loop;

	wait until rising_edge(clk);
	stop_m_ready_stim(inst_id) := true;

	-- Stimulus finished
	PRINT_TO_SCREEN_PROC(MASTER_E, inst_id, "verify finished, entering ATE_STATE_IDLE state");
	ATE_SET_STATE(id, ATE_STATE_IDLE);
	INC_TEST_ID(inst_id);
end procedure;

procedure ATE_M_VERIF(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m			: in axi_st;
	inst_id				: natural ) is
begin
	ATE_M_VERIF(clk, rst, m.data, m.keep, m.valid, m.last, m.ready, inst_id);
end procedure;


-- Stimulus of master ready signal
procedure M_READY_STIM_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m_valid		: in std_logic;	-- currently not in use
	signal m_ready		: out std_logic;
	inst_id				: natural ) is
	variable usr_vec_idx	: natural := 0;
	variable id			: id_t;
begin
	id.inter := MASTER_E;
	id.inst := inst_id;
	id.test := ATE_M_TEST_ID;

-- Sync to rst to get the possbile change of configuration
	wait until rising_edge(clk) and rst = '0';
	m_ready <= ATE_MASTER_CFG(inst_id).M_READY_DEF_VAL;

-- Sync to trigger
	ATE_WAIT_ON_STATE(id, ATE_STATE_RUN);

	case ATE_MASTER_CFG(inst_id).M_READY_STIM_MODE is
	when TIED_TO_VCC =>
		PRINT_TO_SCREEN_PROC(MASTER_E, inst_id, "started m_ready stim in TIED_TO_VCC mode");
			m_ready	<= ATE_MASTER_CFG(inst_id).M_READY_DEF_VAL; -- Init value
		-- Sync to clk and rst
		wait until rising_edge(clk) and rst = '0';
			m_ready <= '1';
		wait until rising_edge(clk); -- One clk delay
		-- Main loop. It has to be done in loop (wait until not working here!)
		while not stop_m_ready_stim(inst_id) loop
			wait until rising_edge(clk); -- Sync to clk
		end loop;
		-- Sync to clk
		wait until rising_edge(clk);
			m_ready	<= ATE_MASTER_CFG(inst_id).M_READY_DEF_VAL;
--		report " [MASTER DBG]   finished m_ready stim in TIED_TO_VCC mode";

	when PRNG =>
		PRINT_TO_SCREEN_PROC(MASTER_E, inst_id, "started m_ready stim in PRNG mode");
		-- Inittial values
			m_ready	<= '0';
		wait until rising_edge(clk) and rst = '0'; -- sync to rst
		wait until rising_edge(clk); -- sync to clk and delay
		-- Main loop
		while not stop_m_ready_stim(inst_id) loop
				m_ready	<= rand_bit(MASTER_LFSR_ID);
			wait until rising_edge(clk);
		end loop;
			-- Leaving value
			m_ready <= '0';

	when USER_VECTOR =>
		-- Inittial values
			m_ready	<= '0';
		wait until rising_edge(clk) and rst = '0'; -- sync to rst
		wait until rising_edge(clk); -- sync to clk and delay
		-- Loop
		usr_vec_idx := 0;
		while not stop_m_ready_stim(inst_id) loop
				m_ready	<= m_ready_usr_vec(usr_vec_idx);
				usr_vec_idx := usr_vec_idx + 1;
			wait until rising_edge(clk);
		end loop;


	when others =>
		assert false
		report " [MASTER]   unsupported m_ready stim mode"
		severity failure;
	end case;
-- Sync to trigger
	ATE_WAIT_ON_STATE(id, ATE_STATE_IDLE);
end procedure;
procedure M_READY_STIM_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m			: inout axi_st;
	inst_id				: natural) is
begin
	M_READY_STIM_PROC(clk, rst, m.valid, m.ready, inst_id);
end procedure;

-- TODO rename to ATE_WATCHDOG
-- Checking for ATE internal errors and violations
procedure MASTER_WATCHDOG_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m_data		: in std_logic_vector;
	signal m_valid		: in std_logic;
	signal m_ready		: in std_logic;
	inst_id				: natural ) is
	variable m_store	: std_logic_vector(m_data'high downto m_data'low);
	variable ret		: boolean;
	variable id			: id_t;
begin
	id.inter := MASTER_E;
	id.inst	:= inst_id;
	id.test := ATE_M_TEST_ID;

	-- Bypass self procedure beacsue probalby already in ATE_STATE_RUN
	--ATE_WAIT_ON_STATE(id, ATE_STATE_RUN);
	ATE_WAIT_UNTIL_STATE(id, ATE_STATE_RUN);

	assert ATE_MASTER_CFG(inst_id).MASTER_TEST_LEN /=0 and ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN /= 0
		report fail_msg(id, "test len no set", "MASTER_WATCHDOG_PROC")
		severity failure;

	-- LOG the content of MASTER STORE
	WRITE_LOG_PROC(id, "master"&natural'image(inst_id)& " test: "&
			natural'image(ATE_M_TEST_ID)&"   Content of data store:", false);
	for I in 0 to ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN-1 loop
		m_store := master_store(inst_id)((m_data'length)*(I+1)-1 downto (m_data'length)*I);
		WRITE_LOG_PROC(id, ("STORE[" & integer'image(I) & "]   "), false, m_store);
	end loop;

	-- Log the content of LAST STORE when enabled
	if ATE_MASTER_CFG(inst_id).VERIF_MASTER_LAST then
			WRITE_LOG_PROC(id, "LAST_STORE =", false, master_last_store(ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN-1 downto 0));
	end if;

	-- Check for U values in store
	if ATE_MASTER_CFG(inst_id).MASTER_DATA_SOURCE = STORE_DATA_SOURCE then
--		ret := check_store(inst_id, ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN, m_data'length, String'(" [MASTER] "));
		ret := check_store(inst_id, ATE_MASTER_CFG(inst_id).MASTER_STORE_LEN,
			m_data'length, fail_msg(id, "there is 'U' in store. Compare result will be always false", "MASTER_WATCHDOG_PROC"));
	end if;

	-- Checking for TIMEOUT condition
	for I in 0 to ATE_MASTER_CFG(inst_id).MASTER_TEST_LEN-1 loop
		wait until rising_edge(clk) and m_valid = '1' and m_ready = '1' for ATE_MASTER_CFG(inst_id).MASTER_TIMEOUT;
		-- Event not detectef for TIMEOUT time
			assert m_valid = '1' and m_ready = '1'
			 report " [MASTER " & natural'image(inst_id) & " ] Exceeded TIMEOUT at index: " & integer'image(I)
			 severity failure;
	end loop;

	-- Also check if DUT dont left m_valid asserted, after required test length.
	-- Only if enabled.
	if ATE_MASTER_CFG(inst_id).MASTER_QUIT_TEST then
		-- UUT can assert valid even after test. Implementation of state_based
		-- checking
		while true loop
			wait until rising_edge(clk);
			assert m_valid = '0'
				report fail_msg(id, "UUT master interface assrted valid when ATE_STATE_IDLE", "ATE_MASTER_WATCHDOG")
				severity ATE_MASTER_CFG(id.inst).MASTER_QUIT_TEST_SEV;
			exit when ATE_M_STATE(id.inst) = ATE_STATE_RUN;
		end loop;
	end if;


end procedure;
procedure MASTER_WATCHDOG_PROC(
	signal clk			: in std_logic;
	signal rst			: in std_logic;
	signal m			: in axi_st;
	inst_id				: natural ) is
begin
	MASTER_WATCHDOG_PROC(clk, rst, m.data, m.valid, m.ready, inst_id);
end procedure;


--------------------------------------------------------------------------------
--  MISC  ----------------------------------------------------------------------
--------------------------------------------------------------------------------
procedure ATE_SET_USE_LAST(
	inter		: interface_t;
	inst		: inst_t;
	arg			: boolean) is
begin
	if inter = MASTER_E then
		ATE_MASTER_CFG(inst).VERIF_MASTER_LAST	:= arg;
	else
		assert false
		 report "procedure ATE_SET_USE_LASTwrong interface. Possbile args: MASTER_E"
		 severity failure;
	end if;
end procedure;
procedure ATE_SET_USE_LAST(
	inter		: interface_t;
	arg			: boolean) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_SET_USE_LAST(inter, i, arg);
	end loop;
end procedure;


procedure ATE_SET_USE_KEEP(
	inter		: interface_t;
	inst		: inst_t;
	arg			: boolean) is
begin
	if inter = BOTH_E then
		ATE_MASTER_CFG(inst).USE_MASTER_KEEP	:= arg;
		ATE_SLAVE_CFG(inst).USE_SLAVE_KEEP	:= arg;
	elsif inter = MASTER_E then
		ATE_MASTER_CFG(inst).USE_MASTER_KEEP	:= arg;
	elsif inter = SLAVE_E then
		ATE_SLAVE_CFG(inst).USE_SLAVE_KEEP	:= arg;
	end if;
end procedure;
procedure ATE_SET_USE_KEEP(
	inter		: interface_t;
	arg			: boolean) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_SET_USE_KEEP(inter, i, arg);
	end loop;
end procedure;


procedure ATE_SET_DATA_SOURCE(
	inter		: interface_t;
	inst		: inst_t;
	arg			: ate_data_source_t) is
begin
	if inter = BOTH_E then
		ATE_MASTER_CFG(inst).MASTER_DATA_SOURCE	:= arg;
		ATE_SLAVE_CFG(inst).SLAVE_DATA_SOURCE	:= arg;
	elsif inter = MASTER_E then
		ATE_MASTER_CFG(inst).MASTER_DATA_SOURCE	:= arg;
	elsif inter = SLAVE_E then
		ATE_SLAVE_CFG(inst).SLAVE_DATA_SOURCE	:= arg;
	end if;
end procedure;
procedure ATE_SET_DATA_SOURCE(
	inter		: interface_t;
	arg			: ate_data_source_t) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_SET_DATA_SOURCE(inter, i, arg);
	end loop;
end procedure;

procedure ATE_SET_STIM_MODE(
	inter	: interface_t;
	inst	: inst_t;
	mode	: stim_mode_t) is
begin
	if inter = BOTH_E then
		ATE_MASTER_CFG(inst).M_READY_STIM_MODE	:= mode;
		ATE_SLAVE_CFG(inst).S_VALID_STIM_MODE	:= mode;
	elsif inter = MASTER_E then
		ATE_MASTER_CFG(inst).M_READY_STIM_MODE	:= mode;
	elsif inter = SLAVE_E then
		ATE_SLAVE_CFG(inst).S_VALID_STIM_MODE	:= mode;
	end if;
end procedure;
procedure ATE_SET_STIM_MODE(
	inter	: interface_t;
	mode	: stim_mode_t) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_SET_STIM_MODE(inter, i, mode);
	end loop;
end procedure;

procedure ATE_SET_TEST_LEN(
	inter : interface_t;
	inst : inst_t;
	len	: positive) is
begin
	if inter = BOTH_E then
		ATE_MASTER_CFG(inst).MASTER_TEST_LEN := len;
		ATE_MASTER_CFG(inst).MASTER_STORE_LEN := len;
		ATE_SLAVE_CFG(inst).SLAVE_TEST_LEN	:= len;
		ATE_SLAVE_CFG(inst).SLAVE_STORE_LEN	:= len;
	elsif inter = MASTER_E then
		ATE_MASTER_CFG(inst).MASTER_STORE_LEN := len;
		ATE_MASTER_CFG(inst).MASTER_TEST_LEN := len;
	elsif inter = SLAVE_E then
		ATE_SLAVE_CFG(inst).SLAVE_TEST_LEN := len;
		ATE_SLAVE_CFG(inst).SLAVE_STORE_LEN := len;
	else
		assert false
		 report "procedure ATE_SET_TEST_LEN wrong interface. Possbile args: MASTER_E, SLAVE_E, BOTH_E"
		 severity failure;
	end if;
end procedure;
procedure ATE_SET_TEST_LEN(
	inter : interface_t;
	len	: positive) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_SET_TEST_LEN(inter, i, len);
	end loop;
end procedure;

procedure ATE_SET_TEST_LEN(
	inter		: interface_t;
	inst		: inst_t;
	len			: positive;
	store_len	: positive) is
begin
-- DEFAULT
	ATE_SET_TEST_LEN(inter, inst, len);

	if inter = MASTER_E then
		ATE_MASTER_CFG(inst).MASTER_STORE_LEN := store_len;
	elsif inter = SLAVE_E then
		ATE_SLAVE_CFG(inst).SLAVE_STORE_LEN := store_len;
	elsif inter = BOTH_E then
		ATE_SLAVE_CFG(inst).SLAVE_STORE_LEN := store_len;
		ATE_MASTER_CFG(inst).MASTER_STORE_LEN := store_len;
	else
		assert false
		 report "procedure ATE_SET_TEST_LEN wrong interface. Possbile args: MASTER_E, SLAVE_E, BOTH_E"
		 severity failure;
	end if;
end procedure;
procedure ATE_SET_TEST_LEN(
	inter		: interface_t;
	len			: positive;
	store_len	: positive;
	null_arg	: boolean) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_SET_TEST_LEN(inter, i, len, store_len);
	end loop;
end procedure;

procedure ATE_SET_ATE_VERBOSE(arg : boolean) is
begin
	if arg then
		ATE_COMMON_CFG.VERBOSE := true;
	else
		ATE_COMMON_CFG.VERBOSE := false;
	end if;
end procedure;

--procedure AXIS_INTERFACE_TEST_PROC(
--	TEST_LEN			: natural;
--	clk					: in std_logic;
--	rst					: in std_logic;
--
--	signal s_data		: out std_logic_vector;
--	signal s_valid		: out std_logic;
--	signal s_ready		: in std_logic;
--
--	signal m_data		: in std_logic_vector;
--	signal m_valid		: in std_logic;
--	signal m_ready		: out std_logic
--) is begin
--	-- Trigger s_valid generator
--
--end procedure;

impure function use_keep(
	 id : id_t
	) return boolean is
	variable v : natural := 0;
begin
	case id.inter is
	when MASTER_E =>
		return ATE_MASTER_CFG(id.inst).USE_MASTER_KEEP;
	when SLAVE_E =>
		return ATE_SLAVE_CFG(id.inst).USE_SLAVE_KEEP;
	when others =>
		FAIL_WRONG_INTERFACE("use_keep");
		return false;
	end case;
end function;

procedure CHECK_X(
	id			: id_t;
	valid		: in std_logic;
	ready		: in std_logic;
	keep		: in std_logic_vector ) is
begin
	if ATE_COMMON_CFG.CHECK_FOR_X_STATES then
		assert not Is_X(valid)
			report fail_msg(id, "valid is X", "CHECK_X")
			severity failure;
		assert not Is_X(ready)
			report fail_msg(id, "ready is X",  "CHECK_X")
			severity failure;
		-- keep default value after  reset CAN be X
		if not Is_X(ATE_SLAVE_CFG(id.inst).S_KEEP_DEF_VAL)  and use_keep(id) then
			assert not Is_X(keep)
				report fail_msg(id, "keep is X",  "CHECK_X")
				severity failure;
		end if;
		-- Bu i never can be X when transaction is performed
		if valid = '1' and ready = '1'  and use_keep(id) then
			assert not Is_X(keep)
				report fail_msg(id, "keep is X",  "CHECK_X")
				severity failure;
		end if;
	end if;
end procedure;

procedure CHECK_KEEP0_VALID1(
	id			: id_t;
	valid		: in std_logic;
	ready		: in std_logic;
	keep		: in std_logic_vector ) is
begin

	if ATE_COMMON_CFG.CHECK_KEEP0_VALID1 and use_keep(id) then
		if valid = '1' and ready = '1' then
			assert or_reduce(keep) /= '0'
			report fail_msg(id, "keep is zeros when valid high", "CHECK_KEEP0_VALID1")
			severity failure;
		end if;
	end if;
end procedure;


-- Below procedure is for looking for AXI-St protocol violations ate Master interfaces
procedure ATE_M_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal m_data		: in std_logic_vector;
	signal m_keep		: in std_logic_vector;
	signal m_valid		: in std_logic;
	signal m_ready		: in std_logic;
	inst_id		: natural ) is
	variable id	: id_t;
begin
	id.inter := MASTER_E;
	id.inst := inst_id;
	id.test	:= ATE_M_TEST_ID;

	wait until rising_edge(clk) and rst = '0';
	CHECK_X(id, m_valid, m_ready, m_keep);
	CHECK_KEEP0_VALID1(id, m_valid, m_ready, m_keep);


-- Check for U data when valid high
	if m_valid = '1' then
		if ATE_MASTER_CFG(inst_id).USE_MASTER_KEEP then
			assert not Is_X(axi_st_zero_mask(m_data, m_keep))
				report fail_msg(id, "Data is X when valid and keep high", "ATE_M_WATCHDOG")
				severity failure;
		else
			assert not Is_X(m_data)
				report fail_msg(id, "Data is X when valid high", "ATE_M_WATCHDOG")
				severity failure;
		end if;
	end if;

-- Check for last when not valid
--	if m_valid = '1' and

-- MASTER integrity. Check for changing data while valid is high
	if m_valid = '1' then
		-- Save data, set flag
		if m_ready = '0' and not wg_check_flag then
			wg_check_flag 	:= true;
			wg_data_v(m_data'range)		:= m_data;
		end if;

		if m_ready = '0' and wg_check_flag then
			assert m_data = wg_data_v(m_data'range)
			 report fail_msg(id, "Data changed when valid high", "ATE_M_WATCHDOG")
			 severity ATE_COMMON_CFG.INTEGRITY_SEVERITY_LEV;
		 	wg_check_flag 	:= false;
		end if;
	end if;


end procedure;
procedure ATE_M_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal m	: in axi_st;
	inst_id		: natural ) is
begin
	ATE_M_WATCHDOG(WIDTH, clk, rst, m.data, m.keep, m.valid, m.ready, inst_id);
end procedure;

-- Below procedure is for looking for AXI-St protocol violations at Slave interfaces
procedure ATE_S_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal s_data		: in std_logic_vector;
	signal s_keep		: in std_logic_vector;
	signal s_valid		: in std_logic;
	signal s_ready		: in std_logic;
	inst_id		: natural ) is
	variable id	: id_t;
begin
	id.inter := SLAVE_E;
	id.inst := inst_id;
	id.test	:= 1;

	wait until rising_edge(clk) and rst = '0';
	CHECK_X(id, s_valid, s_ready, s_keep);
	CHECK_KEEP0_VALID1(id, s_valid, s_ready, s_keep);

-- OPTIONAL SLAVE integrity. Check check if s_valid is deasserten when s_ready was not
-- high
	if ATE_SLAVE_CFG(id.inst).VERIF_S_VALID_INTEGRITY then
		-- valid just asserted
		if s_valid = '1' then
			-- This is ok, data accepted
			if s_ready = '1' then
			 	wg_valid_ready_wait := false;
			-- Remeber to check if ready will be asserted in the next loops
			else
				wg_valid_ready_wait := true;
			end if;
		-- valid deasserted, but ready never high
		elsif s_valid = '0' and wg_valid_ready_wait then
			assert false
			 report fail_msg(id, "s_valid changed without s_ready", "ATE_M_WATCHDOG")
			 severity ATE_COMMON_CFG.INTEGRITY_SEVERITY_LEV;
		end if;
	end if;
end procedure;
procedure ATE_S_WATCHDOG(
	WIDTH		: natural;
	signal clk	: in std_logic;
	signal rst	: in std_logic;
	signal s	: in axi_st;
	inst_id		: natural) is
begin
	ATE_S_WATCHDOG(WIDTH, clk, rst, s.data, s.keep, s.valid, s.ready, inst_id);
end procedure;

procedure ATE_SHIFT_LFSR(
	inter 		: interface_t
) is
	variable lfsr_temp1 : std_logic_vector(LFSR_WIDTH-1 downto 0);
	variable lfsr_temp2 : std_logic_vector(LFSR_WIDTH-1 downto 0);

begin
	lfsr_temp1 := lfsr_state(MASTER_LFSR_ID);
	lfsr_temp2 := lfsr_state(SLAVE_LFSR_ID);

	if inter = MASTER_E then
		lfsr_state(MASTER_LFSR_ID) := std_logic_vector(rotate_left(unsigned(lfsr_temp1), 1));
	elsif inter = SLAVE_E then
		lfsr_state(SLAVE_LFSR_ID) := std_logic_vector(rotate_left(unsigned(lfsr_temp2), 1));
	elsif inter = BOTH_E then
		lfsr_state(MASTER_LFSR_ID) := std_logic_vector(rotate_left(unsigned(lfsr_temp1), 1));
		lfsr_state(SLAVE_LFSR_ID) := std_logic_vector(rotate_left(unsigned(lfsr_temp2), 1));
	else
		assert false
		  report "ATE_SHIFT_LFSR() wrong interface. Shuold be MASTER_E or SLAVE_E or BOTH_E"
		  severity failure;
	end if;
end procedure;

procedure ATE_SET_SEED(
	inter 		: interface_t;
	value		: std_logic_vector(LFSR_WIDTH-1 downto 0)
) is
begin
	if inter = MASTER_E then
		lfsr_state(MASTER_LFSR_ID) := value;
	elsif inter = SLAVE_E then
		lfsr_state(SLAVE_LFSR_ID) := value;
	elsif inter = BOTH_E then
		lfsr_state(MASTER_LFSR_ID) := value;
		lfsr_state(SLAVE_LFSR_ID) := value;
	else
		assert false
		  report "ATE_SHIFT_LFSR() wrong interface. Shuold be MASTER_E or SLAVE_E or BOTH_E"
		  severity failure;
	end if;
end procedure;
procedure ATE_SET_TIMEOUT(
	t 			: time
) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_MASTER_CFG(i).MASTER_TIMEOUT := t;
	end loop;
end procedure;
procedure ATE_SET_VERIF_MASTER_LAST(
	a 			: boolean
) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_MASTER_CFG(i).VERIF_MASTER_LAST := a;
	end loop;
end procedure;
procedure ATE_SET_MASTER_QUIT_TEST(
	enable		: boolean;
	sev			: severity_level
) is
begin
	for i in 1 to ATE_MAX_INST loop
		ATE_MASTER_CFG(i).MASTER_QUIT_TEST := enable;
		ATE_MASTER_CFG(i).MASTER_QUIT_TEST_SEV := sev;
	end loop;
end procedure;
procedure ATE_INCREMENT_SEED(
	inter 		: interface_t;
	value		: positive
) is
	variable lfsr_temp1 : std_logic_vector(LFSR_WIDTH-1 downto 0);
	variable lfsr_temp2 : std_logic_vector(LFSR_WIDTH-1 downto 0);

begin
	lfsr_temp1 := lfsr_state(MASTER_LFSR_ID);
	lfsr_temp2 := lfsr_state(SLAVE_LFSR_ID);

	if inter = MASTER_E then
		lfsr_state(MASTER_LFSR_ID) := std_logic_vector(unsigned(lfsr_temp1)+value);
	elsif inter = SLAVE_E then
		lfsr_state(SLAVE_LFSR_ID) := std_logic_vector(unsigned(lfsr_temp2)+value);
	elsif inter = BOTH_E then
		lfsr_state(MASTER_LFSR_ID) := std_logic_vector(unsigned(lfsr_temp1)+value);
		lfsr_state(SLAVE_LFSR_ID) := std_logic_vector(unsigned(lfsr_temp2)+value);
	else
		assert false
		  report "ATE_SHIFT_LFSR() wrong interface. Shuold be MASTER_E or SLAVE_E or BOTH_E"
		  severity failure;
	end if;
end procedure;
procedure ATE_INCREMENT_SEED(
	inter 		: interface_t
) is
begin
	ATE_INCREMENT_SEED(inter, 1);
end procedure;

procedure ATE_RESET_USER_VECTOR(
	inter 		: interface_t
) is begin
	if inter = MASTER_E then
		m_ready_usr_vec := (others => '1');
	elsif inter = SLAVE_E then
		s_valid_usr_vec := (others => '1');
	elsif inter = BOTH_E then
		m_ready_usr_vec := (others => '1');
		s_valid_usr_vec := (others => '1');
	else
		assert false
		  report "ATE_RESET_USER_VECTOR() wrong interface. Shuold be MASTER_E or SLAVE_E or BOTH_E"
		  severity failure;
	end if;
end procedure;



--procedure RECORD_TEST(
--	signal r		: inout axis_rec_t
--) is begin

--	wait until rising_edge(r.clk) and r.rst = '0';
--	r.valid <= '1';
--	r.last	<= '1';
--	r.keep	<= (others => '1');
--	r.data	<= (others => '1');
--end procedure;



end axis_test_env_pkg;
