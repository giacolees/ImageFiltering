library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_filter_dma_v1_00_a;
use axi_filter_dma_v1_00_a.all;
use work.const_package.all;

--! This component realizes the conversion from RGB to HSV color space.

--! The component can take one color pixel per clock cycle as input.
--! The HSV calculation is pipelined and may take a several clock cycles.
--! The result_rdy output indicates, if the outputs hold a valid computation result.
--! The pixels are processed using the FIFO principle.
entity rgb2hsv is
    port (
        clk        : in  std_logic;   --! Clock input
        rstn       : in  std_logic;   --! Negated asynchronous reset
        data_rdy   : in  std_logic;   --! Input bit indicating if the input data (#r, #g, #b) is ready to be processed
        r          : in  std_logic_vector(7 downto 0);  --! 8 bit red component of the input pixel
        g          : in  std_logic_vector(7 downto 0);  --! 8 bit green component of the input pixel
        b          : in  std_logic_vector(7 downto 0);  --! 8 bit blue component of the input pixel
        result_rdy : out std_logic;       --! Indicates whether the outputs (#h, #s, #v) represent valid pixel data
        h          : out std_logic_vector(8 downto 0);    --! 9 bit hue component of the output pixel (Range: 0° - 360°)
        s          : out std_logic_vector(7 downto 0);    --! 8 bit saturation component of the output pixel
        v          : out std_logic_vector(7 downto 0)     --! 8 bit value component of the output pixel
    );
end entity rgb2hsv;

--! rtl implementation of rgb2hsv
architecture rtl of rgb2hsv is

    --! returns the maximum value of the three given parameters
    function max3(a : unsigned; b : unsigned; c : unsigned) return unsigned is
        variable result : unsigned(7 downto 0) := "00000000";
    begin
        if a > b then
            result := a;
        else
            result := b;
        end if;
        if c > result then
            result := c;
        end if;
        return result;
    end function max3;

    --! returns the minimum value of the three given parameters
    function min3(a : unsigned; b : unsigned; c : unsigned) return unsigned is
        variable result : unsigned(7 downto 0) := "11111111";
    begin
        -- STUDENT CODE HERE
        if a < b then
            result := a;
        else
            result := b;
        end if;
        
        -- Compare result with c, assign the smaller one to result
        if c < result then
            result := c;
        end if;
        return result;    
        -- STUDENT CODE until HERE
    end function min3;


    type std3_array_t is array(natural range <>) of std_logic_vector(2 downto 0);
    type u8_array_t is array(natural range <>) of unsigned(7 downto 0);
    type u16_array_t is array(natural range <>) of signed(15 downto 0);

    component div16_8_8 is
    port (
        clk        : in  std_logic;
		en         : in  STD_LOGIC;
        rstn       : in  std_logic;
        a          : in  std_logic_vector(16 downto 0);
        b          : in  std_logic_vector( 7 downto 0);
        result     : out std_logic_vector( 8 downto 0)
    );
    end component;

    -- STUDENT CODE HERE

    -- Shift registers
    signal r_v_result : u8_array_t(1 to RESULT_WIDTH+2);
    signal r_max : std3_array_t(1 to RESULT_WIDTH+2);
    
    
    signal h_en, s_en : std_logic;
    signal max_val :  std_logic_vector(7 downto 0);
    signal delta :  std_logic_vector(7 downto 0);
    signal delta_ext : std_logic_vector(16 downto 0);
    signal h_div_result : std_logic_vector(8 downto 0);
    signal s_div_result : std_logic_vector(8 downto 0);
    signal h_to : std_logic_vector(16 downto 0);
    signal r_data_rdy : std_logic;

    signal h_final_result : std_logic_vector(8 downto 0);
    signal s_final_result : std_logic_vector(7 downto 0);
    signal v_final_result : std_logic_vector(7 downto 0);


    -- STUDENT CODE until HERE
begin

    div16_8_8_inst_h : div16_8_8
    port map (
        clk => clk,
        en => h_en,
        rstn => rstn,
        a => h_to,
        b => delta,
        result => h_div_result
    );

    div16_8_8_inst_s : div16_8_8
    port map (
        clk => clk,
        en => s_en,
        rstn => rstn,
        a => delta_ext,
        b => max_val,
        result => s_div_result
    );

    -- STUDENT CODE HERE
    --Process for assignment 
    process(clk, rstn)

    variable temp_max : unsigned(7 downto 0);
    variable temp_min : unsigned(7 downto 0);
    variable temp_delta : unsigned(7 downto 0);
    variable signed_red, signed_blue, signed_green : signed(8 downto 0);
    variable intermediate_result : signed(15 downto 0);

    begin

        if rstn = '0' then

            result_rdy <= '0';
            r_data_rdy <= '0';
            result_rdy <= '0';

        elsif rising_edge(clk) then
            
            r_data_rdy <= data_rdy;

            if data_rdy = '1' then

                temp_max := max3(unsigned(r), unsigned(g), unsigned(b));
                temp_min := min3(unsigned(r), unsigned(g), unsigned(b));
                temp_delta := temp_max - temp_min;
                delta <= std_logic_vector(temp_delta);
                max_val <= std_logic_vector(temp_max);
                r_v_result(1) <= temp_max;
                signed_red := '0'&signed(r);
                signed_green := '0'&signed(g);
                signed_blue := '0'&signed(b);
                result_rdy <= '0';
        
                if temp_max = 0  then

                    s_en <= '0';
                    
                else
                
                    s_en <= '1';
                    delta_ext <= std_logic_vector(to_unsigned(255*to_integer(temp_delta), 17));

                end if;

                if temp_delta = 0 then

                    h_en <= '0';
    
                elsif temp_max = unsigned(r) then

                    h_to <= std_logic_vector(to_signed(60*to_integer(signed_green-signed_blue), 17));
                    r_max(1) <= "001";
                    h_en <= '1';

                elsif temp_max = unsigned(g) then
                    
                    h_to <= std_logic_vector(to_signed(60*to_integer(signed_blue-signed_red), 17));
                    r_max(1) <= "010";
                    h_en <= '1';
    
                elsif temp_max = unsigned(b) then

                    h_to <= std_logic_vector(to_signed(60*to_integer(signed_red-signed_green), 17));
                    r_max(1) <= "100";
                    h_en <= '1';

                end if;
                
                for i in 1 to RESULT_WIDTH+1 loop

                    r_max(i+1) <= r_max(i);
                    r_v_result(i+1) <= r_v_result(i);

                end loop;

                if r_max(RESULT_WIDTH+2) = "001" then

                    if to_integer(signed(h_div_result)) < 0 then
                        h_final_result <= std_logic_vector(to_signed(((to_integer(signed(h_div_result))))+360, 9));
                    else
                        h_final_result <= std_logic_vector(to_signed((to_integer(signed(h_div_result))), 9));
                    end if;
                    s_final_result <= std_logic_vector(s_div_result(7 downto 0));
                    v_final_result <= std_logic_vector(r_v_result(RESULT_WIDTH+2));
                    result_rdy <= '1';
                    
                elsif r_max(RESULT_WIDTH+2) = "010" then
                    
                    if to_integer(signed(h_div_result) + 85) < 0 then
                        h_final_result <= std_logic_vector(to_signed(((to_integer(signed(h_div_result) + 120)))+360, 9));
                    else
                        h_final_result <= std_logic_vector(to_signed((to_integer(signed(h_div_result) + 120)), 9));
                    end if;
                    s_final_result <= std_logic_vector(s_div_result(7 downto 0));
                    v_final_result <= std_logic_vector(r_v_result(RESULT_WIDTH+2));
                    result_rdy <= '1';
    
                elsif r_max(RESULT_WIDTH+2) = "100" then

                    if to_integer(signed(h_div_result) + 171) < 0 then
                        h_final_result <= std_logic_vector(to_signed(((to_integer(signed(h_div_result) + 240)))+360, 9));
                    else
                        h_final_result <= std_logic_vector(to_signed((to_integer(signed(h_div_result) + 240)), 9));
                    end if;
                    s_final_result <= std_logic_vector(s_div_result(7 downto 0));
                    v_final_result <= std_logic_vector(r_v_result(RESULT_WIDTH+2));
                    result_rdy <= '1';

                end if;

            elsif r_data_rdy = '1' then

                result_rdy <= '0';

                r_max(1) <= "000";

                for i in 1 to RESULT_WIDTH+1 loop

                    r_max(i+1) <= r_max(i);
                    r_v_result(i+1) <= r_v_result(i);

                end loop;

                if r_max(RESULT_WIDTH+2) = "001" then

                    if to_integer(signed(h_div_result)) < 0 then
                        h_final_result <= std_logic_vector(to_signed(((to_integer(signed(h_div_result))))+360, 9));
                    else
                        h_final_result <= std_logic_vector(to_signed((to_integer(signed(h_div_result))), 9));
                    end if;
                    s_final_result <= std_logic_vector(s_div_result(7 downto 0));
                    v_final_result <= std_logic_vector(r_v_result(RESULT_WIDTH+2));
                    result_rdy <= '1';
                    
                elsif r_max(RESULT_WIDTH+2) = "010" then
                    
                    if to_integer(signed(h_div_result) + 85) < 0 then
                        h_final_result <= std_logic_vector(to_signed(((to_integer(signed(h_div_result) + 120)))+360, 9));
                    else
                        h_final_result <= std_logic_vector(to_signed((to_integer(signed(h_div_result) + 120)), 9));
                    end if;
                    s_final_result <= std_logic_vector(s_div_result(7 downto 0));
                    v_final_result <= std_logic_vector(r_v_result(RESULT_WIDTH+2));
                    result_rdy <= '1';
    
                elsif r_max(RESULT_WIDTH+2) = "100" then

                    if to_integer(signed(h_div_result) + 171) < 0 then
                        h_final_result <= std_logic_vector(to_signed(((to_integer(signed(h_div_result) + 240)))+360, 9));
                    else
                        h_final_result <= std_logic_vector(to_signed((to_integer(signed(h_div_result) + 240)), 9));
                    end if;
                    s_final_result <= std_logic_vector(s_div_result(7 downto 0));
                    v_final_result <= std_logic_vector(r_v_result(RESULT_WIDTH+2));
                    result_rdy <= '1';

                end if;

                if data_rdy = '0' then

                    r_data_rdy <= '1';

                end if;

            
            else
                    
                result_rdy <= '0';

            end if;

        end if;

    end process;

    h <= h_final_result;
    s <= s_final_result;
    v <= v_final_result;

end architecture rtl;
