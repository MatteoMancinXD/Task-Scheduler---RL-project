----------------------------------------------------------------------------------
-- Engineer: Matteo Mancin
-- Create Date: 14.03.2026 13:44:33
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: PROGETTO RETI LOGICHE
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk           : in std_logic;
        i_rst           : in std_logic;
        i_start         : in std_logic;
        i_task_id       : in std_logic_vector(5 downto 0);
        i_task_priority : in std_logic_vector(1 downto 0);
        i_op            : in std_logic_vector(1 downto 0);
        o_done          : out std_logic;
        o_task_id       : out std_logic_vector(5 downto 0);
        o_mem_addr      : out std_logic_vector(15 downto 0);
        i_mem_data      : in std_logic_vector(7 downto 0);
        o_mem_data      : out std_logic_vector(7 downto 0);
        o_mem_we        : out std_logic;
        o_mem_en        : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
--Definizione stati della fsm
    type state_types is (
        RESET_INIT,
        RESET_WAIT,
        WAIT_OPERATION,
        DONE,
        WAIT_START_DOWN,
        CLEAR_MEM,
        SHIFT_READ,
        SHIFT_WRITE,
        INSERT_TASK,
        UPDATE_TASKS_NUM,
        COUNT_TASKS_1,
        COUNT_TASKS_2,
        SEARCH_READ,
        SEARCH_CHECK,
        INCREMENT_PRIO_READ,
        INCREMENT_PRIO_DO,
        CHECK_NUM_READ,
        CHECK_NUM_DO,
        REMOVE_READ,
        REMOVE_CHECK,
        REMOVE_SAVE_ID,
        REMOVE_SHIFT_READ,
        REMOVE_SHIFT_WRITE,
        REMOVE_UPDATE_TOTAL,
        DUPLICATE_READ,
        DUPLICATE_CHECK
    );
    signal current_state, next_state : state_types;
    signal curr_shift_addr, next_shift_addr : std_logic_vector(15 downto 0);  
    signal curr_target_addr, next_target_addr: std_logic_vector(15 downto 0);
    signal curr_num_tasks, next_num_tasks : std_logic_vector(7 downto 0);       
    signal curr_search_addr, next_search_addr: std_logic_vector(15 downto 0);
    signal curr_update_addr, next_update_addr: std_logic_vector(15 downto 0);
    signal curr_task_id_out, next_task_id_out : std_logic_vector(5 downto 0);
    signal curr_shift_src_addr, next_shift_src_addr : std_logic_vector(15 downto 0);
    signal curr_shift_dst_addr, next_shift_dst_addr : std_logic_vector(15 downto 0);
    
begin
    --Processo sincrono per l'aggiornamento dello stato
    process(i_clk, i_rst)
    begin
        if i_rst = '1' then                  --Set a valori di default quando viene chiamato il RESET
            current_state <= RESET_INIT;
            curr_shift_addr <= (others => '0');
            curr_target_addr <= (others => '0');
            curr_num_tasks <= (others => '0');
            curr_search_addr <= (others => '0');
            curr_update_addr <= (others => '0');
        elsif rising_edge(i_clk) then         --Aggiornamento segnali al fronte di salita del clock
            current_state <= next_state;
            curr_shift_addr <= next_shift_addr;
            curr_target_addr <= next_target_addr;
            curr_num_tasks <= next_num_tasks;
            curr_search_addr <= next_search_addr;
            curr_update_addr <= next_update_addr;
            curr_task_id_out <= next_task_id_out;
            curr_shift_src_addr <= next_shift_src_addr;
            curr_shift_dst_addr <= next_shift_dst_addr;
        end if;
     end process;

    --Processo combinatorio per calcolare lo stato successivo e le uscite
    process(current_state, i_start, i_op, i_rst, i_mem_data, curr_shift_addr, curr_target_addr, curr_num_tasks, curr_search_addr, curr_update_addr, curr_task_id_out, curr_shift_src_addr, curr_shift_dst_addr)
    begin
-- Valori di default per le uscite 
        o_done     <= '0';
        o_task_id  <= curr_task_id_out;
        o_mem_addr <= (others => '0');
        o_mem_data <= (others => '0');
        o_mem_we   <= '0';
        o_mem_en   <= '0';
        next_state <= current_state;      
        next_shift_addr <= curr_shift_addr;
        next_target_addr <= curr_target_addr;
        next_num_tasks <= curr_num_tasks;
        next_search_addr <= curr_search_addr;
        next_update_addr <= curr_update_addr;
        next_task_id_out <= curr_task_id_out;
        next_shift_src_addr <= curr_shift_src_addr;
        next_shift_dst_addr <= curr_shift_dst_addr;
        
       
        case current_state is
           
            when RESET_INIT =>
                o_done     <= '1'; -- DONE a 1 durante l'inizializzazione
                o_mem_addr <= (others => '0');      --Indirizzo 0
                o_mem_data <= (others => '0');      --Scrivo 0 
                o_mem_en   <= '1';
                o_mem_we   <= '1';      
                if i_rst = '0' then
                    next_state <= RESET_WAIT;
                end if;
               
            when RESET_WAIT =>
                -- Attende che il reset sia sceso e riporta DONE a 0
                o_done <= '0';
                next_state <= WAIT_OPERATION;

            -- STATO DI ATTESA : Da qui si scelgono poi le OP
            when WAIT_OPERATION =>
                if i_start = '1' then
                    if i_op = "11" then             
                        next_state <= CLEAR_MEM;
                    elsif i_op = "10" then
                        next_state <= COUNT_TASKS_1;
                    elsif i_op = "00" then 
                        next_state <= CHECK_NUM_READ;
                    elsif i_op = "01" then
                        next_state <= REMOVE_READ;
                    end if;
                end if;   
