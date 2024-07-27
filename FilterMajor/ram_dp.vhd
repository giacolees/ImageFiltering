-- Dual-Port Block RAM with Two Write Ports
-- Modelization with a Shared Variable - modification without enable ports and only one clock

-- Old XPS version describes write first implementation as done here!

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;

--! This component encapsulates a dual ported BRAM.

--! If the internal output register is used (#USE_OUTPUT_REG), the output
--! is delayed for one clock cycle.
entity ram_dp is
    generic (
        ADDR_WIDTH     : positive := 2;  --! Width of the BRAM addresses
        DATA_WIDTH     : positive := 6;  --! Width of the data fields in the BRAM
        USE_OUTPUT_REG : std_logic := '0'); --! Specifies if the output is buffered in a separate register
    port(
        clk            : in std_logic;       --! Clock input

        wena           : in std_logic;     --! Write enable for BRAM port A. If set to '1', the value on #dina will be written to position #addra in the RAM.
        wenb           : in std_logic;     --! Write enable for BRAM port B. If set to '1', the value on #dinb will be written to position #addrb in the RAM.
        addra          : in std_logic_vector(ADDR_WIDTH-1 downto 0); --! Address input for reading/writing through port A.
        addrb          : in std_logic_vector(ADDR_WIDTH-1 downto 0); --! Address input for reading/writing through port B.
        dina           : in std_logic_vector(DATA_WIDTH-1 downto 0); --! Data to write through port A.
        dinb           : in std_logic_vector(DATA_WIDTH-1 downto 0); --! Data to write through port B.
        douta          : out std_logic_vector(DATA_WIDTH-1 downto 0);--! Outputs the data in the BRAM at #addra
        doutb          : out std_logic_vector(DATA_WIDTH-1 downto 0) --! Outputs the data in the BRAM at #addrb
    );
end ram_dp;

architecture syn of ram_dp is
   
    type ram_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    shared variable ram_instance : ram_type;

    signal douta_int    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal doutb_int    : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    process (clk)
    begin
        if clk'event and clk = '1' then
            if wena = '1' then
                ram_instance(conv_integer(addra)) := dinA;
                douta_int <= dinA;
            else
                douta_int <= ram_instance(conv_integer(addra));
            end if;
        end if;
    end process;

    process (clk)
    begin
        if clk'event and clk = '1' then
            if wenb = '1' then
                ram_instance(conv_integer(addrb)) := dinB;
                doutb_int <= dinB;
            else
                doutb_int <= ram_instance(conv_integer(addrb));
            end if;
        end if;
    end process;

    G0_USE_OUTPUT_REG_0: if USE_OUTPUT_REG = '0' generate   -- directly connected with the output
        douta <= douta_int;
        doutb <= doutb_int;
    end generate;

    G0_USE_OUTPUT_REG_1: if USE_OUTPUT_REG = '1' generate   -- optional output register is being used
        process (clk)
        begin
            if clk'event and clk = '1' then
                douta <= douta_int;
                doutb <= doutb_int;
            end if;
        end process;
    end generate;

end syn;
