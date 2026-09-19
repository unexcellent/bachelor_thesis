#heading[Appendix]

== Pin Map

#figure(
  table(
    columns: 4,
    align: left,
    [*GPIO*], [*Connected to*], [*Label*], [*Purpose*],
    [9], [SC850SL], [SCL], [I2C bus clock],
    [11], [SC850SL], [SDA], [camera register configuration],
    [12], [MI1602], [SDA], [Register control],
    [15], [MI1602], [SCL], [MIPI-CSI bus clock],
    [20], [PCM5102A], [MCLK], [Master clock],
    [21], [PCM5102A], [BCLK], [Bit clock],
    [22], [PCM5102A], [DOUT], [Serial audio sample data],
    [23], [PCM5102A], [WS], [Word select],
    [28], [MI1602], [SCLK], [SPI2 clock for frame readout],
    [29], [MI1602], [MISO], [SPI2 data input],
    [30], [MI1602], [MOSI], [SPI2 data output],
    [31], [MI1602], [SSN], [SPI2 slave select],
    [37], [THVD1424], [RX], [Receives CSP messages from the payload board],
    [38], [THVD1424], [TX], [Transmits CSP messages to the payload board],
    [39], [THVD1424], [DE], [Enables sending via RS485. Permanently held high],
    [54], [SC850SL], [XSHUTDN], [Shutdown / reset],
  ),
  caption: [ESP32-P4 pin mapping (only the relevant parts)],
) <tab-gpio>

== Data Budgets

#figure(
  table(
    columns: 4,
    align: left,
    [*Category*], [*Name*], [*Value*], [*Unit*],

    table.cell(rowspan: 1)[Link], [*Data Rate*], [*4.8*], [*kB/s*],

    table.cell(rowspan: 5)[Ground Station],
    [Minimum Elevation Angle],
    [10],
    [°],
    [Latitude], [48.0641], [°],
    [Elevation], [0], [m],
    [Velocity due to Earth's Rotation], [310.835], [m/s],
    [*Visibility Cone Width*], [*3191.37*], [*km*],

    table.cell(rowspan: 2)[Satellite],
    [Average Overpasses Per Day],
    [3.61721],
    [],
    [*Average Overpass Duration*], [*329.253*], [*s*],

    table.cell(rowspan: 2)[Result],
    [Average Volume Per Overpass],
    [1580.42],
    [kB],
    [*Average Volume Per Day*], [*5716.7*], [*kB*],
  ),
  caption: [MOVE-IIIa UHF data budget],
) <tab-uhf-data>

#figure(
  table(
    columns: 4,
    align: left,
    [*Category*], [*Name*], [*Value*], [*Unit*],

    table.cell(rowspan: 1)[Link], [*Data Rate*], [*62.5*], [*kB/s*],

    table.cell(rowspan: 5)[Ground Station],
    [Minimum Elevation Angle],
    [10],
    [°],
    [Latitude], [48.0641], [°],
    [Elevation], [0], [m],
    [Velocity due to Earth's Rotation], [310.835], [m/s],
    [*Visibility Cone Width*], [*3191.37*], [*km*],

    table.cell(rowspan: 2)[Satellite],
    [Average Overpasses Per Day],
    [3.61721],
    [],
    [*Average Overpass Duration*], [*329.253*], [*s*],

    table.cell(rowspan: 2)[Result],
    [Average Volume Per Overpass],
    [20578.3],
    [kB],
    [*Average Volume Per Day*], [*74436.2*], [*kB*],
  ),
  caption: [MOVE-IIIa S-band data budget],
) <tab-sband-data>
