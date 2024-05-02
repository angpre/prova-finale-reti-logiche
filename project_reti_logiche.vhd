library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity project_reti_logiche is
  port
  (
    i_clk   : in std_logic;
    i_rst   : in std_logic;
    i_start : in std_logic;
    i_add   : in std_logic_vector(15 downto 0);
    i_k     : in std_logic_vector(9 downto 0);

    o_done : out std_logic;

    o_mem_addr : out std_logic_vector(15 downto 0);
    i_mem_data : in std_logic_vector(7 downto 0);
    o_mem_data : out std_logic_vector(7 downto 0);
    o_mem_we   : out std_logic;
    o_mem_en   : out std_logic
  );
end project_reti_logiche;

architecture behavioral of project_reti_logiche is

  type state_t is (
    STATE_IDLE,
    STATE_ACTIVE,
    STATE_WAIT_START_LOW,
    STATE_WAIT_WORD_READ,
    STATE_ZERO_WORD_CHECK_AND_WRITE,
    STATE_WRITE_DECREMENTED_CRED
  );

  signal next_state    : state_t;
  signal current_state : state_t;

  signal current_address      : std_logic_vector(15 downto 0);
  signal current_address_next : std_logic_vector(15 downto 0);

  signal end_address      : std_logic_vector(15 downto 0);
  signal end_address_next : std_logic_vector(15 downto 0);

  signal last_word      : std_logic_vector(7 downto 0);
  signal last_word_next : std_logic_vector(7 downto 0);

  signal last_credibility      : std_logic_vector(7 downto 0);
  signal last_credibility_next : std_logic_vector(7 downto 0);

  constant zero_word        : std_logic_vector(7 downto 0) := (others => '0');
  constant zero_credibility : std_logic_vector(7 downto 0) := (others => '0');
  constant max_credibility  : std_logic_vector(7 downto 0) := "00011111";

begin
  -- This process handles clock and reset.
  state_manager : process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      -- Go to the first state
      current_state <= STATE_IDLE;

      -- Init all other signals
      current_address  <= (others => '-');
      last_credibility <= (others => '-');
      last_word        <= (others => '-');
      end_address      <= (others => '-');

    elsif rising_edge(i_clk) then
      -- Update state
      current_state <= next_state;

      -- Update signals
      current_address  <= current_address_next;
      last_credibility <= last_credibility_next;
      last_word        <= last_word_next;
      end_address      <= end_address_next;

    end if;
  end process;

  -- This process selects next state and handles the logic
  lambda : process (current_state, i_start)
  begin
    -- Default next signals assignments
    current_address_next  <= current_address;
    last_credibility_next <= last_credibility;
    last_word_next        <= last_word;
    end_address_next      <= end_address;

    -- Default memory assignments
    o_mem_en   <= '0';
    o_mem_we   <= '0';
    o_mem_addr <= (others => '-');
    o_mem_data <= (others => '-');

    -- Default done assignment
    o_done <= '0';

    -- Default next state assignment
    next_state <= STATE_IDLE;

    case current_state is
      when STATE_IDLE =>
        -- Keep memory disabled

        if i_start = '1' then
          next_state <= STATE_ACTIVE;

          -- Set signals
          current_address_next  <= i_add;
          end_address_next      <= std_logic_vector(unsigned(i_add) + unsigned(i_k & '0'));
          last_credibility_next <= zero_credibility;
          last_word_next        <= zero_word;
        end if;

      when STATE_ACTIVE =>
        if current_address = end_address then
          -- Computation has ended
          o_done <= '1';

          next_state <= STATE_WAIT_START_LOW;

        else
          -- Enable reading from memory
          o_mem_en   <= '1';
          o_mem_addr <= current_address;

          next_state <= STATE_WAIT_WORD_READ;

        end if;

      when STATE_WAIT_START_LOW =>
        o_done <= '1';

        if i_start = '0' then
          -- When i_start is low, transition to idle where o_done will be '0'
          next_state <= STATE_IDLE;
        end if;

      when STATE_WAIT_WORD_READ =>
        -- This state is for waiting for o_mem_data to be available

        next_state <= STATE_ZERO_WORD_CHECK_AND_WRITE;

      when STATE_ZERO_WORD_CHECK_AND_WRITE =>
        -- Enable writing to memory
        o_mem_en <= '1';
        o_mem_we <= '1';

        if i_mem_data /= zero_word then
          -- If the read word is non zero, write max credibility to memory
          current_address_next <= std_logic_vector(unsigned(current_address) + 2);
          o_mem_addr           <= std_logic_vector(unsigned(current_address) + 1);
          o_mem_data           <= max_credibility;

          -- and  save the current word as the last non-zero word
          last_word_next        <= i_mem_data;
          last_credibility_next <= max_credibility;

          next_state <= STATE_ACTIVE;

        else
          -- Otherwise overwrite it with the last non-zero word read
          o_mem_addr <= current_address;
          o_mem_data <= last_word;

          -- The new zero word's credibility is min(last_credibility - 1, 0)
          if last_credibility /= zero_credibility then
            last_credibility_next <= std_logic_vector(unsigned(last_credibility) - 1);
          else
            -- TODO maybe the else is not needed (check if removing it generates latches)
            last_credibility_next <= zero_credibility;
          end if;

          current_address_next <= std_logic_vector(unsigned(current_address) + 1);

          next_state <= STATE_WRITE_DECREMENTED_CRED;

        end if;

      when STATE_WRITE_DECREMENTED_CRED =>
        -- Prepare the memory for writing
        o_mem_en   <= '1';
        o_mem_we   <= '1';
        o_mem_data <= last_credibility;
        o_mem_addr <= current_address;

        -- Update the current address to point to next word
        current_address_next <= std_logic_vector(unsigned(current_address) + 1);

        next_state <= STATE_ACTIVE;
    end case;
  end process;
end architecture behavioral;