library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;

entity game_top is
    -- Board clock, switches and video signals.
    generic (
        STATIC_MODE : boolean := false
    );
    port (
        clk : in std_logic;
        SW0 : in std_logic;
        SW1 : in std_logic;
        SW2 : in std_logic;
        SW3 : in std_logic;
        H : out std_logic;
        V : out std_logic;
        DAC_CLK : out std_logic;
        Rout : out std_logic_vector(7 downto 0);
        Gout : out std_logic_vector(7 downto 0);
        Bout : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of game_top is
    signal startup_count : integer range 0 to 255 := 0;
    signal reset : std_logic := '1';
    -- Two stages for reading the switches safely.
    signal switches_meta : std_logic_vector(3 downto 0) := (others => '0');
    signal switches_sync : std_logic_vector(3 downto 0) := (others => '0');
    signal pixel_x : integer range 0 to 799;
    signal pixel_y : integer range 0 to 524;
    signal frame_tick : std_logic;
    signal game : game_state_t;
    signal red, green, blue : std_logic_vector(7 downto 0);
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of switches_meta : signal is "TRUE";
    attribute ASYNC_REG of switches_sync : signal is "TRUE";
    attribute SHREG_EXTRACT : string;
    attribute SHREG_EXTRACT of switches_meta : signal is "NO";
    attribute SHREG_EXTRACT of switches_sync : signal is "NO";
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Hold reset briefly at startup.
            if startup_count < 255 then
                startup_count <= startup_count + 1;
                reset <= '1';
            else
                reset <= '0';
            end if;
            switches_meta <= SW3 & SW2 & SW1 & SW0;
            switches_sync <= switches_meta;
        end if;
    end process;

    -- Update the game state.
    engine : entity work.game_engine
        generic map (STATIC_MODE => STATIC_MODE)
        port map (
            clk => clk,
            reset => reset,
            frame_tick => frame_tick,
            switches => switches_sync,
            game => game
        );

    -- Choose each pixel colour.
    renderer : entity work.game_renderer
        port map (
            pixel_x => pixel_x,
            pixel_y => pixel_y,
            game => game,
            red => red,
            green => green,
            blue => blue
        );

    -- Generate the VGA timing and outputs.
    timing : entity work.vga_controller
        port map (
            clk => clk,
            reset => reset,
            red => red,
            green => green,
            blue => blue,
            pixel_x => pixel_x,
            pixel_y => pixel_y,
            frame_tick => frame_tick,
            H => H,
            V => V,
            DAC_CLK => DAC_CLK,
            Rout => Rout,
            Gout => Gout,
            Bout => Bout
        );
end architecture;
