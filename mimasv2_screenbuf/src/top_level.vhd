----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
--
-- Module : top_level.vhd
-- 
-- Description: Test of a MCB based 1280x720 frame buffer.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( 
      clk_50          : in  STD_LOGIC;
      -- VGA Port
      hsync           : out STD_LOGIC;
      vsync           : out STD_LOGIC;
      red             : out std_logic_vector(2 downto 0);      
      green           : out std_logic_vector(2 downto 0);
      blue            : out std_logic_vector(2 downto 1);
      -- Status LEDs
      led_calibrate   : out STD_LOGIC;
      led_written     : out STD_LOGIC;
      -- Memory Signals
      mcb3_dram_dq    : inout std_logic_vector(15 downto 0);
      mcb3_dram_a     : out   std_logic_vector(12 downto 0);
      mcb3_dram_ba    : out   std_logic_vector( 1 downto 0);
      mcb3_dram_cke   : out   std_logic;
      mcb3_dram_ras_n : out   std_logic;
      mcb3_dram_cas_n : out   std_logic;
      mcb3_dram_we_n  : out   std_logic;
      mcb3_dram_dm    : out   std_logic;
      mcb3_dram_udqs  : inout std_logic;
      mcb3_rzq        : inout std_logic;
      mcb3_dram_udm   : out   std_logic;
      mcb3_dram_dqs   : inout std_logic;
      mcb3_dram_ck    : out   std_logic;
      mcb3_dram_ck_n  : out   std_logic
    );
end top_level;

