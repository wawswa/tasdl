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