`timescale 1ns/1ps

module tb_viterbi_top_exhaustive;

  localparam integer MAX_WAIT_CYCLES = 30;

  reg clk = 1'b0;
  reg rstn = 1'b0;
  reg viterbi_enable = 1'b0;
  reg [15:0] input_data = 16'd0;
  wire [7:0] output_data;
  wire output_done;

  integer frame_count = 0;
  integer errors = 0;
  integer frame;
  integer wait_cycles;
  reg [7:0] expected_data;

  viterbi_top dut (
    .clk(clk),
    .rstn(rstn),
    .input_data(input_data),
    .viterbi_enable(viterbi_enable),
    .output_data(output_data),
    .output_done(output_done)
  );

  always #5 clk = ~clk;

  function automatic integer branch_label(input integer state, input integer bit_in);
    integer s1, s0;
    begin
      s1 = (state >> 1) & 1;
      s0 = state & 1;
      branch_label = ((bit_in ^ s1 ^ s0) << 1) | (bit_in ^ s0);
    end
  endfunction

  function automatic integer hamming(input integer a, input integer b);
    integer d;
    begin
      d = a ^ b;
      hamming = (d & 1) + ((d >> 1) & 1);
    end
  endfunction

  function automatic [7:0] ref_decode(input [15:0] frame_value);
    integer pm [0:3];
    integer next_pm [0:3];
    integer predecessor [0:31];
    integer order [0:3];
    integer step, dst, rank, src0, src1, bit_in, rx, cost0, cost1, node;
    reg [7:0] decoded;
    begin
      pm[0] = 0;
      pm[1] = 23;
      pm[2] = 23;
      pm[3] = 23;

      for (step = 0; step < 8; step = step + 1) begin
        rx = (frame_value >> (14 - 2*step)) & 3;
        for (dst = 0; dst < 4; dst = dst + 1) begin
          bit_in = dst >> 1;
          src0 = (dst & 1) * 2;
          src1 = src0 + 1;
          cost0 = pm[src0] + hamming(rx, branch_label(src0, bit_in));
          cost1 = pm[src1] + hamming(rx, branch_label(src1, bit_in));
          if (cost0 <= cost1) begin
            next_pm[dst] = cost0;
            predecessor[step*4 + dst] = src0;
          end else begin
            next_pm[dst] = cost1;
            predecessor[step*4 + dst] = src1;
          end
        end
        for (dst = 0; dst < 4; dst = dst + 1)
          pm[dst] = next_pm[dst];
      end

      order[0] = 0;
      order[1] = 2;
      order[2] = 1;
      order[3] = 3;
      node = order[0];
      for (rank = 1; rank < 4; rank = rank + 1)
        if (pm[order[rank]] < pm[node]) node = order[rank];

      decoded = 8'd0;
      for (step = 7; step >= 0; step = step - 1) begin
        decoded[7-step] = node >> 1;
        node = predecessor[step*4 + node];
      end
      ref_decode = decoded;
    end
  endfunction

  task automatic run_frame(input [15:0] frame_value, input [7:0] expected);
    begin
      @(negedge clk);
      input_data = frame_value;
      viterbi_enable = 1'b1;
      @(negedge clk);
      viterbi_enable = 1'b0;

      wait_cycles = 0;
      while (output_done !== 1'b1 && wait_cycles < MAX_WAIT_CYCLES) begin
        @(negedge clk);
        wait_cycles = wait_cycles + 1;
      end

      if (output_done !== 1'b1) begin
        errors = errors + 1;
        if (errors <= 20)
          $display("LOI frame %0d input=%04h: timeout", frame_count, frame_value);
      end else if (output_data !== expected) begin
        errors = errors + 1;
        if (errors <= 20)
          $display("LOI frame %0d input=%04h expected=%02h actual=%02h",
                   frame_count, frame_value, expected, output_data);
      end

      if (output_done === 1'b1) @(negedge clk);
      frame_count = frame_count + 1;
      if ((frame_count % 8192) == 0)
        $display("Da kiem tra %0d / 65536 frame", frame_count);
    end
  endtask

  initial begin
    repeat (3) @(posedge clk);
    @(negedge clk);
    rstn = 1'b1;

    $display("--- Exhaustive Viterbi test: 0000..FFFF ---");
    for (frame = 0; frame < 65536; frame = frame + 1) begin
      expected_data = ref_decode(frame[15:0]);
      run_frame(frame[15:0], expected_data);
    end

    $display("So frame: %0d; so loi: %0d", frame_count, errors);
    if (errors == 0) $display("KET QUA: PASSED");
    else             $display("KET QUA: FAILED");
    $finish;
  end

endmodule
