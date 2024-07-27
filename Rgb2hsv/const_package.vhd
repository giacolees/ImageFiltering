library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package const_package is
    -- contant values for divisor, dividend and quotient:
    constant A_WIDTH      : POSITIVE := 17; -- dividend
    constant B_WIDTH      : POSITIVE := 8; -- divisor
    constant RESULT_WIDTH : POSITIVE := 9; -- quotient
end package;