library vunit_lib;
context vunit_lib.vunit_context;
library vhdlbaselib;
use vhdlbaselib.axis_test_env_pkg.all;

entity tb_example is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_example is
begin
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    report "Hello world!";
    test_runner_cleanup(runner); -- Simulation ends here
  end process;
end architecture;
