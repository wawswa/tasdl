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