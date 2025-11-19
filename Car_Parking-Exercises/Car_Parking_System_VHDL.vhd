library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Car_Parking_System_VHDL is
port 
(
    clk, reset_n                 : in std_logic;
    front_sensor, back_sensor    : in std_logic;
    password_1, password_2       : in std_logic_vector(1 downto 0);
    pswd_in                      : in std_logic;                     --checks status of password input interface
    GREEN_LED, RED_LED           : out std_logic;
    HEX_1, HEX_2                 : out std_logic_vector(6 downto 0);
    car_count                    : out std_logic_vector(7 downto 0)  -- car counter (up to 255)
);
end Car_Parking_System_VHDL;

architecture Behavioral of Car_Parking_System_VHDL is 
    type state_types is (IDLE, WAIT_PASSWORD, WRONG_PASS, 
                        RIGHT_PASS, STOP, TIMEOUT); 
    signal current_state, next_state    : state_types;

    signal counter_wait                 : unsigned(3 downto 0)  := (others => '0');
    signal counter_wrong                : unsigned(1 downto 0)  := (others => '0');

    signal red_tmp, green_tmp           : std_logic;
    signal blink_counter                : unsigned(1 downto 0)  := (others => '0');
    
    signal timeout_counter              : unsigned(3 downto 0) := (others => '0');
    signal internal_car_count           : unsigned(7 downto 0) := (others => '0');
    
    signal password_accepted            : std_logic            := '0';
    signal password_checked             : std_logic            := '0';
    signal pswd_activity                : std_logic            := '0';



begin
    -- State register
    process(clk, reset_n)
    begin
        if(reset_n='0') then
            current_state <= IDLE;
            password_accepted <= '0';
            password_checked <= '0';
            pswd_activity <= '0';
        elsif(rising_edge(clk)) then
            current_state <= next_state;
            
            -- Reset password_accepted when in IDLE or WAIT_PASSWORD
            if current_state = IDLE then
                password_accepted <= '0';
                password_checked <= '0';
                pswd_activity <= '0';
            elsif current_state = WAIT_PASSWORD then
                password_checked <= '0';
                -- checks activity in password input interface
                if pswd_in = '1' then
                    pswd_activity <= '1';
                end if;
            end if;
        end if; 
    end process;

    -- Transition process
    process(current_state, front_sensor, back_sensor, counter_wait, counter_wrong, 
            password_1, password_2, password_accepted, password_checked, timeout_counter, pswd_activity)
    begin
        case current_state is
            when IDLE =>  
                if front_sensor = '1' then
                    next_state <= WAIT_PASSWORD;
                else
                    next_state <= IDLE;
                end if;
                
            when WAIT_PASSWORD =>
                if timeout_counter >= 10 and pswd_activity = '0' then
                    next_state <= TIMEOUT;                  -- timeout state if no activity after 10 ck cycles
                elsif counter_wait <= 9 then
                    next_state <= WAIT_PASSWORD;
                else
                    if (password_1 = "01" and password_2 = "10") then
                        next_state <= RIGHT_PASS;
                        password_accepted <= '1';
                        password_checked <= '1';
                        --reset password!!!!!!!!!!! --wdym
                        
                    else
                        next_state <= WRONG_PASS;
                        password_checked <= '1';
                    end if;
                end if;
                
            when WRONG_PASS => 
                if counter_wrong >= 2 then
                    next_state <= WAIT_PASSWORD;
                else
                    next_state <= WRONG_PASS;
                end if;
                
            when RIGHT_PASS =>
                if front_sensor = '1' and password_checked = '1' then
                    next_state <= STOP;
                elsif back_sensor = '1' then
                    next_state <= IDLE;
                else
                    next_state <= RIGHT_PASS;
                end if;
                
            when STOP => 
                if back_sensor = '1' then
                    next_state <= WAIT_PASSWORD;
                else
                    next_state <= STOP;
                end if;
                
            when TIMEOUT =>
                -- if car goes away, returns to IDLE state
                if front_sensor = '0' then
                    next_state <= IDLE;
                else
                    next_state <= TIMEOUT;
                end if;
                
        end case; 
    end process;

    -- WAIT_PASSWORD - counter process (10 ck cycles)
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            counter_wait <= (others => '0');
        elsif rising_edge(clk) then
            if current_state = WAIT_PASSWORD then
                if counter_wait <= 9 then                        -- changed to <=9
                    counter_wait <= counter_wait + 1;
                end if;
            else
                counter_wait <= (others => '0');
            end if;
        end if;
    end process;

    -- WRONG_PASSWORD - counter (3 ck cycles)
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            counter_wrong <= (others => '0');
        elsif rising_edge(clk) then
            if current_state = WRONG_PASS then
                if counter_wrong < 4 then
                    counter_wrong <= counter_wrong + 1;
                else
                    counter_wrong <= (others => '0');
                end if;
            else
                counter_wrong <= (others => '0');
            end if;
        end if;
    end process;

    -- TIMEOUT - counter  (14 ck cycles)
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            timeout_counter <= (others => '0');
        elsif rising_edge(clk) then
            if current_state = WAIT_PASSWORD then
                if timeout_counter < 15 then  
                    timeout_counter <= timeout_counter + 1;
                end if;
            else
                timeout_counter <= (others => '0');
            end if;
        end if;
    end process;

    -- CAR COUNTER - increments when cars enter parking lot
    --!!current: Incrementa il contatore quando si passa da RIGHT_PASS a IDLE (macchina entrata)
    --!!!idea - increments when back-sensor = 1

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            internal_car_count <= (others => '0');
        elsif rising_edge(clk) then
            if current_state = RIGHT_PASS and next_state = IDLE then
                internal_car_count <= internal_car_count + 1;
            end if;
        end if;
    end process;
    car_count <= std_logic_vector(internal_car_count);

    -- 1 HZ Prescaler - Blink counter
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            blink_counter <= (others => '0');
        elsif rising_edge(clk) then
            blink_counter <= blink_counter + 1;
        end if;
    end process;

    -- Output process
    process(clk)
        variable blink_fast : std_logic;
    begin
        blink_fast := blink_counter(0);
        
        if rising_edge(clk) then
            case current_state is
                when IDLE => 
                    green_tmp <= '0';
                    red_tmp   <= '0';
                    HEX_1     <= "1111111"; -- off
                    HEX_2     <= "1111111"; -- off
                    
                when WAIT_PASSWORD =>
                    green_tmp <= '0';
                    red_tmp   <= '1';
                    HEX_1     <= "0000110"; -- E
                    HEX_2     <= "0101011"; -- n
                    
                when WRONG_PASS =>
                    green_tmp <= '0';
                    red_tmp   <= blink_fast;
                    HEX_1     <= "0000110"; -- E
                    HEX_2     <= "0000110"; -- E
                    
                when RIGHT_PASS =>
                    green_tmp <= blink_fast;
                    red_tmp   <= '0';
                    HEX_1     <= "0000010"; -- G
                    HEX_2     <= "1000000"; -- O
                    
                when STOP => 
                    green_tmp <= '0';
                    red_tmp   <= blink_fast;
                    HEX_1     <= "0100100"; -- S
                    HEX_2     <= "0001100"; -- P
                    
                when TIMEOUT =>
                    green_tmp <= '0';
                    red_tmp   <= blink_fast;
                    HEX_1     <= "0000111"; -- T 
                    HEX_2     <= "1000000"; -- O
                    
            end case;
        end if;
    end process;
    
    GREEN_LED <= green_tmp;
    RED_LED   <= red_tmp;

end architecture;