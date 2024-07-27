library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std.unsigned;
use work.const_package.all;

entity div16_8_8 is
	port (
		clk        : in  STD_LOGIC; -- Clock input
		en         : in  STD_LOGIC; -- Enable input
		rstn       : in  STD_LOGIC; -- Asynchronous reset (active low)
		a          : in  STD_LOGIC_VECTOR(A_WIDTH-1 downto 0); -- Dividend input
		b          : in  STD_LOGIC_VECTOR(B_WIDTH-1 downto 0); -- Divisor input
		result     : out STD_LOGIC_VECTOR(RESULT_WIDTH-1 downto 0) -- Result output
	);
end entity div16_8_8;

architecture rtl of div16_8_8 is

	type unsigned_8_array  is array(natural range <>) of UNSIGNED(B_WIDTH-1 downto 0); -- Array type for storing 8-bit unsigned values
	type unsigned_16_array is array(natural range <>) of UNSIGNED(A_WIDTH-2 downto 0); -- Array type for storing 16-bit unsigned values

	signal r_remainder 		: unsigned_16_array(1 to RESULT_WIDTH); -- Signal for storing remainders
	signal r_shifted_b 		: unsigned_16_array(1 to RESULT_WIDTH); -- Signal for storing shifted divisor values
	signal r_result    		: unsigned_8_array(1 to RESULT_WIDTH); -- Signal for storing intermediate results
	signal r_result_signed 	: SIGNED(RESULT_WIDTH-1 downto 0); -- Signal for storing the signed result
	signal r_sign      		: STD_LOGIC_VECTOR(1 to RESULT_WIDTH); -- Signal for storing sign bits
	signal r_en		     	: STD_LOGIC_VECTOR(1 to RESULT_WIDTH); -- Signal for storing enable bits

begin

	process(clk, rstn, en)

		variable v_result 	: UNSIGNED(RESULT_WIDTH-1 downto 1); -- Variable for storing the final result
		variable a_signed 	: SIGNED(A_WIDTH-1 downto 0); -- Variable for storing the signed version of the dividend
		variable a_unsigned : UNSIGNED(A_WIDTH-2 downto 0); -- Variable for storing the unsigned version of the dividend

	begin

		if rstn = '0' then
			-- Asynchronous reset
			r_remainder <= (others => (others => '0'));
			r_shifted_b <= (others => (others => '0'));
			r_result <= (others => (others => '0'));
			r_result_signed <= (others => '0');
			r_sign <= (others => '0');
			r_en <= (others => '0');
			v_result := (others => '0');

		elsif rising_edge(clk) then
			-- Synchronous process on rising edge of clock
			if en = '1' then
				-- Enable signal is high
				a_signed := SIGNED(a);
				-- Check if the dividend is positive or negative, and convert to unsigned
				if a_signed(A_WIDTH-1) = '1' then
					a_unsigned := UNSIGNED(not(a_signed(A_WIDTH-2 downto 0)) + 1); -- Two's complement for negative values
					r_sign(1) <= '1'; -- Set sign bit for negative dividend
				else
					a_unsigned := UNSIGNED(a(A_WIDTH-2 downto 0)); -- Direct assignment for positive values
					r_sign(1) <= '0'; -- Set sign bit for positive dividend
				end if;

				-- Initialize shifted divisor and remainder
				r_shifted_b(1) <= UNSIGNED(b) & (B_WIDTH - 1 downto 0 => '0');
				r_remainder(1) <= a_unsigned;

				-- Check for division by zero
				if to_integer(UNSIGNED(b)) = 0 then
					r_en(1) <= '0'; -- Disable further processing
					r_result(1) <= (others => '1'); -- Set result to all ones
				else
					r_en(1) <= '1'; -- Enable further processing
				end if;

				-- Loop through the bits to perform the division
				for k in 2 to RESULT_WIDTH loop
					if r_en(k-1) = '1' then
						-- Shift the divisor to the right
						r_shifted_b(k) <= r_shifted_b(k-1) srl 1;
						v_result := r_result(k-1); -- Load the previous result
						r_sign(k) <= r_sign(k-1); -- Propagate the sign bit
						r_en(k) <= r_en(k-1); -- Propagate the enable bit

						-- Shift and subtract logic
						if r_remainder(k-1) >= r_shifted_b(k-1) then
							r_remainder(k) <= r_remainder(k-1) - r_shifted_b(k-1); -- Subtract shifted divisor from remainder
							r_result(k) <= (v_result sll 1) + 1; -- Set the result bit to 1
						else
							r_remainder(k) <= r_remainder(k-1); -- Keep the remainder as is
							r_result(k) <= v_result sll 1; -- Set the result bit to 0
						end if;
					else
						-- Propagate previous values when enable is low
						r_remainder(k) <= r_remainder(k-1);
						r_result(k) <= r_result(k-1);
						r_sign(k) <= r_sign(k-1);
						r_en(k) <= r_en(k-1);
					end if;
				end loop;

				-- Final bit of division
				if r_remainder(RESULT_WIDTH) >= r_shifted_b(RESULT_WIDTH) then
					v_result := (r_result(RESULT_WIDTH) sll 1) + 1; -- Set the last result bit to 1
				else
					v_result := (r_result(RESULT_WIDTH) sll 1); -- Set the last result bit to 0
				end if;

				-- Handle the sign of the result
				if r_sign(RESULT_WIDTH) = '1' then
					r_result_signed <= SIGNED(not('0' & v_result) + 1); -- Two's complement for negative result
				else
					r_result_signed <= SIGNED('0' & v_result); -- Direct assignment for positive result
				end if;

			end if;

		end if;

	end process;

	-- Assign the signed result to the output
	result <= STD_LOGIC_VECTOR(r_result_signed);

end architecture rtl;