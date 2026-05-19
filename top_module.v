// ============================================================
// Modul 2: Structural (Top Module)
// Top Module menginstansiasi seluruh sub-module:
//   1. clock_divider   -> Modul 3 (Clocking Function)
//   2. fsm_controller  -> Modul 1,4,5 (Behavioral, D-FF, FSM)
//   3. seven_seg_decoder -> Modul 1,2 (Data Flow, Reuse)
// ============================================================

module top_module(
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire sensor_kering,
    input  wire sensor_hujan,
    output wire pompa_air_r,
    output wire pompa_air_g,
    output wire pompa_air_b,
    output wire [6:0] seg,
    output wire dp,
    output wire [7:0] an
);

    wire slow_clk;
    wire [1:0] state_bus;
    wire pompa_air_wire;

    // ========================================================
    // Modul 3: Instansiasi Clock Divider
    // ========================================================
    clock_divider u_clock_divider(
        .clk      (clk),
        .reset    (reset),
        .slow_clk (slow_clk)
    );

    // ========================================================
    // Modul 4 & 5: Instansiasi FSM Controller
    // ========================================================
    fsm_controller u_fsm(
        .slow_clk      (slow_clk),
        .reset          (reset),
        .enable         (enable),
        .sensor_kering  (sensor_kering),
        .sensor_hujan   (sensor_hujan),
        .pompa_air      (pompa_air_wire),
        .state_out      (state_bus)
    );

    // ========================================================
    // Modul 1 & 2: Instansiasi 7-Segment Decoder
    // ========================================================
    seven_seg_decoder u_seven_seg(
        .state (state_bus),
        .seg   (seg),
        .an    (an)
    );

    // ========================================================
    // Data Flow: Decimal point selalu OFF
    // ========================================================
    assign dp = 1'b1;

    // ========================================================
    // Data Flow: RGB LED (Biru saat pompa ON)
    // ========================================================
    assign pompa_air_r = 1'b0;
    assign pompa_air_g = 1'b0;
    assign pompa_air_b = pompa_air_wire;

endmodule