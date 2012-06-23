simvision {
  # Open new waveform window

    window new WaveWindow  -name  "Waves for SuperMIPS"
    window  geometry  "Waves for SuperMIPS"  1010x410+0+25
    waveform  using  "Waves for SuperMIPS"

  # Add basic signals to wave window

    waveform  add  -signals  top.clock
    waveform  add  -signals  top.reset_n

    set id [waveform add -signals top.CPU.IF.pc]
    waveform format $id -radix %x
}
