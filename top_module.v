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

    // --- Output RGB LED (Pompa Air = Biru) ---
    output wire pompa_air_r,     // LED16_R: Selalu OFF
    output wire pompa_air_g,     // LED16_G: Selalu OFF
    output wire pompa_air_b      // LED16_B: Biru saat pompa ON

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
    wire pompa_air_wire;          // Sinyal pompa_air dari FSM

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
        .pompa_air      (pompa_air_wire),
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

    // ========================================================
    // Data Flow: RGB LED untuk indikator Pompa Air (Biru)
    // Saat pompa_air=1 → LED16_B ON (biru), R & G OFF
    // Saat pompa_air=0 → Semua OFF
    // ========================================================
    assign pompa_air_r = 1'b0;
    assign pompa_air_g = 1'b0;
    assign pompa_air_b = pompa_air_wire;

endmodule