----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Alberto Pirillo
-- Professor: Gianluca Palermo
-- Year: 2020/2021
-- Module Name: project_reti_logiche - Behavioral
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity project_reti_logiche is
    port (
        i_clk     : in std_logic;
        i_rst     : in std_logic;
        i_start   : in std_logic;
        i_data    : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done    : out std_logic;
        o_en      : out std_logic;
        o_we      : out std_logic;
        o_data    : out std_logic_vector(7 downto 0)
    );
end project_reti_logiche;



architecture Behavioral of project_reti_logiche is

    type state_type is (IDLE, ASK_DIM, RAM_SYNC, READ_DIM, SAVE_MAX_MIN, COMPUTE_SHIFT, READ_PIXEL, EQ_AND_WRITE, DONE);
    signal curr_state, next_state : state_type;

    signal o_done_next, o_en_next, o_we_next : std_logic := '0';
    signal o_data_next : std_logic_vector(7 downto 0) := "00000000";
    signal o_address_next : std_logic_vector(15 downto 0) := "0000000000000000";

    -- curr_pixel stores the value of a pixel between READ_PIXEL and EQ_AND_WRITE
    signal curr_pixel, curr_pixel_next : integer range 0 to 255 := 0;
    -- Those flags tell whether the two dimensions of the image were already read or not
    signal got_col, got_row, got_col_next, got_row_next : boolean := false;
    -- "Flag signal" used to determine the next state when in RAM_SYNC
    signal max_min_found, max_min_found_next : boolean := false;
    -- Signals used to manipulate o_address more easily
    signal r_address, w_address, r_address_next, w_address_next : std_logic_vector(15 downto 0) := "0000000000000000";

    signal n_col, n_row, n_col_next, n_row_next : integer range 0 to 128 := 0;
    signal out_begin, out_begin_next :  std_logic_vector(15 downto 0) := "0000000000000000";
    signal max_value, max_value_next : integer range 0 to 255 := 0;
    signal min_value, min_value_next : integer range 0 to 255 := 255;
    signal shift_level, shift_level_next: integer range 0 to 255 := 0;

