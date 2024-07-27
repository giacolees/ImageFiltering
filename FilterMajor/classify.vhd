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

    -- This architecture contains a process to classify the input data based on given thresholds.
begin

    process(clk, rstn)
        -- Declare internal variables for integer comparisons
        variable data_int : unsigned(VECTOR_LENGTH-1 downto 0);
        variable min_int : unsigned(VECTOR_LENGTH-1 downto 0);
        variable max_int : unsigned(VECTOR_LENGTH-1 downto 0);
    begin
        if rstn = '0' then
            -- Asynchronous reset: Initialize outputs to '0'
            result <= '0';
            result_rdy <= '0';
        elsif rising_edge(clk) then
            -- Synchronous process triggered on the rising edge of the clock
            if data_rdy = '1' then
                -- When input data is ready for processing
                -- Convert std_logic_vector inputs to unsigned integers for comparison
                data_int := unsigned(data_in);
                min_int := unsigned(min);
                max_int := unsigned(max);
                
                -- Check if data_in is within the specified thresholds
                if data_int >= min_int and data_int <= max_int then
                    result <= '1';  -- Set result to '1' if within range
                    result_rdy <= '1';  -- Indicate valid result
                else
                    result <= '0';  -- Set result to '0' if out of range
                    result_rdy <= '1';  -- Indicate valid result
                end if;
            else
                result_rdy <= '0';  -- Indicate result is not valid when data is not ready
            end if;
        end if;
    end process;

end rtl;

