// ============================================================
// Modul 1: Data Flow (assign statements untuk decoding)
// Modul 2: Sub-module yang dapat di-reuse (7-seg decoder)
// ============================================================
// Decoder 7-Segment untuk menampilkan inisial state:
//   S_IDLE  (3'b000) → 'I'  (IDLE)
//   S_CHECK (3'b001) → 'C'  (CHECK)
//   S_DRY   (3'b010) → 'y'  (Kering / Dry, kuning)
//   S_WATER (3'b011) → 'A'  (AIR = menyiram/pengairan, biru)
//   S_RAIN  (3'b100) → 'H'  (HUJAN / Rain, hijau)
//   S_DONE  (3'b101) → 'd'  (DONE)
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
    input  wire [2:0] state,
    output reg  [6:0] seg,
    output reg  [7:0] an
);

    always @(*) begin
        an = 8'b11111110;

        case (state)
            3'b000: seg = 7'b1001111;  // 'I'
            3'b001: seg = 7'b1000110;  // 'C'
            3'b010: seg = 7'b0010001;  // 'y' (kuning/kering)
            3'b011: seg = 7'b0001000;  // 'A' (air/biru)
            3'b100: seg = 7'b0001001;  // 'H' (hujan/hijau)
            3'b101: seg = 7'b0100001;  // 'd' (done)
            default: seg = 7'b1111111;
        endcase
    end

endmodule