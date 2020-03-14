library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dataPath is
  port( 
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    control : in  std_logic_vector(19 downto 0);
    Zero    : out std_logic;
    op      : out std_logic_vector(5 downto 0)
  );
end dataPath;

architecture dataPathArch of dataPath is

  component reg
    generic(
      n : positive := 32
    );
    port( 
      clk   : in  std_logic;
      rst_n : in  std_logic;
      load  : in  std_logic;
      din   : in  std_logic_vector( n-1 downto 0 );
      dout  : out std_logic_vector( n-1 downto 0 ) 
    );
  end component;
  
  component multiplexer2to1
    generic(
      bits_inputs: positive := 32
    ); 
    port( 
      input0  : in  std_logic_vector(bits_inputs-1 downto 0); 
      input1  : in  std_logic_vector(bits_inputs-1 downto 0); 
      selector: in  std_logic; 
      output  : out std_logic_vector(bits_inputs-1 downto 0)  
    ); 
  end component; 

  component multiplexer4to1 
    generic(
      bits_inputs: positive := 32
    ); 
    port( 
      input0  : in  std_logic_vector(bits_inputs-1 downto 0);
      input1  : in  std_logic_vector(bits_inputs-1 downto 0);
      input2  : in  std_logic_vector(bits_inputs-1 downto 0);
      input3  : in  std_logic_vector(bits_inputs-1 downto 0);
      selector: in  std_logic_vector(1 downto 0); 
      output  : out std_logic_vector(bits_inputs-1 downto 0)  
    ); 
  end component;

  component memory is
    port( 
      clk      : in  std_logic;
      ADDR     : in  std_logic_vector(31 downto 0 );
      MemWrite : in  std_logic;
      MemRead  : in  std_logic;
      DW       : in  std_logic_vector(31 downto 0 );
      DR       : out std_logic_vector(31 downto 0 ) 
    );
  end component;  
  
  
  component registerBank
    port( 
      clk      : in  std_logic;
      rst_n    : in  std_logic;
      RA       : in  std_logic_vector(4 downto 0);
      RB       : in  std_logic_vector(4 downto 0);
      RegWrite : in  std_logic;
      RW       : in  std_logic_vector(4 downto 0);
      busW     : in  std_logic_vector(31 downto 0);
      busA     : out std_logic_vector(31 downto 0);
      busB     : out std_logic_vector(31 downto 0) 
    );
  end component;  
  
  component ALU
    port(     
      A      : in  std_logic_vector(31 downto 0);
      B      : in  std_logic_vector(31 downto 0);
      ALUop  : in  std_logic_vector(1 downto 0);
      funct  : in  std_logic_vector(5 downto 0);
      Zero   : out std_logic;
      R      : out std_logic_vector(31 downto 0)
    );
  end component;  
  
  signal control_aux : std_logic_vector(19 downto 0);
  
  alias PCWrite      : std_logic is control_aux(0);
  alias IorD         : std_logic is control_aux(1);
  alias MemWrite     : std_logic is control_aux(2);
  alias MemRead      : std_logic is control_aux(3);
  alias IRWrite      : std_logic is control_aux(4);
  alias RegDst       : std_logic is control_aux(5);
  
  --increased (mv r)
  alias MemtoReg     : std_logic_vector(1 downto 0) is control_aux(7 downto 6);
  
  alias RegWrite     : std_logic is control_aux(8);
  alias AWrite       : std_logic is control_aux(9);
  alias BWrite       : std_logic is control_aux(10);  
  
  --increased (mv i)
  alias ALUScrA      : std_logic_vector(1 downto 0) is control_aux(12 downto 11);
  alias ALUScrB      : std_logic_vector(1 downto 0) is control_aux(14 downto 13);
  
  alias OutWrite     : std_logic is control_aux(15);
  alias ALUop        : std_logic_vector(1 downto 0) is control_aux(17 downto 16);
  alias PCMux        : std_logic_vector is control_aux(19 downto 18);
  
  -------------------------------------------------------
  
  signal outputALU       : std_logic_vector(31 downto 0);
  signal PC              : std_logic_vector(31 downto 0);
  signal ALUOut          : std_logic_vector(31 downto 0);
  signal ADDR            : std_logic_vector(31 downto 0);
  signal A               : std_logic_vector(31 downto 0);
  signal B               : std_logic_vector(31 downto 0);
  signal outputMem       : std_logic_vector(31 downto 0);
  signal IR              : std_logic_vector(31 downto 0) := (others => '0');
  signal OPA             : std_logic_vector(31 downto 0);
  signal OPB             : std_logic_vector(31 downto 0);
  signal RW              : std_logic_vector(4 downto 0);
  signal busW            : std_logic_vector(31 downto 0);
  signal extended_sign   : std_logic_vector(31 downto 0);
  signal shifted         : std_logic_vector(31 downto 0);
  signal outputRegBankA : std_logic_vector(31 downto 0);
  signal outputRegBankB : std_logic_vector(31 downto 0);  
  
  signal outputMuxPC    : std_logic_vector(31 downto 0) := (others => '0');
  signal extendedAddr   : std_logic_vector(31 downto 0); 
  
