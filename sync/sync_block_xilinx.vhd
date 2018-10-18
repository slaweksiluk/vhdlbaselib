-- Engineer: Slawomir Siluk slaweksiluk@gazeta.pl
-- Description:
--		 Xilinx FD primitive based architecture for sync_block entity
-- 15/12/17 Divided into vendors specific architectures:
--		TODO

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

architecture xilinx of sync_block is

  -- Internal Signals
  signal data_meta : std_logic;

  -- These attributes will stop timing errors being reported in back annotated
  -- SDF simulation.
  attribute ASYNC_REG               : string;
  attribute ASYNC_REG of data_meta : signal is "TRUE";
--  attribute RLOC      of data_meta : signal is "X0Y0";
  attribute SHREG_EXTRAC of data_meta 	: signal is "FALSE";    
  attribute RLOC of sync_reg1_inst: label is "X0Y0";
  attribute RLOC of sync_reg2_inst: label is "X0Y0";
begin


  sync_reg1_inst : FD
  generic map (
    INIT => INITIALISE(0)
  )
  port map (
    C    => clk,
    D    => data_in,
    Q    => data_meta
  );


  sync_reg2_inst : FD
  generic map (
    INIT => INITIALISE(1)
  )
  port map (
    C    => clk,
    D    => data_meta,
    Q    => data_out
  );


end xilinx;

