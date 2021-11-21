----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: zpekic@hotmail.com
-- 
-- Create Date: 08/29/2020 11:13:02 PM
-- Design Name: 
-- Module Name: 
-- Project Name: 
-- Target Devices: https://store.digilentinc.com/anvyl-spartan-6-fpga-trainer-board/
-- Input devices: 
--
-- Tool Versions: ISE 14.7 (nt)
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.99 - Kinda works...
-- Additional Comments:
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sys_sbc8085 is
    Port ( 
	 			-- 100MHz on the Anvyl board
				CLK: in std_logic;
				-- Switches
				-- SW(0) -- LED display selection
				-- SW(2 downto 1) -- tracing selection
				-- SW(3)
				-- SW(4)
				-- SW(6 downto 5) -- system clock speed 
				-- SW7
				SW: in std_logic_vector(7 downto 0); 
				-- Push buttons 
				-- BTN0 - 
				-- BTN1 - 
				-- BTN2 - 
				-- BTN3 - 
				BTN: in std_logic_vector(3 downto 0); 
				-- 6 7seg LED digits
				SEG: out std_logic_vector(6 downto 0); 
				AN: out std_logic_vector(5 downto 0); 
				DP: out std_logic; 
				-- 8 single LEDs
				LED: out std_logic_vector(7 downto 0);
				--PMOD interface
				JA1: inout std_logic;
				JA2: inout std_logic;
				JA3: inout std_logic;
				JA4: inout std_logic;
				--JB1: inout std_logic;
				--JB2: buffer std_logic;
				--JB3: in std_logic;
				--JB4: inout std_logic;
				--DIP switches
				--DIP_B4, DIP_B3, DIP_B2, DIP_B1: in std_logic;
				--DIP_A4, DIP_A3, DIP_A2, DIP_A1: in std_logic;
--				-- Hex keypad
				--KYPD_COL: out std_logic_vector(3 downto 0);
				--KYPD_ROW: in std_logic_vector(3 downto 0);
				-- SRAM --
				--SRAM_CS1: out std_logic;
				--SRAM_CS2: out std_logic;
				--SRAM_OE: out std_logic;
				--SRAM_WE: out std_logic;
				--SRAM_UPPER_B: out std_logic;
				--SRAM_LOWER_B: out std_logic;
				--Memory_address: out std_logic_vector(18 downto 0);
				--Memory_data: inout std_logic_vector(15 downto 0);
				-- Red / Yellow / Green LEDs
				--LDT1G: out std_logic;
				--LDT1Y: out std_logic;
				--LDT1R: out std_logic;
				--LDT2G: out std_logic;
				--LDT2Y: out std_logic;
				--LDT2R: out std_logic;
				-- VGA
				HSYNC_O: out std_logic;
				VSYNC_O: out std_logic;
				RED_O: out std_logic_vector(3 downto 0);
				GREEN_O: out std_logic_vector(3 downto 0);
				BLUE_O: out std_logic_vector(3 downto 0)
				-- TFT
--				TFT_R_O: out std_logic_vector(7 downto 0);
--				TFT_G_O: out std_logic_vector(7 downto 0);
--				TFT_B_O: out std_logic_vector(7 downto 0);
--				TFT_CLK_O: out std_logic;
--				TFT_DE_O: out std_logic;
--				TFT_DISP_O: out std_logic;
--				TFT_BKLT_O: out std_logic;
--				TFT_VDDEN_O: out std_logic;
				-- breadboard signal connections
				--BB1: inout std_logic;
				--BB2: inout std_logic;
				--BB3: inout std_logic;
				--BB4: out std_logic;
				--BB5: inout std_logic;
				--BB6: inout std_logic;
				--BB7: inout std_logic;
				--BB8: inout std_logic;
				--BB9: inout std_logic;
				--BB10: in std_logic
          );
end sys_sbc8085;

architecture Structural of sys_sbc8085 is

-- Core components
component uart_ser2par is
    Port ( reset : in  STD_LOGIC;
           rxd_clk : in  STD_LOGIC;
           mode : in  STD_LOGIC_VECTOR (2 downto 0);
           char : out  STD_LOGIC_VECTOR (7 downto 0);
           ready : buffer  STD_LOGIC;
           valid : out  STD_LOGIC;
           rxd : in  STD_LOGIC);
end component;

component uart_par2ser is
    Port ( reset : in  STD_LOGIC;
			  txd_clk: in STD_LOGIC;
			  send: in STD_LOGIC;
			  mode: in STD_LOGIC_VECTOR(2 downto 0);
			  data: in STD_LOGIC_VECTOR(7 downto 0);
           ready : buffer STD_LOGIC;
           txd : out  STD_LOGIC);
end component;

-- Misc components
component sn74hc4040 is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           q : out  STD_LOGIC_VECTOR(11 downto 0));
end component;