-- OP = 11: SVUOTA LA LISTA    
            when CLEAR_MEM =>
                o_mem_addr <= (others => '0');
                o_mem_data <= (others => '0'); 
                o_mem_en   <= '1';
                o_mem_we   <= '1';
                next_state <= DONE;
--OP = 10: AGGIUNGI UN ELEM ALLA LISTA
            when COUNT_TASKS_1 => 
                o_mem_addr <= (others => '0');
                o_mem_en <= '1';
                o_mem_we <= '0';
                next_state <= COUNT_TASKS_2;
            
            when COUNT_TASKS_2 =>
                next_num_tasks <= i_mem_data;
                if i_mem_data = "00000000" then                 
                    next_target_addr <= std_logic_vector(to_unsigned(1,16));     
                    next_state <= INSERT_TASK;
                else
                    next_search_addr <= std_logic_vector(to_unsigned(1,16));
                    next_state <= DUPLICATE_READ;
                end if;
            
            when DUPLICATE_READ =>
                o_mem_addr <= curr_search_addr;
                o_mem_en <= '1';
                o_mem_we <= '0';
                next_state <= DUPLICATE_CHECK;
                
            when DUPLICATE_CHECK =>
                if i_mem_data(7 downto 2) = i_task_id then     
                    next_state <= DONE;
                else
                    if unsigned(curr_search_addr) = unsigned("00000000" & curr_num_tasks) then 
                        next_search_addr <= std_logic_vector(to_unsigned(1,16));
                        next_state <= SEARCH_READ;
                    else
                        next_search_addr <= std_logic_vector(unsigned(curr_search_addr) + 1);
                        next_state <= DUPLICATE_READ;
                    end if;
                end if;
              
            when SEARCH_READ =>
                o_mem_addr <= curr_search_addr;
                o_mem_en <= '1';
                o_mem_we <= '0';
                
                next_state <= SEARCH_CHECK;
                
            when SEARCH_CHECK => 
                if unsigned(i_mem_data(1 downto 0)) <= unsigned(i_task_priority) then    --Caso A: il task da inserire viene dopo il task che stiamo leggendo
                    if unsigned(curr_search_addr) = unsigned("00000000" & curr_num_tasks) then        --Caso1: siamo in fondo alla lista, non serve shiftare / aggiungo gli 8 zeri per confrontare un 16 bit con un val a 8 bit
                        next_target_addr <= std_logic_vector(unsigned(curr_search_addr) + 1);
                        next_state <= INSERT_TASK;
                    else        --Caso2: non siamo alla fine, continuo a leggere
                        next_search_addr <= std_logic_vector(unsigned(curr_search_addr) + 1);
                        next_state <= SEARCH_READ;
                    end if;
                else --CASO B: devo inserire il task qua
                    next_target_addr <= curr_search_addr;
                    next_shift_addr <= "00000000" & curr_num_tasks; --Si shifta partendo dalla fine
                    next_state <= SHIFT_READ;
                end if;
                
            when SHIFT_READ =>
                o_mem_addr <= curr_shift_addr;
                o_mem_en <= '1';
                o_mem_we <= '0'; --Non serve scrivere 
                next_state <= SHIFT_WRITE;
                
                
             when SHIFT_WRITE =>
                o_mem_addr <= std_logic_vector(unsigned(curr_shift_addr) + 1);
                o_mem_data <= i_mem_data;
                o_mem_en <= '1';
                o_mem_we <= '1';
                next_shift_addr <= std_logic_vector(unsigned(curr_shift_addr) - 1);  --decremento
                if unsigned(curr_shift_addr) <= unsigned(curr_target_addr) then
                    next_state <= INSERT_TASK;
                else
                    next_state <= SHIFT_READ;
                end if;
            
            when INSERT_TASK =>
                o_mem_addr <= curr_target_addr;
                o_mem_data <= i_task_id & i_task_priority;
                o_mem_en <= '1';
                o_mem_we <= '1';
                next_state <= UPDATE_TASKS_NUM;
            
            when UPDATE_TASKS_NUM =>
                o_mem_addr <= (others => '0');      --Incrementiamo di 1 il valore all'indirizzo 0
                o_mem_data <= std_logic_vector(unsigned(curr_num_tasks)+ 1);
                o_mem_en <= '1';
                o_mem_we <= '1';
                next_state <= DONE;   --Operazione completata --> gestione handshake
                
