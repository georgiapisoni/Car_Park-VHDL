library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test is
end test;

architecture testbench of test is
    component Car_Parking_System_VHDL is
    port 
    (
        clk, reset_n                 : in std_logic;
        front_sensor, back_sensor   : in std_logic;
        password_1, password_2      : in std_logic_vector(1 downto 0);
        pswd_in                     : in std_logic;
        GREEN_LED, RED_LED           : out std_logic;
        HEX_1, HEX_2                : out std_logic_vector(6 downto 0);
        car_count                   : out std_logic_vector(7 downto 0)
    );
    end component;

    -- Test signals
    signal clk_tb : std_logic := '0';
    signal reset_n_tb : std_logic := '0';
    signal front_sensor_tb, back_sensor_tb : std_logic := '0';
    signal password_1_tb, password_2_tb : std_logic_vector(1 downto 0) := "00";
    signal pswd_in_tb : std_logic := '0';
    signal GREEN_LED_tb, RED_LED_tb : std_logic;
    signal HEX_1_tb, HEX_2_tb : std_logic_vector(6 downto 0);
    signal car_count_tb : std_logic_vector(7 downto 0);

    -- Clock period
    constant clk_period : time := 20 ns;

begin
    -- Clock generation
    clk_tb <= not clk_tb after clk_period/2;

    -- DUT instantiation
    DUT: Car_Parking_System_VHDL
        port map (
            clk => clk_tb,
            reset_n => reset_n_tb,
            front_sensor => front_sensor_tb,
            back_sensor => back_sensor_tb,
            password_1 => password_1_tb,
            password_2 => password_2_tb,
            pswd_in => pswd_in_tb,
            GREEN_LED => GREEN_LED_tb,
            RED_LED => RED_LED_tb,
            HEX_1 => HEX_1_tb,
            HEX_2 => HEX_2_tb,
            car_count => car_count_tb
        );

    -- Stimulus process
    stimulus: process
    begin
        -- Inizializzazione
        reset_n_tb <= '0';
        front_sensor_tb <= '0';
        back_sensor_tb <= '0';
        password_1_tb <= "00";
        password_2_tb <= "00";
        pswd_in_tb <= '0';
        wait for 100 ns;
        
        -- Deassert reset
        reset_n_tb <= '1';
        wait for 100 ns;
        
        -- Scenario 1: Normal Entry
        report "=== Scenario 1: Normal Entry ===";
        front_sensor_tb <= '1';
        wait for 200 ns;
        
        -- Simula attività tastiera dopo qualche ciclo
        wait for 60 ns;
        pswd_in_tb <= '1';
        wait for clk_period;
        pswd_in_tb <= '0';
        
        -- Inserimento password corretta
        password_1_tb <= "01";
        password_2_tb <= "10";
        wait for 200 ns;
        
        -- Macchina passa
        back_sensor_tb <= '1';
        wait for 100 ns;
        back_sensor_tb <= '0';
        front_sensor_tb <= '0';
        wait for 100 ns;
        
        -- Scenario 2: Wrong Password
        report "=== Scenario 2: Wrong Password ===";
        front_sensor_tb <= '1';
        wait for 200 ns;
        
        pswd_in_tb <= '1';
        wait for clk_period;
        pswd_in_tb <= '0';
        
        -- Password errata
        password_1_tb <= "00";
        password_2_tb <= "00";
        wait for 200 ns;
        
        -- Password corretta
        password_1_tb <= "01";
        password_2_tb <= "10";
        wait for 200 ns;
        
        back_sensor_tb <= '1';
        wait for 100 ns;
        back_sensor_tb <= '0';
        front_sensor_tb <= '0';
        wait for 100 ns;
        
        -- Scenario 3: Multiple Cars
        report "=== Scenario 3: Multiple Cars ===";
        front_sensor_tb <= '1';
        wait for 200 ns;
        
        pswd_in_tb <= '1';
        wait for clk_period;
        pswd_in_tb <= '0';
        
        password_1_tb <= "01";
        password_2_tb <= "10";
        wait for 100 ns;
        
        -- Seconda macchina arriva prima che la prima passi
        front_sensor_tb <= '1'; -- Rimane alto per seconda macchina
        wait for 100 ns;
        
        back_sensor_tb <= '1'; -- Prima macchina passa
        wait for 100 ns;
        back_sensor_tb <= '0';
        
        -- Password per seconda macchina
        pswd_in_tb <= '1';
        wait for clk_period;
        pswd_in_tb <= '0';
        
        password_1_tb <= "01";
        password_2_tb <= "10";
        wait for 200 ns;
        
        back_sensor_tb <= '1';
        wait for 100 ns;
        back_sensor_tb <= '0';
        front_sensor_tb <= '0';
        wait for 100 ns;
        
        -- Scenario 4: Timeout
        report "=== Scenario 4: Timeout ===";
        front_sensor_tb <= '1';
        wait for 400 ns; -- Aspetta senza inserire password
        
        -- Macchina si allontana
        front_sensor_tb <= '0';
        wait for 100 ns;
        
        -- Scenario 5: Reset
        report "=== Scenario 5: Reset ===";
        front_sensor_tb <= '1';
        wait for 100 ns;
        
        pswd_in_tb <= '1';
        wait for clk_period;
        pswd_in_tb <= '0';
        
        password_1_tb <= "01";
        password_2_tb <= "10";
        wait for 100 ns;
        
        -- Reset durante RIGHT_PASS
        reset_n_tb <= '0';
        wait for 100 ns;
        reset_n_tb <= '1';
        
        wait for 200 ns;
        
        report "=== Tutti gli scenari completati ===";
        wait;
    end process;

end testbench;