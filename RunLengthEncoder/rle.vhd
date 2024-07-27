library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--! This copmonent implements a run-length encoder for 1 bit black/white images.

--! The resulting runs are parametrized using the start position (#start_pos), end position (#end_pos) and
--! the corresponding row number (#row_number).

entity rle is
  generic
  (
    ROW_LENGTH       : positive              := 640; --! Length of a row in the input image
    ROW_LENGTH_WIDTH : positive              := 10; --! Bitwidth of #ROW_LENGTH
    NUMBER_OF_ROWS   : positive              := 480; --! Number of rows in the input image
    ROW_NUMBER_WIDTH : positive              := 9; --! Bitwidth of #NUMBER_OF_ROWS
    PIXEL_OFFSET     : integer range 0 to 10 := 2; --! Offset in the first line caused by filter_major
    LINE_OFFSET      : integer range 0 to 10 := 2 --! Number of lines absorbed by filter_major
  );
  port
  (
    clk        : in std_logic; --! Clock input
    rstn       : in std_logic; --! Negated asynchronous reset
    data_in    : in std_logic; --! 1 bit black or white input pixel
    data_rdy   : in std_logic; --! Indicates if the input data (#data_in) is ready to be processed
    start_pos  : out std_logic_vector(ROW_LENGTH_WIDTH - 1 downto 0); --! The starting position of the detected run. Only valid if #new_run is '1'.
    end_pos    : out std_logic_vector(ROW_LENGTH_WIDTH - 1 downto 0); --! The end position of the detected run. Only valid if #new_run is '1'.
    row_number : out std_logic_vector(ROW_NUMBER_WIDTH - 1 downto 0);--! The row number of the detected run. Only valid if #new_run is '1'.
    new_run    : out std_logic; --! Indicates if a new run has been detected. The run parameters are only valid if #new_run is '1'.
    eol        : out std_logic; --! Indicates if the run-length encoder has reached the end of a row in the image.
    eof        : out std_logic --! Indicates if the run-length encoder has reached the end of the data stream (i.e. the image has been processed completely).
  );
end rle;

architecture behavioral of rle is

  -- STUDENT CODE HERE
  signal eof_watch  : std_logic := '0';
  signal eof_is_set : boolean   := false;
  -- STUDENT CODE until HERE

begin

  -- STUDENT CODE HERE
  process (clk, rstn)

    variable start_p    : integer := PIXEL_OFFSET;
    variable count      : integer := PIXEL_OFFSET;
    variable num_rows   : integer := LINE_OFFSET;
    variable run_active : boolean := False;

    variable temp : boolean := false;

  begin
    if rstn = '0' then

      start_p    := PIXEL_OFFSET;
      count      := PIXEL_OFFSET;
      num_rows   := LINE_OFFSET;
      run_active := False;
      eol        <= '0';
      eof        <= '0';
      eof_watch  <= '0';
      eof_is_set <= false;
      start_pos  <= (others => '0');
      end_pos    <= (others => '0');
      row_number <= std_logic_vector(to_unsigned(LINE_OFFSET, ROW_NUMBER_WIDTH));

    elsif rising_edge(clk) then

      temp := false;

      new_run   <= '0';
      eof       <= '0';
      eof_watch <= '0';
      eol       <= '0';

      if data_rdy = '1' then

        if data_in = '1' then

          if not run_active then

            start_p    := count;
            run_active := True;

          end if;

        else

          if run_active then

            row_number <= std_logic_vector(to_unsigned(num_rows, ROW_NUMBER_WIDTH));
            start_pos  <= std_logic_vector(to_unsigned(start_p, ROW_LENGTH_WIDTH));
            end_pos    <= std_logic_vector(to_unsigned(count - 1, ROW_LENGTH_WIDTH));
            run_active := False;
            new_run <= '1';

          end if;

        end if;

        if (count + 1) mod ROW_LENGTH = 0 then

          count := 0;

          if run_active then

            if count /= 0 then
              end_pos <= std_logic_vector(to_unsigned(count - 1, ROW_LENGTH_WIDTH));
            else
              end_pos <= std_logic_vector(to_unsigned(ROW_LENGTH - 1, ROW_LENGTH_WIDTH));
            end if;

            start_pos  <= std_logic_vector(to_unsigned(start_p, ROW_LENGTH_WIDTH));
            row_number <= std_logic_vector(to_unsigned(num_rows, ROW_NUMBER_WIDTH));
            new_run    <= '1';
            run_active := False;

          end if;

          eol <= '1';
          num_rows := num_rows + 1;

          if num_rows = NUMBER_OF_ROWS - LINE_OFFSET then
            report "num_rows = NUMBER_OF_ROWS - LINE_OFFSET";
            --eof       <= '1';
            --eof_watch <= '1';

          end if;
          --         8  =      11        -     2       - 1  and    27  =     30     -       2      - 1                
        elsif (num_rows = NUMBER_OF_ROWS - LINE_OFFSET - 1) and (count = ROW_LENGTH - PIXEL_OFFSET - 1) then
          temp := true;

          if run_active then

            row_number <= std_logic_vector(to_unsigned(num_rows, ROW_NUMBER_WIDTH));
            start_pos  <= std_logic_vector(to_unsigned(start_p, ROW_LENGTH_WIDTH));
            end_pos    <= std_logic_vector(to_unsigned(count, ROW_LENGTH_WIDTH));
            new_run    <= '1';
            run_active := False;
            eol <= '1';
            eof <= '1';
            --eof_watch <= '1';
          end if;

          if (eof_watch = '1') then
            eof       <= '0';
            eof_watch <= '0';
          elsif eof_watch = '0' and not eof_is_set then
            eol        <= '1';
            eof        <= '1';
            eof_watch  <= '1';
            eof_is_set <= true;
          end if;
        else

          count := count + 1;

        end if;

      end if;

    end if;
  end process;

  -- STUDENT CODE until HERE
end behavioral;