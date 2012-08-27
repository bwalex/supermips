import pipTypes::*;

module circ_buf #(
  parameter type T     = iq_entry_t,
  parameter      DEPTH     = 16,
                 INS_COUNT = 4,
                 EXT_COUNT = 4,
                 DEPTHLOG2  = `clogb2(DEPTH),
                 EXTCOUNTLOG2  = `clogb2(EXT_COUNT),
                 INSCOUNTLOG2  = `clogb2(INS_COUNT)
)(
  input                    clock,
  input                    reset_n,

  input                    ins_enable,
  input [INSCOUNTLOG2-1:0] new_count,
  input                    T new_elements[INS_COUNT],

  input                    ext_enable,
  input                    ext_consumed[EXT_COUNT],
  output reg               ext_valid[EXT_COUNT],
  output                   T out_elements[EXT_COUNT],

  input                    flush,
  input                    flush_stream,
  input [6:0]              flush_idx,

  output                   full,
  output                   empty,
  output reg [DEPTHLOG2:0] used_count
);

  wire                     ins_enable_i;
  wire                     ext_enable_i;
  wire [EXTCOUNTLOG2-1:0]  ext_consumed_i;

  reg [6:0]                idx_r;

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      idx_r <= 'b0;
    else if (ins_enable)
      idx_r <= idx_r + new_count + 1;


  iq_entry_int_t buffer[$:DEPTH];

  assign ins_enable_i    = ins_enable & ~full;
  assign ext_enable_i    = ext_enable & ~empty;

  always_ff @(posedge clock, negedge reset_n)
    if (~reset_n)
      buffer = { };
    else begin
      automatic integer fi  = 0;
      automatic bit [6:0] ft;

`ifdef IQ_TRACE_ENABLE
      $fwrite(trace_file, "%d IQ: used_count: %d, empty: %b, full: %b\n",
              $time, used_count, empty, full);
`endif

      if (ext_enable_i) begin
        ft  = flush_idx+1;
        for (integer i = 0; i < buffer.size(); i++)
          if (buffer[i].idx == ft)
            fi  = i;

        for (integer i = EXT_COUNT-1; i >= 0; i--) begin
          automatic iq_entry_int_t e  = buffer[i];
          if (ext_consumed[i] & ext_valid[i]) begin
            if (i <= fi)
              fi -= 1;

            buffer.delete(i);
`ifdef IQ_TRACE_ENABLE
            $fwrite(trace_file, "%d IQ: extract from slot %d, pc=%x, iw=%x, rob_slot=%d, stream=%b idx=%d\n",
                    $time, i, e.dec_inst.pc, e.dec_inst.inst_word, e.rob_slot, e.stream, e.idx);
`endif
          end
        end
      end

      if (ins_enable_i)
        for (integer i = 0; i <= new_count; i++) begin
          automatic iq_entry_int_t e;
          e.rob_slot  = new_elements[i].rob_slot;
          e.dec_inst  = new_elements[i].dec_inst;
          e.stream    = new_elements[i].stream;
          e.idx       = idx_r + i;
          buffer.push_back(e);

`ifdef IQ_TRACE_ENABLE
          $fwrite(trace_file, "%d IQ: insert at slot %d, pc=%x, iw=%x, rob_slot=%d, stream=%b, idx=%d\n",
                  $time,
                  buffer.size()-1, new_elements[i].dec_inst.pc, new_elements[i].dec_inst.inst_word,
                  new_elements[i].rob_slot, new_elements[i].stream, e.idx);
`endif
        end

      if (flush) begin
`ifdef IQ_TRACE_ENABLE
        automatic integer count  = buffer.size();
`endif
        for (integer i = fi; i < buffer.size() && buffer[fi].stream == flush_stream; i++) begin
          buffer.delete(fi);
        end

`ifdef IQ_TRACE_ENABLE
        $fwrite(trace_file, "%d IQ: flush %d instructions, stream=%b\n",
                $time, count - buffer.size(), flush_stream);
`endif
      end

      used_count <= buffer.size();

      for (integer i = 0; i < buffer.size(); i++) begin
        out_elements[i].dec_inst <= buffer[i].dec_inst;
        out_elements[i].rob_slot <= buffer[i].rob_slot;
        out_elements[i].stream   <= buffer[i].stream;
        out_elements[i].idx      <= buffer[i].idx;
        ext_valid[i]             <= 1'b1;
      end
      for (integer i = buffer.size(); i < EXT_COUNT; i++) begin
        ext_valid[i] <= 1'b0;
      end
    end


  assign empty      = (used_count == 0);
  assign full       = (used_count > DEPTH-INS_COUNT);



`ifdef IQ_TRACE_ENABLE
  integer trace_file;

  initial begin
    trace_file  = $fopen("iq.trace", "w");
  end
`endif


endmodule // circbuf