--OP 00 : incremento priorità a tutti i task
            
            when CHECK_NUM_READ =>
                o_mem_addr <= (others => '0');
                o_mem_en <= '1';
                o_mem_we <= '0';
                next_state <= CHECK_NUM_DO;
                
            when CHECK_NUM_DO => 
                next_num_tasks <= i_mem_data;
                
                if i_mem_data = "00000000" then       --se la lista è vuota vado subito in DONE
                    next_state <= DONE;
                else
                    next_update_addr <= std_logic_vector(to_unsigned(1,16));
                    next_state <= INCREMENT_PRIO_READ;
                end if;
            
            when INCREMENT_PRIO_READ =>
                o_mem_addr <= curr_update_addr;
                o_mem_en <= '1';
                o_mem_we <= '0';
                next_state <= INCREMENT_PRIO_DO;
                
            when INCREMENT_PRIO_DO =>
                o_mem_addr <= curr_update_addr;
                o_mem_en <= '1';
                o_mem_we <= '1';
                
                if i_mem_data(1 downto 0) = "11" then        --prio già a 3 non faccio nulla
                    o_mem_data <= i_mem_data;     
                else                                         --prio <3 : aumento
                    o_mem_data <= i_mem_data(7 downto 2) & std_logic_vector(unsigned(i_mem_data(1 downto 0)) + 1);
               end if;

               --Controllo se sono alla fine
                if unsigned(curr_update_addr) = unsigned("00000000" & curr_num_tasks) then
                    next_state <= DONE;
                else
                    next_update_addr <= std_logic_vector(unsigned(curr_update_addr) + 1);
                    next_state <= INCREMENT_PRIO_READ;
                end if;

--OP 01 : RIMUOVERE IL PRIMO TASK

            when REMOVE_READ =>
                o_mem_addr <= (others => '0');
                o_mem_en   <= '1';
                o_mem_we   <= '0';
                next_state <= REMOVE_CHECK;
                
             when REMOVE_CHECK =>
                next_num_tasks <= i_mem_data;
                if i_mem_data = "00000000" then       --Caso lista vuota, id_task = 0
                    next_task_id_out <= (others => '0');
                    next_state <= DONE;
                else                                  --Caso lista non vuota, prendiamo il primo task
                    o_mem_addr <= std_logic_vector(to_unsigned(1, 16));
                    o_mem_en   <= '1';
                    o_mem_we   <= '0';
                    next_state <= REMOVE_SAVE_ID;
                end if;   
                
                             
            when REMOVE_SAVE_ID =>
                -- Il primo task è arrivato dalla memoria.
                -- Salvo i 6 bit più alti (ID_TASK) nel registro di uscita
                next_task_id_out <= i_mem_data(7 downto 2);

                if unsigned(curr_num_tasks) = 1 then        --Solo 1 task
                    next_state <= REMOVE_UPDATE_TOTAL;
                else            -- più di  1 task
                    next_shift_src_addr <= std_logic_vector(to_unsigned(2, 16));
                    next_shift_dst_addr <= std_logic_vector(to_unsigned(1, 16));
                    next_state <= REMOVE_SHIFT_READ;
                end if;

            when REMOVE_SHIFT_READ =>
                o_mem_addr <= curr_shift_src_addr;
                o_mem_en   <= '1';
                o_mem_we   <= '0';
                next_state <= REMOVE_SHIFT_WRITE;

            when REMOVE_SHIFT_WRITE =>
                o_mem_addr <= curr_shift_dst_addr;
                o_mem_data <= i_mem_data;
                o_mem_en   <= '1';
                o_mem_we   <= '1';
              
                next_shift_src_addr <= std_logic_vector(unsigned(curr_shift_src_addr) + 1);
                next_shift_dst_addr <= std_logic_vector(unsigned(curr_shift_dst_addr) + 1);
                
                if unsigned(curr_shift_src_addr) = unsigned("00000000" & curr_num_tasks) then   --FINE LISTA 
                    next_state <= REMOVE_UPDATE_TOTAL;
                else                        --LISTA NON FINITA
                    next_state <= REMOVE_SHIFT_READ;
                end if;

            when REMOVE_UPDATE_TOTAL =>
                o_mem_addr <= (others => '0');
                o_mem_data <= std_logic_vector(unsigned(curr_num_tasks) - 1);
                o_mem_en   <= '1';
                o_mem_we   <= '1';
                next_state <= DONE;
                
                
            --Protocollo  handshake Start-Done 
            when DONE =>
                o_done <= '1'; --Fine operazione --> DONE = 1 
                if i_start = '0' then
                    next_state <= WAIT_START_DOWN;
                end if;

            when WAIT_START_DOWN =>
                o_done <= '0'; -- Riporta DONE a 0
                next_state <= WAIT_OPERATION; -- Torna in attesa di nuove operazioni

            when others =>
                next_state <= WAIT_OPERATION;

        end case;
    end process;
end Behavioral;
