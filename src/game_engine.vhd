library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;

entity game_engine is
    -- Game settings and inputs.
    generic (
        STATIC_MODE : boolean := false;
        SERVE_FRAMES : positive := 45
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        frame_tick : in std_logic;
        switches : in std_logic_vector(3 downto 0);
        game : out game_state_t
    );
end entity;

architecture rtl of game_engine is
    -- Current game state.
    signal state : game_state_t := INITIAL_GAME;
begin
    assert SERVE_FRAMES <= 255
        report "SERVE_FRAMES must be between 1 and 255" severity failure;

    process(clk)
    begin
        if rising_edge(clk) then
            -- Reset or update once per frame.
            if reset = '1' then
                state <= INITIAL_GAME;
            elsif frame_tick = '1' and not STATIC_MODE then
                state <= advance_game(state, switches, SERVE_FRAMES);
            end if;
        end if;
    end process;

    game <= state;
end architecture;
