library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Piano entity definition ------------------------------------------------------------------------------
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

-- Piano architecture definition ------------------------------------------------------------------------
architecture Behavioral of piano is
    -- Note constants in 14 bits ------------------------------------------------------------------------
    constant NOTE_NULL : unsigned (13 downto 0) := to_unsigned (0, 14);   -- 0 Hz wave
    constant NOTE_01 : unsigned (13 downto 0) := to_unsigned (351, 14); -- C
    constant NOTE_02 : unsigned (13 downto 0) := to_unsigned (372, 14); -- C#
    constant NOTE_03 : unsigned (13 downto 0) := to_unsigned (394, 14); -- D
    constant NOTE_04 : unsigned (13 downto 0) := to_unsigned (418, 14); -- Eb
    constant NOTE_05 : unsigned (13 downto 0) := to_unsigned (442, 14); -- E
    constant NOTE_06 : unsigned (13 downto 0) := to_unsigned (469, 14); -- F
    constant NOTE_07 : unsigned (13 downto 0) := to_unsigned (497, 14); -- F#
    constant NOTE_08 : unsigned (13 downto 0) := to_unsigned (526, 14); -- G
    constant NOTE_09 : unsigned (13 downto 0) := to_unsigned (557, 14); -- G#
    constant NOTE_10 : unsigned (13 downto 0) := to_unsigned (591, 14); -- A
    constant NOTE_11 : unsigned (13 downto 0) := to_unsigned (626, 14); -- Bb
    constant NOTE_12 : unsigned (13 downto 0) := to_unsigned (663, 14); -- B
    constant NOTE_13 : unsigned (13 downto 0) := to_unsigned (702, 14); -- B
    -- http://www.sengpielaudio.com/calculator-notenames.htm (units of 0.745 Hz)
  
    -- Keypad component definition ----------------------------------------------------------------------
    component kpd_interface is
        port (
            clk : in std_logic;
            row : in std_logic_vector(4 downto 1);
            col : out std_logic_vector(4 downto 1);
            val : out std_logic_vector(3 downto 0);
            hit : out std_logic
        );
    end component;

    -- Tone component definition ------------------------------------------------------------------------
    component tone_generator is
        port (
            clk : in std_logic;
            note: in unsigned (13 downto 0);
            data: out signed (15 downto 0)
        );
    end component;

    -- DAC component definition -------------------------------------------------------------------------
    component dac_interface is
        port(
            clk : in std_logic;
            l_load : in std_logic;
            r_load : in std_logic;
            l_data : in signed (15 downto 0);
            r_data : in signed (15 downto 0);
            data : out std_logic
        );
    end component;

    -- Signals passed to keypad -------------------------------------------------------------------------
    signal kpd_cnt : std_logic_vector(20 downto 0);
    signal kpd_clk : std_logic;
    signal kpd_hit : std_logic;
    signal kpd_val : std_logic_vector (3 downto 0);
    
    -- Signals passed to tone ---------------------------------------------------------------------------
    signal ton_clk : std_logic;
    signal ton_note : unsigned (13 downto 0);
    signal ton_wave : unsigned (2 downto 0);

    -- Signals passed to DAC ----------------------------------------------------------------------------
    signal dac_cnt : unsigned (19 downto 0) := (others => '0');
    signal dac_l_load : std_logic;
    signal dac_r_load : std_logic;
    signal dac_data : signed (15 downto 0);
    signal dac_l_data : signed (15 downto 0);
    signal dac_r_data : signed (15 downto 0);
    signal dac_clk : std_logic;

-- Process definitions ----------------------------------------------------------------------------------
begin
    -- Clock divider counters ----------------------------------------------------------------------------
    clk_proc : process(clk_50MHz) begin
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
            kpd_cnt <= kpd_cnt + 1;
        end if;
    end process;
      
    -- Clocks created by counter signals ----------------------------------------------------------------
    ton_clk <= dac_cnt(9);
    dac_clk <= dac_cnt(4);  
    kpd_clk <= kpd_cnt(15);
    
    -- DAC clock assignments ----------------------------------------------------------------------------
    dac_mclk <= NOT dac_cnt(1);
    dac_lrck <= ton_clk;
    dac_sclk <= dac_clk;

    -- Instantiate keypad -------------------------------------------------------------------------------
    kpd : kpd_interface
    port map(
        clk => kpd_clk,
        col => kpd_col,
        row => kpd_row,
        val => kpd_val,
        hit => kpd_hit
    );
    
    -- Instantiate tone ---------------------------------------------------------------------------------
    ton : tone_generator
    port map(
        clk => ton_clk,
        note => ton_note,
        data => dac_data
    );

    -- Instantiate DAC ----------------------------------------------------------------------------------
    dac : dac_interface
    port map (
        clk => dac_clk,
        l_load => dac_l_load,
        r_load => dac_r_load,
        l_data => dac_data,
        r_data => dac_data,
        data => dac_sdin
    );

    -- Keypad switch statement --------------------------------------------------------------------------
    kpd_sm_proc : process (kpd_hit, kpd_val, clk_50MHz)
    begin
        if kpd_hit = '1' then
            case kpd_val is
                when X"D" =>

                when X"1" =>
                ton_note <= NOTE_01;

                when X"2" =>
                ton_note <= NOTE_02;

                when X"3" =>
                ton_note <= NOTE_03;

                when X"A" =>
                ton_note <= NOTE_04;

                when X"4" =>
                ton_note <= NOTE_05;

                when X"5" =>
                ton_note <= NOTE_06;

                when X"6" =>
                ton_note <= NOTE_07;

                when X"B" =>
                ton_note <= NOTE_08;

                when X"7" =>
                ton_note <= NOTE_09;

                when X"8" =>
                ton_note <= NOTE_10;

                when X"9" =>
                ton_note <= NOTE_11;

                when X"C" =>
                ton_note <= NOTE_12;
                    
                when X"0" =>
                ton_note <= NOTE_13;
                    
                when others =>
                ton_note <= NOTE_NULL;
            end case;
                
            else
                ton_note <= NOTE_NULL;
        end if;
    end process;
end Behavioral;