LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity dtac is
	port (
		sclk : in std_logic; -- serial clock (1.56 MHz)
		l_start : in std_logic; -- strobe to load LEFT data
		r_start : in std_logic; -- strobe to load RIGHT data
		l_data : in signed (15 downto 0); -- LEFT data (15-bit signed)
		r_data : in signed (15 downto 0); -- RIGHT data (15-bit signed)
	    sdata : out std_logic
        ); -- serial data stream to DAC
end dtac;

architecture Behavioral of dtac is
	signal sreg : std_logic_vector (15 downto 0); -- 16-bit shift register to do
	-- parallel to serial conversion
begin
	-- SREG is used to serially shift data out to DAC, MSBit first.
	-- Left data is loaded into SREG on falling edge of SCLK when L_start is active.
	-- Right data is loaded into SREG on falling edge of SCLK when R_start is active.
	-- At other times, falling edge of SCLK causes REG to logically shift one bit left
	-- Serial data to DAC is MSBit of SREG
	dac_proc : process
	begin
		wait until falling_edge(sclk);
		if l_start = '1' then
			sreg <= std_logic_vector (l_data); -- load LEFT data into SREG
		elsif r_start = '1' then
			sreg <= std_logic_vector (r_data); -- load RIGHT data into SREG
		else
			sreg <= sreg(14 downto 0) & '0'; -- logically shift SREG one bit left
		end if;
	end process;
	sdata <= sreg(15); -- serial data to DAC is MSBit of SREG
end Behavioral;