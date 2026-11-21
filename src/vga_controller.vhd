library ieee;
use ieee.std_logic_1164.all;

entity vga_controller is
    -- Clock, colours and VGA outputs.
    port (
        clk : in std_logic;
        reset : in std_logic;
        red : in std_logic_vector(7 downto 0);
        green : in std_logic_vector(7 downto 0);
        blue : in std_logic_vector(7 downto 0);
        pixel_x : out integer range 0 to 799;
        pixel_y : out integer range 0 to 524;
        frame_tick : out std_logic;
        H : out std_logic;
        V : out std_logic;
        DAC_CLK : out std_logic;
        Rout : out std_logic_vector(7 downto 0);
        Gout : out std_logic_vector(7 downto 0);
        Bout : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of vga_controller is
    -- Pixel timing and screen counters.
    signal phase : std_logic := '0';
    signal column : integer range 0 to 799 := 0;
    signal row : integer range 0 to 524 := 0;
begin
    pixel_x <= column;
    pixel_y <= row;
    DAC_CLK <= not phase;
    -- Update the game during vertical blanking.
    frame_tick <= '1' when reset = '0' and phase = '0' and
                           column = 0 and row = 480 else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                phase <= '0';
                column <= 0;
                row <= 0;
                H <= '1';
                V <= '1';
                Rout <= x"00";
                Gout <= x"00";
                Bout <= x"00";
            else
                phase <= not phase;
                -- Process one pixel every two clock cycles.
                if phase = '0' then
                    -- Generate the sync pulses.
                    if column >= 656 and column < 752 then
                        H <= '0';
                    else
                        H <= '1';
                    end if;
                    if row >= 490 and row < 492 then
                        V <= '0';
                    else
                        V <= '1';
                    end if;

                    -- Show colours only inside the visible area.
                    if column < 640 and row < 480 then
                        Rout <= red;
                        Gout <= green;
                        Bout <= blue;
                    else
                        Rout <= x"00";
                        Gout <= x"00";
                        Bout <= x"00";
                    end if;

                    -- Advance to the next pixel, line or frame.
                    if column = 799 then
                        column <= 0;
                        if row = 524 then
                            row <= 0;
                        else
                            row <= row + 1;
                        end if;
                    else
                        column <= column + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
