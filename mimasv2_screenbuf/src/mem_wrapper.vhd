----------------------------------------------------------------------------------
-- Engineer: Mike Field <hasmter@snap.net.nz>
-- 
-- Module Name: mem_wrapper.vhd - Behavioral 
--
-- Description: Creates a tidy interface into the MCB
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_wrapper is
    Port ( 
      clk_sys     : in std_logic;
      clk_sys_out : out std_logic;
      clk_calibration : out std_logic;
      clk_writer  : in std_logic;
      clk_reader  : in std_logic;

      -- Writes are in a burst length of 1
      write_cmd_enable  : in  std_logic;
      write_cmd_empty   : out std_logic;
      write_cmd_full    : out std_logic;
      write_cmd_address : in  std_logic_vector(29 downto 0);
      --
      write_data_enable : in  std_logic;
      write_mask        : in  std_logic_vector(3 downto 0);
      write_data        : in  std_logic_vector(31 downto 0);      
      write_data_empty  : out std_logic;
      write_data_full   : out std_logic;
      write_data_count  : out std_logic_vector(6 downto 0);

      -- Reads are in a burst length of 16
      read_cmd_enable   : in  std_logic;
      read_cmd_address  : in  std_logic_vector(29 downto 0);
      read_cmd_full     : out std_logic;
      read_cmd_empty    : out std_logic;
      --
      read_data_enable  : in  std_logic;
      read_data         : out std_logic_vector(31 downto 0);
      read_data_empty   : out std_logic;
      read_data_full   : out std_logic;
      read_data_count   : out std_logic_vector(6 downto 0);


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
      mcb3_dram_ck_n  : out   std_logic;
      -- status
      calib_done      : out   std_logic;
      read_error      : out   std_logic;
      read_overflow   : out   std_logic;
      write_error     : out   std_logic;
      -- reset         
      reset           : in    std_logic
    );
end mem_wrapper;

