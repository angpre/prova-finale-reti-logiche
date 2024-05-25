#import "@preview/finite:0.3.0"
#import "@preview/lovelace:0.2.0": *
#import "@preview/diagraph:0.2.4"

#show: setup-lovelace

#let polimiColor = color.cmyk(40%,10%,0%,40%)
#show heading: set text(fill: polimiColor)

// Polimi logo
#image("logo_polimi_ing_indinf.svg", width: 70%)

// Titolo
#align(right, 
  text(19pt, weight: "bold", polimiColor, [Progetto Reti Logiche \ 2023/2024])
)

// Info
*Angelo Prete* \
#link("mailto:angelo2.prete@mail.polimi.it") \
10767149

// Schema della Relazione

// Qui di seguito vengono riportate delle indicazioni sui punti fondamentali che devono essere trattati all'interno della relazione. Si presti attenzione al fatto che la relazione deve essere sintetica, completa e chiara; lo scopo é quello di per permettere di comprendere come il progetto é stato svolto.

= Introduzione
// 1. Introduzione: L'obiettivo non è la "copia" della specifica ma una elaborazione, con un esempio e, se é possibile, un disegno e/o una immagine, che spieghi cosa succede;

Il componente realizzato si occupa di elaborare una sequenza in memoria andando a sostituire alle celle con valori pari a $0$, che possono essere interpretati come valori mancanti, l'ultimo valore valido la cui credibilità viene decrementata man mano. Il componente potrebbe essere utilizzato, ad esempio, per correggere letture assenti di sensori, che spesso indicano valori assenti con $0$.

Il componente presenta i seguenti ingressi e uscite
#figure(
  image("project_reti_logiche.svg")
)
descritti con più dettaglio nei paragrafi successivi.

== Collegamento a memoria RAM

Il componente deve essere collegato a una memoria RAM che rispetta la seguente interfaccia
```
entity ram is
    port
    (
        clk  : in std_logic;
        we   : in std_logic;
        en   : in std_logic;
        addr : in std_logic_vector(15 downto 0);
        di   : in std_logic_vector(7 downto 0);
        do   : out std_logic_vector(7 downto 0)
    );
end ram;
```
In particolare, deve essere collegata al componente realizzato come in tabella
#table(
  columns: 4,
  [Segnale], [RAM], [Componente], [Dimensione],
  [Enable],[en],[o_mem_en],[1 bit],
  [Write enable],[we],[o_mem_we],[1 bit],
  [Address],[addr],[o_mem_addr],[16 bits],
  [Data in],[di],[i_mem_data],[8 bits],
  [Data out],[do],[o_mem_data],[8 bits],
)
e RAM e componente stesso devono condividere il segnale di clock.

== Descrizione funzionamento

Funzionamento modulo:
1. Vengono forniti in input l'indirizzo di partenza, il numero di coppie (divise in valore e credibilità) di celle da processare e un segnale di start (dopo l'eventuale segnale di reset)
2. Il modulo inizia a processare i dati in memoria, come descritto nel seguente pseudocodice

#pseudocode(
  no-number,
  [*input:* indirizzo di partenza $a$, numero di iterazioni $k$], no-number,
  [$a_f <- a + 2*k$ (indirizzo finale da processare più uno)], no-number,
  [$d_l <- 0$ (ultimo dato letto diverso da 0)],no-number,
  [$c_l <- 0$ ultima credibilità],no-number,
  [$"RAM"$ (memoria RAM rappresentata come un vettore)],no-number,
  [*while* $a != a_f$ *do*], ind,no-number,
    $d <- "RAM"[a]$,no-number,
    [*if* $d!=0$ *then*], ind,no-number,
      [$d_l <- d$],no-number,
      [$"RAM"[a+1] <- 31$], no-number,
            [$c_l <- 31$], ded,no-number,
    [*else*], ind,no-number,
      [$"RAM"[a] <- d_l$],no-number,
      [$c_l <- max ( (c_l-1), 0)$],no-number,
      [$"RAM"[a+1] <- c_l$],ded,no-number,
    [*end*],no-number,
    [$a <- a + 2$], ded,no-number,
  [*end*], no-number,
)
3. Finita l'operazione, il componente lo segnala ponendo *o_done* alto e aspetta che venga portato basso il segnale *o_start*.

== Esempio funzionamento



= Architettura

// 2. Architettura: Lobiettivo è quello di riportare uno schema funzionale che consenta di valutare come la rete sia stata progettata (schema in moduli... un bel disegno chiaro... i segnali i bus, il/i clock, reset... i segnali interni che interconnettono i moduli, ...):

