library ieee;
use ieee.std_logic_1164.all;

entity game_debug_top is
    -- Same board ports as game_top.
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

architecture rtl of game_debug_top is
    -- ChipScope control core.
    component icon
        port (
            CONTROL0 : inout std_logic_vector(35 downto 0)
        );
    end component;

    -- ChipScope capture core.
    component ila
        port (
            CONTROL : inout std_logic_vector(35 downto 0);
            CLK : in std_logic;
            DATA : in std_logic_vector(31 downto 0);
            TRIG0 : in std_logic_vector(7 downto 0)
        );
    end component;

    signal control_bus : std_logic_vector(35 downto 0);
    signal ila_data : std_logic_vector(31 downto 0);
    signal ila_trigger : std_logic_vector(7 downto 0);
    signal h_signal : std_logic;
    signal v_signal : std_logic;
    signal dac_signal : std_logic;
    signal red_signal : std_logic_vector(7 downto 0);
    signal green_signal : std_logic_vector(7 downto 0);
    signal blue_signal : std_logic_vector(7 downto 0);
begin
    -- Run the moving game.
    game : entity work.game_top
        generic map (
            STATIC_MODE => false
        )
        port map (
            clk => clk,
            SW0 => SW0,
            SW1 => SW1,
            SW2 => SW2,
            SW3 => SW3,
            H => h_signal,
            V => v_signal,
            DAC_CLK => dac_signal,
            Rout => red_signal,
            Gout => green_signal,
            Bout => blue_signal
        );

    debug_controller : icon
        port map (
            CONTROL0 => control_bus
        );

    debug_analyzer : ila
        port map (
            CONTROL => control_bus,
            CLK => clk,
            DATA => ila_data,
            TRIG0 => ila_trigger
        );

    -- Data bits: red 0-7, green 8-15, blue 16-23, H 24, V 25, clock 26.
    ila_data <= "00000" & dac_signal & v_signal & h_signal &
                blue_signal & green_signal & red_signal;

    -- Trigger bits: H 0, V 1 and DAC clock 2.
    ila_trigger <= "00000" & dac_signal & v_signal & h_signal;

    -- Send the same signals to the board.
    H <= h_signal;
    V <= v_signal;
    DAC_CLK <= dac_signal;
    Rout <= red_signal;
    Gout <= green_signal;
    Bout <= blue_signal;
end architecture;