architecture Behavioral of mem_wrapper is
component mem32
 generic(
    C3_P0_MASK_SIZE           : integer := 4;
    C3_P0_DATA_PORT_SIZE      : integer := 32;
    C3_P1_MASK_SIZE           : integer := 4;
    C3_P1_DATA_PORT_SIZE      : integer := 32;
    C3_MEMCLK_PERIOD          : integer := 20000;
    C3_RST_ACT_LOW            : integer := 0;
    C3_INPUT_CLK_TYPE         : string := "SINGLE_ENDED";
    C3_CALIB_SOFT_IP          : string := "TRUE";
    C3_SIMULATION             : string := "FALSE";
    DEBUG_EN                  : integer := 1;
    C3_MEM_ADDR_ORDER         : string := "ROW_BANK_COLUMN";
    C3_NUM_DQ_PINS            : integer := 16;
    C3_MEM_ADDR_WIDTH         : integer := 13;
    C3_MEM_BANKADDR_WIDTH     : integer := 2
);
    port (
   mcb3_dram_dq                            : inout  std_logic_vector(C3_NUM_DQ_PINS-1 downto 0);
   mcb3_dram_a                             : out std_logic_vector(C3_MEM_ADDR_WIDTH-1 downto 0);
   mcb3_dram_ba                            : out std_logic_vector(C3_MEM_BANKADDR_WIDTH-1 downto 0);
   mcb3_dram_cke                           : out std_logic;
   mcb3_dram_ras_n                         : out std_logic;
   mcb3_dram_cas_n                         : out std_logic;
   mcb3_dram_we_n                          : out std_logic;
   mcb3_dram_dm                            : out std_logic;
   mcb3_dram_udqs                          : inout  std_logic;
   mcb3_rzq                                : inout  std_logic;
   mcb3_dram_udm                           : out std_logic;
   c3_sys_clk                              : in  std_logic;
   c3_sys_rst_i                            : in  std_logic;
   c3_calib_done                           : out std_logic;
   c3_clk0                                 : out std_logic;
   c3_rst0                                 : out std_logic;
   mcb_drp_clk                               : out std_logic;
   mcb3_dram_dqs                           : inout  std_logic;
   mcb3_dram_ck                            : out std_logic;
   mcb3_dram_ck_n                          : out std_logic;
   c3_p0_cmd_clk                           : in std_logic;
   c3_p0_cmd_en                            : in std_logic;
   c3_p0_cmd_instr                         : in std_logic_vector(2 downto 0);
   c3_p0_cmd_bl                            : in std_logic_vector(5 downto 0);
   c3_p0_cmd_byte_addr                     : in std_logic_vector(29 downto 0);
   c3_p0_cmd_empty                         : out std_logic;
   c3_p0_cmd_full                          : out std_logic;
   c3_p0_wr_clk                            : in std_logic;
   c3_p0_wr_en                             : in std_logic;
   c3_p0_wr_mask                           : in std_logic_vector(C3_P0_MASK_SIZE - 1 downto 0);
   c3_p0_wr_data                           : in std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
   c3_p0_wr_full                           : out std_logic;
   c3_p0_wr_empty                          : out std_logic;
   c3_p0_wr_count                          : out std_logic_vector(6 downto 0);
   c3_p0_wr_underrun                       : out std_logic;
   c3_p0_wr_error                          : out std_logic;
   c3_p0_rd_clk                            : in std_logic;
   c3_p0_rd_en                             : in std_logic;
   c3_p0_rd_data                           : out std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
   c3_p0_rd_full                           : out std_logic;
   c3_p0_rd_empty                          : out std_logic;
   c3_p0_rd_count                          : out std_logic_vector(6 downto 0);
   c3_p0_rd_overflow                       : out std_logic;
   c3_p0_rd_error                          : out std_logic;
   c3_p1_cmd_clk                           : in std_logic;
   c3_p1_cmd_en                            : in std_logic;
   c3_p1_cmd_instr                         : in std_logic_vector(2 downto 0);
   c3_p1_cmd_bl                            : in std_logic_vector(5 downto 0);
   c3_p1_cmd_byte_addr                     : in std_logic_vector(29 downto 0);
   c3_p1_cmd_empty                         : out std_logic;
   c3_p1_cmd_full                          : out std_logic;
   c3_p1_wr_clk                            : in std_logic;
   c3_p1_wr_en                             : in std_logic;
   c3_p1_wr_mask                           : in std_logic_vector(C3_P1_MASK_SIZE - 1 downto 0);
   c3_p1_wr_data                           : in std_logic_vector(C3_P1_DATA_PORT_SIZE - 1 downto 0);
   c3_p1_wr_full                           : out std_logic;
   c3_p1_wr_empty                          : out std_logic;
   c3_p1_wr_count                          : out std_logic_vector(6 downto 0);
   c3_p1_wr_underrun                       : out std_logic;
   c3_p1_wr_error                          : out std_logic;
   c3_p1_rd_clk                            : in std_logic;
   c3_p1_rd_en                             : in std_logic;
   c3_p1_rd_data                           : out std_logic_vector(C3_P1_DATA_PORT_SIZE - 1 downto 0);
   c3_p1_rd_full                           : out std_logic;
   c3_p1_rd_empty                          : out std_logic;
   c3_p1_rd_count                          : out std_logic_vector(6 downto 0);
   c3_p1_rd_overflow                       : out std_logic;
   c3_p1_rd_error                          : out std_logic);
end component;

begin
   
