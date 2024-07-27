library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! Classifies input data based on an upper (#max) and a lower (#min) threshold.

--! The output (#result) of the component is '1' if the input value lies in
--! between the upper and lower threshold.
entity classify is
    generic(
        VECTOR_LENGTH : positive    --! Bitwidth of the input data to classify
    );
    port (
        clk         : in std_logic;       --! Clock input
        data_in     : in std_logic_vector(VECTOR_LENGTH-1 downto 0);  --! Input data
        data_rdy    : in std_logic;     --! Input bit indicating if the input data (#data_in) is ready to be processed
        rstn        : in std_logic;     --! Negated asynchronous reset
        min         : in std_logic_vector(VECTOR_LENGTH-1 downto 0);  --! Lower threshold for classification
        max         : in std_logic_vector(VECTOR_LENGTH-1 downto 0);  --! Upper threshold for classification
        result_rdy  : out  std_logic;   --! Indicates whether the output (#result) represents a valid value
        result      : out  std_logic    --! The output value of the component
    );

end classify;

architecture rtl of classify is

    -- STUDENT CODE HERE
begin

    process(clk, rstn)

    variable data_int : unsigned(VECTOR_LENGTH-1 downto 0);
    variable min_int : unsigned(VECTOR_LENGTH-1 downto 0);
    variable max_int : unsigned(VECTOR_LENGTH-1 downto 0);


    begin
        if rstn = '0' then
            result <= '0';
            result_rdy <= '0';

        elsif rising_edge(clk) then

            if data_rdy = '1' then
                data_int := unsigned(data_in);
                min_int := unsigned(min);
                max_int := unsigned(max);
                
                if data_int >= min_int and data_int <= max_int then
                    result <= '1';
                    result_rdy <= '1';
                else
                    result <= '0';
                    result_rdy <= '1';
                end if;
                    
            else
                result_rdy <= '0';
            end if;
        end if;
    end process;


    -- STUDENT CODE until HERE

end rtl;

