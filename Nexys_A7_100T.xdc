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