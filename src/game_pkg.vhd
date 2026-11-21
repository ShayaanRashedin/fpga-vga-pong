library ieee;
use ieee.std_logic_1164.all;

package game_pkg is
    -- Screen and game sizes.
    constant SCREEN_WIDTH : integer := 640;
    constant SCREEN_HEIGHT : integer := 480;
    constant FIELD_LEFT : integer := 16;
    constant FIELD_RIGHT : integer := 624;
    constant FIELD_TOP : integer := 16;
    constant FIELD_BOTTOM : integer := 464;
    constant BORDER_SIZE : integer := 8;
    constant INNER_LEFT : integer := FIELD_LEFT + BORDER_SIZE;
    constant INNER_RIGHT : integer := FIELD_RIGHT - BORDER_SIZE;
    constant INNER_TOP : integer := FIELD_TOP + BORDER_SIZE;
    constant INNER_BOTTOM : integer := FIELD_BOTTOM - BORDER_SIZE;
    constant GATE_TOP : integer := 128;
    constant GATE_BOTTOM : integer := 352;
    constant PADDLE_WIDTH : integer := 12;
    constant PADDLE_HEIGHT : integer := 72;
    constant LEFT_PADDLE_X : integer := 40;
    constant RIGHT_PADDLE_X : integer := 588;
    constant PADDLE_SPEED : integer := 4;
    constant BALL_SIZE : integer := 12;
    constant BALL_SPEED : integer := 3;
    constant CENTRE_X : integer := (SCREEN_WIDTH - BALL_SIZE) / 2;
    constant CENTRE_Y : integer := (SCREEN_HEIGHT - BALL_SIZE) / 2;

    -- Store positions, directions and game mode.
    type game_mode_t is (SERVING, PLAYING, EXITING);
    type game_state_t is record
        left_y : integer range INNER_TOP to INNER_BOTTOM - PADDLE_HEIGHT;
        right_y : integer range INNER_TOP to INNER_BOTTOM - PADDLE_HEIGHT;
        ball_x : integer range -BALL_SIZE to SCREEN_WIDTH;
        ball_y : integer range INNER_TOP to INNER_BOTTOM - BALL_SIZE;
        going_right : boolean;
        going_down : boolean;
        mode : game_mode_t;
        wait_count : integer range 0 to 255;
    end record;

    -- Starting positions.
    constant INITIAL_GAME : game_state_t := (
        left_y => 320,
        right_y => 80,
        ball_x => CENTRE_X,
        ball_y => CENTRE_Y,
        going_right => true,
        going_down => true,
        mode => SERVING,
        wait_count => 0
    );

    function clamp(value, minimum, maximum : integer) return integer;
    function advance_game(current : game_state_t;
                          switches : std_logic_vector(3 downto 0);
                          serve_frames : positive) return game_state_t;
end package;

package body game_pkg is
    -- Keep a value within its limits.
    function clamp(value, minimum, maximum : integer) return integer is
    begin
        if value < minimum then
            return minimum;
        elsif value > maximum then
            return maximum;
        else
            return value;
        end if;
    end function;

    function advance_game(current : game_state_t;
                          switches : std_logic_vector(3 downto 0);
                          serve_frames : positive) return game_state_t is
        variable result : game_state_t;
        variable next_x, next_y : integer;
        variable left_hit, right_hit, side_solid : boolean;
    begin
        result := current;

        -- Move the left paddle.
        if switches(0) = '1' and switches(1) = '0' then
            result.left_y := clamp(current.left_y - PADDLE_SPEED,
                                   INNER_TOP, INNER_BOTTOM - PADDLE_HEIGHT);
        elsif switches(0) = '0' and switches(1) = '1' then
            result.left_y := clamp(current.left_y + PADDLE_SPEED,
                                   INNER_TOP, INNER_BOTTOM - PADDLE_HEIGHT);
        end if;

        -- Move the right paddle.
        if switches(2) = '1' and switches(3) = '0' then
            result.right_y := clamp(current.right_y - PADDLE_SPEED,
                                    INNER_TOP, INNER_BOTTOM - PADDLE_HEIGHT);
        elsif switches(2) = '0' and switches(3) = '1' then
            result.right_y := clamp(current.right_y + PADDLE_SPEED,
                                    INNER_TOP, INNER_BOTTOM - PADDLE_HEIGHT);
        end if;

        -- Wait before serving the ball.
        if current.mode = SERVING then
            if current.wait_count >= serve_frames - 1 then
                result.mode := PLAYING;
                result.wait_count := 0;
            else
                result.wait_count := current.wait_count + 1;
            end if;
            return result;
        end if;

        -- Find the next ball position.
        if current.going_right then
            next_x := current.ball_x + BALL_SPEED;
        else
            next_x := current.ball_x - BALL_SPEED;
        end if;
        if current.going_down then
            next_y := current.ball_y + BALL_SPEED;
        else
            next_y := current.ball_y - BALL_SPEED;
        end if;

        -- Bounce off the top and bottom.
        if next_y < INNER_TOP then
            next_y := 2 * INNER_TOP - next_y;
            result.going_down := true;
        elsif next_y > INNER_BOTTOM - BALL_SIZE then
            next_y := 2 * (INNER_BOTTOM - BALL_SIZE) - next_y;
            result.going_down := false;
        end if;

        -- Restart after the ball leaves the screen.
        if current.mode = EXITING then
            if next_x <= -BALL_SIZE or next_x >= SCREEN_WIDTH then
                result.ball_x := CENTRE_X;
                result.ball_y := CENTRE_Y;
                result.going_right := not current.going_right;
                result.going_down := not current.going_down;
                result.mode := SERVING;
                result.wait_count := 0;
            else
                result.ball_x := next_x;
                result.ball_y := next_y;
            end if;
            return result;
        end if;

        -- Check for paddle hits.
        left_hit := not current.going_right and
                    current.ball_x >= LEFT_PADDLE_X + PADDLE_WIDTH and
                    next_x <= LEFT_PADDLE_X + PADDLE_WIDTH and
                    next_y < result.left_y + PADDLE_HEIGHT and
                    next_y + BALL_SIZE > result.left_y;
        right_hit := current.going_right and
                     current.ball_x + BALL_SIZE <= RIGHT_PADDLE_X and
                     next_x + BALL_SIZE >= RIGHT_PADDLE_X and
                     next_y < result.right_y + PADDLE_HEIGHT and
                     next_y + BALL_SIZE > result.right_y;

        if left_hit then
            next_x := 2 * (LEFT_PADDLE_X + PADDLE_WIDTH) - next_x;
            result.going_right := true;
        elsif right_hit then
            next_x := 2 * (RIGHT_PADDLE_X - BALL_SIZE) - next_x;
            result.going_right := false;
        else
            -- Bounce off a side wall or leave through a gate.
            side_solid := next_y < GATE_TOP or next_y + BALL_SIZE > GATE_BOTTOM;
            if not current.going_right and next_x < INNER_LEFT then
                if side_solid then
                    next_x := 2 * INNER_LEFT - next_x;
                    result.going_right := true;
                else
                    result.mode := EXITING;
                end if;
            elsif current.going_right and next_x + BALL_SIZE > INNER_RIGHT then
                if side_solid then
                    next_x := 2 * (INNER_RIGHT - BALL_SIZE) - next_x;
                    result.going_right := false;
                else
                    result.mode := EXITING;
                end if;
            end if;
        end if;

        result.ball_x := next_x;
        result.ball_y := next_y;
        return result;
    end function;
end package body;
