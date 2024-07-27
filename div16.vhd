library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std.unsigned;
use work.const_package.all;

entity div16_8_8 is
	port (
		clk        : in  STD_LOGIC;
		en         : in  STD_LOGIC;
		rstn       : in  STD_LOGIC;
		a          : in  STD_LOGIC_VECTOR( A_WIDTH-1 downto 0);
		b          : in  STD_LOGIC_VECTOR( B_WIDTH-1 downto 0);
		result     : out STD_LOGIC_VECTOR( RESULT_WIDTH-1 downto 0)		
	);
end entity div16_8_8;

architecture rtl of div16_8_8 is

	type unsigned_8_array  is array(natural range <>) of UNSIGNED(B_WIDTH-1 downto 0);
	type unsigned_16_array is array(natural range <>) of UNSIGNED(A_WIDTH-2 downto 0);

	signal r_remainder 		: unsigned_16_array(1 to RESULT_WIDTH);
	signal r_shifted_b 		: unsigned_16_array(1 to RESULT_WIDTH);
	signal r_result    		: unsigned_8_array(1 to RESULT_WIDTH);
	signal r_result_signed 	: SIGNED(RESULT_WIDTH-1 downto 0);
	signal r_sign      		: STD_LOGIC_VECTOR(1 to RESULT_WIDTH);
	signal r_en		     	: STD_LOGIC_VECTOR(1 to RESULT_WIDTH);

begin

	process(clk, rstn, en)

		variable v_result 	: UNSIGNED(RESULT_WIDTH-1 downto 1);
		variable a_signed 	: SIGNED(A_WIDTH-1 downto 0);
		variable a_unsigned : UNSIGNED(A_WIDTH-2 downto 0);

	begin

		if rstn = '0' then
			
			r_remainder <= (others => (others => '0'));
			r_shifted_b <= (others => (others => '0'));
			r_result <= (others => (others => '0'));
			r_result_signed <= (others => '0');
			r_sign <= (others => '0');
			r_en <= (others => '0');
			v_result := (others => '0');

		elsif rising_edge(clk) then

			if en = '1' then

				a_signed := SIGNED(a);
				-- Check if a is positive or negative, and convert to unsigned
				if a_signed(A_WIDTH-1) = '1' then
					a_unsigned := UNSIGNED(not(a_signed(A_WIDTH-2 downto 0)) + 1);
					r_sign(1) <= '1';
				else
					a_unsigned := UNSIGNED(a(A_WIDTH-2 downto 0));
					r_sign(1) <= '0';
				end if;

				r_shifted_b(1) <= UNSIGNED(b) & (B_WIDTH - 1 downto 0 => '0');
				r_remainder(1) <= a_unsigned;

				if to_integer(UNSIGNED(b)) = 0 then
					r_en(1) <= '0';
					r_result(1) <= (others => '1');
				else
					r_en(1) <= '1';
				end if;

				for k in 2 to RESULT_WIDTH loop

						if r_en(k-1) = '1' then

							r_shifted_b(k) <= r_shifted_b(k-1) srl 1;
							v_result := r_result(k-1);
							r_sign(k) <= r_sign(k-1);
							r_en(k) <= r_en(k-1);

							
							-- Shift and subtract logics
							if r_remainder(k-1) >= r_shifted_b(k-1) then

								r_remainder(k) <= r_remainder(k-1) - r_shifted_b(k-1);
								r_result(k) <= (v_result sll 1) + 1;

							else

								r_remainder(k) <= r_remainder(k-1);
								r_result(k) <= v_result sll 1;

							end if;

						else
							
							r_remainder(k) <= r_remainder(k-1);
							r_result(k) <= r_result(k-1);
							r_sign(k) <= r_sign(k-1);
							r_en(k) <= r_en(k-1);

						end if;


				end loop;

				if r_remainder(RESULT_WIDTH) >= r_shifted_b(RESULT_WIDTH) then

					v_result := (r_result(RESULT_WIDTH) sll 1) + 1;

				else

					v_result := (r_result(RESULT_WIDTH) sll 1);

				end if;

				if r_sign(RESULT_WIDTH) = '1' then

					r_result_signed <= SIGNED(not('0' & v_result) + 1);

				else

					r_result_signed <= SIGNED('0' & v_result);

				end if;

			end if;

		end if;

	end process;

	result <= STD_LOGIC_VECTOR(r_result_signed);

end architecture rtl;