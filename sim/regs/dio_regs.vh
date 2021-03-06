`define ADDR_DIO_TRIG0                 8'h0
`define DIO_TRIG0_SECONDS_OFFSET 0
`define DIO_TRIG0_SECONDS 32'hffffffff
`define ADDR_DIO_TRIGH0                8'h4
`define DIO_TRIGH0_SECONDS_OFFSET 0
`define DIO_TRIGH0_SECONDS 32'h000000ff
`define ADDR_DIO_CYC0                  8'h8
`define DIO_CYC0_CYC_OFFSET 0
`define DIO_CYC0_CYC 32'h0fffffff
`define ADDR_DIO_TRIG1                 8'hc
`define DIO_TRIG1_SECONDS_OFFSET 0
`define DIO_TRIG1_SECONDS 32'hffffffff
`define ADDR_DIO_TRIGH1                8'h10
`define DIO_TRIGH1_SECONDS_OFFSET 0
`define DIO_TRIGH1_SECONDS 32'h000000ff
`define ADDR_DIO_CYC1                  8'h14
`define DIO_CYC1_CYC_OFFSET 0
`define DIO_CYC1_CYC 32'h0fffffff
`define ADDR_DIO_TRIG2                 8'h18
`define DIO_TRIG2_SECONDS_OFFSET 0
`define DIO_TRIG2_SECONDS 32'hffffffff
`define ADDR_DIO_TRIGH2                8'h1c
`define DIO_TRIGH2_SECONDS_OFFSET 0
`define DIO_TRIGH2_SECONDS 32'h000000ff
`define ADDR_DIO_CYC2                  8'h20
`define DIO_CYC2_CYC_OFFSET 0
`define DIO_CYC2_CYC 32'h0fffffff
`define ADDR_DIO_TRIG3                 8'h24
`define DIO_TRIG3_SECONDS_OFFSET 0
`define DIO_TRIG3_SECONDS 32'hffffffff
`define ADDR_DIO_TRIGH3                8'h28
`define DIO_TRIGH3_SECONDS_OFFSET 0
`define DIO_TRIGH3_SECONDS 32'h000000ff
`define ADDR_DIO_CYC3                  8'h2c
`define DIO_CYC3_CYC_OFFSET 0
`define DIO_CYC3_CYC 32'h0fffffff
`define ADDR_DIO_TRIG4                 8'h30
`define DIO_TRIG4_SECONDS_OFFSET 0
`define DIO_TRIG4_SECONDS 32'hffffffff
`define ADDR_DIO_TRIGH4                8'h34
`define DIO_TRIGH4_SECONDS_OFFSET 0
`define DIO_TRIGH4_SECONDS 32'h000000ff
`define ADDR_DIO_CYC4                  8'h38
`define DIO_CYC4_CYC_OFFSET 0
`define DIO_CYC4_CYC 32'h0fffffff
`define ADDR_DIO_OUT                   8'h3c
`define DIO_OUT_MODE_OFFSET 0
`define DIO_OUT_MODE 32'h0000001f
`define ADDR_DIO_LATCH                 8'h40
`define DIO_LATCH_TIME_CH0_OFFSET 0
`define DIO_LATCH_TIME_CH0 32'h00000001
`define DIO_LATCH_TIME_CH1_OFFSET 1
`define DIO_LATCH_TIME_CH1 32'h00000002
`define DIO_LATCH_TIME_CH2_OFFSET 2
`define DIO_LATCH_TIME_CH2 32'h00000004
`define DIO_LATCH_TIME_CH3_OFFSET 3
`define DIO_LATCH_TIME_CH3 32'h00000008
`define DIO_LATCH_TIME_CH4_OFFSET 4
`define DIO_LATCH_TIME_CH4 32'h00000010
`define ADDR_DIO_TRIG                  8'h44
`define DIO_TRIG_RDY_OFFSET 0
`define DIO_TRIG_RDY 32'h0000001f
`define ADDR_DIO_PROG0_PULSE           8'h48
`define DIO_PROG0_PULSE_LENGTH_OFFSET 0
`define DIO_PROG0_PULSE_LENGTH 32'h0fffffff
`define ADDR_DIO_PROG1_PULSE           8'h4c
`define DIO_PROG1_PULSE_LENGTH_OFFSET 0
`define DIO_PROG1_PULSE_LENGTH 32'h0fffffff
`define ADDR_DIO_PROG2_PULSE           8'h50
`define DIO_PROG2_PULSE_LENGTH_OFFSET 0
`define DIO_PROG2_PULSE_LENGTH 32'h0fffffff
`define ADDR_DIO_PROG3_PULSE           8'h54
`define DIO_PROG3_PULSE_LENGTH_OFFSET 0
`define DIO_PROG3_PULSE_LENGTH 32'h0fffffff
`define ADDR_DIO_PROG4_PULSE           8'h58
`define DIO_PROG4_PULSE_LENGTH_OFFSET 0
`define DIO_PROG4_PULSE_LENGTH 32'h0fffffff
`define ADDR_DIO_PULSE                 8'h5c
`define DIO_PULSE_IMM_0_OFFSET 0
`define DIO_PULSE_IMM_0 32'h00000001
`define DIO_PULSE_IMM_1_OFFSET 1
`define DIO_PULSE_IMM_1 32'h00000002
`define DIO_PULSE_IMM_2_OFFSET 2
`define DIO_PULSE_IMM_2 32'h00000004
`define DIO_PULSE_IMM_3_OFFSET 3
`define DIO_PULSE_IMM_3 32'h00000008
`define DIO_PULSE_IMM_4_OFFSET 4
`define DIO_PULSE_IMM_4 32'h00000010
`define ADDR_DIO_EIC_IDR               8'h60
`define DIO_EIC_IDR_NEMPTY_0_OFFSET 0
`define DIO_EIC_IDR_NEMPTY_0 32'h00000001
`define DIO_EIC_IDR_NEMPTY_1_OFFSET 1
`define DIO_EIC_IDR_NEMPTY_1 32'h00000002
`define DIO_EIC_IDR_NEMPTY_2_OFFSET 2
`define DIO_EIC_IDR_NEMPTY_2 32'h00000004
`define DIO_EIC_IDR_NEMPTY_3_OFFSET 3
`define DIO_EIC_IDR_NEMPTY_3 32'h00000008
`define DIO_EIC_IDR_NEMPTY_4_OFFSET 4
`define DIO_EIC_IDR_NEMPTY_4 32'h00000010
`define DIO_EIC_IDR_TRIGGER_READY_0_OFFSET 5
`define DIO_EIC_IDR_TRIGGER_READY_0 32'h00000020
`define DIO_EIC_IDR_TRIGGER_READY_1_OFFSET 6
`define DIO_EIC_IDR_TRIGGER_READY_1 32'h00000040
`define DIO_EIC_IDR_TRIGGER_READY_2_OFFSET 7
`define DIO_EIC_IDR_TRIGGER_READY_2 32'h00000080
`define DIO_EIC_IDR_TRIGGER_READY_3_OFFSET 8
`define DIO_EIC_IDR_TRIGGER_READY_3 32'h00000100
`define DIO_EIC_IDR_TRIGGER_READY_4_OFFSET 9
`define DIO_EIC_IDR_TRIGGER_READY_4 32'h00000200
`define ADDR_DIO_EIC_IER               8'h64
`define DIO_EIC_IER_NEMPTY_0_OFFSET 0
`define DIO_EIC_IER_NEMPTY_0 32'h00000001
`define DIO_EIC_IER_NEMPTY_1_OFFSET 1
`define DIO_EIC_IER_NEMPTY_1 32'h00000002
`define DIO_EIC_IER_NEMPTY_2_OFFSET 2
`define DIO_EIC_IER_NEMPTY_2 32'h00000004
`define DIO_EIC_IER_NEMPTY_3_OFFSET 3
`define DIO_EIC_IER_NEMPTY_3 32'h00000008
`define DIO_EIC_IER_NEMPTY_4_OFFSET 4
`define DIO_EIC_IER_NEMPTY_4 32'h00000010
`define DIO_EIC_IER_TRIGGER_READY_0_OFFSET 5
`define DIO_EIC_IER_TRIGGER_READY_0 32'h00000020
`define DIO_EIC_IER_TRIGGER_READY_1_OFFSET 6
`define DIO_EIC_IER_TRIGGER_READY_1 32'h00000040
`define DIO_EIC_IER_TRIGGER_READY_2_OFFSET 7
`define DIO_EIC_IER_TRIGGER_READY_2 32'h00000080
`define DIO_EIC_IER_TRIGGER_READY_3_OFFSET 8
`define DIO_EIC_IER_TRIGGER_READY_3 32'h00000100
`define DIO_EIC_IER_TRIGGER_READY_4_OFFSET 9
`define DIO_EIC_IER_TRIGGER_READY_4 32'h00000200
`define ADDR_DIO_EIC_IMR               8'h68
`define DIO_EIC_IMR_NEMPTY_0_OFFSET 0
`define DIO_EIC_IMR_NEMPTY_0 32'h00000001
`define DIO_EIC_IMR_NEMPTY_1_OFFSET 1
`define DIO_EIC_IMR_NEMPTY_1 32'h00000002
`define DIO_EIC_IMR_NEMPTY_2_OFFSET 2
`define DIO_EIC_IMR_NEMPTY_2 32'h00000004
`define DIO_EIC_IMR_NEMPTY_3_OFFSET 3
`define DIO_EIC_IMR_NEMPTY_3 32'h00000008
`define DIO_EIC_IMR_NEMPTY_4_OFFSET 4
`define DIO_EIC_IMR_NEMPTY_4 32'h00000010
`define DIO_EIC_IMR_TRIGGER_READY_0_OFFSET 5
`define DIO_EIC_IMR_TRIGGER_READY_0 32'h00000020
`define DIO_EIC_IMR_TRIGGER_READY_1_OFFSET 6
`define DIO_EIC_IMR_TRIGGER_READY_1 32'h00000040
`define DIO_EIC_IMR_TRIGGER_READY_2_OFFSET 7
`define DIO_EIC_IMR_TRIGGER_READY_2 32'h00000080
`define DIO_EIC_IMR_TRIGGER_READY_3_OFFSET 8
`define DIO_EIC_IMR_TRIGGER_READY_3 32'h00000100
`define DIO_EIC_IMR_TRIGGER_READY_4_OFFSET 9
`define DIO_EIC_IMR_TRIGGER_READY_4 32'h00000200
`define ADDR_DIO_EIC_ISR               8'h6c
`define DIO_EIC_ISR_NEMPTY_0_OFFSET 0
`define DIO_EIC_ISR_NEMPTY_0 32'h00000001
`define DIO_EIC_ISR_NEMPTY_1_OFFSET 1
`define DIO_EIC_ISR_NEMPTY_1 32'h00000002
`define DIO_EIC_ISR_NEMPTY_2_OFFSET 2
`define DIO_EIC_ISR_NEMPTY_2 32'h00000004
`define DIO_EIC_ISR_NEMPTY_3_OFFSET 3
`define DIO_EIC_ISR_NEMPTY_3 32'h00000008
`define DIO_EIC_ISR_NEMPTY_4_OFFSET 4
`define DIO_EIC_ISR_NEMPTY_4 32'h00000010
`define DIO_EIC_ISR_TRIGGER_READY_0_OFFSET 5
`define DIO_EIC_ISR_TRIGGER_READY_0 32'h00000020
`define DIO_EIC_ISR_TRIGGER_READY_1_OFFSET 6
`define DIO_EIC_ISR_TRIGGER_READY_1 32'h00000040
`define DIO_EIC_ISR_TRIGGER_READY_2_OFFSET 7
`define DIO_EIC_ISR_TRIGGER_READY_2 32'h00000080
`define DIO_EIC_ISR_TRIGGER_READY_3_OFFSET 8
`define DIO_EIC_ISR_TRIGGER_READY_3 32'h00000100
`define DIO_EIC_ISR_TRIGGER_READY_4_OFFSET 9
`define DIO_EIC_ISR_TRIGGER_READY_4 32'h00000200
`define ADDR_DIO_TSF0_R0               8'h70
`define DIO_TSF0_R0_TAG_SECONDS_OFFSET 0
`define DIO_TSF0_R0_TAG_SECONDS 32'hffffffff
`define ADDR_DIO_TSF0_R1               8'h74
`define DIO_TSF0_R1_TAG_SECONDSH_OFFSET 0
`define DIO_TSF0_R1_TAG_SECONDSH 32'h000000ff
`define ADDR_DIO_TSF0_R2               8'h78
`define DIO_TSF0_R2_TAG_CYCLES_OFFSET 0
`define DIO_TSF0_R2_TAG_CYCLES 32'h0fffffff
`define ADDR_DIO_TSF0_CSR              8'h7c
`define DIO_TSF0_CSR_FULL_OFFSET 16
`define DIO_TSF0_CSR_FULL 32'h00010000
`define DIO_TSF0_CSR_EMPTY_OFFSET 17
`define DIO_TSF0_CSR_EMPTY 32'h00020000
`define DIO_TSF0_CSR_USEDW_OFFSET 0
`define DIO_TSF0_CSR_USEDW 32'h000000ff
`define ADDR_DIO_TSF1_R0               8'h80
`define DIO_TSF1_R0_TAG_SECONDS_OFFSET 0
`define DIO_TSF1_R0_TAG_SECONDS 32'hffffffff
`define ADDR_DIO_TSF1_R1               8'h84
`define DIO_TSF1_R1_TAG_SECONDSH_OFFSET 0
`define DIO_TSF1_R1_TAG_SECONDSH 32'h000000ff
`define ADDR_DIO_TSF1_R2               8'h88
`define DIO_TSF1_R2_TAG_CYCLES_OFFSET 0
`define DIO_TSF1_R2_TAG_CYCLES 32'h0fffffff
`define ADDR_DIO_TSF1_CSR              8'h8c
`define DIO_TSF1_CSR_FULL_OFFSET 16
`define DIO_TSF1_CSR_FULL 32'h00010000
`define DIO_TSF1_CSR_EMPTY_OFFSET 17
`define DIO_TSF1_CSR_EMPTY 32'h00020000
`define DIO_TSF1_CSR_USEDW_OFFSET 0
`define DIO_TSF1_CSR_USEDW 32'h000000ff
`define ADDR_DIO_TSF2_R0               8'h90
`define DIO_TSF2_R0_TAG_SECONDS_OFFSET 0
`define DIO_TSF2_R0_TAG_SECONDS 32'hffffffff
`define ADDR_DIO_TSF2_R1               8'h94
`define DIO_TSF2_R1_TAG_SECONDSH_OFFSET 0
`define DIO_TSF2_R1_TAG_SECONDSH 32'h000000ff
`define ADDR_DIO_TSF2_R2               8'h98
`define DIO_TSF2_R2_TAG_CYCLES_OFFSET 0
`define DIO_TSF2_R2_TAG_CYCLES 32'h0fffffff
`define ADDR_DIO_TSF2_CSR              8'h9c
`define DIO_TSF2_CSR_FULL_OFFSET 16
`define DIO_TSF2_CSR_FULL 32'h00010000
`define DIO_TSF2_CSR_EMPTY_OFFSET 17
`define DIO_TSF2_CSR_EMPTY 32'h00020000
`define DIO_TSF2_CSR_USEDW_OFFSET 0
`define DIO_TSF2_CSR_USEDW 32'h000000ff
`define ADDR_DIO_TSF3_R0               8'ha0
`define DIO_TSF3_R0_TAG_SECONDS_OFFSET 0
`define DIO_TSF3_R0_TAG_SECONDS 32'hffffffff
`define ADDR_DIO_TSF3_R1               8'ha4
`define DIO_TSF3_R1_TAG_SECONDSH_OFFSET 0
`define DIO_TSF3_R1_TAG_SECONDSH 32'h000000ff
`define ADDR_DIO_TSF3_R2               8'ha8
`define DIO_TSF3_R2_TAG_CYCLES_OFFSET 0
`define DIO_TSF3_R2_TAG_CYCLES 32'h0fffffff
`define ADDR_DIO_TSF3_CSR              8'hac
`define DIO_TSF3_CSR_FULL_OFFSET 16
`define DIO_TSF3_CSR_FULL 32'h00010000
`define DIO_TSF3_CSR_EMPTY_OFFSET 17
`define DIO_TSF3_CSR_EMPTY 32'h00020000
`define DIO_TSF3_CSR_USEDW_OFFSET 0
`define DIO_TSF3_CSR_USEDW 32'h000000ff
`define ADDR_DIO_TSF4_R0               8'hb0
`define DIO_TSF4_R0_TAG_SECONDS_OFFSET 0
`define DIO_TSF4_R0_TAG_SECONDS 32'hffffffff
`define ADDR_DIO_TSF4_R1               8'hb4
`define DIO_TSF4_R1_TAG_SECONDSH_OFFSET 0
`define DIO_TSF4_R1_TAG_SECONDSH 32'h000000ff
`define ADDR_DIO_TSF4_R2               8'hb8
`define DIO_TSF4_R2_TAG_CYCLES_OFFSET 0
`define DIO_TSF4_R2_TAG_CYCLES 32'h0fffffff
`define ADDR_DIO_TSF4_CSR              8'hbc
`define DIO_TSF4_CSR_FULL_OFFSET 16
`define DIO_TSF4_CSR_FULL 32'h00010000
`define DIO_TSF4_CSR_EMPTY_OFFSET 17
`define DIO_TSF4_CSR_EMPTY 32'h00020000
`define DIO_TSF4_CSR_USEDW_OFFSET 0
`define DIO_TSF4_CSR_USEDW 32'h000000ff
