library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity line_buffer is
    Generic (
        LINE_LENGTH : positive;   -- Length of the lines in the image
        ADDR_WIDTH  : positive;   -- Address width for the ram_dp subcomponent
        DATA_WIDTH  : positive    -- Data width for the ram_dp subcomponent
    );
    Port (
        clk             : in std_logic;     -- Clock input
        rstn            : in std_logic;     -- Negated asynchronous reset
        data_in         : in std_logic; -- Input to be pushed to the FIFO
        data_rdy        : in std_logic;     -- Input bit indicating if the current input data should be pushed to the back of the FIFO queue
        result          : out std_logic; -- Outputs the element at the front of the FIFO queue
        result_rdy      : out std_logic      -- If '1', the front element will be removed from the FIFO queue until the next clock cycle
    );
end line_buffer;

architecture rtl of line_buffer is

    component ram_dp is
        Generic (
            ADDR_WIDTH : positive;
            DATA_WIDTH : positive;
            USE_OUTPUT_REG : std_logic  := '0'
        );
        Port(
            clk     : in std_logic;
            wena    : in std_logic;
            wenb    : in std_logic;
            addra   : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            addrb   : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            dina    : in std_logic_vector(DATA_WIDTH-1 downto 0);
            dinb    : in std_logic_vector(DATA_WIDTH-1 downto 0);
            douta   : out std_logic_vector(DATA_WIDTH-1 downto 0);
            doutb   : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

    signal read_addr  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal write_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal write_enable : std_logic := '1';

    signal ram_dout : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fifo_count : integer range 0 to LINE_LENGTH := 0;
    signal fifo_count_next : integer range 0 to LINE_LENGTH := 0;
    signal can_read : std_logic := '0';
    signal dout : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal no_data_rdy : std_logic := '0';
    signal r_res : std_logic := '0';

begin
    -- Instantiate the dual-port RAM
    ram_inst : ram_dp
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk     => clk,
            wena    => data_rdy,
            wenb    => '0',
            addra   => write_addr,
            addrb   => read_addr,
            dina(0) => data_in,
            dinb    => (others => '0'),
            douta   => open,
            doutb   => dout
        );

    -- FIFO logic
    process(clk, rstn)
    begin   
        if rstn = '0' then
            write_addr <= (others => '0');
            read_addr <= (others => '0');
            can_read <= '0';
        elsif rising_edge(clk) then

            no_data_rdy <= '0';
            result_rdy <= '0';

            if data_rdy = '1' then
                
                write_addr <= std_logic_vector((unsigned(write_addr) + 1) mod LINE_LENGTH);            

                if fifo_count = LINE_LENGTH -1 then
                    can_read <= '1';
                    read_addr <= std_logic_vector((unsigned(read_addr) + 1) mod LINE_LENGTH);
                end if;

                if can_read = '1' then
                    read_addr <= std_logic_vector((unsigned(read_addr) + 1) mod LINE_LENGTH);
                    result_rdy <= '1';
                    if fifo_count = 0 then
                        can_read <= '0';
                    end if;
                end if;
                
                if no_data_rdy = '1' then
                    result <= r_res;
                else
                    result <= dout(0);
                end if;

            else 

                if no_data_rdy = '0' then
                    r_res <= dout(0);
                end if; 
                no_data_rdy <= '1';

            end if;
        end if;
    end process;

    fifo_count <= to_integer(unsigned(write_addr) - unsigned(read_addr)) when unsigned(write_addr) >= unsigned(read_addr) else to_integer(unsigned(write_addr) + LINE_LENGTH - unsigned(read_addr));

end rtl;