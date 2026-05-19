# Sistem Penyiram Tanaman Otomatis dengan Sensor Kelembapan Tanah dan Sensor Deteksi Hujan

**Board FPGA:** Nexys A7-100T  
**Clock Internal:** 100 MHz (diturunkan menjadi 1 Hz)

---

## Daftar Isi

1. [Penjelasan Program/Sistem](#1-penjelasan-programsistem)
2. [Desain Diagram FSM (Moore)](#2-desain-diagram-fsm-moore)
3. [Tabel Kebenaran (Truth Table)](#3-tabel-kebenaran-truth-table)
4. [Diagram Rangkaian Digital / Arsitektur RTL](#4-diagram-rangkaian-digital--arsitektur-rtl)
5. [Kode Program Verilog dan Constraint](#5-kode-program-verilog-dan-constraint)

---

## 1. Penjelasan Program/Sistem

**Sistem Penyirim Tanaman Otomatis** beroperasi dengan logika berikut:

- **Reset (SW0):** Saat aktif tinggi, FSM langsung kembali ke state `S_IDLE` secara asinkron. Clock divider juga di-reset, sehingga sistem mulai dari awal.
- **Enable (SW1):** Menjalankan atau menghentikan sistem. Jika Enable=0, dari state apapun FSM akan kembali ke `S_IDLE`.
- **Sensor_Kering (SW2):** Nilai 1 menandakan tanah kering (perlu disiram), 0 menandakan tanah basah.
- **Sensor_Hujan (SW3):** Nilai 1 menandakan sedang hujan (pompa tidak boleh menyiram), 0 berarti tidak hujan.

**Alur kerja sistem:**

1. Sistem di `S_IDLE` → Jika Enable ON, berpindah ke `S_CHECK`.
2. Di `S_CHECK` → Membaca sensor:
   - Jika **kering & tidak hujan** → `S_WATER` (pompa menyala, LED ON, 7-seg tampil "A").
   - Jika **basah atau hujan** → `S_DONE` (tanah sudah basah / sedang hujan).
   - Jika **Enable OFF** → kembali ke `S_IDLE`.
3. Di `S_WATER` (pompa aktif):
   - Tetap menyiram selama tanah kering & tidak hujan.
   - Jika **hujan** atau **tanah sudah basah** → `S_DONE`.
   - Jika **Enable OFF** → `S_IDLE`.
4. Di `S_DONE` → Jika Enable ON, kembali ke `S_CHECK` untuk evaluasi ulang, membentuk siklus monitoring.

Semua perpindahan state berjalan pada clock **1 Hz** (hasil penurunan dari 100 MHz), sehingga perubahan status terlihat jelas oleh mata.

---

## 2. Desain Diagram FSM (Moore)

### Representasi State

| State | Encoding | Pompa Air | 7-Segment |
|:---:|:---:|:---:|:---:|
| S_IDLE | 2'b00 | OFF | I |
| S_CHECK | 2'b01 | OFF | C |
| S_WATER | 2'b10 | ON | A |
| S_DONE | 2'b11 | OFF | d |

### Diagram Transisi State (ASCII-Art)

```
                      enable=0
                ┌──────────────────────┐
                │                      │
                │                      ▼
           ┌─────────┐  enable=1  ┌─────────────┐
           │  IDLE   │───────────►│ CHECK_SENSOR │◄────────────┐
           │  (S00)  │            │    (S01)      │            │
           │ Pompa=0 │            │  Pompa=0      │            │
           │ 7seg=I  │◄──┐        │  7seg=C       │            │
           └─────────┘   │        └──────┬────────┘            │
                ▲        │          │kering=1│                  │
                │        │          │hujan=0 │                  │
                │        │          │        │                  │
                │        │          ▼        │                  │
                │        │     ┌───────────┐ │                  │
      enable=0  │        │     │ WATERING  │ │                  │
     (dari      │        │     │  (S10)    │ │                  │
      semua     │        │     │ Pompa=1   │ │                  │
      state)    │        │     │ 7seg=A    │─┘                  │
                │        │     └─────┬─────┘  hujan=1           │
                │        │        ┌───┴───┐    atau kering=0     │
                │        │        │       │    atau enable=0     │
                │        │        │       ▼                      │
                │        │     ┌───────────┐                    │
                │        │     │   DONE    │─────────────────────┘
                │        └─────│  (S11)    │   enable=1
                │              │  Pompa=0  │
                │              │  7seg=d   │
                │              └─────┬─────┘
                │                    │
                └────────────────────┘ enable=0
```

### Tabel Transisi Ringkas

| Current State | enable | kering | hujan | Next State |
|:---:|:---:|:---:|:---:|:---:|
| S_IDLE | 0 | X | X | S_IDLE |
| S_IDLE | 1 | X | X | S_CHECK |
| S_CHECK | 0 | X | X | S_IDLE |
| S_CHECK | 1 | 1 | 0 | S_WATER |
| S_CHECK | 1 | 0 | X | S_DONE |
| S_CHECK | 1 | 1 | 1 | S_DONE |
| S_WATER | 0 | X | X | S_IDLE |
| S_WATER | 1 | 1 | 0 | S_WATER |
| S_WATER | 1 | X | 1 | S_DONE |
| S_WATER | 1 | 0 | X | S_DONE |
| S_DONE | 0 | X | X | S_IDLE |
| S_DONE | 1 | X | X | S_CHECK |

---

## 3. Tabel Kebenaran (Truth Table)

### Notasi

- `CS` = Current State, `NS` = Next State
- `E` = Enable, `SK` = Sensor_Kering, `SH` = Sensor_Hujan
- `X` = Don't Care (tidak berpengaruh)

### Tabel Output (Moore — hanya bergantung pada current state)

| Current State | Pompa_Air | 7-Segment |
|:---:|:---:|:---:|
| S_IDLE (00) | 0 | I |
| S_CHECK (01) | 0 | C |
| S_WATER (10) | 1 | A |
| S_DONE (11) | 0 | d |

### Tabel Transisi State Lengkap

| CS[1:0] | E | SK | SH | NS[1:0] | Pompa | 7seg |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 00 | 0 | X | X | 00 | 0 | I |
| 00 | 1 | X | X | 01 | 0 | I |
| 01 | 0 | X | X | 00 | 0 | C |
| 01 | 1 | 0 | 0 | 11 | 0 | C |
| 01 | 1 | 0 | 1 | 11 | 0 | C |
| 01 | 1 | 1 | 0 | 10 | 0 | C |
| 01 | 1 | 1 | 1 | 11 | 0 | C |
| 10 | 0 | X | X | 00 | 1 | A |
| 10 | 1 | 1 | 0 | 10 | 1 | A |
| 10 | 1 | 1 | 1 | 11 | 1 | A |
| 10 | 1 | 0 | 0 | 11 | 1 | A |
| 10 | 1 | 0 | 1 | 11 | 1 | A |
| 11 | 0 | X | X | 00 | 0 | d |
| 11 | 1 | X | X | 01 | 0 | d |

> **Catatan:** Pada state S_CHECK(01), kondisi SK=0 menghasilkan S_DONE **terlepas dari SH** (tanah sudah basah, tidak perlu menyiram). Pada state S_WATER(10), kondisi SK=0 atau SH=1 menghasilkan S_DONE (berhenti menyiram karena tanah basah atau sedang hujan).

---

## 4. Diagram Rangkaian Digital / Arsitektur RTL

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            TOP_MODULE                                       │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    BLOK 1: CLOCK DIVIDER                              │  │
│  │                    (Modul 3: Clocking Function)                       │  │
│  │                                                                      │  │
│  │   clk (100MHz) ──┐                                                  │  │
│  │                  │  ┌───────────────────────┐                        │  │
│  │   reset ────────┤  │   26-bit Counter       │                        │  │
│  │                  │  │   (0 → 49.999.999)     │                        │  │
│  │                  └──┤   Toggle Output        │──► slow_clk (1Hz)      │  │
│  │                     │   (D-FF + Comparator)   │                        │  │
│  │                     └───────────────────────┘                        │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                      │                                      │
│                                      │ slow_clk (1Hz)                      │
│                                      ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │              BLOK 2: FSM CONTROLLER                                   │  │
│  │              (Modul 1, 4, 5: Behavioral, D-FF, FSM)                  │  │
│  │                                                                      │  │
│  │  ┌─────────────────────┐    ┌───────────────────────┐               │  │
│  │  │  Next State Logic    │    │  State Register (D-FF)│               │  │
│  │  │  (Kombinasional)     │    │  (Modul 4)            │               │  │
│  │  │                      │    │                       │               │  │
│  │  │  Input:              │    │  always @(posedge     │               │  │
│  │  │   - current_state ──┐│    │    slow_clk or        │               │  │
│  │  │   - enable          ││    │    posedge reset)     │               │  │
│  │  │   - sensor_kering   ││    │                       │               │  │
│  │  │   - sensor_hujan    │└───►│  current_state        │               │  │
│  │  │                      │next │         │             │               │  │
│  │  │  Output:             │state│         │current_state│               │  │
│  │  │   - next_state[1:0] ┘│     │         └────────────┼──┐            │  │
│  │  └─────────────────────┘      │                      │  │            │  │
│  │         ▲                      └────────────────────┘  │            │  │
│  │         │ feedback                    │                  │            │  │
│  │         └────────────────────────────┘                  │            │  │
│  │                                                           │            │  │
│  │  ┌─────────────────────────────────────┐                │            │  │
│  │  │  Output Logic (Data Flow - Modul 1)  │                │            │  │
│  │  │                                      │                │            │  │
│  │  │  pompa_air = (current_state == S_WATER)│               │            │  │
│  │  │  state_out = current_state            │◄───────────────┘            │  │
│  │  └─────────────────────────────────────┘                             │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                      │ state_out[1:0]                       │
│                                      │ pompa_air                              │
│                                      ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │              BLOK 3: 7-SEGMENT DECODER                               │  │
│  │              (Modul 1, 2: Data Flow, Reuse)                          │  │
│  │                                                                      │  │
│  │   state[1:0] ──► Case Decoder ──► seg[6:0] (cathodes)                │  │
│  │                                   an[7:0]  (anodes)                  │  │
│  │                                                                      │  │
│  │   00 → "I" (7'b1001111)                                              │  │
│  │   01 → "C" (7'b1000110)                                              │  │
│  │   10 → "A" (7'b0001000)                                              │  │
│  │   11 → "d" (7'b0100001)                                              │  │
│  │                                                                      │  │
│  │   an = 8'b11111110 (hanya digit AN0 aktif)                           │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  I/O Eksternal:                                                            │
│  ─────────────────────────────────────────────────────────                  │
│  clk (E3) ─────► Clock Divider                                             │
│  SW0 (J15) ────► reset                                                     │
│  SW1 (L16) ────► enable                                                    │
│  SW2 (M13) ────► sensor_kering                                             │
│  SW3 (R15) ────► sensor_hujan                                              │
│  LED0 (H17) ◄── pompa_air                                                  │
│  7-Seg Cathodes (T10,R10,K16,K13,P15,T11,L18) ◄── seg[6:0]               │
│  7-Seg DP (H15) ◄── dp = 1 (OFF)                                          │
│  7-Seg Anodes (J17,J18,T9,J14,P14,T14,K2,U13) ◄── an[7:0]               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Penjelasan Wiring Antar Blok

1. **Clock 100MHz** masuk ke **Clock Divider** → diubah menjadi **1Hz (`slow_clk`)**.
2. **slow_clk** menjadi clock untuk **D-FF State Register** di FSM.
3. **4 buah input switch** (`reset`, `enable`, `sensor_kering`, `sensor_hujan`) masuk ke **Next State Logic** (kombinasional).
4. **Next State Logic** menghitung `next_state` berdasarkan `current_state` + semua input.
5. **D-FF Register** menyimpan `current_state`, di-update pada **posedge slow_clk**, dan di-reset asinkron pada **posedge reset**.
6. **Output Logic** (Data Flow) menghasilkan `pompa_air` dan `state_out` dari `current_state` saja (khas Moore).
7. **7-Segment Decoder** menerima `state_out[1:0]` dan mengkonversi ke pola segmen huruf yang sesuai.

---

## 5. Kode Program Verilog dan Constraint

### Struktur File Proyek

```
tasdl/
├── src/
│   ├── top_module.v        # Modul 2: Structural (Top Module)
│   ├── clock_divider.v     # Modul 3: Clocking Function
│   ├── fsm_controller.v    # Modul 1, 4, 5: Behavioral, D-FF, FSM
│   └── seven_seg_decoder.v # Modul 1, 2: Data Flow, Reuse
└── constr/
    └── Nexys_A7_100T.xdc  # Constraint file untuk Nexys A7-100T
```

### Pemetaan Modul Praktikum dalam Kode

| Modul | Konsep | Lokasi dalam Kode |
|-------|--------|-------------------|
| **Modul 1** | Behavioral | `fsm_controller.v` → blok `always @(*)` untuk next state logic |
| **Modul 1** | Data Flow | `fsm_controller.v` → `assign pompa_air`; `seven_seg_decoder.v` → `assign an` |
| **Modul 1** | Structural | `top_module.v` → instansiasi `u_clock_divider`, `u_fsm`, `u_seven_seg` |
| **Modul 2** | Coding Reuse | `top_module.v` → top module memanggil 3 sub-module |
| **Modul 3** | Clocking Function | `clock_divider.v` → counter 50M untuk menurunkan 100MHz → 1Hz |
| **Modul 4** | D-Flip-Flop | `fsm_controller.v` → `always @(posedge slow_clk or posedge reset)` menyimpan state |
| **Modul 5** | FSM Moore | `fsm_controller.v` → 4 state (S_IDLE, S_CHECK, S_WATER, S_DONE) dengan output = f(state) |

### Pemetaan Pin XDC

| Sinyal | Pin | Perangkat |
|--------|-----|-----------|
| `clk` | E3 | Clock 100MHz |
| `reset` | J15 | SW0 |
| `enable` | L16 | SW1 |
| `sensor_kering` | M13 | SW2 |
| `sensor_hujan` | R15 | SW3 |
| `pompa_air` | H17 | LED0 |
| `seg[0]` (a) | T10 | 7-Seg CA |
| `seg[1]` (b) | R10 | 7-Seg CB |
| `seg[2]` (c) | K16 | 7-Seg CC |
| `seg[3]` (d) | K13 | 7-Seg CD |
| `seg[4]` (e) | P15 | 7-Seg CE |
| `seg[5]` (f) | T11 | 7-Seg CF |
| `seg[6]` (g) | L18 | 7-Seg CG |
| `dp` | H15 | 7-Seg DP |
| `an[0]` | J17 | 7-Seg AN0 |
| `an[1]` | J18 | 7-Seg AN1 |
| `an[2]` | T9 | 7-Seg AN2 |
| `an[3]` | J14 | 7-Seg AN3 |
| `an[4]` | P14 | 7-Seg AN4 |
| `an[5]` | T14 | 7-Seg AN5 |
| `an[6]` | K2 | 7-Seg AN6 |
| `an[7]` | U13 | 7-Seg AN7 |

---

### Source Code: `src/clock_divider.v`

```verilog
// ============================================================
// Modul 3: Clocking Function
// Clock Divider: 100 MHz → 1 Hz
// Menggunakan counter untuk menurunkan frekuensi clock
// Counter menghitung 50.000.000 siklus (0.5 detik) lalu
// toggle slow_clk, sehingga periode slow_clk = 1 detik (1 Hz)
// ============================================================

module clock_divider(
    input  wire clk,        // Clock 100 MHz dari board (pin E3)
    input  wire reset,      // Reset aktif tinggi (sinkron)
    output reg  slow_clk   // Clock 1 Hz output
);

    // 100 MHz / (2 x 50.000.000) = 1 Hz
    parameter DIVISOR = 50_000_000;

    reg [25:0] counter;     // 26-bit counter (2^26 > 50.000.000)

    always @(posedge clk) begin
        if (reset) begin
            counter   <= 26'd0;
            slow_clk  <= 1'b0;
        end else if (counter == DIVISOR - 1) begin
            counter   <= 26'd0;
            slow_clk  <= ~slow_clk;  // Toggle output
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
```

---

### Source Code: `src/fsm_controller.v`

```verilog
// ============================================================
// Modul 1: Behavioral (FSM Next State Logic)
//           Data Flow  (assign untuk output logika)
// Modul 4: D-Flip-Flop (State Register dengan always posedge clk)
// Modul 5: Desain FSM Moore
// ============================================================
// FSM Moore: Output hanya bergantung pada current_state
//
// State Encoding:
//   S_IDLE  = 2'b00  → Pompa OFF, 7seg = 'I'
//   S_CHECK = 2'b01  → Pompa OFF, 7seg = 'C'
//   S_WATER = 2'b10  → Pompa ON,  7seg = 'A'
//   S_DONE  = 2'b11  → Pompa OFF, 7seg = 'd'
// ============================================================

module fsm_controller(
    input  wire slow_clk,       // Clock 1 Hz dari clock_divider
    input  wire reset,          // Reset aktif tinggi (asinkron)
    input  wire enable,         // Switch Enable: 1 = sistem aktif
    input  wire sensor_kering,  // 1 = tanah kering, 0 = tanah basah
    input  wire sensor_hujan,   // 1 = hujan, 0 = tidak hujan
    output wire pompa_air,      // 1 = pompa menyala (LED)
    output wire [1:0] state_out // State saat ini untuk 7-seg decoder
);

    // --- Definisi State (Moore FSM) ---
    localparam S_IDLE  = 2'b00;
    localparam S_CHECK = 2'b01;
    localparam S_WATER = 2'b10;
    localparam S_DONE  = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    // ============================================================
    // Modul 4: D-Flip-Flop (State Register)
    // Blok always posedge clk menyimpan state ke D-FF
    // Reset asinkron memastikan FSM langsung ke S_IDLE
    // ============================================================
    always @(posedge slow_clk or posedge reset) begin
        if (reset)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end

    // ============================================================
    // Modul 1 (Behavioral) & Modul 5 (FSM): Next State Logic
    // Logika kombinational menentukan state berikutnya berdasarkan
    // current_state dan input
    // ============================================================
    always @(*) begin
        case (current_state)
            S_IDLE: begin
                if (enable)
                    next_state = S_CHECK;
                else
                    next_state = S_IDLE;
            end

            S_CHECK: begin
                if (!enable)
                    next_state = S_IDLE;
                else if (sensor_kering && !sensor_hujan)
                    next_state = S_WATER;
                else
                    next_state = S_DONE;
            end

            S_WATER: begin
                if (!enable)
                    next_state = S_IDLE;
                else if (sensor_hujan)
                    next_state = S_DONE;
                else if (!sensor_kering)
                    next_state = S_DONE;
                else
                    next_state = S_WATER;
            end

            S_DONE: begin
                if (!enable)
                    next_state = S_IDLE;
                else
                    next_state = S_CHECK;
            end

            default: next_state = S_IDLE;
        endcase
    end

    // ============================================================
    // Modul 1 (Data Flow): Output Logic (Moore)
    // Output hanya bergantung pada current_state (khas Moore)
    // ============================================================
    assign pompa_air  = (current_state == S_WATER) ? 1'b1 : 1'b0;
    assign state_out  = current_state;

endmodule
```

---

### Source Code: `src/seven_seg_decoder.v`

```verilog
// ============================================================
// Modul 1: Data Flow (assign statements untuk decoding)
// Modul 2: Sub-module yang dapat di-reuse (7-seg decoder)
// ============================================================
// Decoder 7-Segment untuk menampilkan inisial state:
//   S_IDLE  (2'b00) → 'I'  (IDLE)
//   S_CHECK (2'b01) → 'C'  (CHECK SENSOR)
//   S_WATER (2'b10) → 'A'  (AIR = menyiram/pengairan)
//   S_DONE  (2'b11) → 'd'  (DONE)
//
// 7-Segment Common Anode (aktif rendah):
//   Segmen ON  = 0
//   Segmen OFF = 1
//
// Layout segmen:
//     aaa
//    f   b
//     ggg
//    e   c
//     ddd
//
// seg[6:0] = {g, f, e, d, c, b, a}
// ============================================================

module seven_seg_decoder(
    input  wire [1:0] state,
    output reg  [6:0] seg,    // Segmen {g,f,e,d,c,b,a}, aktif rendah
    output reg  [7:0] an      // Anode, aktif rendah (hanya AN0 aktif)
);

    // Hanya mengaktifkan digit AN0 (paling kanan)
    always @(*) begin
        an = 8'b11111110;     // AN0=0 (aktif), AN7..AN1=1 (nonaktif)

        case (state)
            // 'I' : segmen e,f ON → 7'b1001111
            2'b00: seg = 7'b1001111;

            // 'C' : segmen a,d,e,f ON → 7'b1000110
            2'b01: seg = 7'b1000110;

            // 'A' : segmen a,b,c,e,f,g ON (semua kecuali d) → 7'b0001000
            //       'A' mewakili "Air" (air = water dalam bahasa Indonesia)
            2'b10: seg = 7'b0001000;

            // 'd' : segmen b,c,d,e,g ON → 7'b0100001
            2'b11: seg = 7'b0100001;

            default: seg = 7'b1111111;  // Semua segmen OFF
        endcase
    end

endmodule
```

---

### Source Code: `src/top_module.v`

```verilog
// ============================================================
// Modul 2: Structural (Top Module)
// Top Module menginstansiasi seluruh sub-module:
//   1. clock_divider   → Modul 3 (Clocking Function)
//   2. fsm_controller  → Modul 1,4,5 (Behavioral, D-FF, FSM)
//   3. seven_seg_decoder → Modul 1,2 (Data Flow, Reuse)
// ============================================================

module top_module(
    // --- Clock ---
    input  wire clk,              // 100 MHz crystal oscillator (pin E3)

    // --- Input Switches ---
    input  wire reset,            // SW0: Reset (aktif tinggi)
    input  wire enable,           // SW1: Enable sistem (1=ON, 0=OFF)
    input  wire sensor_kering,    // SW2: Sensor kelembapan (1=kering, 0=basah)
    input  wire sensor_hujan,     // SW3: Sensor hujan (1=hujan, 0=tidak)

    // --- Output LED ---
    output wire pompa_air,        // LED0: Indikator pompa air (1=menyala)

    // --- Output 7-Segment ---
    output wire [6:0] seg,        // Segmen {g,f,e,d,c,b,a}, aktif rendah
    output wire dp,               // Decimal point (selalu OFF)
    output wire [7:0] an          // Anode, aktif rendah (hanya AN0)
);

    // ========================================================
    // Wire Internal (menghubungkan antar submodule)
    // ========================================================
    wire slow_clk;                // Clock 1 Hz dari clock_divider
    wire [1:0] state_bus;         // Bus state dari FSM ke 7-seg decoder

    // ========================================================
    // Modul 3: Instansiasi Clock Divider
    // Mengubah clock 100 MHz menjadi 1 Hz
    // ========================================================
    clock_divider u_clock_divider(
        .clk       (clk),
        .reset     (reset),
        .slow_clk  (slow_clk)
    );

    // ========================================================
    // Modul 4 & 5: Instansiasi FSM Controller
    // Mesin state Moore dengan D-Flip-Flop untuk state register
    // ========================================================
    fsm_controller u_fsm(
        .slow_clk       (slow_clk),
        .reset          (reset),
        .enable          (enable),
        .sensor_kering  (sensor_kering),
        .sensor_hujan   (sensor_hujan),
        .pompa_air      (pompa_air),
        .state_out      (state_bus)
    );

    // ========================================================
    // Modul 1 & 2: Instansiasi 7-Segment Decoder
    // Decoding state menjadi tampilan huruf pada 7-seg
    // ========================================================
    seven_seg_decoder u_seven_seg(
        .state  (state_bus),
        .seg    (seg),
        .an     (an)
    );

    // ========================================================
    // Data Flow: Decimal point selalu OFF (aktif rendah = 1)
    // ========================================================
    assign dp = 1'b1;

endmodule
```

---

### Constraint File: `constr/Nexys_A7_100T.xdc`

```xdc
## ============================================================
## Constraint File untuk Nexys A7-100T
## Sistem Penyiram Tanaman Otomatis
## ============================================================

## --- Clock 100 MHz ---
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports clk];       # 100 MHz crystal oscillator
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk];

## --- Switches (Input) ---
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports reset];           # SW0: Reset
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports enable];          # SW1: Enable
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports sensor_kering];   # SW2: Sensor Kelembapan
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports sensor_hujan];    # SW3: Sensor Hujan

## --- LED (Output) ---
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports pompa_air];  # LED0: Pompa Air

## --- 7-Segment Display Cathodes (seg) ---
## seg[0]=a, seg[1]=b, seg[2]=c, seg[3]=d, seg[4]=e, seg[5]=f, seg[6]=g
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports {seg[0]}];  # CA (segment a)
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports {seg[1]}];  # CB (segment b)
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports {seg[2]}];  # CC (segment c)
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports {seg[3]}];  # CD (segment d)
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports {seg[4]}];  # CE (segment e)
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports {seg[5]}];  # CF (segment f)
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {seg[6]}];  # CG (segment g)

## --- 7-Segment Decimal Point ---
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports dp];        # DP (decimal point)

## --- 7-Segment Display Anodes ---
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {an[0]}];   # AN0 (digit paling kanan)
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {an[1]}];   # AN1
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports {an[2]}];   # AN2
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports {an[3]}];   # AN3
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports {an[4]}];   # AN4
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports {an[5]}];   # AN5
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports {an[6]}];   # AN6
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports {an[7]}];   # AN7

## --- Konfigurasi Bitstream ---
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCIO [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLDOWN [current_design]
```