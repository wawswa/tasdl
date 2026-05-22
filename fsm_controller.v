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
//   S_RAIN  = 2'b11  → Pompa OFF, 7seg = 'R' (sedang hujan)
// ============================================================

module fsm_controller(
    input  wire slow_clk,       // Clock 1 Hz dari clock_divider
    input  wire reset,          // Reset aktif tinggi (asinkron)
    input  wire enable,         // Switch Enable: 1 = sistem aktif
    input  wire sensor_kering,  // 1 = tanah kering, 0 = tanah basah
    input  wire sensor_hujan,   // 1 = hujan, 0 = tidak hujan
    output wire pompa_air,      // 1 = pompa menyala (LED biru)
    output wire [1:0] state_out // State saat ini untuk 7-seg decoder
);

    // --- Definisi State (Moore FSM) ---
    localparam S_IDLE  = 2'b00;
    localparam S_CHECK = 2'b01;
    localparam S_WATER = 2'b10;
    localparam S_RAIN  = 2'b11;

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
                else if (sensor_hujan)
                    next_state = S_RAIN;
                else if (sensor_kering)
                    next_state = S_WATER;
                else
                    next_state = S_CHECK;
            end

            S_WATER: begin
                if (!enable)
                    next_state = S_IDLE;
                else if (sensor_hujan)
                    next_state = S_RAIN;
                else if (!sensor_kering)
                    next_state = S_RAIN;
                else
                    next_state = S_WATER;
            end

            S_RAIN: begin
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