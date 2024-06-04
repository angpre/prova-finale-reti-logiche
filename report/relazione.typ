#import "@preview/finite:0.3.0"
#import "@preview/lovelace:0.2.0": *
#import "@preview/diagraph:0.2.4"

#show: setup-lovelace

#set page(
  numbering: "1",
)

#set figure(numbering: none)
#show figure.caption: emph

#set raw(syntaxes: "VHDL.sublime-syntax")

#let polimiColor = color.cmyk(40%,10%,0%,40%)

// Table styling
#set table(
  stroke: none,
  gutter: 0.2em,
  fill: (x, y) =>
    if (x == 0 or y == 0) and not (x==0 and y==0) {
      polimiColor.lighten(80%)
    },
  inset: (right: 1.5em),
)

// Headings style
#show heading: set text(fill: polimiColor)

// Headings numbering
#let clean_numbering(..schemes) = {
  (..nums) => {
    let (section, ..subsections) = nums.pos()
    let (section_scheme, ..subschemes) = schemes.pos()

    if subsections.len() == 0 {
      numbering(section_scheme, section)
    } else if subschemes.len() == 0 {
      numbering(section_scheme, ..nums.pos())
    }
    else {
      clean_numbering(..subschemes)(..subsections)
    }
  }
}
#set heading(numbering: clean_numbering("1.", "a.", "i."))

// Paragraph styling
#set par(justify: true)

// Polimi logo
#image("logo_polimi_ing_indinf.svg", width: 70%)

#line(length: 100%, stroke: 0.7pt + polimiColor)

// Titolo
#box(
text(19pt, weight: "bold", polimiColor, [Prova finale: Reti Logiche \ 2023/2024])
)
#h(1fr)
// Info
#box(
align(right, text(11pt,
[*Angelo Prete* \
#link("mailto:angelo2.prete@mail.polimi.it") \
10767149]
)))

// #v(-7pt)
#line(length: 100%, stroke: 0.7pt + polimiColor)

#v(17pt)

// Schema della Relazione

// Qui di seguito vengono riportate delle indicazioni sui punti fondamentali che devono essere trattati all'interno della relazione. Si presti attenzione al fatto che la relazione deve essere sintetica, completa e chiara; lo scopo é quello di per permettere di comprendere come il progetto é stato svolto.

= Introduzione
// 1. Introduzione: L'obiettivo non è la "copia" della specifica ma una elaborazione, con un esempio e, se é possibile, un disegno e/o una immagine, che spieghi cosa succede;

Il componente realizzato elabora una sequenza di dati presenti in una memoria RAM sostituendo alle celle con valore $0$, interpretabili come valori assenti, l'ultimo dato con valore valido, con credibilità opportunamente decrementata.

#figure(
  caption: "Rappresentazione grafica dell'interfaccia del componente",
  image("project_reti_logiche.svg")
)

Un esempio di applicazione è la correzione di letture assenti di sensori, solitamente segnalate tramite il valore $0$.

Nei paragrafi successivi è fornita una descrizione sia dei segnali necessari per il corretto funzionamento, sia del funzionamento del componente in maggior dettaglio.

== Collegamento a memoria RAM

Il componente deve essere collegato a una memoria RAM che ha interfaccia
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
Specifichiamo, nella tabella seguente, le corrispondeze tra segnali della memoria RAM e del componente:

#align(center,
table(
  columns: 4,
  [], [RAM (segnale)], [Componente (segnale)], [Dimensione],
  [Enable],[en],[o_mem_en],[1 bit],
  [Write enable],[we],[o_mem_we],[1 bit],
  [Address],[addr],[o_mem_addr],[16 bits],
  [Data in],[di],[i_mem_data],[8 bits],
  [Data out],[do],[o_mem_data],[8 bits],
))

Ricordiamo infine che RAM e componente devono condividere lo stesso segnale di clock.

== Collegamento all'utilizzatore

L'utilizzatore del componente qui specificato dovrà fornire come segnali di ingresso:
- *i_clk*: segnale di clock
- *i_rst*: reset asincrono del componente
- *i_start*: segnale di avvio
- *i_add*: indirizzo iniziale
- *i_k*: numero di dati da processare
Per segnalare la fine di una computazione, il componente fa uso del segnale *o_done*.

== Descrizione funzionamento

Possiamo descrivere il funzionamento dividendolo in tre fasi:

1. *Inizializzazione*: vengono forniti in input l'indirizzo iniziale, il numero di coppie (valore + credibilità) di celle da processare e un segnale di start; questa fase segue un eventuale reset o il termine di un'esecuzione precedente.
2. *Aggiornamento*: Il modulo inizia a processare i dati in memoria, aggiornandoli come descritto dal seguente pseudocodice

