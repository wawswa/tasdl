// ============================================================
// Modul 1: Behavioral (FSM Next State Logic)
//           Data Flow  (assign untuk output logika)
// Modul 4: D-Flip-Flop (State Register dengan always posedge clk)
// Modul 5: Desain FSM Moore
// ============================================================
// FSM Moore: Output hanya bergantung pada current_state
//
// State Encoding (3-bit):
//   S_IDLE  = 3'b000  → Pompa OFF, 7seg = 'I', LED = OFF
//   S_CHECK = 3'b001  → Pompa OFF, 7seg = 'C', LED = OFF
//   S_DRY   = 3'b010  → Pompa OFF, 7seg = 'y', LED = Kuning
//   S_WATER = 3'b011  → Pompa ON,  7seg = 'A', LED = Biru
//   S_RAIN  = 3'b100  → Pompa OFF, 7seg = 'H', LED = Hijau
//   S_DONE  = 3'b101  → Pompa OFF, 7seg = 'd', LED = OFF
// ============================================================

module fsm_controller(
    input  wire slow_clk,
    input  wire reset,
    input  wire enable,
    input  wire sensor_kering,
    input  wire sensor_hujan,
    output wire pompa_air,
    output wire [2:0] state_out
);

    localparam S_IDLE  = 3'b000;
    localparam S_CHECK = 3'b001;
    localparam S_DRY   = 3'b010;
    localparam S_WATER = 3'b011;
    localparam S_RAIN  = 3'b100;
    localparam S_DONE  = 3'b101;

    reg [2:0] current_state;
    reg [2:0] next_state;

    always @(posedge slow_clk or posedge reset) begin
        if (reset)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end

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
                    next_state = S_DRY;
                else
                    next_state = S_CHECK;
            end

            S_DRY: begin
                if (!enable)
                    next_state = S_IDLE;
                else if (sensor_hujan)
                    next_state = S_RAIN;
                else if (sensor_kering)
                    next_state = S_WATER;
                else
                    next_state = S_DONE;
            end

            S_WATER: begin
                if (!enable)
                    next_state = S_IDLE;
                else if (sensor_hujan)
                    next_state = S_RAIN;
                else if (!sensor_kering)
                    next_state = S_DONE;
                else
                    next_state = S_WATER;
            end

            S_RAIN: begin
                if (!enable)
                    next_state = S_IDLE;
                else if (sensor_hujan)
                    next_state = S_RAIN;
                else
                    next_state = S_CHECK;
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

    assign pompa_air  = (current_state == S_WATER) ? 1'b1 : 1'b0;
    assign state_out  = current_state;

endmodule