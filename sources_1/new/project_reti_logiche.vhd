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
    Port (
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

    type state_type is (IDLE, FETCH_COL, FETCH_ROW, SAVE_MAX_MIN, COMPUTE_DELTA, COMPUTE_SHIFT, READ_PIXEL, EQUALIZE_AND_WRITE, DONE);
    signal curr_state, next_state : state_type;

    signal o_done_next, o_en_next, o_we_next : std_logic := '0';
	signal o_data_next : std_logic_vector(7 downto 0) := "00000000";
	signal o_address_next : std_logic_vector(15 downto 0) := "0000000000000000";

    -- TODO: all these signals should be initialized
    signal curr_pixel, curr_pixel_next : integer range 0 to 255;
    signal r_address, w_address, r_address_next, w_address_next : std_logic_vector(15 downto 0) := "0000000000000000";
    signal n_column, n_row, n_column_next, n_row_next : integer range 0 to 128;
    signal max_value, min_value, max_value_next, min_value_next : integer range 0 to 255;
    signal out_begin, out_begin_next : integer range 0 to 255;
    signal delta_value, shift_level, temp_pixel, delta_value_next, shift_level_next, temp_pixel_next : integer range 0 to 255;

begin
    -- This process updates resets the device or updates the signals
    process (i_clk, i_rst)
    begin
        if (i_rst = '1') then
            -- Initialize the device
            curr_pixel <= 0;
            r_address <= "0000000000000000";
            w_address <= "0000000000000000";
            n_column <= 0;
            n_row <= 0;
            max_value <= 0;
            min_value <= 255;
            out_begin <= 0;
            delta_value <= 0;
            shift_level <= 0;
            temp_pixel <= 0;
            curr_state <= IDLE;
    
        -- TODO: change this to use rising_edge
        elsif rising_edge(i_clk) then
            -- Update the value of the signals
            o_done <= o_done_next;
            o_en <= o_en_next;
            o_we <= o_we_next;
            o_data <= o_data_next;
            o_address <= o_address_next;
            
            curr_pixel <= curr_pixel_next;
            r_address <= r_address_next;
            w_address <= w_address_next;
            n_column <= n_column_next;
            n_row <= n_row_next;
            max_value <= max_value_next;
            min_value <= min_value_next;
            out_begin <= out_begin_next;
            delta_value <= delta_value_next;
            shift_level <= shift_level_next;
            temp_pixel <= temp_pixel_next;

            curr_state <= next_state;
        end if;
    end process;


    process(curr_state, i_data, i_start, curr_pixel, r_address, w_address, n_column,
            n_row, max_value, min_value, out_begin, delta_value, shift_level, temp_pixel)
        
        variable i_data_integer: integer range 0 to 255 := 0;
        variable temp_vector : std_logic_vector(7 downto 0) := "00000000";
        variable temp_integer: integer range 0 to 255 := 0;
    
    begin  
        o_done_next <= '0';
        o_en_next <= '0';
        o_we_next <= '0';
        o_data_next <= "00000000";
        o_address_next <= "0000000000000000";
        
        curr_pixel_next <= curr_pixel;
        r_address_next <= r_address;
        w_address_next <= w_address;
        n_column_next <= n_column;
        n_row_next <= n_row;
        max_value_next <= max_value;
        min_value_next <= min_value;
        out_begin_next <= out_begin;
        delta_value_next <= delta_value;
        shift_level_next <= shift_level;
        temp_pixel_next <= temp_pixel;

        next_state <= curr_state;

        -- FSA
        case curr_state is
            when IDLE =>
                if(i_start = '1') then
                    next_state <= FETCH_COL;
                end if;

            when FETCH_COL =>
                n_column_next <= conv_integer(i_data);
                o_address_next <= "0000000000000001";
                next_state <= FETCH_ROW;

            when FETCH_ROW =>
                n_row_next <= conv_integer(i_data);
                o_address_next <= "0000000000000010";
                r_address_next <= "0000000000000010";
                out_begin_next <= 2 + (n_column * conv_integer(i_data));
                next_state <= SAVE_MAX_MIN;

            when SAVE_MAX_MIN =>
                -- Update maximum and minimum value
                if r_address < out_begin then
                    i_data_integer := conv_integer(i_data);
                    if i_data_integer < min_value then
                        min_value_next <= i_data_integer;
                    elsif i_data_integer > max_value then
                        max_value_next <= i_data_integer;
                    end if;
                    o_address_next <= r_address + 1;
                    r_address_next <= r_address + 1;
                else 
                    -- MAX and MIN found
                    o_en_next <= '0';
                    next_state <= COMPUTE_DELTA;
                end if;

            when COMPUTE_DELTA =>
                delta_value_next <= max_value - min_value;
                next_state <= COMPUTE_SHIFT;
        
            when COMPUTE_SHIFT =>
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
                o_en_next <= '1';
                o_we_next <= '0';
                r_address_next <= "0000000000000010";
                o_address_next <= "0000000000000010";
                w_address_next <= std_logic_vector(to_unsigned(out_begin, 16));
                next_state <= READ_PIXEL;

            when READ_PIXEL =>
                if r_address < out_begin then
                    curr_pixel_next <= to_integer(unsigned(i_data));

                    -- Prepare to write in the next state
                    o_we_next <= '1';
                    o_address_next <= w_address;
                
                    r_address_next <= r_address + 1;
                    next_state <= EQUALIZE_AND_WRITE;
                else 
                    o_we_next <= '0';
                    o_en_next <= '0';
                    next_state <= DONE;
                end if;
    
            when EQUALIZE_AND_WRITE =>
                temp_integer := curr_pixel - min_value;
                temp_vector := std_logic_vector(shift_left(to_unsigned(temp_pixel, 8), shift_level));
                o_data_next <= std_logic_vector(to_unsigned(minimum(255, to_integer(unsigned(temp_vector))), 8));
                
                -- Prepare to read in the next state
                o_we_next <= '0';
                o_address_next <= r_address;

                w_address_next <= w_address + 1;
                next_state <= READ_PIXEL;
                
            when DONE =>
                    next_state <= IDLE;
        end case;
    end process;

end Behavioral;
