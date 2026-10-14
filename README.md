# Modello bayesiano di crescita della biomassa di un cianobatterio

Pipeline in **R + Stan** per modellare la crescita della biomassa di un cianobatterio
in funzione delle condizioni di coltura, e per individuare, tramite
ottimizzazione della superficie di risposta, le combinazioni sperimentali che
massimizzano la resa a diversi orizzonti temporali.

> **Nota sui dati e sui risultati.** Questo repository contiene **solo il codice**.
> I dati sperimentali reali e i risultati dello studio **non** sono pubblicati.
> Per garantire la riproducibilità, il repo include un **dataset sintetico**
> (`data/biomassa.xlsx`) con la stessa struttura dei dati reali ma con relazioni
> **fittizie**: permette di eseguire l'intera pipeline end-to-end, ma **qualsiasi
> risultato ottenuto è privo di significato** e non riflette le conclusioni dello
> studio originale.

## Contesto e obiettivo

I dati provengono da un esperimento fattoriale su colture di un cianobatterio in cui la
resa di biomassa (misurata come densità ottica, **OD**) viene osservata nel tempo
per diverse combinazioni di tre fattori di coltura:

| Fattore | Simbolo | Livelli |
|--------|---------|---------|
| Intensità luminosa | `I` | 90, 280, 470 |
| Durata di esposizione | `D` | 12, 18, 24 |
| Concentrazione di fosforo | `P` | 1, 25.5, 50 |

Il disegno è di tipo **RSM Central-Composite Face-Centered** (53 curve di crescita,
7 istanti temporali ciascuna). L'obiettivo è duplice:

1. **descrivere** la dinamica di crescita di ciascuna curva con un modello a
   base biologica;
2. **ottimizzare** le condizioni sperimentali `(I, D, P)` per massimizzare la
   resa prevista a un dato orizzonte temporale.

## Dataset

- **Struttura** (identica per dati reali e sintetici): un foglio Excel con le
  colonne `I`, `D`, `P`, `Tempo`, `OD`; 53 biomasse × 7 tempi (0–6).
- **`data/biomassa.xlsx`** incluso nel repo è **sintetico** (vedi nota sopra),
  generato in modo riproducibile da [`R/00_genera_dati_sintetici.R`](R/00_genera_dati_sintetici.R).
- Per usare i dati reali è sufficiente **sostituire** `data/biomassa.xlsx` con il
  file vero, mantenendo lo stesso layout: la pipeline gira senza modifiche.

## Metodo

Il cuore dell'analisi è un **modello di Gompertz bayesiano gerarchico** stimato
con Stan (implementato in [`R/modello.stan`](R/modello.stan)):

- **Curva di crescita**: Gompertz nella parametrizzazione con asintoto:
  `OD(t) = A · exp(−B · Cᵗ)`, con `A` (biomassa massima), `B` (posizione) e
  `C ∈ (0,1)` (velocità).
- **Superficie di risposta (RSM)**: i tre parametri dipendono dalle covariate
  di coltura tramite un predittore quadratico completo (effetti principali,
  interazioni e termini quadratici), con link che garantiscono i vincoli
  biologici: `log(A)`, `log(B)`, `logit(C)`.
- **Effetto casuale**: sulla velocità di crescita per catturare la variabilità
  tra curve non spiegata dalle covariate.
- **Errore eteroschedastico**: varianza che cresce con la media secondo una
  legge di potenza (`Var ∝ μ^δ`, con `δ` stimato).
- **Inferenza**: MCMC (NUTS) con `CmdStanR`, 4 catene, seed fissato per la
  riproducibilità; diagnostiche di convergenza standard (R-hat, ESS, divergenze).
- **Ottimizzazione post-stima**: per ogni campione posteriore si cerca su griglia
  densa la tripletta `(I, D, P)` che massimizza l'OD previsto a orizzonti `t*`
  fissati, ottenendo la **distribuzione posteriore delle condizioni ottimali**.

Il razionale completo del modello è documentato nei commenti degli script.

## Come riprodurre

Prerequisiti: **R ≥ 4.1** (usa la pipe nativa `|>`), un toolchain C++ e
**CmdStan** (per `cmdstanr`).

```bash
# 1. Installazione dipendenze
Rscript requirements.R
# poi, una tantum, il backend Stan:
Rscript -e 'cmdstanr::check_cmdstan_toolchain(fix = TRUE); cmdstanr::install_cmdstan()'

# 2. (Opzionale) rigenera il dataset sintetico
Rscript R/00_genera_dati_sintetici.R

# 3. Esegui la pipeline in ordine
Rscript R/01_esplorative.R      # pulizia dati + analisi esplorativa
Rscript R/02_modello.R          # stima del modello Gompertz bayesiano
Rscript R/03_ottimizzazione.R   # ottimizzazione della superficie di risposta
```

Gli script funzionano sia lanciati con `Rscript`, sia eseguiti dentro **RStudio**
(rilevano automaticamente il percorso). Tutti gli output (dati intermedi, figure,
fit MCMC) vengono scritti in `outputs/`, che è escluso dal versionamento.

> Con `data/biomassa.xlsx` sintetico la pipeline è pienamente eseguibile ma i
> risultati non sono interpretabili: servono solo a verificare il funzionamento.

## Struttura del repository

```
.
├── R/
│   ├── 00_genera_dati_sintetici.R   # genera data/biomassa.xlsx (dati FITTIZI)
│   ├── 01_esplorative.R             # caricamento, pulizia, analisi esplorativa
│   ├── 02_modello.R                 # stima del modello Gompertz bayesiano (Stan)
│   ├── 03_ottimizzazione.R          # ottimizzazione della superficie di risposta
│   └── modello.stan                 # modello Stan
├── data/
│   └── biomassa.xlsx               # dataset SINTETICO (riproducibilità)
├── outputs/                         # (generata a runtime, non versionata)
├── requirements.R                   # installazione dipendenze
├── LICENSE                          # MIT
└── README.md
```

## Tecnologie

**R** (`dplyr`, `tidyr`, `ggplot2`, `patchwork`, `gridExtra`, `readxl`,
`openxlsx`, `minpack.lm`) · **Stan** via `cmdstanr`, `posterior`, `bayesplot`.
Modellazione: statistica bayesiana, modelli non lineari a effetti misti,
Response Surface Methodology (RSM), Gompertz.

## Autori

Giorgia Caicchiolo · Marco Nascimben · Riccardo Pati · Luca Varotto

## Licenza

Distribuito con licenza [MIT](LICENSE).
