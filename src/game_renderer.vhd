library ieee;
use ieee.std_logic_1164.all;
use work.game_pkg.all;

entity game_renderer is
    -- Pixel position, game state and colours.
    port (
        pixel_x : in integer range 0 to 799;
        pixel_y : in integer range 0 to 524;
        game : in game_state_t;
        red : out std_logic_vector(7 downto 0);
        green : out std_logic_vector(7 downto 0);
        blue : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of game_renderer is
begin
    process(pixel_x, pixel_y, game)
        variable border_pixel, left_pixel, right_pixel, ball_pixel : boolean;
    begin
        -- Start with a black pixel.
        red <= x"00";
        green <= x"00";
        blue <= x"00";

        -- Check which object covers this pixel.
        border_pixel :=
            pixel_x >= FIELD_LEFT and pixel_x < FIELD_RIGHT and
            pixel_y >= FIELD_TOP and pixel_y < FIELD_BOTTOM and
            (pixel_y < INNER_TOP or pixel_y >= INNER_BOTTOM or
             ((pixel_x < INNER_LEFT or pixel_x >= INNER_RIGHT) and
              (pixel_y < GATE_TOP or pixel_y >= GATE_BOTTOM)));
        left_pixel := pixel_x >= LEFT_PADDLE_X and
                      pixel_x < LEFT_PADDLE_X + PADDLE_WIDTH and
                      pixel_y >= game.left_y and
                      pixel_y < game.left_y + PADDLE_HEIGHT;
        right_pixel := pixel_x >= RIGHT_PADDLE_X and
                       pixel_x < RIGHT_PADDLE_X + PADDLE_WIDTH and
                       pixel_y >= game.right_y and
                       pixel_y < game.right_y + PADDLE_HEIGHT;
        ball_pixel := pixel_x >= game.ball_x and
                      pixel_x < game.ball_x + BALL_SIZE and
                      pixel_y >= game.ball_y and
                      pixel_y < game.ball_y + BALL_SIZE;

        if pixel_x < SCREEN_WIDTH and pixel_y < SCREEN_HEIGHT then
            -- Draw the blue outer edge.
            if pixel_x >= FIELD_LEFT - 1 and pixel_x <= FIELD_RIGHT and
               pixel_y >= FIELD_TOP - 1 and pixel_y <= FIELD_BOTTOM and
               (pixel_x = FIELD_LEFT - 1 or pixel_x = FIELD_RIGHT or
                pixel_y = FIELD_TOP - 1 or pixel_y = FIELD_BOTTOM) then
                blue <= x"FF";
            end if;

            -- Draw the green field.
            if pixel_x >= FIELD_LEFT and pixel_x < FIELD_RIGHT and
               pixel_y >= FIELD_TOP and pixel_y < FIELD_BOTTOM then
                green <= x"FF";
            end if;

            -- Draw the white border and dashed centre line.
            if border_pixel then
                red <= x"FF";
                green <= x"FF";
                blue <= x"FF";
            elsif pixel_x >= 318 and pixel_x < 322 and
                  pixel_y >= INNER_TOP and pixel_y < INNER_BOTTOM and
                  (pixel_y mod 32) < 16 then
                red <= x"00";
                green <= x"00";
                blue <= x"00";
            end if;

            -- Draw the paddles.
            if left_pixel then
                red <= x"00";
                green <= x"00";
                blue <= x"FF";
            elsif right_pixel then
                red <= x"FF";
                green <= x"00";
                blue <= x"FF";
            end if;

            -- Draw a yellow ball, or red when exiting.
            if ball_pixel then
                red <= x"FF";
                blue <= x"00";
                if game.mode = EXITING then
                    green <= x"00";
                else
                    green <= x"FF";
                end if;
            end if;
        end if;
    end process;
end architecture;
