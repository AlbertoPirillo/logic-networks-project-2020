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

    -- TODO: lista di sensibilitÓ
    process(i_clk)
        variable N_COLUMN, N_ROW : std_logic;
        variable MAX_PIXEL_VALUE, MIN_PIXEL_VALUE, OUT_BEGIN : integer;
    begin
        N_COLUMN := i_data(0);
        N_ROW := i_data(1);
        OUT_BEGIN := 2 + (integer(N_COLUMN) * integer(N_ROW));
    end process;
    
end Behavioral;
