`timescale 1ns/10ps

module circbuf_tb;
  parameter EXT_COUNT  = 2;
  parameter INS_COUNT  = 2;

  logic clock;
  logic reset_n;

  logic [0:0] new_count;
  logic [0:0] ext_consumed;

  logic       ins_enable;
  logic       ext_enable;

  logic out_valid[EXT_COUNT];
  integer unsigned out_elements[EXT_COUNT];
  integer unsigned new_elements[INS_COUNT];

  logic   empty;
  logic   full;

  circbuf #
    (
     .T(integer unsigned),
     .INS_COUNT(2),
     .EXT_COUNT(2)
     )
  cb1
    (
     .clock (clock),
     .reset_n(reset_n),

     .ins_enable(ins_enable),
     .new_count(new_count),
     .new_elements(new_elements),

     .ext_enable(ext_enable),
     .ext_consumed(ext_consumed),
     .ext_valid(out_valid),
     .out_elements(out_elements),

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


  task insert;
    new_count  = $random;

    for (integer i = 0; i <= new_count; i++)
      new_elements[i]  = $random;

    ins_enable  = 1'b1;
    @(posedge clock);

    for (integer i = 0; i <= new_count; i++)
      $display("=> %x", new_elements[i]);

    ins_enable = 1'b0;
  endtask


  task extract;
    ext_consumed  = (cb1.used_count >= 2) ? $random : 0;

    for (integer i = 0; i < EXT_COUNT; i++) begin
      $display("<= %x (valid: %b)", out_elements[i], out_valid[i]);
    end

    ext_enable  = 1'b1;
    @(posedge clock);
    $display("consumed %d elements", ext_consumed + 1);
    ext_enable  = 1'b0;
  endtask


  task dump_state;
    #1
    $display("empty: %b, full: %b, used: %d", cb1.empty, cb1.full, cb1.used_count);
    $display("ins_ptr: %d, ext_ptr: %d", cb1.ins_ptr, cb1.ext_ptr);
  endtask //


  initial begin
    reset_n      = 1;
    ins_enable   = 1'b0;
    ext_enable   = 1'b0;

    #5  reset_n  = 0;
    #16 reset_n  = 1;

    @(posedge clock);
    @(posedge clock);

    insert();
    dump_state();

    extract();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    extract();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    extract();
    dump_state();

    extract();
    dump_state();

    extract();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();

    insert();
    dump_state();


  end

endmodule