#grid(
  columns: (0.05fr, 1fr),
  [],
  pseudocode(
  no-number,
  [*input:* indirizzo di partenza $a$, numero di iterazioni $k$], no-number,
  [$a_f <- a + 2*k$ (indirizzo finale, escluso)], no-number,
  [$d_l <- 0$ (ultimo dato letto diverso da 0)],no-number,
  [$c_l <- 0$ (ultima credibilità)],no-number,
  [$"RAM"$ (memoria RAM rappresentata come vettore)],no-number,
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
)

3. *Terminazione*: la fine della fase di aggiornamento è seguita da una segnalazione da parte del componente: _o_done_ viene posto alto e si rimane in attesa di osservare basso il segnale _i_start_.

== Esempio funzionamento <example>

In questa sezione mostriamo il risultato di una computazione, introducendo anche uno dei possibili edge-cases, ovvero l'inizio di una sequenza con uno zero.

Siano dati in ingresso $"i_k"=37$ e $"i_add"=157$; sia la situazione iniziale e finale della memoria RAM quella rappresentata in figura (i dati memorizzati sono stati evidenziati in grassetto per distinguerli dalla credibilità):

#grid(
  columns: (1fr, 0.1fr, 1fr),
  image("EXAMPLE.png"),
  [],
  [
    Il primo dato letto è uno zero e, non avendo letto nessun altro dato prima il suo valore rimane inalterato e la sua credibilità viene posta a zero.

    Il dato successivo è pari a $13$, è quindi non nullo e possiamo assegnarli credibilità massima ($31$).

    Troviamo ora una serie di dati pari a $0$, ma avendo come ultimo dato salvato $13$ possiamo riscriverlo, associandolo ogni volta a una credibilità decrementa rispetto l'ultima utilizzata.

    Quando la credibilità è stata già decrementata a $0$, se il dato nella cella successiva è nullo dobbiamo assegnarli credibilità nulla non potendola decrementare ulteriormente.

    Infine incontriamo un nuovo dato diverso da $0$, $111$, e gli assegnamo credibilità $31$. Il dato successivo è pari a $0$ e quindi, come fatto precedentemente, lo sovrascriviamo con $111$ (l'ultimo dato valido) e gli assegnamo credibilità decrementata pari a $30$.
  ]
)

== Osservazioni

Notiamo che, nonostante le celle che ospitano la credibilità abbiano valore $0$ sia in questo esempio sia in tutti i test forniti nella specifica, non è il caso generale. È quindi necessario, qualora non si abbia la certezza che sia presente uno $0$, sovrascrivere il valore di credibilità anche se il valore da assegnare è pari a $0$. Controllare la cella che ospiterà la credibilità aggiornata per verificare che abbia valore nullo, seppur possibile, è un'operazione più costosta (un ciclo di clock in più) rispetto alla semplice sovrascrittura.

= Architettura

// 2. Architettura: Lobiettivo è quello di riportare uno schema funzionale che consenta di valutare come la rete sia stata progettata (schema in moduli... un bel disegno chiaro... i segnali i bus, il/i clock, reset... i segnali interni che interconnettono i moduli, ...):

Data la semplicità del componente, non si è ritenuto necessario dividerlo in più entities. Il risultato finale è una singola entity, la cui architettura realizza una macchina a stati tramite due processi.
== Macchina a stati finiti (entity project_reti_logiche)
// a. Modulo 1 (la descrizione - sottoparagrafo - di ogni modulo e la scelta implementativa - per esempio, il modulo ... @ una collezione di process che implementano la macchina a stati e la parte di registri, .... La macchina a stati, il cui schema in termini di diagramma degli stati, ha 8 stati. Il primo rappresenta .... e svolge le operazioni di ... il secondo... etc etc)

La macchina a stati finiti dell'architecture implementata è una macchina di Mealy.
Internamente, le transizioni della FSM sono sul fronte di salita del clock.
È composta da 6 stati, sono quindi necessari 3 flip flop per memorizzare lo stato corrente.

#figure(
  caption: "Rappresentazione ad alto livello della FSM implementata",
  // TODO fare la freccia i_mem_data = 0 tonda
  image(
    "./FSM-high-res.png",
  )
)

#v(15pt)

#figure(
  caption: "Tabella di mapping dei nomi degli stati tra rappresentazione grafica e implementazione",
  table(
    fill: (x, y) =>
      if y==0 {
        polimiColor.lighten(80%)
    },
    columns: 2,
    [_Nome stato implementato_], [_Abbreviazione_],
    [STATE_IDLE], [IDLE],
    [STATE_ACTIVE], [ACTIVE],
    [STATE_WAIT_START_LOW], [WAIT_LOW],
    [STATE_WAIT_WORD_READ], [WAIT_RD],
    [STATE_ZERO_WORD_CHECK_AND_WRITE], [CHK_ZERO],
    [STATE_WRITE_DECREMENTED_CRED], [WR_DECR],
  )
)


