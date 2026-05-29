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
    wire [2:0] state_bus;
    wire pompa_air_wire;

    clock_divider u_clock_divider(
        .clk      (clk),
        .reset    (reset),
        .slow_clk (slow_clk)
    );

    fsm_controller u_fsm(
        .slow_clk      (slow_clk),
        .reset          (reset),
        .enable         (enable),
        .sensor_kering  (sensor_kering),
        .sensor_hujan   (sensor_hujan),
        .pompa_air      (pompa_air_wire),
        .state_out      (state_bus)
    );

    seven_seg_decoder u_seven_seg(
        .state (state_bus),
        .seg   (seg),
        .an    (an)
    );

    assign dp = 1'b1;

    // ========================================================
    // Data Flow: RGB LED indicator per state
    // S_DRY   (010) -> Kuning (R=1, G=1, B=0)
    // S_WATER (011) -> Biru   (R=0, G=0, B=1)
    // S_RAIN  (100) -> Hijau  (R=0, G=1, B=0)
    // Lainnya        -> OFF    (R=0, G=0, B=0)
    // ========================================================
    assign pompa_air_r = (state_bus == 3'b010) ? 1'b1 : 1'b0;
    assign pompa_air_g = (state_bus == 3'b010 || state_bus == 3'b100) ? 1'b1 : 1'b0;
    assign pompa_air_b = (state_bus == 3'b011) ? 1'b1 : 1'b0;

endmodule