begin
    -- This process implements the registry part
    -- Resets the device is needed, otherwise just updates the registries
    process (i_clk, i_rst)
    begin
        if (i_rst = '1') then
            -- Reset the device
            curr_pixel <= 0;
            got_col <= false;
            got_row <= false;
            max_min_found <= false;
            r_address <= "0000000000000000";
            w_address <= "0000000000000000";
            n_col <= 0;
            n_row <= 0;
            max_value <= 0;
            min_value <= 255;
            out_begin <= "0000000000000000";
            shift_level <= 0;
            curr_state <= IDLE;
    
        elsif rising_edge(i_clk) then
            -- Update the value of the registries
            o_done <= o_done_next;
            o_en <= o_en_next;
            o_we <= o_we_next;
            o_data <= o_data_next;
            o_address <= o_address_next;
            
            curr_pixel <= curr_pixel_next;
            got_col <= got_col_next;
            got_row <= got_row_next;
            max_min_found <= max_min_found_next;
            r_address <= r_address_next;
            w_address <= w_address_next;
            n_col <= n_col_next;
            n_row <= n_row_next;
            max_value <= max_value_next;
            min_value <= min_value_next;
            out_begin <= out_begin_next;
            shift_level <= shift_level_next;

            curr_state <= next_state;
        end if;
    end process;

    -- This process implements the FSM 
    process(curr_state, i_data, i_start, curr_pixel, got_col, got_row, max_min_found,
            r_address, w_address, n_col, n_row, max_value, min_value, out_begin, shift_level)
        
        variable delta_value: integer range 0 to 255 := 0;
        variable i_data_integer: integer range 0 to 255 := 0;
        variable temp_vector : std_logic_vector(15 downto 0) := "0000000000000000";
        variable temp_integer: integer range 0 to 255 := 0;
    
    begin  
        o_done_next <= '0';
        o_en_next <= '0';
        o_we_next <= '0';
        o_data_next <= "00000000";
        o_address_next <= "0000000000000000";
        
        curr_pixel_next <= curr_pixel;
        got_col_next <= got_col;
        got_row_next <= got_row;
        max_min_found_next <= max_min_found;
        r_address_next <= r_address;
        w_address_next <= w_address;
        n_col_next <= n_col;
        n_row_next <= n_row;
        max_value_next <= max_value;
        min_value_next <= min_value;
        out_begin_next <= out_begin;
        shift_level_next <= shift_level;

        next_state <= curr_state;

        -- FSM
        case curr_state is
            when IDLE =>
                if(i_start = '1') then
                        -- Some signals need to be re-initialized for continous operation
                        got_col_next <= false;
                        got_row_next <= false;
                        max_min_found_next <= false;
                        max_value_next <= 0;
                        min_value_next <= 255;
                       
                       -- Prepare to start operating
                       o_en_next <= '1';
                       o_we_next <= '0';
                       next_state <= ASK_DIM;
                end if;

            when ASK_DIM =>
                if got_col = false then
                    o_address_next <= "0000000000000000";
                elsif got_row = false then
                    o_address_next <= "0000000000000001";
                end if;
                o_en_next <= '1';
                o_we_next <= '0';
                next_state <= RAM_SYNC;
            
            when RAM_SYNC =>
                if max_min_found = false and got_row = false then
                    next_state <= READ_DIM; 
                elsif max_min_found = false and got_row = true then
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= "0000000000000011";
                    r_address_next <= "0000000000000011";
                    next_state <= SAVE_MAX_MIN;
                else 
                    next_state <= READ_PIXEL;
                end if;
                      
            when READ_DIM =>
                i_data_integer := to_integer(unsigned(i_data));
                if got_col = false then
                    n_col_next <= i_data_integer;
                    got_col_next <= true;
                    next_state <= ASK_DIM;
                elsif got_row = false then
                    n_row_next <= i_data_integer;
                    out_begin_next <= std_logic_vector(to_unsigned(2 + (n_col * i_data_integer), 16));
                    got_row_next <= true;

                    -- Prepare to read sequentially
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= "0000000000000010";
                    r_address_next <= "0000000000000010";
                    next_state <= RAM_SYNC;
                end if;

            when SAVE_MAX_MIN =>
                -- Update maximum and minimum value
                if r_address <= out_begin then
                    i_data_integer := to_integer(unsigned(i_data));
                    if i_data_integer < min_value then
                        min_value_next <= i_data_integer;
                    end if;
                    if i_data_integer > max_value then
                        max_value_next <= i_data_integer;
                    end if;
                    -- Keep reading sequentially
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= r_address + 1;
                    r_address_next <= r_address + 1;          
                else 
                    -- MAX and MIN found
                    max_min_found_next <= true;
                    next_state <= COMPUTE_SHIFT;
                end if;
        
            when COMPUTE_SHIFT =>
                delta_value := max_value - min_value;
                -- Compute shift_level by threshold discretization
                if delta_value = 0 then
                    shift_level_next <= 8;
                elsif delta_value >= 1 AND delta_value < 3 then
                    shift_level_next <= 7;
                elsif delta_value >= 3 AND delta_value < 7 then
                    shift_level_next <= 6;
                elsif delta_value >= 7 AND delta_value < 15 then
                    shift_level_next <= 5;
                elsif delta_value >= 15 AND delta_value < 31 then
                    shift_level_next <= 4;
                elsif delta_value >= 31 AND delta_value < 63 then
                    shift_level_next <= 3;
                elsif delta_value >= 63 AND delta_value < 127 then
                    shift_level_next <= 2;
                elsif delta_value >= 127 AND delta_value < 255 then
                    shift_level_next <= 1;
                elsif delta_value = 255 then
                    shift_level_next <= 0;
                end if;
                
                -- Prepare to read and write sequentially
                o_en_next <= '1';
                o_we_next <= '0';
                o_address_next <= "0000000000000010";
                r_address_next <= "0000000000000010";
                w_address_next <= out_begin;
                next_state <= RAM_SYNC;

            when READ_PIXEL =>
                if r_address < out_begin then
                    curr_pixel_next <= to_integer(unsigned(i_data));
                    r_address_next <= r_address + 1;

                    -- Ask RAM to load the next pixel
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= r_address + 1;
                    next_state <= EQ_AND_WRITE;
                else 
                    -- Computation is over
                    o_we_next <= '0';
                    o_en_next <= '0';
                    o_done_next <= '1';
                    next_state <= DONE;
                end if;
    
            when EQ_AND_WRITE =>
                temp_integer := curr_pixel - min_value;
                temp_vector := std_logic_vector(shift_left(to_unsigned(temp_integer, 16), shift_level));
                
                -- Select the minimum between 255 and temp_vector
                if to_integer(unsigned(temp_vector)) <= 255 then
                    o_data_next <= temp_vector(7 downto 0);
                else
                    o_data_next <= "11111111";
                end if;
                w_address_next <= w_address + 1;

                -- Write at the next clock cycle
                o_en_next <= '1';
                o_we_next <= '1';
                o_address_next <= w_address;
                next_state <= READ_PIXEL;
                
            when DONE =>
                    next_state <= IDLE;
        end case;
    end process;

end Behavioral;