architecture Behavioral of top_level is
   -- Timings for 1280x720@60Hz, 75Mhz pixel clock
   constant hVisible    : natural := 1280;
   constant hSyncStart  : natural := 1352;
   constant hSyncEnd    : natural := 1432;
   constant hMax        : natural := 1647;
   constant hSyncActive : std_logic := '1';

   constant vVisible    : natural := 720;
   constant vSyncStart  : natural := 723;
   constant vSyncEnd    : natural := 728;
   constant vMax        : natural := 750;
   constant vSyncActive : std_logic := '1';

   COMPONENT mem_wrapper
   PORT(
      clk_sys     : IN  std_logic;
      clk_sys_out : OUT std_logic;
      clk_reader  : IN  std_logic;
      clk_writer  : IN  std_logic;
      clk_calibration : out std_logic;

      write_cmd_enable  : IN  std_logic;
      write_cmd_address : IN  std_logic_vector(29 downto 0);
      write_cmd_empty   : OUT std_logic;
      write_cmd_full    : OUT std_logic;
      write_data_empty  : OUT std_logic;
      write_data_full   : OUT std_logic;
      write_data_count  : OUT std_logic_vector(6 downto 0);
      write_data_enable : IN  std_logic;
      write_mask        : in  std_logic_vector(3 downto 0);
      write_data        : IN  std_logic_vector(31 downto 0);
      write_error       : OUT std_logic;

      read_cmd_enable   : IN  std_logic;
      read_cmd_address  : IN  std_logic_vector(29 downto 0);
      read_data_enable  : IN  std_logic;    
      read_cmd_empty    : OUT std_logic;
      read_cmd_full     : OUT std_logic;
      read_data         : OUT std_logic_vector(31 downto 0);
      read_data_empty   : OUT std_logic;
      read_data_full    : OUT std_logic;
      read_data_count   : OUT std_logic_vector(6 downto 0);
      read_overflow     : OUT std_logic;
      read_error        : OUT std_logic;

      mcb3_dram_dq     : INOUT std_logic_vector(15 downto 0);
      mcb3_dram_udqs   : INOUT std_logic;
      mcb3_rzq         : INOUT std_logic;
      mcb3_dram_dqs    : INOUT std_logic;      
      mcb3_dram_a      : OUT   std_logic_vector(12 downto 0);
      mcb3_dram_ba     : OUT   std_logic_vector(1 downto 0);
      mcb3_dram_cke    : OUT   std_logic;
      mcb3_dram_ras_n  : OUT   std_logic;
      mcb3_dram_cas_n  : OUT   std_logic;
      mcb3_dram_we_n   : OUT   std_logic;
      mcb3_dram_dm     : OUT   std_logic;
      mcb3_dram_udm    : OUT   std_logic;
      mcb3_dram_ck     : OUT   std_logic;
      mcb3_dram_ck_n   : OUT   std_logic;
      
      reset            : IN    std_logic;
      calib_done       : OUT   std_logic
      );
   END COMPONENT;

   COMPONENT Test_pattern_writer GENERIC (
		hVisible : natural;
		vVisible : natural
	);
	PORT(
      clk               : IN  std_logic;
      completed         : OUT std_logic;
      memory_ready      : IN  std_logic;
      write_cmd_empty   : IN  std_logic;
      write_cmd_full    : IN  std_logic;
      write_data_empty  : IN  std_logic;
      write_data_count  : IN  std_logic_vector(6 downto 0);          
      write_cmd_enable  : OUT std_logic;
      write_cmd_address : OUT std_logic_vector(29 downto 0);
      write_data_enable : OUT std_logic;
      write_mask        : OUT std_logic_vector(3 downto 0);
      write_data        : OUT std_logic_vector(31 downto 0)
      );
   END COMPONENT;

   COMPONENT mcb_vga
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
	PORT (
      clk_reader : IN std_logic;
      
      hsync           : OUT std_logic;
      vsync           : OUT std_logic;
      red             : OUT std_logic_vector(2 downto 0);
      green           : OUT std_logic_vector(2 downto 0);      
      blue            : OUT std_logic_vector(2 downto 1);
      
      memory_ready     : IN  std_logic;

      read_cmd_enable  : OUT std_logic;
      read_cmd_address : OUT std_logic_vector(29 downto 0);
      read_data_enable : OUT std_logic;          
      
      read_cmd_full   : IN std_logic;
      read_cmd_empty  : IN std_logic;
      read_data       : IN std_logic_vector(31 downto 0);
      read_data_empty : IN std_logic;
      read_data_full  : IN std_logic;
      read_data_count : IN std_logic_vector(6 downto 0)
      );
   END COMPONENT;

	-- clocks --
   signal clk_75            : std_logic;
   signal clk_reader        : std_logic;
   signal clk_writer        : std_logic;

	-- Read port signals --
   signal read_cmd_enable   : std_logic := '0';
   signal read_cmd_address  : std_logic_vector(29 downto 0) := (others => '0');
   signal read_cmd_empty    : std_logic;
   signal read_cmd_full     : std_logic;
   signal read_error        : std_logic;

   signal read_data         : std_logic_vector(31 downto 0);
   signal read_data_enable  : std_logic := '0';
   signal read_data_empty   : std_logic;
   signal read_data_full    : std_logic;
   signal read_data_count   : std_logic_vector(6 downto 0);
   signal read_overflow     : std_logic;

	-- Write port signals --
   signal write_cmd_enable  : std_logic := '0';
   signal write_cmd_address : std_logic_vector(29 downto 0)  := (others => '0');
   signal write_cmd_empty   : std_logic;
   signal write_cmd_full    : std_logic;
   signal write_error       : std_logic;
      
   signal write_data_empty  : std_logic;
   signal write_data_full   : std_logic;
   signal write_data_count  : std_logic_vector(6 downto 0);
   signal write_data_enable : std_logic := '0';
   signal write_mask        : std_logic_vector(3 downto 0);
   signal write_data        : std_logic_vector(31 downto 0) := (others => '0');
	
	-- Status signals --
   signal memory_ready      : std_logic;
   signal memory_written    : std_logic;
   signal reset             : std_logic := '0';

