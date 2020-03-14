library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity BlockRam is
  port (
    clka, wea, ena : in  STD_LOGIC;
    addra          : in  STD_LOGIC_VECTOR (8  downto 0);
    dina           : in  STD_LOGIC_VECTOR (31 downto 0);
    douta          : out STD_LOGIC_VECTOR (31 downto 0)
  );
end BlockRam;

architecture Behavioral of BlockRam is

  type ram_type is array (0 to 511) of std_logic_vector (31 downto 0);
  signal ram : ram_type := 
    (                                                        -- ADDR     INSTRUCTION ENCODING IN BITS
    x"40030000",--         xor R3, R3, R3      (mv R3, #0) Result       0x00000000  01000000000000110000000000000000
    x"48640000",--         xor R4, R4, R4      (mv R4, #0) Get a 0      0x00000004  01001000011001000000000000000000
    
    x"8C800030",--         lw  R0, 44(R4)      (lw A, R0)               0x00000008  100011 00100 00000 0000000000101100
    x"8C810034",--         lw  R1, 48(R4)      (lw B, R1)               0x0000000C  100011 00100 00001 0000000000110000
    
    x"40020001",--         lw  R2, 52(R4)      (lw UNO, R2)             0x00000010  100011 00100 00010 0000000000110100
    --x"00012821", -- mul R5,R0,R1 WORKING (Check r5 in the simulation)
    
    x"10240003",-- WHILE:  beq R1, R4, END                              0x00000014  000100 00001 00100 0000000000000011  <-----
    x"00601820",--         add R3, R3, R0                               0x00000018  000000 00011 00000 00011 00000 100000
    
    x"00220822",--         sub R1, R1, R2                               0x0000001C  000000 00001 00010 00001 00000 100010
    
    x"08000005",--         j WHILE                                      0x00000020  000100 00000 00000 1111111111111100
    x"AC830038",-- END:    sw R3, 56(R4)       (sw R3, C)               0x00000024  101011 00100 00011 0000000000111000
  --x"0800000A",-- DONE:   j DONE                                       0x00000028  000100 00000 00000 1111111111111111
    
    
    -- I am adding two instructions, and removing one, thus, the memory positions of A,B (and UNO but it is unused because of the homework changes), are moved 4 bytes, thus, the instructions that 
    -- access A,B (or UNO) must be chamged accordingly:
    
    --Before:
    --x"8C80002C",--         lw  R0, 44(R4)      (lw A, R0)               0x00000008  100011 00100 00000 0000000000101100
    --x"8C810030",--         lw  R1, 48(R4)      (lw B, R1)               0x0000000C  100011 00100 00001 0000000000110000

    --After:
    --x"8C800030",--         lw  R0, 48(R4)      (lw A, R0)               0x00000008  100011 00100 00000 0000000000110000
    --x"8C810034",--         lw  R1, 52(R4)      (lw B, R1)               0x0000000C  100011 00100 00001 0000000000110100

    --In fact, the UNO memory address is where the result of the multiplication is going to be stored.
    
	
	
    x"4006002C",--         mv R6, #48                                    
    x"0CC00000",--         jr R6                                         
    
    x"00000007",--         A                                            0x0000002C +4  0x00000007
    x"00000003",--         B                                            0x00000030 +4  0x00000003
    x"00000001",--         UNO(1) no longer exists. This is C=A*B now   0x00000034 +4  0x00000001
    x"00000000",--         unused                                       0x00000038
    others => x"00000000"
    );


--  type ram_type is array (0 to 511) of std_logic_vector (31 downto 0);
--  signal ram : ram_type := 
--    (          --                                                          ADDR     INSTRUCTION ENCODING IN BITS
--    x"40030000",--         xor R3, R3, R3      (mv R3, #0) Result       0x00000000  01000000000000110000000000000000
--    x"48640000",--         xor R4, R4, R4      (mv R4, #0) Get a 0      0x00000004  01001000011001000000000000000000
    
--    x"8C80002C",--         lw  R0, 44(R4)      (lw A, R0)               0x00000008  100011 00100 00000 0000000000101100
--    x"8C810030",--         lw  R1, 48(R4)      (lw B, R1)               0x0000000C  100011 00100 00001 0000000000110000
    
--    x"40020001",--         lw  R2, 52(R4)      (lw UNO, R2)             0x00000010  100011 00100 00010 0000000000110100
    
--    x"10240003",-- WHILE:  beq R1, R4, END                              0x00000014  000100 00001 00100 0000000000000011
--    x"00601820",--         add R3, R3, R0                               0x00000018  000000 00011 00000 00011 00000 100000
--    x"00220822",--         sub R1, R1, R2                               0x0000001C  000000 00001 00010 00001 00000 100010
--    x"0800FFFC",--         j WHILE                            0x00000020  000100 00000 00000 1111111111111100
--    x"AC830038",-- END:    sw R3, 56(R4)       (sw R3, C)               0x00000024  101011 00100 00011 0000000000111000
--    x"0800FFFF",-- DONE:   j DONE                             0x00000028  000100 00000 00000 1111111111111111
--    x"00000007",--         A                                            0x0000002C  0x00000007
--    x"00000003",--         B                                            0x00000030  0x00000003
--    x"00000001",--         1                                            0x00000034  0x00000001
--    x"BEEFCAFE",--         C = A*B                                      0x00000038
--    others => x"00000000"
--    );

--  type ram_type is array (0 to 511) of std_logic_vector (31 downto 0);
--  signal ram : ram_type := 
--    (          --                                                          ADDR
--    x"00631816",--         xor R3, R3, R3      (mv R3, #0) Result       0x00000000  000000 00011 00011 00011 00000 010110
--    x"00842016",--         xor R4, R4, R4      (mv R4, #0) Get a 0      0x00000004  000000 00100 00100 00100 00000 010110
--    x"8C80002C",--         lw  R0, 44(R4)      (lw A, R0)               0x00000008  100011 00100 00000 0000000000101100
--    x"8C810030",--         lw  R1, 48(R4)      (lw B, R1)               0x0000000C  100011 00100 00001 0000000000110000
--    x"8C820034",--         lw  R2, 52(R4)      (lw UNO, R2)             0x00000010  100011 00100 00010 0000000000110100
--    x"10240003",-- WHILE:  beq R1, R4, END                              0x00000014  000100 00001 00100 0000000000000011
--    x"00601820",--         add R3, R3, R0                               0x00000018  000000 00011 00000 00011 00000 100000
--    x"00220822",--         sub R1, R1, R2                               0x0000001C  000000 00001 00010 00001 00000 100010
--    x"1000FFFC",--         beq R0, R0, WHILE                            0x00000020  000100 00000 00000 1111111111111100
--    x"AC830038",-- END:    sw R3, 56(R4)       (sw R3, C)               0x00000024  101011 00100 00011 0000000000111000
--    x"1000FFFF",-- DONE:   beq R0, R0, DONE                             0x00000028  000100 00000 00000 1111111111111111
--    x"00000007",--         A                                            0x0000002C  0x00000007
--    x"00000003",--         B                                            0x00000030  0x00000003
--    x"00000001",--         1                                            0x00000034  0x00000001
--    x"BEEFCAFE",--         C = A*B                                      0x00000038
--    others => x"00000000"
--    );

begin

  process( clka )
  begin
    if rising_edge(clka) then
      if ena = '1' then
        if wea = '1' then
          ram(to_integer(unsigned(addra))) <= dina;
          douta <= dina;
        else
          douta <= ram(to_integer(unsigned(addra)));
        end if;
      end if;
    end if;
  end process;
  
end Behavioral;

