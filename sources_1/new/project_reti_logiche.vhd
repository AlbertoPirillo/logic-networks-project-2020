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


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
    Port (
           i_clk : in std_logic;
           i_rst : in std_logic;
           i_start : in std_logic;
           i_data : in std_logic_vector(7 downto 0);
           o_address : out std_logic_vector(15 downto 0);
           o_done : out std_logic;
           o_en : out std_logic;
           o_we : out std_logic;
           o_data : out std_logic_vector(7 downto 0)
     );
end project_reti_logiche;




architecture Behavioral of project_reti_logiche is

begin

    -- BEST PRACTICE: std_logic_vector => unsigned => integer (=> back to std_logic_vector) 
    -- TODO: lista di sensibilità
    process(i_clk)
        variable N_COLUMN, N_ROW : std_logic;
        variable MAX_PIXEL_VALUE, MIN_PIXEL_VALUE, OUT_BEGIN : integer;
        variable DELTA_VALUE, SHIFT_LEVEL, TEMP_PIXEL : integer;
    begin
        N_COLUMN := i_data(0);
        N_ROW := i_data(1);
        OUT_BEGIN := 2 + (integer(N_COLUMN) * integer(N_ROW));
        
        
        -- Find highest and the lowest value between all pixels
        MAX_PIXEL_VALUE := integer(i_data(2));
        MIN_PIXEL_VALUE := integer(i_data(2));
        
        for i in 2 to (OUT_BEGIN - 1) loop   
            if integer(i_data(i)) < MIN_PIXEL_VALUE then
                MIN_PIXEL_VALUE := integer(i_data(i));
            elsif integer(i_data(i)) > MAX_PIXEL_VALUE then
                MAX_PIXEL_VALUE := integer(i_data(i));
            end if;
        end loop;     
        
        --Perform the equalization on each pixel
        DELTA_VALUE := MAX_PIXEL_VALUE - MIN_PIXEL_VALUE;
        for i in 2 to (OUT_BEGIN - 1) loop
            -- Compute SHIFT_LEVEL by threshold discretization
            if DELTA_VALUE = 0 then
                SHIFT_LEVEL := 8;     
            elsif DELTA_VALUE >= 1 AND DELTA_VALUE < 3 then
                SHIFT_LEVEL := 7;      
            elsif DELTA_VALUE >= 3 AND DELTA_VALUE < 7 then
                SHIFT_LEVEL := 6;
            elsif DELTA_VALUE >= 7 AND DELTA_VALUE < 15 then
                SHIFT_LEVEL := 5;
            elsif DELTA_VALUE >= 15 AND DELTA_VALUE < 31 then
                SHIFT_LEVEL := 4;
            elsif DELTA_VALUE >= 31 AND DELTA_VALUE < 63 then
                SHIFT_LEVEL := 3;
            elsif DELTA_VALUE >= 63 AND DELTA_VALUE < 127 then
                SHIFT_LEVEL := 2;
            elsif DELTA_VALUE >= 127 AND DELTA_VALUE < 255 then
                SHIFT_LEVEL := 1;
            elsif DELTA_VALUE = 255 then
                SHIFT_LEVEL := 0;   
            end if;    

--            TEMP_PIXEL = (CURRENT_PIXEL_VALUE - MIN_PIXEL_VALUE) << SHIFT_LEVEL;
--            NEW_PIXEL_VALUE = MIN( 255 , TEMP_PIXEL);


        end loop;
        
   end process;
    
end Behavioral;