begin
   led_calibrate <= memory_ready;  -- this LED is red  (L2)
   led_written   <= memory_written;  -- this LED is green(L1)   
   
   clk_writer <= clk_75;
   clk_reader <= clk_75;
   
   Inst_mem_wrapper: mem_wrapper PORT MAP(
      clk_sys     => clk_50,
      clk_sys_out => open,
      clk_calibration => clk_75,
      
      -- Write port
      clk_writer        => clk_writer,
      write_cmd_enable  => write_cmd_enable,
      write_cmd_empty   => write_cmd_empty,
      write_cmd_full    => write_cmd_full,
      write_cmd_address => write_cmd_address,
      write_error       => write_error,
      
      write_data_enable => write_data_enable,
      write_mask        => write_mask,
      write_data        => write_data,
      write_data_full   => write_data_full,
      write_data_empty  => write_data_empty,
      write_data_count  => write_data_count,
      
      -- Read port
      clk_reader        => clk_reader,
      read_cmd_enable   => read_cmd_enable,
      read_cmd_address  => read_cmd_address,
      read_cmd_full     => read_cmd_full,
      read_cmd_empty    => read_cmd_empty,
      read_error        => read_error,
      read_overflow     => read_overflow,
      
      read_data_enable  => read_data_enable,
      read_data         => read_data,
      read_data_full    => read_data_full,
      read_data_empty   => read_data_empty,
      read_data_count   => read_data_count,
      
      -- Memory chip interface
      mcb3_dram_dq      => mcb3_dram_dq,
      mcb3_dram_a       => mcb3_dram_a,
      mcb3_dram_ba      => mcb3_dram_ba,
      mcb3_dram_cke     => mcb3_dram_cke,
      mcb3_dram_ras_n   => mcb3_dram_ras_n,
      mcb3_dram_cas_n   => mcb3_dram_cas_n,
      mcb3_dram_we_n    => mcb3_dram_we_n,
      mcb3_dram_dm      => mcb3_dram_dm,
      mcb3_dram_udqs    => mcb3_dram_udqs,
      mcb3_rzq          => mcb3_rzq,
      mcb3_dram_udm     => mcb3_dram_udm,
      mcb3_dram_dqs     => mcb3_dram_dqs,
      mcb3_dram_ck      => mcb3_dram_ck,
      mcb3_dram_ck_n    => mcb3_dram_ck_n,
      
      -- Status
      calib_done => memory_ready,
      
      -- reset
      reset => reset
   );
   
   Inst_Test_pattern_writer: Test_pattern_writer GENERIC MAP (
		hVisible => hVisible,
		vVisible => vVisible
	) PORT MAP(
      clk               => clk_writer,
      completed         => memory_written,
      memory_ready      => memory_ready,
      write_cmd_enable  => write_cmd_enable,
      write_cmd_address => write_cmd_address,
      write_cmd_empty   => write_cmd_empty,
      write_cmd_full    => write_cmd_full,
      write_data_empty  => write_data_empty,
      write_data_count  => write_data_count,
      write_data_enable => write_data_enable,
      write_mask        => write_mask,
      write_data        => write_data
   );

inst_vga: mcb_vga GENERIC MAP (
		hVisible    => hVisible,
		hSyncStart  => hSyncStart,
		hSyncEnd    => hSyncEnd,
		hMax        => hMax,
		hSyncActive => hSyncActive,

		vVisible    => vVisible,
		vSyncStart  => vSyncStart,
		vSyncEnd    => vSyncEnd,
		vMax        => vMax,
		vSyncActive => vSyncActive
	) PORT MAP (
      hsync => hsync,
      vsync => vsync,
      red   => red,
      green => green,
      blue  => blue,

		-- Only start reading pixels once the frame buffer has been written
      memory_ready      => memory_written,

      -- Read port
      clk_reader        => clk_reader,
      read_cmd_enable   => read_cmd_enable,
      read_cmd_address  => read_cmd_address,
      read_cmd_full     => read_cmd_full,
      read_cmd_empty    => read_cmd_empty,      
      read_data_enable  => read_data_enable,
      read_data         => read_data,
      read_data_full    => read_data_full,
      read_data_empty   => read_data_empty,
      read_data_count   => read_data_count
   );
	
end Behavioral;