Descriviamo brevemente le azioni svolte dal componente quando si trova nei vari stati:

- *STATE_IDLE*: \
  La FSM  si trova in questo stato quando è in attesa di iniziare una nuova computazione (quando aspetta che il segnale i_start pari a 1). È possibile in STATE_IDLE sia a seguito del reset asincrono sia a seguito della fine di una computazione.
- *STATE_ACTIVE*: \
  In questo stato viene deciso se bisogna processare un nuovo indirizzo di memoria oppure teminare la computazione.
  Se l'indirizzo corrente è da processare, si preparano i segnali di memoria per leggere il dato all'indirizzo corrente, altrimenti ci si sposta nello stato STATE_WAIT_START_LOW.
- *STATE_WAIT_START_LOW*: \
  Arriviamo in questo stato quando gli indirizzi da processare sono finiti, la macchina lo segnala all'utilizzatore ponendo il segnale o_done alto e aspetta che i_start venga abbassato, evento seguito dal ritorno nello stato di STATE_IDLE.
- *STATE_WAIT_WORD_READ*: \
  Questo stato serve per permettere alla memoria di fornire il dato richiesto negli stati precedenti; infatti, come stabilito nella specifica, la memoria ha un delay di 2 nanosecondi, solo al termine dei quali può fornire il dato richiesto.
- *STATE_ZERO_WORD_CHECK_AND_WRITE*: \
  Il dato è finalmente disponibile: se è uguale a 0 bisogna sovrascriverlo (comunicandolo opportunamente alla RAM) con l'ultimo dato diverso da 0 e spostarsi nello stato di scrittura della credibilità decrementata, altrimenti, scriviamo nell'indirizzo successivo in RAM il massimo valore di credibilità (31) e torniamo nello stato STATE_ACTIVE.
