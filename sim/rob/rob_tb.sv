`timescale 1ns/10ps

module rob_tb;
  parameter EXT_COUNT  = 4;
  parameter INS_COUNT  = 4;

  logic clock;
  logic reset_n;

  logic reserve_en;
  logic [1:0] reserve_count;
  logic [3:0] reserved_slots[4];

  logic [3:0] write_slot[4];
  logic       write_valid[4];
  integer     unsigned write_data[4];

  logic       consume_en;
  logic [1:0] consume_count;
  integer     unsigned slot_data[4];
  logic       slot_valid[4];

  logic   empty;
  logic   full;

  typedef struct {
    logic [3:0]  slot;
    integer      unsigned result;
    integer      pc;
    } inst_t;

  inst_t results[$];

  rob #
    (
     .T(integer unsigned),
     .INS_COUNT(4),
     .EXT_COUNT(4)
     )
  cb1
    (
     .clock (clock),
     .reset_n(reset_n),

     .reserve(reserve_en),
     .reserve_count(reserve_count),
     .reserved_slots(reserved_slots),

     .write_slot(write_slot),
     .write_valid(write_valid),
     .write_data(write_data),

     .consume(consume_en),
     .consume_count(consume_count),
     .slot_data(slot_data),
     .slot_valid(slot_valid),

     .empty(empty),
     .full(full)
     );


  // 100 MHz clock
  always
  begin
         clock = 0;
    #5   clock = 1;
    #5   clock = 0;
  end



  task reserve(input integer count, output logic [3:0] slots[4]);
    while (full)
      @(posedge clock);

    reserve_count   = count-1;
    reserve_en      = 1'b1;
    slots           = reserved_slots;
    for (integer i = 0; i < 4; i++) begin
      //$display("slot %x <-> %x reserved_slot", slots[i], reserved_slots[i]);
    end

    @(posedge clock); #1

    reserve_en  = 1'b0;
    dump_state();
  endtask // reserve


  task write(input logic [3:0] slots[4], input integer unsigned data[4], input integer count);
    write_slot  = slots;

    for (integer i = 0; i < count; i++)
      write_valid[i]  = 1'b1;

    write_data = data;
    @(posedge clock); #1

    for (integer i = 0; i < 4; i++)
      write_valid[i]  = 1'b0;
    dump_state();
  endtask // write


  task consume(output integer unsigned data[4], output integer count);
    automatic integer c;

    data     = slot_data;

    for (c = 0; c < 4 && slot_valid[c]; c++)
      ;

    count          = c;
    consume_en     = (c > 0) ? 1'b1 : 1'b0;
    consume_count  = c-1;
    @(posedge clock); #1

    consume_en  = 1'b0;
    dump_state();

  endtask // consume


  task automatic execute(input logic [3:0] slot, input integer pc);
    automatic logic [2:0] cycles  = $random;
    automatic inst_t insn;

    insn.slot                     = slot;
    insn.result                   = pc;//$random;
    insn.pc                       = pc;

    $display("Start execute pc=%d, slot=%x, result=%x", pc, insn.slot, insn.result);

    for (integer i = 0; i < cycles; i++)
      @(posedge clock);

    results.push_back(insn);
    //$display("Finish execute pc=%d, slot=%x, result=%x", insn.pc, insn.slot, insn.result);
  endtask // execute


  task retire();
    automatic inst_t insn;
    automatic logic [3:0] slots[4];
    automatic integer     unsigned data[4];
    automatic integer i, c;

    while (1) begin
      @(posedge clock);
      c  = (results.size() < 4) ? results.size() : 4;

      for (i = 0; i < c; i++) begin
        insn      = results.pop_front();
        slots[i]  = insn.slot;
        data[i]   = insn.result;
        $display("Retire pc=%d, slot=%x, result=%x", insn.pc, insn.slot, insn.result);
      end

      write(.slots(slots), .data(data), .count(i));
    end
  endtask // retire


  task decode();
    automatic logic [3:0] slots[4];
    automatic integer pc = 0;
    automatic integer res_count  = 4;
    while (1) begin
      reserve(.count(res_count), .slots(slots));
      for (integer i = 0; i < 4; i++) begin
        $display("Reserve slot %x", slots[i]);
      end

      for (integer i = 0; i < res_count; i++) begin
        automatic integer pcs       = pc;
        automatic logic [3:0] slot  = slots[i];

        fork
          //$display("call execute(%x, %x)", slot, pcs);

          execute(.slot(slot), .pc(pcs));
        join_none
        pc += 1;
      end
    end
  endtask // decode


  task commit();
    automatic integer c;
    automatic integer expected_pc  = 0;
    automatic integer unsigned data[4];

    while (1) begin
      consume(.data(data), .count(c));
      for (integer i = 0; i < c; i++) begin
        $display("Commit: result=%x", data[i]);
        assert(expected_pc == data[i]) begin
        end else
          $stop;

        expected_pc += 1;
      end
    end
  endtask // commit


  task dump_state;
    #1
    $display("empty: %b, full: %b, used: %d", cb1.empty, cb1.full, cb1.used_count);
    $display("ins_ptr: %d, ext_ptr: %d", cb1.ins_ptr, cb1.ext_ptr);
  endtask //


  /* // XXX: my version of ModelSim doesn't support covergroups
  covergroup cg_fill_level @(posedge clock);
    coverpoint cb1.used_count;
  endgroup // cg_fill_level
   */


  initial begin
    reset_n         = 1;
    reserve_en      = 1'b0;
    consume_en      = 1'b0;
    for (integer i = 0; i < 4; i++)
      write_valid[i]  = 1'b0;

    #5  reset_n       = 0;
    #16 reset_n       = 1;

    @(posedge clock);
    @(posedge clock);

    fork
      decode();
      retire();
      commit();
    join
  end

endmodule