begin

  control_aux <= control;
  op <= IR(31 downto 26);
  
  extendedAddr <= "0000"&IR(25 downto 0)&"00";

  -- NEW COMPONENT FOR j INSTRUCTION
  mux_PC   : multiplexer4to1 port map(input0 => outputALU, input1 => extendedAddr, input2 => A , input3 => A , selector => PCMux, output => outputMuxPC);  
  
  -- ALSO MODIFIED
  reg_PC   : reg port map(clk => clk, rst_n => rst_n, load => PCWrite, din => outputMuxPC, dout => PC);

  mux_IorD : multiplexer2to1 port map(input0 => PC, input1 => ALUOut, selector => IorD, output => ADDR); 

  mem      : memory port map(clk => clk, ADDR => ADDR, MemWrite => MemWrite, MemRead => MemRead, DW => B, DR => outputMem);
  
  reg_IR   : reg port map(clk => clk, rst_n => rst_n, load => IRWrite, din => outputMem, dout => IR);
  
  mux_RW   : multiplexer2to1 generic map (bits_inputs => 5) port map(input0 => IR(20 downto 16), input1 => IR(15 downto 11), selector => RegDst, output => RW);
  
  --MODIFIED from a 2 to 1   to a  4 to 1
  mux_MDR  : multiplexer4to1 port map(input0 => ALUout, input1 => outputMem, input2 => A, input3 => (others => '0'), selector => MemtoReg, output => busW);
  
  -- Sign extension
  extended_sign(15 downto 0) <= IR(15 downto 0);
  extended_sign(31 downto 16) <= x"FFFF" when (IR(15) = '1') else x"0000";
  
  -- <<2
  shifted <= extended_sign(29 downto 0)&"00";
    
  register_bank: registerBank port map(clk => clk, rst_n => rst_n, RA => IR(25 downto 21), RB => IR(20 downto 16), RegWrite => RegWrite, RW => RW, busW => busW, busA => outputRegBankA, busB => outputRegBankB);
  
  reg_A        : reg port map(clk => clk, rst_n => rst_n, load => AWrite, din => outputRegBankA, dout => A);
  
  reg_B        : reg port map(clk => clk, rst_n => rst_n, load => BWrite, din => outputRegBankB, dout => B);
  
  --MODIFIED from a 2 to 1   to a  4 to 1
  mux_opA      : multiplexer4to1 port map(input0 => PC, input1 => A, input2 => (others => '0'), input3 => (others => '0'), selector => ALUScrA, output => OPA);
  
  mux_opB      : multiplexer4to1 port map(input0 => B, input1 => x"00000004", input2 => extended_sign, input3 => shifted, selector => ALUScrB, output => OPB); 
  
  ALU_i        : ALU port map(A => OPA, B => OPB, ALUop => ALUop, funct => IR(5 downto 0), Zero => Zero, R => outputALU);
  
  reg_ALUout   : reg port map(clk => clk, rst_n => rst_n, load => OutWrite, din => outputALU, dout => ALUout);

end dataPathArch;