Data la semplicità del componente, non si è ritenuto necessario dividerlo in più entities. Il risultato finale è una singola entity, la cui architettura realizza una macchina a stati tramite due processi.
== Macchina a stati finiti (entity project_reti_logiche)
// a. Modulo 1 (la descrizione - sottoparagrafo - di ogni modulo e la scelta implementativa - per esempio, il modulo ... @ una collezione di process che implementano la macchina a stati e la parte di registri, .... La macchina a stati, il cui schema in termini di diagramma degli stati, ha 8 stati. Il primo rappresenta .... e svolge le operazioni di ... il secondo... etc etc)

La macchina a stati finiti dell'architecture del componente è una macchina di Mealy. Internamente, le transizioni della FSM sono sul fronte di salita del clock.

È composta da 6 stati, sono quindi necessari 3 flip flop per memorizzare lo stato corrente. Ogni stato ha uno specifico compito:
- *STATE_IDLE*:
  Quando la FSM è in attesa di iniziare una nuova computazione, si trova in questo stato. È possibile arrivare qui a seguito del reset asincrono o della fine di una computazione.
- *STATE_ACTIVE*:
  In questo stato la FSM decide se processare una nuova coppia di indirizzi di memoria, a seguito di un controllo sull'indirizzo da processare, oppure teminare la computazione.
  Se l'indirizzo da processare non è l'ultimo, si preparano i segnali di memoria per leggere il dato all'indirizzo corrente.
- *STATE_WAIT_START_LOW*:
  Arriviamo in questo stato quando gli indirizzi da processare sono finiti, la macchina segnala questo ponendo il segnale o_done alto e aspetta che i_start venga abbassato a 0, evento seguito dal ritorno nello stato di idle.  
- *STATE_WAIT_WORD_READ*: 
  Questo stato serve per permettere alla memoria di fornire il dato richiesto negli stati precedenti; infatti, da specifica, la memoria ha un delay di 2 nanosecondi solo al termine dei quali può fornire il dato richiesto.
- *STATE_ZERO_WORD_CHECK_AND_WRITE*:
  Il dato è finalmente disponibile: se è uguale a 0 bisogna sovrascriverlo (comunicandolo opportunamente alla RAM) con l'ultimo dato diverso da 0 e spostarsi nello stato di scrittura della credibilità decrementata, altrimenti, scriviamo nell'indirizzo successivo in RAM il massimo valore di credibilità (31) e torniamo nello stato active.
- *STATE_WRITE_DECREMENTED_CRED*: Siamo in questo stato se abbiamo letto un valore pari a 0 in memoria. Scriviamo in memoria quindi un valore di credibilità decrementato rispetto al precedente (o 0 se l'ultima credibilità era già pari a 0 stesso).

// #finite.automaton((
//     idle: (active: "i_start = 1"),
//     active: (waitStartLow: "processed all addresses", waitReadWord: "addresses to process left"),
//     waitStartLow: (idle: "i_start = 0"),
//     waitReadWord: (checkZeroWordAndWrite: ""),
//     checkZeroWordAndWrite: (writeDecrementedCredibility: "read word is 0", active: "read word is non-zero"),
//     writeDecrementedCredibility: (active: ""),
//   ),
//   layout: finite.layout.custom.with(positions:(..)=> (
//     idle: (2,10),
//     active: (0,8),
//     waitStartLow: (4,8),
//     waitReadWord: (0,4),
//     checkZeroWordAndWrite: (0,2),
//     writeDecrementedCredibility: (0,0),
//   )),
// )

#diagraph.render(width: 80%, read("./fsm.dot"))

=== Processo 1: Clock e reset asincrono
=== Processo 2: Scelta stati e scritture in memoria


== Modulo 2
// b. Modulo ...

= Risultati sperimentali

// 3. Risultati sperimentali:

== Sintesi

// a. Sintesi (Report del tool di sintesi adeguatamente commentato)

== Simulazioni

// b. Simulazioni: L'obiettivo non é solo riportare i risultati ottenuti attraverso la simulazione test bench forniti dai docenti, ma anche una analisi personale e una identificazione dei casi particolari; il fine € mostrare in modo convincente e più completo possibile, che il problema é stato esaminato a fondo e che, quanto sviluppato, soddisfa completamente i requisiti.

Il componente è stato sottoposto a testbeches scritti a mano per verificare gli edge-cases e testbeches casuali per verificare il corretto funzionamento su vari range di memoria.

=== Testbench 1
// i. test bench 1 (cosa fa e perché lo fa e cosa verifica; per esempio controlla una condizione limite)
Il primo testbench è 

=== Testbench 2
// ii. test bench 2 (....)

=== Testbench 3
// iii.

= Conclusioni
// 4. Conclusioni (mezza pagina max)
