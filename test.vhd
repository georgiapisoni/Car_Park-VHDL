library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test is
end test;

architecture testbench of test is
    component Car_Parking_System_VHDL is
    port (
        clk, reset_n: in std_logic;
        front_sensor, back_sensor: in std_logic;
        password_1, password_2: in std_logic_vector(1 downto 0);
        GREEN_LED, RED_LED: out std_logic;
        HEX_1, HEX_2: out std_logic_vector(6 downto 0)
    );
    end component;

    signal clk_tb           : std_logic := '0';
    signal reset_n_tb       : std_logic := '0';
    signal front_sensor_tb  : std_logic := '0';
    signal back_sensor_tb   : std_logic := '0';
    signal password_1_tb    : std_logic_vector(1 downto 0) := "00";
    signal password_2_tb    : std_logic_vector(1 downto 0) := "00";
    signal GREEN_LED_tb     : std_logic;
    signal RED_LED_tb       : std_logic;
    signal HEX_1_tb         : std_logic_vector(6 downto 0);
    signal HEX_2_tb         : std_logic_vector(6 downto 0);

    constant clk_period : time := 200 ms;

begin
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for clk_period/2;
            clk_tb <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    DUT: Car_Parking_System_VHDL
    port map (
        clk => clk_tb,
        reset_n => reset_n_tb,
        front_sensor => front_sensor_tb,
        back_sensor => back_sensor_tb,
        password_1 => password_1_tb,
        password_2 => password_2_tb,
        GREEN_LED => GREEN_LED_tb,
        RED_LED => RED_LED_tb,
        HEX_1 => HEX_1_tb,
        HEX_2 => HEX_2_tb
    );

    stimulus: process
    begin
        -- Initial Reset
        reset_n_tb <= '0';
        wait for clk_period * 2;
        reset_n_tb <= '1';
        
        -- No cars for 2 seconds
        wait for 2000 ms;
        
        -- ========== 1stCar 1 ==========
        -- Car 1 Approeaches
        front_sensor_tb <= '1';
        
        -- The system wait for 10 clock cycles (2 seconds) for checking the pw
        -- Meanwhile En and Stable-Red-Led by def of state machine
        wait for 2000 ms;
        
        -- 1st (wrong) attempt!
        password_1_tb <= "11";
        password_2_tb <= "11";
        -- system goes in WRONGPASS and waits
        wait for 1000 ms;
        
        -- After WRONG_PASS, go back in WAIT_PASSWORD and shows "En"
        -- Waits again 10 cycles to check the pw
        wait for 2000 ms;
        
        -- 2nd (correct) attempt! --> Good To Go!
        password_1_tb <= "01";
        password_2_tb <= "10";
        -- System oges in PASS and "Go" displayed
        
        -- Car 1 starts to enter (slowly total time= 3 seconds)
        front_sensor_tb <='0';
        -- After 2 sec, Car #2 approaches
        wait for 2000 ms;
        front_sensor_tb <= '1'; -- Car 2 Approched
        
        -- System in STOP as show "SP" 
        -- Waits for car1 to enter
        wait for 2000 ms;
        back_sensor_tb <= '1'; -- Car 1 entered
        wait for clk_period;
        back_sensor_tb <= '0';
        
        -- ========== Car 2 ==========
        -- After Car1 in inside, system in WAIT_PASSWORD and shows "En" + Reset Password in the machine
        password_1_tb <= "00";
        password_2_tb <= "00";
        
        -- Car 2 waits a little
        wait for 1500 ms;
        
        --  Car 2 enters the pw in 0.5 secondi
        -- btw the system waits 10 clks (2 seconds)  to check the pw
        -- So we wait still 0.5 secondi (totale 2 secondi dall'ingresso in WAIT_PASSWORD)
        wait for 500 ms;
        
        -- Car 2 puts correct pw
        password_1_tb <= "01";
        password_2_tb <= "10";
        
        -- System goes in RIGHT_PASS and shows "GO" 
        -- Car 2 takes 5 seconds to enter
        wait for 1000 ms;
        back_sensor_tb <= '1'; -- Car 2 starts to go through
        front_sensor_tb <= '0'; -- No Car Waiting
        wait for clk_period;
        back_sensor_tb <= '0'; -- Car 2 completely in
        front_sensor_tb <= '0';
        
        -- Fine simulazione
        wait for clk_period * 5;
        
        assert false report "Simulazione completata con successo!" severity note;
        wait;
    end process;

end architecture testbench;