`timescale 1ns/1ps

module tb_viterbi_top_files;

  localparam integer MAX_WAIT_CYCLES = 40;

  reg clk = 1'b0;
  reg rstn = 1'b0;
  reg viterbi_enable = 1'b0;
  reg [15:0] input_data = 16'd0;
  wire [7:0] output_data;
  wire output_done;

  integer input_fd, output_fd;
  integer input_scan, output_scan;
  integer frame_count = 0;
  integer errors = 0;
  integer wait_cycles;
  reg [15:0] input_frame;
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

  task automatic check_frame(input [15:0] frame, input [7:0] expected);
    begin
      @(negedge clk);
      input_data = frame;
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
        $display("LOI frame %0d: timeout, input=%04b", frame_count, frame);
      end else if (output_data !== expected) begin
        errors = errors + 1;
        $display("LOI frame %0d: input=%04b expected=%08b actual=%08b",
                 frame_count, frame, expected, output_data);
      end

      if (output_done === 1'b1) begin
        @(negedge clk);
        if (output_done === 1'b1) begin
          errors = errors + 1;
          $display("LOI frame %0d: output_done dai hon 1 chu ky", frame_count);
        end
      end
    end
  endtask

  initial begin
    input_fd = $fopen("C:/Source_Code/Viterbi_Decoder/tb/input.txt", "r");
    output_fd = $fopen("C:/Source_Code/Viterbi_Decoder/tb/output.txt", "r");
    if (input_fd == 0 || output_fd == 0) begin
      errors = errors + 1;
      $display("LOI: khong mo duoc ../tb/input.txt hoac ../tb/output.txt (hay chay tu thu muc sim)");
      if (input_fd != 0) $fclose(input_fd);
      if (output_fd != 0) $fclose(output_fd);
      $display("KET QUA: FAILED");
      $finish;
    end

    repeat (3) @(posedge clk);
    @(negedge clk);
    rstn = 1'b1;

    input_scan = $fscanf(input_fd, "%b", input_frame);
    output_scan = $fscanf(output_fd, "%b", expected_data);
    while (input_scan == 1 && output_scan == 1) begin
      check_frame(input_frame, expected_data);
      frame_count = frame_count + 1;
      input_scan = $fscanf(input_fd, "%b", input_frame);
      output_scan = $fscanf(output_fd, "%b", expected_data);
    end

    if (input_scan != -1 || output_scan != -1) begin
      errors = errors + 1;
      $display("LOI: input.txt va output.txt sai dinh dang hoac khong cung so dong");
    end
    if (frame_count == 0) begin
      errors = errors + 1;
      $display("LOI: khong co vector nao de kiem tra");
    end

    $fclose(input_fd);
    $fclose(output_fd);
    $display("So frame: %0d; so loi: %0d", frame_count, errors);
    if (errors == 0) $display("KET QUA: PASSED");
    else             $display("KET QUA: FAILED");
    $finish;
  end

endmodule
