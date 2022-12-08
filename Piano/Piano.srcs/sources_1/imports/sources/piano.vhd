library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Define piano ports --------------------------------------------------
entity piano is
    port (
        clk_50MHz : in std_logic;

        kpd_col : out std_logic_vector(4 downto 1);
        kpd_row : in std_logic_vector(4 downto 1);

        dac_mclk : out std_logic;
        dac_lrck : out std_logic;
        dac_sclk : out std_logic;
        dac_sdin : out std_logic
    );
end piano;

-- Define piano behavior
architecture Behavioral of piano is
    -- Frequency constants - Passed to tone
    constant note01 : unsigned (13 downto 0) := to_unsigned (351, 14); -- C
    constant note02 : unsigned (13 downto 0) := to_unsigned (372, 14); -- C#
    constant note03 : unsigned (13 downto 0) := to_unsigned (394, 14); -- D
    constant note04 : unsigned (13 downto 0) := to_unsigned (418, 14); -- Eb
    constant note05 : unsigned (13 downto 0) := to_unsigned (442, 14); -- E
    constant note06 : unsigned (13 downto 0) := to_unsigned (496, 14); -- F
    constant note07 : unsigned (13 downto 0) := to_unsigned (526, 14); -- F#
    constant note08 : unsigned (13 downto 0) := to_unsigned (557, 14); -- G
    constant note09 : unsigned (13 downto 0) := to_unsigned (591, 14); -- G#
    constant note10 : unsigned (13 downto 0) := to_unsigned (626, 14); -- A
    constant note11 : unsigned (13 downto 0) := to_unsigned (663, 14); -- Bb
    constant note12 : unsigned (13 downto 0) := to_unsigned (702, 14); -- B
    -- http://www.sengpielaudio.com/calculator-notenames.htm (units of 0.745 Hz)

    -- Initialize keypad ports
    component keypad is
        port (
            clk : in std_logic;
            row : in std_logic_vector(4 downto 1);
            col : out std_logic_vector(4 downto 1);
            val : out std_logic_vector(3 downto 0);
            hit : out std_logic
        );
    end component;

    -- Initialize tone ports
    component tone is
        port (
            clk : in std_logic;
            note: in unsigned (13 downto 0);
            -- wave: in t_state; -- Not sure about this one
            data: out signed (15 downto 0)
        );
    end component;

    -- Initialize dac ports
    component dac is
        port(
            clk : in std_logic;
            l_load : in std_logic;
            r_load : in std_logic;
            l_data : in signed (15 downto 0);
            r_data : in signed (15 downto 0);
            data : out std_logic
        );
    end component;

    -- Keypad signals
    signal kpd_cnt : std_logic_vector(20 downto 0);
    signal kpd_clk : std_logic;
    signal kpd_hit : std_logic;
    signal kpd_val : std_logic_vector (3 downto 0);

    -- Tone signals
    signal ton_clk : std_logic;
    signal ton_note : unsigned (13 downto 0);
    signal ton_wave : unsigned (2 downto 0);


    -- DAC signals
    signal dac_cnt : unsigned (19 downto 0) := (others => '0');
    signal dac_l_load : std_logic;
    signal dac_r_load : std_logic;
    signal dac_l_data : signed (15 downto 0);
    signal dac_r_data : signed (15 downto 0);
    signal dac_clk : std_logic;


begin
    -- Keypad count process
    kpd_cnt_proc : process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
            kpd_cnt <= kpd_cnt + 1; -- increment keypad counter
        end if;
    end process;

    -- DAC counting and loading process
    dac_cnt_proc : process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
            if (dac_cnt(9 downto 0) >= X"00F") AND (dac_cnt(9 downto 0) < X"02E") then
                dac_l_load <= '1';
            else
                dac_l_load <= '0';
            end if;

            if (dac_cnt(9 downto 0) >= X"20F") AND (dac_cnt(9 downto 0) < X"22E") then
                dac_r_load <= '1';
            else
                dac_r_load <= '0';
            end if;

            dac_cnt <= dac_cnt + 1;
        end if;
    end process;

    -- Subfile clocks
    kpd_clk <= kpd_cnt(15);
    ton_clk <= dac_cnt(9);
    dac_clk <= dac_cnt(4);

    -- DAC output clocks
    dac_mclk <= NOT dac_cnt(1);
    dac_lrck <= ton_clk;
    dac_sclk <= dac_clk;

    -- Keypad port map
    kp : keypad
    port map(
        clk => kpd_clk,
        col => kpd_col,
        row => kpd_row,
        val => kpd_val,
        hit => kpd_hit
    );
    
    -- Tone port map
    ton : tone
    port map(
        clk => ton_clk,
        note => ton_note,
        data => dac_l_data
    );
    dac_r_data <= dac_l_data;

    -- DAC port map
    dc : dac
    port map (
        clk => dac_clk,
        l_load => dac_l_load,
        r_load => dac_r_load,
        l_data => dac_l_data,
        r_data => dac_r_data,
        data => dac_sdin
    );

    -- Keypad combing process
    sm_comb_proc : process (kpd_hit, kpd_val, clk_50MHz)
    begin
             if kpd_hit = '1' then
                case kpd_val is
                    --when X"0" =>
                    --sm_state <= nx_state;
        
                    when X"1" =>
                    ton_note <= note01;

                    when X"2" =>
                    ton_note <= note02;

                    when X"3" =>
                    ton_note <= note03;

                    when X"A" =>
                    ton_note <= note04;

                    when X"4" =>
                    ton_note <= note05;

                    when X"5" =>
                    ton_note <= note06;

                    when X"6" =>
                    ton_note <= note07;

                    when X"B" =>
                    ton_note <= note08;

                    when X"7" =>
                    ton_note <= note09;

                    when X"8" =>
                    ton_note <= note10;

                    when X"9" =>
                    ton_note <= note11;

                    when X"C" =>
                    ton_note <= note12;
                    
                    when others =>
                    ton_note <= note01;
                end case;
            end if;
    end process;
end Behavioral;