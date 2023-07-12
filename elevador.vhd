library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Counter
entity Counter is
    port(
        clock, reset, write, enable, action : in std_logic;
        target: in std_logic_vector(2 downto 0);

        result: out std_logic_vector(2 downto 0)
    );
end Counter;

architecture behaviour of Counter is 
    signal target_current: integer range 0 to 7;
begin
    handle: process(clock, reset, enable, action, target) 
    begin
        if(enable = '1') then 
            if(reset = '1')  then
                    target_current <= 0; 
                else
                if(rising_edge(clock)) then
                    if(write = '1') then
                            target_current <= to_integer(unsigned(target));
                    else 
                        if(action = '1') then
                            if(target_current = 7) then
                                target_current <= target_current;
                            else
                                target_current <= target_current + 1;
                            end if;
                        else
                            if(target_current = 0) then
                                target_current <= target_current;
                            else
                                target_current <= target_current - 1;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process handle;

    result <= std_logic_vector(to_unsigned(target_current, result'length));
end architecture behaviour;



-- Queue
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity Queue is
    generic(
        size: natural := 4
    );
    port(
      -- in
      clock, reset: in std_logic;

      -- write
      push: in std_logic;
      write_data: in std_logic_vector(2 downto 0);

      -- read
      pop: in std_logic;

      -- out
      empty, full: out std_logic;
      data: out std_logic_vector(2 downto 0)
    );
end Queue;

architecture queue_behaviour of Queue is
    type q_type is array (0 to size) of std_logic_vector(2 downto 0);
    signal q_data: q_type := (others => (others => '0'));

    signal q_empty, q_full: std_logic;

    signal count, w_index, r_index: integer range 0 to size-1 := 0;
begin
    logic: process(clock, reset) is 
    begin
        if(rising_edge(clock)) then
            if(reset = '1') then
               count <= 0; 
            else
                -- Atualiza contador 
                if(push = '1' and pop = '0')  then
                    if(count = size-1 ) then
                        count <= size - 1;
                    else 
                        count <= count + 1;
                    end if;
                elsif(push = '0' and pop = '1') then
                    if(count = 0 ) then
                        count <= 0;
                    else 
                        count <= count - 1;
                    end if;
                end if;

                -- Atualiza index de escrita
                if (push = '1' and q_full = '0') then
                  if w_index = size-1 then
                    w_index <= 0;
                  else
                    w_index <= w_index + 1;
                  end if;
                end if;

                -- Atualiza index de leitura 
                if(pop = '1' and q_empty='0') then
                    if r_index = size-1 then
                        r_index <= 0;
                    else
                        r_index <= r_index + 1;
                    end if;
                end if;

                if(push = '1') then
                    q_data(w_index) <= write_data;
                end if;
            end if;
        end if;
    end process logic;

    data <= q_data(r_index);

    q_full <= '1' when count = size-1 else '0';
    q_empty <= '1' when count = 0 else '0';

    full <= q_full;
    empty <= q_empty; 
    
end architecture queue_behaviour;




-- UC
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UC is
    port(
        clock, reset: in std_logic;
        initial_floor: in std_logic_vector(2 downto 0);

        -- In 
        call, passed_floor: in std_logic;
        next_floor: in std_logic_vector(2 downto 0);

        -- Counter In
        result: in std_logic_vector(2 downto 0);

        -- Queue In
        empty: in std_logic;
        data: in std_logic_vector(2 downto 0);

        -- Control
        direction, enable: out std_logic;

        -- Counter Control
        counter_enable, counter_action, counter_write: out std_logic;
        counter_target: out std_logic_vector(2 downto 0);

        -- Control Queue
        push, pop: out std_logic;
        write_data: out std_logic_vector(2 downto 0);

        -- Out 
        moving, arrived: out std_logic;
        destination_floor, current_floor: out std_logic_vector(2 downto 0)
    );
end UC;

architecture uc_behaviour of UC  is
    -- states
    type state_type is(A, B, C, D);
    signal CS, NS: state_type := B;


    signal dr, m_sig: std_logic := '0';

    -- Out
    signal c_f: std_logic_vector(2 downto 0) := "000";
begin
    handle_call: process(clock, next_floor, call) is 
    begin
        if(rising_edge(clock)) then
            if(call = '1') then
                write_data <= next_floor;
                push <= '1';
            else
                push <= '0';
            end if;
        end if;
    end process handle_call;

    sync: process(clock, reset, NS)  
    begin
        if(reset = '1') then
            CS <= A;
        elsif(rising_edge(clock)) then
            CS <= NS;
        end if;
    end process sync;

    state_handle: process(CS, data, passed_floor, empty, result) 
    begin
        c_f <= initial_floor or "000";

        enable <= '0';
        m_sig <= '0';
        arrived <= '0';
        pop <= '0';

        case CS is
            when A => 
                counter_write <= '0';
                m_sig <= '0';
                enable <= '0';
                counter_enable<= '0';

                if(empty = '0') then
                    -- Validar essa lógica
                    -- Ver como validar se a diferenca é negativa
                    pop <= '1';

                    if(data = result) then
                        NS <= A;
                    elsif(unsigned(data) < unsigned(result)) then
                        NS <= D;
                    elsif(unsigned(data) > unsigned(result)) then
                        NS <= C;
                    end if;
                else
                    NS <= A;
                end if;

            when B => 
                arrived <= '1';
                m_sig <= '0';
                enable <= '0';
                pop <= '0';
                counter_enable <= '0';
                
                if(empty = '0') then NS <= A;
                else NS <= B;
                end if;

            when C => 
                dr <= '1'; 
                enable <= '1';
                m_sig <= '1';
                arrived <= '0';

                pop <= '0'; 

                counter_enable <= '1';
                counter_action <= '1';

                if(data = result) then
                    counter_enable <= '0';
                    NS <= B;
                else 
                    NS <= C;
                end if;

                -- if(passed_floor = '1') then
                --     c_f <= std_logic_vector(unsigned(c_f) + 1);
                -- end if;

            when D =>
                dr <= '0';
                enable <= '1';
                m_sig <= '1';
                arrived <= '0';

                pop <= '0';

                counter_action <= '0';
                counter_enable <= '1';

                if(data = result) then
                    counter_enable <= '0';
                    NS <= B;
                else 
                    NS <= D;
                end if;

            when others =>
                enable <= '0';
                m_sig <= '0';
                arrived <= '0';
                pop <= '0';

                NS <= A;
        end case;
    end process state_handle;

    destination_floor <= data;
    direction <= dr;
    current_floor <= result;
    moving <= m_sig;
end architecture uc_behaviour;

-- Elevator
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Elevator is
    port(
        -- in
       clock, reset, call, passed_floor: in std_logic;
       next_floor: in std_logic_vector(2 downto 0);
       -- out
       arrived, moving, direction: out std_logic;
       destination_floor, current_floor: out std_logic_vector(2 downto 0)
    );
end Elevator;

architecture behaviour of Elevator is 
  component queue is 
        generic(
            size: natural := 4
        );
        port(
          -- in
          clock, reset: in std_logic;

          -- write
          push: in std_logic;
          write_data: in std_logic_vector(2 downto 0);

          -- read
          pop: in std_logic;

          -- out
          empty, full: out std_logic;
          data: out std_logic_vector(2 downto 0)
        );
    end component queue;

    component UC is
        port(
            clock, reset: in std_logic;
            initial_floor: in std_logic_vector(2 downto 0);

            -- In 
            call, passed_floor: in std_logic;
            next_floor: in std_logic_vector(2 downto 0);

            -- Counter In
            result: in std_logic_vector(2 downto 0);

            -- Queue In
            empty: in std_logic;
            data: in std_logic_vector(2 downto 0);

            -- Control
            direction, enable: out std_logic;

            -- Counter Control
            counter_enable, counter_action, counter_write: out std_logic;
            counter_target: out std_logic_vector(2 downto 0);

            -- Control Queue
            push, pop: out std_logic;
            write_data: out std_logic_vector(2 downto 0);

            -- Out 
            moving, arrived: out std_logic;
            destination_floor, current_floor: out std_logic_vector(2 downto 0)
        );
    end component UC;

    component Counter is
        port(
            clock, reset, write, enable, action : in std_logic;
            target: in std_logic_vector(2 downto 0);

            result: out std_logic_vector(2 downto 0)
        );
    end component Counter;

    -- Queue
    signal q_data: std_logic_vector(2 downto 0);
    signal q_call, q_empty, q_full: std_logic;

    -- Counter 
    signal c_enable, c_action, c_write: std_logic;
    signal c_target, c_result: std_logic_vector(2 downto 0);

    -- UC
    signal uc_dr, uc_fc_enable, uc_q_push, uc_q_pop, uc_moving, uc_arrived: std_logic := '0';
    signal uc_d_f, uc_c_f, uc_q_write_data: std_logic_vector(2 downto 0);
begin
    uc_mapped: UC port map(clock, reset, "000", call, '1', next_floor, c_result, q_empty, q_data, uc_dr, uc_fc_enable, c_enable, c_action, c_write, c_target, uc_q_push, uc_q_pop, uc_q_write_data, uc_moving, uc_arrived, uc_d_f, uc_c_f);
    reg_queue: Queue port map(clock, reset, uc_q_push, uc_q_write_data, uc_q_pop, q_empty, q_full, q_data);
    counter_comp: Counter port map(clock, reset, c_write, c_enable, c_action, c_target, c_result);


    arrived <= uc_arrived;
    moving <= uc_moving;
    direction <= uc_dr;
    destination_floor <= uc_d_f;
    current_floor <= c_result;
end behaviour;

