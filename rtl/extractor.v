module extractor (
    input wire clk,
    input wire rst_n,

    input wire viterbi_enable,
    input wire [15:0] input_data,

    output wire [1:0] o_pair,
    output wire o_valid, 
    output wire o_sof
);

    reg [15:0] frame;
    reg [3:0] count;
    reg busy;

    wire load = viterbi_enable && ~bussy && rst_n;

    // Nạp dữ liệu vào thanh ghi frame 
    always @(posedge clk) begin
        if (load) begin
            frame <= input_data;
        end
    end

    // Điều khiển trạng thái hoạt động busy và bộ đếm count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            count <= 4'd0;
        end
        else if (load) begin
            busy <= 1'b1;
            count <= 4'd0;
        end
        else if (busy && (count < 4'd12)) begin
            count <= count + 1'b1;
        end
        else if (busy && (count == 4'd12)) begin
            busy <= 1'b0;
            count <= 4'd12;
        end
    end

    reg [1:0] pair_raw;

    always @(count or frame) begin
        pair_raw = 2'b00;

        case (count[2:0])
            3'd0: pair_raw = frame[15:14];
            3'd1: pair_raw = frame[13:12];
            3'd2: pair_raw = frame[11:10];
            3'd3: pair_raw = frame[9:8];
            3'd4: pair_raw = frame[7:6];
            3'd5: pair_raw = frame[5:4];
            3'd6: pair_raw = frame[3:2];
            3'd7: pair_raw = frame[1:0];
        endcase
    end

    assign o_valid = busy && (count < 4'd8);
    assign o_sof = o_valid && (count == 4'd0);
    assign o_pair = o_valid ? pair_raw : 2'b00;

endmodule 