- *STATE_WRITE_DECREMENTED_CRED*: \
  Siamo in questo stato se abbiamo letto un valore pari a 0 in memoria nello stato STATE_ZERO_WORD_CHECK_AND_WRITE. Scriviamo in memoria quindi un valore di credibilità decrementato rispetto al precedente (o 0 se l'ultima credibilità era già pari a 0 stesso).

// TODO descrivere segnali interni

// #finite.automaton(
//   style: (
//     state: (
//       stroke: 1.5pt + polimiColor,
//       radius: 0.8,
//     ),
//     transition: (
//     )
//   ),
//   (
//     IDLE: (ACTIVE: "i_start = 1"),
//     ACTIVE: (WAIT_LOW: "processed all addresses", WAIT_RD: "addresses to process left"),
//     WAIT_LOW: (IDLE: "i_start = 0"),
//     WAIT_RD: (CHK_ZERO: ""),
//     CHK_ZERO: (WR_DECR: "read word is 0", ACTIVE: "read word is non-zero"),
//     WR_DECR: (ACTIVE: ""),
//   ),
//   layout: finite.layout.custom.with(positions:(..) =>
//     (
//       IDLE: (0,12),
//       ACTIVE: (0,9),
//       WAIT_LOW: (3,9),
//       WAIT_RD: (0,6),
//       CHK_ZERO: (0,3),
//       WR_DECR: (0,0),
//     )
//   ),
// )

// #figure(caption: "FSM del componente (con opportune semplificazioni)",
//   diagraph.render(width: 80%, read("./fsm.dot"))
// )

=== Processo 1: Reset asincrono e clock

Il primo processo della FSM ha due funzioni:
- *Gestione del reset asincrono*: quando il segnale i_rst è alto, al registro contenente lo stato corrente viene assegnato lo stato di IDLE.
- *Transizioni*: se siamo sul fronte di salita del segnale i_clk allora i registri contententi i valori correnti vengo assegnati i nuovi valori. Questa operazione aggiorna anche lo stato corrente che, essendo presente nella sensitivity list del Processo 2, lo "sveglia".

=== Processo 2: Delta/Lambda

Questo processo corrisponde alle funzioni $delta$ e $lambda$ della FSM di Mealy. Si occupa quindi di stabilire quale sarà il prossimo stato e quali valori fornire in output (sia verso la memoria, sia verso l'utilizzatore del modulo).

// == Modulo 2
// // b. Modulo ...

= Risultati sperimentali

// 3. Risultati sperimentali:

== Sintesi

// a. Sintesi (Report del tool di sintesi adeguatamente commentato)

A seguito del processo di sintesi (con target *xa7a12tcpg238-2I*), otteniamo i seguenti dati:

// ```
// +-------------------------+------+-------+-----------+-------+
// |        Site Type        | Used | Fixed | Available | Util% |
// +-------------------------+------+-------+-----------+-------+
// | Slice LUTs*             |   78 |     0 |    134600 |  0.06 |
// |   LUT as Logic          |   78 |     0 |    134600 |  0.06 |
// |   LUT as Memory         |    0 |     0 |     46200 |  0.00 |
// | Slice Registers         |   51 |     0 |    269200 |  0.02 |
// |   Register as Flip Flop |   51 |     0 |    269200 |  0.02 |
// |   Register as Latch     |    0 |     0 |    269200 |  0.00 |
// | F7 Muxes                |    0 |     0 |     67300 |  0.00 |
// | F8 Muxes                |    0 |     0 |     33650 |  0.00 |
// +-------------------------+------+-------+-----------+-------+
// ```

#align(center, 
table(
  columns: 5,
  [], [Used], [Fixed], [Available], [Util%],
  [Slice LUTs\*], [78], [0], [134600], [0.06],
  [LUT as Logic], [78], [0], [134600], [0.06],
  [LUT as Memory], [0], [0], [46200], [0.00],
  [Slice Registers], [51], [0], [269200], [0.02],
  [Register as Flip Flop], [51], [0], [269200], [0.02],
  [Register as Latch], [0], [0], [269200], [0.00],
  [F7 Muxes], [0], [0], [67300], [0.00],
  [F8 Muxes], [0], [0], [33650], [0.00]
))

Notiamo che il componente usa:
- *51 flip flop* (0.02%), tutti e soli i previsti. Nell'implementazione del componente viene salvato l'indirizzo di fine per controllare se ci sono indirizzi rimanenti: una scelta alternativa, che avrebbe permesso di ridurre ulteriormente il numero di flip flop, è quella di salvare $k$ e decrementarlo.
- *78 look-up tables* (0.06%)
- *0 latches*, risultato ottenuto grazie ad opportune scelte progettuali
La percentuale di occupazione degli elementi disponibili è molto bassa: la logica implementata è molto semplice e non necessita di ampi spazi di memoria o complesse operazioni.

== Simulazioni

// b. Simulazioni: L'obiettivo non é solo riportare i risultati ottenuti attraverso la simulazione test bench forniti dai docenti, ma anche una analisi personale e una identificazione dei casi particolari; il fine è mostrare in modo convincente e più completo possibile, che il problema é stato esaminato a fondo e che, quanto sviluppato, soddisfa completamente i requisiti.

Il componente è stato sottoposto sia testbeches scritti a mano per verificare il suo comportamento nei vari in edge-cases, sia a testbenches generati automaticamente per controllare il corretto funzionamento su vari range di memoria.

=== Testbench ufficiale
// i. test bench 1 (cosa fa e perché lo fa e cosa verifica; per esempio controlla una condizione limite)
Il primo testbench ad essere stato provato è quello presente nei materiali per il progetto, funziona correttamente e rispetta i vincoli di clock. Inoltre, il componente funziona correttamente con tutti gli altri esempi forniti nella specifica.

=== Start multipli
// ii. test bench 2 (....)
Questo testbench è stato scritto per verificare il corretto funzionamento del componente in esecuzioni successive senza reset intermedi.

=== Dato iniziale nullo
// iii.
È stato necessario verificare che il componente funzionasse correttamente in condizioni simili a quelle dell'esempuo di funzionamento (@example)

=== Reset durante la computazione
Grazie a questo test si è mostrato il funzionamento del componente quando il segnale di reset viene portato alto durante una computazione.

=== Reset durante accesso a memoria
Come nel testbench precedente, si è verificato il funzionamento a seguito di reset, questa volta durante una lettura e poi una scrittura in memoria.

=== Credibilità a zero
Con questo testbench si è voluto testare che la credibilità, qualora sia stata decrementata fino a zero, rimanga pari a zero se i nuovi dati letti abbiano valore nullo. 

= Conclusioni
// 4. Conclusioni (mezza pagina max)
Il componente, oltre a rispettare la specifica, è stato implementato in modo efficiente. È stata posta particolare attenzione a ridurre il numero di stati, senza sacrificare allo stesso tempo la leggibilità del codice.

Oltre a funzionare nelle simulazioni Behavioral e Post-Synthesis Functional, il componente ha il comportamento richiesto anche quando viene testato in simulazioni Post-Synthesis Timing.

Come già anticipato, un possibile miglioramento per ridurre l'uso di flip flop è quello di cambiare la condizione di fine della computazione.