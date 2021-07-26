----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Alberto Pirillo
-- 
-- Create Date: 25.07.2021 00:17:22
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
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

    type state_type is (IDLE, FETCH_COL, FETCH_ROW, SAVE_IMG, COMPUTE_DELTA, COMPUTE_SHIFT, EQUALIZE_AND_WRITE, DONE);
    type pixel_array is array (16383 downto 0) of std_logic_vector(7 downto 0);
    
    signal curr_state, next_state : state_type;
    signal mem_img : pixel_array;

    signal o_done_next, o_en_next, o_we_next : std_logic := '0';
	signal o_data_next : std_logic_vector(7 downto 0) := "00000000";
	signal o_address_next : std_logic_vector(15 downto 0) := "0000000000000000";
    
    signal curr_pixel, curr_pixel_next : integer range 0 to 16383;
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
            n_column <= 0;
            n_row <= 0;
            max_value <= 0;
            min_value <= 255;
            out_begin <= 0;
            delta_value <= 0;
            shift_level <= 0;
            temp_pixel <= 0;
            curr_state <= IDLE;
    
        elsif (i_clk'event and i_clk = '1') then
            -- Update the value of the signals
            o_done <= o_done_next;
            o_en <= o_en_next;
            o_we <= o_we_next;
            o_data <= o_data_next;
            o_address <= o_address_next;

            curr_pixel <= curr_pixel_next;
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


    -- TODO: lista di sensibilità
    process(curr_state, i_data, i_start, curr_pixel, n_column, n_row, max_value, min_value, out_begin, delta_value, shift_level, temp_pixel)
        variable i_data_integer, temp_integer: integer range 0 to 255;
        variable temp_vector : std_logic_vector(7 downto 0);
    begin  
        o_done_next <= '0';
--        o_en_next <= '0';
--        o_we_next <= '0';
        o_data_next <= "00000000";
        o_address_next <= "0000000000000000";
        
        curr_pixel_next <= curr_pixel;
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
                    o_en_next <= '1';
                    o_we_next <= '0';
                    next_state <= FETCH_COL;
                end if;

            when FETCH_COL =>
                n_column_next <= conv_integer(i_data);
                next_state <= FETCH_ROW;

            when FETCH_ROW =>
                n_row_next <= conv_integer(i_data);
                out_begin_next <= 2 + (n_column * n_row);
                next_state <= SAVE_IMG;

            when SAVE_IMG =>
                -- Save pixel to memory
                mem_img(curr_pixel) <= i_data; 
                curr_pixel_next <= curr_pixel + 1;
                -- Update maximum and minimum value
                i_data_integer := conv_integer(i_data);
                if i_data_integer < min_value then
                    min_value_next <= i_data_integer;
                elsif i_data_integer > max_value then
                    max_value_next <= i_data_integer;
                end if;
                next_state <= COMPUTE_DELTA;

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
                curr_pixel_next <= 0;
                o_we_next <= '1';
                next_state <= EQUALIZE_AND_WRITE;

            when EQUALIZE_AND_WRITE =>
                if curr_pixel <= ((n_column * n_row) - 1) then
                    temp_integer := (conv_integer(mem_img(curr_pixel)) - min_value);
                    temp_vector := std_logic_vector(shift_left(to_unsigned(temp_integer, 8), shift_level));
                    o_data_next <= std_logic_vector(to_unsigned(minimum(255, to_integer(unsigned(temp_vector))), 8));
                    o_address_next <= std_logic_vector(to_unsigned((out_begin + curr_pixel), 16));
                    curr_pixel_next <= curr_pixel + 1;
                else 
                    o_done_next <= '1';
                    next_state <= DONE;
                end if;
                
            when DONE =>
                    next_state <= IDLE;
        end case;
    end process;

end Behavioral;
