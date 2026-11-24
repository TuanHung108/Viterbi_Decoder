module extractor_unit (
    input wire clk,
    input wire rstn,

    input wire viterbi_enable,
    input wire [15:0] input_data,

    output wire [1:0] o_pair,
    output wire o_valid, 
    output wire o_sof
);

    reg [15:0] frame; // thanh ghi chứa dữ liệu đầu vào
    reg [3:0] count;
    reg busy; // trạng thái bận của EU

    wire accept = viterbi_enable && ~busy && rstn;

    // Nạp dữ liệu vào thanh ghi frame 
    always @(posedge clk) begin
        if (accept) begin
            frame <= input_data;
        end
    end

    // Điều khiển trạng thái hoạt động busy và bộ đếm count
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            busy <= 1'b0;
            count <= 4'd0;
        end
        else if (accept) begin
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

    reg [1:0] pair_sel;

    always @(count or frame) begin
        pair_sel = 2'b00;

        case (count[2:0])
            3'd0: pair_sel = frame[15:14];
            3'd1: pair_sel = frame[13:12];
            3'd2: pair_sel = frame[11:10];
            3'd3: pair_sel = frame[9:8];
            3'd4: pair_sel = frame[7:6];
            3'd5: pair_sel = frame[5:4];
            3'd6: pair_sel = frame[3:2];
            3'd7: pair_sel = frame[1:0];
        endcase
    end

    assign o_valid = busy && (count < 4'd8);
    assign o_sof = o_valid && (count == 4'd0);
    assign o_pair = o_valid ? pair_sel : 2'b00;

endmodule 