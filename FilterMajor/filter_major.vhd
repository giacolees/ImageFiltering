library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! This component implements noise filtering for a 1-bit black/white image.
--! Two image lines are buffered internally to have the values of all
--! pixels in a 3x3 pixel matrix available for filtering.
entity filter_major is
    generic (
        IMAGE_WIDTH  : integer range 3 to 2047 := 640; --! Width of the input image in pixels
        IMAGE_HEIGHT : integer range 3 to 2047 := 480; --! Height of the input image in pixels
        ADDR_WIDTH   : positive := 11;   --! Address width for the line_buffer subcomponent
        DATA_WIDTH   : positive := 1;    --! Data width for the line_buffer subcomponent
        PIXEL_COUNT  : positive := 4     --! Threshold for the number of pixels with value '1' in the 3x3 pixel matrix of the noise filter.
    );
    Port (
        clk         : in  std_logic;    --! Clock input
        rstn        : in  std_logic;    --! Negated asynchronous reset
        data_in     : in  std_logic;    --! 1-bit black or white input pixel
        data_rdy    : in  std_logic;    --! Input bit indicating if the input data (#data_in) is ready to be processed
        result      : out std_logic;    --! Output pixel
        result_rdy  : out std_logic     --! Indicates whether the output (#result) represents a valid pixel
    );
end filter_major;

--! RTL implementation of filter_major
architecture rtl of filter_major is

    component line_buffer is
        Generic (
            LINE_LENGTH : positive;
            ADDR_WIDTH  : positive;
            DATA_WIDTH  : positive
        );
        Port (
            clk             : in std_logic;
            rstn            : in std_logic;
            data_in         : in std_logic;
            data_rdy        : in std_logic;
            result          : out std_logic;
            result_rdy      : out std_logic
        );
    end component;

    -- Signals for line buffer outputs
    signal line1_out, line2_out : std_logic;
    signal line1_rdy, line2_rdy : std_logic;
    signal r_line1, r_line2 : std_logic;
    signal reg1 : std_logic;
    signal reg3 : std_logic_vector(1 downto 0);
    signal k : integer := 0;

    signal pixel_matrix : std_logic_vector(8 downto 0);

begin

    -- Instantiation of the first line buffer
    line_buff1 : line_buffer
        Generic map (
            LINE_LENGTH => IMAGE_WIDTH,
            ADDR_WIDTH  => ADDR_WIDTH,
            DATA_WIDTH  => DATA_WIDTH
        )
        Port map (
            clk         => clk,
            rstn        => rstn,
            data_in     => data_in,
            data_rdy    => data_rdy,
            result      => line1_out,
            result_rdy  => line1_rdy
        );

    -- Instantiation of the second line buffer
    line_buff2 : line_buffer
        Generic map (
            LINE_LENGTH => IMAGE_WIDTH,
            ADDR_WIDTH  => ADDR_WIDTH,
            DATA_WIDTH  => DATA_WIDTH
        )
        Port map (
            clk         => clk,
            rstn        => rstn,
            data_in     => line1_out,
            data_rdy    => line1_rdy,
            result      => line2_out,
            result_rdy  => line2_rdy
        );  

    -- Process to handle the filtering operation
    process(clk, rstn)
        variable count : integer := 0;
    begin
        if rstn = '0' then
            -- Asynchronous reset
            k <= 0;
        elsif rising_edge(clk) then
            -- On rising edge of the clock
            reg1 <= line1_out;
            reg3(0) <= data_in;
            reg3(1) <= reg3(0);

            if line2_rdy = '1' then
                -- Shift pixel matrix values
                pixel_matrix(8 downto 7) <= pixel_matrix(7 downto 6);
                pixel_matrix(5 downto 4) <= pixel_matrix(4 downto 3);
                pixel_matrix(2 downto 1) <= pixel_matrix(1 downto 0);

                -- Count the number of '1's in the pixel matrix
                count := 0;
                for i in pixel_matrix'range loop
                    if pixel_matrix(i) = '1' then
                        count := count + 1;
                    end if;
                end loop;

                if k > 1 then
                    -- Compare count with PIXEL_COUNT to determine output pixel
                    if count >= PIXEL_COUNT then
                        result <= '1';  -- Set the output pixel to '1'
                        result_rdy <= '1';  -- Set the output ready signal to '1'
                    else
                        result <= '0';  -- Set the output pixel to '0'
                        result_rdy <= '1';  -- Set the output ready signal to '1'
                    end if;
                end if;

                k <= k + 1;
            else
                result_rdy <= '0';  -- Set output ready signal to '0' if line2_rdy is not '1'
            end if;
        end if;
    end process;

    -- Assignments to update pixel matrix based on line buffer outputs
    pixel_matrix(0) <= reg3(1) when line2_rdy = '1';
    pixel_matrix(3) <= reg1 when line2_rdy = '1';
    pixel_matrix(6) <= line2_out when line2_rdy = '1';

end rtl;
