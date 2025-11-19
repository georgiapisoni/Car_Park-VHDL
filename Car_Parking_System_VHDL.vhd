library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Car_Parking_System_VHDL is
port 
(
    clk, reset_n                 : in std_logic;
    front_sensor, back_sensor   : in std_logic;
    password_1, password_2      : in std_logic_vector(1 downto 0);
    GREEN_LED, RED_LED           : out std_logic;
    HEX_1, HEX_2                : out std_logic_vector(6 downto 0)
);
end Car_Parking_System_VHDL;

architecture Behavioral of Car_Parking_System_VHDL is 
    type state_types is (IDLE, WAIT_PASSWORD, WRONG_PASS, 
                        RIGHT_PASS, STOP);
    signal current_state, next_state: state_types;
    signal counter_wait: unsigned(3 downto 0) := (others => '0');
    signal counter_wrong: unsigned(1 downto 0) := (others => '0');
    signal red_tmp, green_tmp: std_logic;
    signal blink_counter: unsigned(1 downto 0) := (others => '0');

    signal password_accepted: std_logic := '0';
    signal password_checked: std_logic := '0';

begin
    -- State register
    process(clk, reset_n)
    begin
        if(reset_n='0') then
            current_state <= IDLE;
            password_accepted <= '0';
            password_checked <= '0';
        elsif(rising_edge(clk)) then
            current_state <= next_state;
            
            -- Reset password_accepted when returns to IDLE or WAIT_PASSWORD
            if current_state = IDLE then
                password_accepted <= '0';
                password_checked <= '0';
            elsif current_state = WAIT_PASSWORD then
                password_checked <= '0';
            end if;
        end if; 
    end process;

    -- Transition process
    process(current_state, front_sensor, back_sensor, counter_wait, counter_wrong, 
            password_1, password_2, password_accepted, password_checked)
    begin
        case current_state is
            when IDLE =>  
                if front_sensor = '1' then
                    next_state <= WAIT_PASSWORD;
                else
                    next_state <= IDLE;
                end if;
                
            when WAIT_PASSWORD =>
                if counter_wait < 9 then
                    next_state <= WAIT_PASSWORD;
                else
                    if (password_1 = "01" and password_2 = "10") then
                        next_state <= RIGHT_PASS;
                        password_accepted <= '1';
                        password_checked <= '1';
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
                
        end case; 
    end process;

    -- Counter Process for WAIT_PASSWORD
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            counter_wait <= (others => '0');
        elsif rising_edge(clk) then
            if current_state = WAIT_PASSWORD then
                if counter_wait < 9 then
                    counter_wait <= counter_wait + 1;
                end if;
            else
                counter_wait <= (others => '0');
            end if;
        end if;
    end process;

    -- Counter Process for WRONG_PASS
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            counter_wrong <= (others => '0');
        elsif rising_edge(clk) then
            if current_state = WRONG_PASS then
                if counter_wrong < 3 then
                    counter_wrong <= counter_wrong + 1;
                else
                    counter_wrong <= (others => '0');
                end if;
            else
                counter_wrong <= (others => '0');
            end if;
        end if;
    end process;

    -- Blink counter
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
                    HEX_1     <= "1111111";
                    HEX_2     <= "1111111";
                    
                when WAIT_PASSWORD =>
                    green_tmp <= '0';
                    red_tmp   <= '1';
                    HEX_1     <= "0000110";
                    HEX_2     <= "0101011";
                    
                when WRONG_PASS =>
                    green_tmp <= '0';
                    red_tmp   <= blink_fast;
                    HEX_1     <= "0000110";
                    HEX_2     <= "0000110";
                    
                when RIGHT_PASS =>
                    green_tmp <= blink_fast;
                    red_tmp   <= '0';
                    HEX_1     <= "0000010";
                    HEX_2     <= "1000000";
                    
                when STOP => 
                    green_tmp <= '0';
                    red_tmp   <= blink_fast;
                    HEX_1     <= "0100100";
                    HEX_2     <= "0001100";
            end case;
        end if;
    end process;
    
    GREEN_LED <= green_tmp;
    RED_LED   <= red_tmp;

end architecture;