u_mem32 : mem32
   port map (
      c3_sys_clk          => clk_sys,
      c3_sys_rst_i        => reset,
      
      c3_clk0             => clk_sys_out,
      mcb_drp_clk           => clk_calibration,
      c3_rst0             => open,
      c3_calib_done       => calib_done,

      mcb3_dram_dq        => mcb3_dram_dq,  
      mcb3_dram_a         => mcb3_dram_a,  
      mcb3_dram_ba        => mcb3_dram_ba,
      mcb3_dram_ras_n     => mcb3_dram_ras_n,                        
      mcb3_dram_cas_n     => mcb3_dram_cas_n,                        
      mcb3_dram_we_n      => mcb3_dram_we_n,                          
      mcb3_dram_cke       => mcb3_dram_cke,                          
      mcb3_dram_ck        => mcb3_dram_ck,                          
      mcb3_dram_ck_n      => mcb3_dram_ck_n,       
      mcb3_dram_dqs       => mcb3_dram_dqs,                          
      mcb3_dram_udqs      => mcb3_dram_udqs,    -- for X16 parts           
      mcb3_dram_udm       => mcb3_dram_udm,     -- for X16 parts
      mcb3_dram_dm        => mcb3_dram_dm,
      mcb3_rzq            => mcb3_rzq,
      ---------------------------------------------------
      c3_p0_cmd_clk       =>  clk_reader,
      c3_p0_cmd_en        =>  read_cmd_enable,
      c3_p0_cmd_instr     =>  "001", -- read
      c3_p0_cmd_bl        =>  "001111",  -- 16 words
      c3_p0_cmd_byte_addr =>  read_cmd_address,
      c3_p0_cmd_empty     =>  read_cmd_empty,
      c3_p0_cmd_full      =>  read_cmd_full,

      c3_p0_wr_clk        =>  clk_reader,
      c3_p0_wr_en         =>  '0',
      c3_p0_wr_mask       =>  (others => '0'),
      c3_p0_wr_data       =>  (others => '0'),
      c3_p0_wr_full       =>  open,
      c3_p0_wr_empty      =>  open,
      c3_p0_wr_count      =>  open,
      c3_p0_wr_underrun   =>  open,
      c3_p0_wr_error      =>  open,
   
      ---------------------------------------------------
      c3_p0_rd_clk        =>  clk_reader,       -- data FIFO clock
      c3_p0_rd_en         =>  read_data_enable, -- read enable
      c3_p0_rd_data       =>  read_data,        -- read data
      c3_p0_rd_full       =>  read_data_full,   -- read FIFO full
      c3_p0_rd_empty      =>  read_data_empty,  -- read FIFO empty
      c3_p0_rd_count      =>  read_data_count,  -- count in read FIFO
      c3_p0_rd_overflow   =>  read_overflow,    -- read fifo overflow
      c3_p0_rd_error      =>  read_error,       -- read fifo error

      ---------------------------------------------------
      c3_p1_cmd_clk       =>  clk_writer,
      c3_p1_cmd_en        =>  write_cmd_enable,
      c3_p1_cmd_instr     =>  "000", -- write
      c3_p1_cmd_bl        =>  "000000",  -- 1 word
      c3_p1_cmd_byte_addr =>  write_cmd_address,
      c3_p1_cmd_empty     =>  write_cmd_empty,
      c3_p1_cmd_full      =>  write_cmd_full,
    
      c3_p1_wr_clk        =>  clk_writer,
      c3_p1_wr_en         =>  write_data_enable,
      c3_p1_wr_mask       =>  write_mask,
      c3_p1_wr_data       =>  write_data,
      c3_p1_wr_full       =>  write_data_full,
      c3_p1_wr_empty      =>  write_data_empty,
      c3_p1_wr_count      =>  open,
      c3_p1_wr_underrun   =>  open,
      c3_p1_wr_error      =>  write_error,
   
      c3_p1_rd_clk        =>  clk_writer,
      c3_p1_rd_en         =>  '0', 
      c3_p1_rd_data       =>  open,
      c3_p1_rd_full       =>  open,
      c3_p1_rd_empty      =>  open,
      c3_p1_rd_count      =>  open,
      c3_p1_rd_overflow   =>  open,
      c3_p1_rd_error      =>  open
   );     
end Behavioral;
