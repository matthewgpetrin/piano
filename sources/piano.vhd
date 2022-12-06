library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity piano is
    port (
        clk_50MHz : in std_logic;

        kp_col : out std_logic_vector(4 downto 1);
        kp_row : in std_logic_vector(4 downto 1);

        dac_mclk : out std_logic;
        dac_lrck : out std_logic;
        dac_sclk : out std_logic;
        dac_sdin : out std_logic
    );
end piano;

architecture Behavioral of piano is
    -- frequency constants for different notes 
    -- frequency constants for different notes
    -- try to represent given frequency in 14 bits
    constant tone01 : unsigned (13 downto 0) := to_unsigned (351, 14); -- C
    constant tone02 : unsigned (13 downto 0) := to_unsigned (372, 14); -- C#
    constant tone03 : unsigned (13 downto 0) := to_unsigned (394, 14); -- D
    constant tone04 : unsigned (13 downto 0) := to_unsigned (418, 14); -- Eb
    constant tone05 : unsigned (13 downto 0) := to_unsigned (442, 14); -- E
    constant tone06 : unsigned (13 downto 0) := to_unsigned (496, 14); -- F
    constant tone07 : unsigned (13 downto 0) := to_unsigned (526, 14); -- F#
    constant tone08 : unsigned (13 downto 0) := to_unsigned (557, 14); -- G
    constant tone09 : unsigned (13 downto 0) := to_unsigned (591, 14); -- G#
    constant tone10 : unsigned (13 downto 0) := to_unsigned (626, 14); -- A
    constant tone11 : unsigned (13 downto 0) := to_unsigned (663, 14); -- Bb
    constant tone12 : unsigned (13 downto 0) := to_unsigned (702, 14); -- B
    -- http://www.sengpielaudio.com/calculator-notenames.htm (units of 0.745 Hz)

    
    -- enum for state machine state. 3 states for 3 waveforms
    -- type t_state is (wave01, wave02, wave03);
    
    -- initialize in/out of keypad.vhd
    component keypad is
        port (
            clk : in std_logic;
            row : in std_logic_vector(4 downto 1);
            col : out std_logic_vector(4 downto 1);
            val : out std_logic_vector(3 downto 0);
            hit : out std_logic
        );
    end component;

    -- initialize in/out of tone.vhd
    component tone is
        port (
            clk : in std_logic;
            note: in unsigned (13 downto 0);
            -- wave: in t_state; -- Not sure about this one
            data: out signed (15 downto 0)
        );
    end component;

    -- initialize in/out of dtac.vhd
    component dtac is
        port(
            sclk : in std_logic;
            l_start : in std_logic;
            r_start : in std_logic;
            l_data : in signed (15 downto 0);
            r_data : in signed (15 downto 0);
            sdata : out std_logic
        );
    end component;

    -- signal definitions for keypad stuff
    signal kp_cnt : std_logic_vector(20 downto 0);
    signal kp_clk : std_logic;
    signal kp_hit : std_logic;
    signal sm_clk : std_logic; -- state machine clock
    signal kp_val : std_logic_vector (3 downto 0);
    signal sm_acc : std_logic_vector (2 downto 0);

    -- signal defintions for state machine - interacts with tone.vhd
    -- signal sm_state : t_state;
    -- signal nx_state : t_state;

    -- signal defintions for dac
    signal dac_cnt : unsigned (19 downto 0) := (others => '0');
    signal dac_l_load : std_logic;
    signal dac_r_load : std_logic;
    signal dac_l_data : signed (15 downto 0);
    signal dac_r_data : signed (15 downto 0);
    signal dac_clk : std_logic;

    -- signal definitions for tone
    signal tn_clk : std_logic;
    signal tn_note : unsigned (13 downto 0);
    signal tn_wave : unsigned (2 downto 0);

begin
    -- process:
    -- sends data to dac
    -- increments keypad counter for scanning
    clk_proc : process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
            kp_cnt <= kp_cnt + 1; -- increment keypad counter

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

    -- state machine and keypad clocks
    kp_clk <= kp_cnt(15);
    sm_clk <= kp_cnt(20);


    -- dac stuff - this is just copied
    dac_mclk <= NOT dac_cnt(1);
    tn_clk <= dac_cnt(9);
    dac_lrck <= tn_clk;
    dac_clk <= dac_cnt(4);
    dac_sclk <= dac_clk;

    -- instantiates keypad and assignes in/out
    kp : keypad
    port map(
        clk => kp_clk,
        col => kp_col,
        row => kp_row,
        val => kp_val,
        hit => kp_hit
    );
    
    -- instantiates tone and assigns in/out
    tn : tone
    port map(
        clk => tn_clk,
        note => tn_note,
        -- wave => sm_state,
        data => dac_l_data
    );
    dac_r_data <= dac_l_data;

    -- instantiates dtac and assigns in/out
    dac : dtac
    port map (
        sclk => dac_clk,
        l_start => dac_l_load,
        r_start => dac_r_load,
        l_data => dac_l_data,
        r_data => dac_r_data,
        sdata => dac_sdin
    );

    -- process to:
    -- update next state
    -- comb through keypad values
    -- assign tone frequency using constants defined above
    sm_comb_proc : process (kp_hit, kp_val, clk_50MHz)
    begin
             if kp_hit = '1' then
                case kp_val is
                    --when X"0" =>
                    --sm_state <= nx_state;
        
                    when X"1" =>
                    tn_note <= tone01;

                    when X"2" =>
                    tn_note <= tone02;

                    when X"3" =>
                    tn_note <= tone03;

                    when X"A" =>
                    tn_note <= tone04;

                    when X"4" =>
                    tn_note <= tone05;

                    when X"5" =>
                    tn_note <= tone06;

                    when X"6" =>
                    tn_note <= tone07;

                    when X"B" =>
                    tn_note <= tone08;

                    when X"7" =>
                    tn_note <= tone09;

                    when X"8" =>
                    tn_note <= tone10;

                    when X"9" =>
                    tn_note <= tone11;

                    when X"C" =>
                    tn_note <= tone12;
                    
                    when others =>
                    tn_note <= tone01;
                end case;
            end if;
    end process;
end Behavioral;