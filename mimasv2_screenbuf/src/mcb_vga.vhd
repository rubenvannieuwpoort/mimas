----------------------------------------------------------------------------------
-- Engineer: Mike Field <hasmter@snap.net.nz>
-- 
-- Module Name: mcb_vga.vhd - Behavioral 
--
-- Description: Reads from the MCB to display a picture on the screen.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcb_vga is
	GENERIC (
		-- Timings for 1280x720@60Hx
		hVisible    : natural;
		hSyncStart  : natural;
		hSyncEnd    : natural;
		hMax        : natural;
		hSyncActive : std_logic;

		vVisible    : natural;
		vSyncStart  : natural;
		vSyncEnd    : natural;
		vMax        : natural;
		vSyncActive : std_logic
	);
    Port ( clk_reader : in  STD_LOGIC;
           hsync      : out  STD_LOGIC;
           vsync      : out  STD_LOGIC;
           red        : out  STD_LOGIC_VECTOR (2 downto 0);
           green      : out  STD_LOGIC_VECTOR (2 downto 0);
           blue       : out  STD_LOGIC_VECTOR (2 downto 1);
           
           memory_ready : in  std_logic;

            -- Reads are in a burst length of 16
            read_cmd_enable   : out std_logic;
            read_cmd_refresh  : out  std_logic;
            read_cmd_address  : out std_logic_vector(29 downto 0);
            read_cmd_full     : in  std_logic;
            read_cmd_empty    : in  std_logic;
            --
            read_data_enable  : out std_logic;
            read_data         : in  std_logic_vector(31 downto 0);
            read_data_empty   : in  std_logic;
            read_data_full    : in  std_logic;
            read_data_count   : in  std_logic_vector(6 downto 0)
   );
end mcb_vga;

architecture Behavioral of mcb_vga is
   signal hCounter : unsigned(10 downto 0) := (others => '0');
   signal vCounter : unsigned(10 downto 0) := (others => '0');
   signal address  : unsigned(29 downto 0) := (others => '0');
   signal read_cmd_enable_local : std_logic := '0';
begin
   read_cmd_address <= std_logic_vector(address);
   read_cmd_enable  <= read_cmd_enable_local;

process(clk_reader)
   begin
      if rising_edge(clk_reader) then
         if read_cmd_enable_local = '1' then
            address <= address + 64;  -- Address is the byte address, so each read is 16 words
         end if;

         -------------------------------------------
         -- should we issue a read command?
         -------------------------------------------
         read_cmd_enable_local <= '0';
         if hCounter >= hVisible-64 then
            read_cmd_refresh <= '1';
         else
            read_cmd_refresh <= '0';
         end if;
         if hCounter(5 downto 0) = "111100" then -- once out of 64 cycles
            if vCounter < vVisible-1 then
               if hCounter < hVisible then 
                  -- issue a read every 64th cycle of a visible line (except last)
                  read_cmd_enable_local <= memory_ready and not read_cmd_full;
               end if;
            elsif vCounter = vVisible-1 then
               -- don't issue the last three reads on the last line
               if hCounter < (hVisible-4*64) then 
                  read_cmd_enable_local <= memory_ready and not read_cmd_full;
               end if;
            elsif vCounter = vMax-1 then 
               -- prime the read queue just before the first line with 3 read * 16 words * 4 bytes = 192 bytes
               if hCounter < 4 * 64 then
                  read_cmd_enable_local <= memory_ready and not read_cmd_full;            
               end if;
            end if;   
         end if;
         
         -------------------------------------------
         -- Should we read a word from the read FIFO
         -------------------------------------------
         read_data_enable <= '0';

         -------------------------------------------
         -- Flushing the MCB's read port at the end of frame
         -------------------------------------------
         if vCounter = vVisible then
         --   read_data_enable <= memory_ready and not read_data_empty;
            address <= (others => '0');
         end if;

         -------------------------------------------
         -- Display pixels and trigger data FIFO reads
         -------------------------------------------
         if hCounter < hVisible and vCounter < vVisible then 
            case hcounter(1 downto 0) is
               when "00" =>
                  red   <= read_data( 7 downto 5);
                  green <= read_data( 4 downto 2);
                  blue  <= read_data( 1 downto 0);
               when "01" =>
                  red   <= read_data(15 downto 13);
                  green <= read_data(12 downto 10);
                  blue  <= read_data( 9 downto  8);
               when "10" =>
                  red   <= read_data(23 downto 21);
                  green <= read_data(20 downto 18);
                  blue  <= read_data(17 downto 16);
                  -- read_data_enable will be asserted next cycle,
                  -- so read_data will change the one following that
                  read_data_enable <= memory_ready and not read_data_empty;
               when others =>
                  red   <= read_data(31 downto 29);
                  green <= read_data(28 downto 26);
                  blue  <= read_data(25 downto 24);
            end case; 
         else
            red   <= (others => '0');
            green <= (others => '0');
            blue  <= (others => '0');
         end if;

         -------------------------------------------
         -- track the horizontal and vertical position
         -- and generate sync pulses
         -------------------------------------------
         if hCounter = hMax then
            hCounter <= (others => '0');
            if vCounter = vMax then 
               vCounter <= (others => '0');
            else
               vCounter <= vCounter +1;
            end if;
            
            if vCounter = vSyncStart then
               vSync <= vSyncActive;
            end if;
         
            if vCounter = vSyncEnd then
               vSync <= not vSyncActive;
            end if;
         else
            hCounter <= hCounter+1;
         end if;
         
         if hCounter = hSyncStart then
            hSync <= hSyncActive;
         end if;
         
         if hCounter = hSyncEnd then
            hSync <= not hSyncActive;
         end if;         
      end if;
   end process;
end Behavioral;