component freqcounter is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           freq : in  STD_LOGIC;
           bcd : in  STD_LOGIC;
			  add: in STD_LOGIC_VECTOR(31 downto 0);
			  cin: in STD_LOGIC;
			  cout: out STD_LOGIC;
           value : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component debouncer8channel is
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           signal_raw : in STD_LOGIC_VECTOR (7 downto 0);
           signal_debounced : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component sixdigitsevensegled is
    Port ( -- inputs
			  hexdata : in  STD_LOGIC_VECTOR (23 downto 0);
           digsel : in  STD_LOGIC_VECTOR (2 downto 0);
           showdigit : in  STD_LOGIC_VECTOR (5 downto 0);
           showdot : in  STD_LOGIC_VECTOR (5 downto 0);
           showsegments : in  STD_LOGIC;
			  -- outputs
           anode : out  STD_LOGIC_VECTOR (5 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

component tty2vga is
    Port ( reset : in  STD_LOGIC;
           tty_clk : in  STD_LOGIC;
           char : in  STD_LOGIC_VECTOR (7 downto 0);
			  char_sent: out STD_LOGIC;
			  cur_clk : in  STD_LOGIC;
           vga_clk : in  STD_LOGIC;
           vga_hsync : out  STD_LOGIC;
           vga_vsync : out  STD_LOGIC;
           vga_r : out  STD_LOGIC_VECTOR (3 downto 0);
           vga_g : out  STD_LOGIC_VECTOR (3 downto 0);
           vga_b : out  STD_LOGIC_VECTOR (3 downto 0);
			  -- debug only --
			  debug : out STD_LOGIC_VECTOR(31 downto 0)
			  );
end component;
	
type table_8x16 is array (0 to 7) of std_logic_vector(15 downto 0);
constant uartmode_debug: table_8x16 := (
	X"8001",	-- 8N1
	X"8001",
	X"8001",
	X"8001",
	X"8111",	-- 8, parity space, 1 stop
	X"8002",	-- 8, parity mark, 1 == 8, no parity, 2 stop
	X"8101",	-- 8, parity even, 1 stop
	X"8011"	-- 8, parity odd, 1 stop
);

constant clk_board: integer := 100000000;

type prescale_lookup is array (0 to 7) of integer range 0 to 65535;
constant prescale_value: prescale_lookup := (
		(clk_board / (16 * 600)),
		(clk_board / (16 * 1200)),
		(clk_board / (16 * 2400)),
		(clk_board / (16 * 4800)),
		(clk_board / (16 * 9600)),
		(clk_board / (16 * 19200)),
		(clk_board / (16 * 38400)),
		(clk_board / (16 * 57600))
	);

-- Connect to PmodUSBUART 
alias PMOD_RTS: std_logic is JA1;	
alias PMOD_RXD: std_logic is JA2;
alias PMOD_TXD: std_logic is JA3;
alias PMOD_CTS: std_logic is JA4;	

-- 
signal reset: std_logic;

-- debug
signal showdigit, showdot: std_logic_vector(3 downto 0);
--signal charpat: std_logic_vector(7 downto 0);
--signal symbol_d: std_logic_vector(7 downto 0);
--signal symbol_a: std_logic_vector(12 downto 0);
signal led_debug, hexin_debug, hexout_debug, baudrate_debug, tty_debug: std_logic_vector(31 downto 0);

--- frequency signals
signal freq_50M: std_logic_vector(11 downto 0);
alias debounce_clk: std_logic is freq_50M(9);

signal freq4096: std_logic;		
signal freq_2048: std_logic_vector(11 downto 0);
signal prescale_baud, prescale_power: integer range 0 to 65535;

-- input by switches and buttons
signal switch, button: std_logic_vector(7 downto 0);
alias switch_sel:	std_logic_vector(1 downto 0) is switch(7 downto 6);
alias switch_uart_rate: std_logic_vector(2 downto 0) is switch(5 downto 3);
alias switch_uart_mode: std_logic_vector(2 downto 0) is switch(2 downto 0);
signal btn_command, btn_window: std_logic_vector(3 downto 0);

-- HEX common 
signal baudrate_x1, baudrate_x2, baudrate_x4, baudrate_x8: std_logic;
signal mux_clk: std_logic;

-- HEX output path
signal tx_send: std_logic;
signal tx_char: std_logic_vector(7 downto 0);
signal tty_sent, tty_sent_delayed: std_logic;
alias tty_clk: std_logic is freq_50M(2); --freq_2048(11);

-- HEX input path
signal rx_ready: std_logic;
signal rx_char: std_logic_vector(7 downto 0);

-- UART control registers
--signal uart_baudsel, uart_modesel: std_logic_vector(2 downto 0);

begin

-- no separate reset button
reset <= '1' when (BTN = "1111") else '0';

-- various clock signal generation (main clock domain is derived from external clock)
	
clockgen: sn74hc4040 port map (
			clock => CLK,	-- 100MHz crystal on Anvyl board
			reset => RESET,
			q => freq_50M
		);
		
prescale: process(CLK, baudrate_x8, freq4096, switch_uart_rate)
begin
	if (rising_edge(CLK)) then
		if (prescale_baud = 0) then
			baudrate_x8 <= not baudrate_x8;
			prescale_baud <= prescale_value(to_integer(unsigned(switch_uart_rate)));
		else
			prescale_baud <= prescale_baud - 1;
		end if;
		if (prescale_power = 0) then
			freq4096 <= not freq4096;
			prescale_power <= (clk_board / (2 * 4096));
		else
			prescale_power <= prescale_power - 1;
		end if;
	end if;
end process;

powergen: sn74hc4040 port map (
			clock => freq4096,
			reset => RESET,
			q => freq_2048
		);
	
baudgen: sn74hc4040 port map (
			clock => baudrate_x8,
			reset => RESET,
			q(0) => baudrate_x4, 
			q(1) => baudrate_x2,
			q(2) => baudrate_x1,
			q(11 downto 3) => open		
		);	
		
-- common clock for hex input and output processors
--hex_clk <= freq(to_integer(4 + unsigned(switch_hexclk)));
--with switch_tmclk select mux_clk <=
--	freq4 	when "000",	-- lentissimo
--	freq16	when "001",	-- lento
--	freq4096 when "010",	-- vivace
--	freq(9) when "011",	-- 0.09375MHz
--	freq(8) when "100",	-- 0.1875HHz
--	freq(7) when "101",	-- 0.375MHz
--	freq(6) when "110",	-- 0.75MHz	
--	freq(5) when others;	-- 1.50MHz	


	debounce_sw: debouncer8channel Port map ( 
		clock => debounce_clk, 
		reset => RESET,
		signal_raw => SW,
		signal_debounced => switch
	);

	debounce_btn: debouncer8channel Port map ( 
		clock => debounce_clk, 
		reset => RESET,
		signal_raw(7 downto 4) => "0000",
		signal_raw(3 downto 0) => BTN,
		signal_debounced => button
	);
	
counter: freqcounter Port map ( 
		reset => RESET,
      clk => freq_2048(11),
      freq => baudrate_x1,
		bcd => '1',
		add => X"00000001",
		cin => '1',
		cout => open,
      value => baudrate_debug
	);
			
LED <= tx_char; --freq_2048(11 downto 4);
			
-- loopback
uart_rx: uart_ser2par Port map ( 
		reset => reset, 
		rxd_clk => baudrate_x4,
		mode => switch_uart_mode,
		char => rx_char,
		ready => rx_ready,
		valid => open,
		rxd => PMOD_TXD
		);

uart_tx: uart_par2ser Port map (
		reset => reset,
		txd_clk => baudrate_x1,
		send => tx_send,
		mode => switch_uart_mode,
		data => tx_char,
		ready => open,
		txd => PMOD_RXD
		);
			
tx_send <= not rx_ready;

on_rx_ready: process(rx_ready, rx_char, tty_sent)
begin
	if ((reset or (tty_sent and (not tty_sent_delayed))) = '1') then
		tx_char <= X"00";	-- to stop VGA to echo forever
	else
		if (rising_edge(rx_ready)) then
			tx_char <= rx_char;
		end if;
	end if;
end process;

on_tty_clk: process(tty_clk, tty_sent)
begin
	if (rising_edge(tty_clk)) then
		tty_sent_delayed <= tty_sent;
	end if;
end process;

-- echo to VGA
tty: tty2vga Port map(
		reset => reset,
		tty_clk => tty_clk, --freq_2048(11), --freq_50M(2),		-- 12.5MHz
		char => tx_char,
		char_sent => tty_sent,
		cur_clk => freq_2048(10),	-- 2Hz
		vga_clk => freq_50M(1),		-- 25MHz
		vga_hsync => HSYNC_O,
		vga_vsync => VSYNC_O,
		vga_r => RED_O,
		vga_g => GREEN_O,
		vga_b => BLUE_O,
		-- debug
		debug => tty_debug
		);

-- 7 seg LED debug display		
with switch_sel select led_debug <= 
	tty_debug when "00",
	"11111111" & X"543210" when "01",
	baudrate_debug when "10",
	X"0000" & uartmode_debug(to_integer(unsigned(switch_uart_mode))) when others;
	
led6: sixdigitsevensegled Port map ( 
		-- inputs
		hexdata => led_debug(23 downto 0),
		digsel => freq_2048(3 downto 1),
		showdigit => "111111",
		showdot => led_debug(29 downto 24),
		showsegments => '1',
		-- outputs
		anode => AN,
		segment(6 downto 0) => SEG,
		segment(7) => DP
		);

				
end;
