module survivor_memory_unit (
    input wire clk,
    input wire rstn,

    input wire i_valid,
    input wire i_sof,
    
    input wire i_dec_00,
    input wire i_dec_01,
    input wire i_dec_10,
    input wire i_dec_11,

    output wire o_bck_dec_00,
    output wire o_bck_dec_01,
    output wire o_bck_dec_10,
    output wire o_bck_dec_11,

    output reg o_memory_done
);

    reg [3:0] mem [0:5];
    reg [2:0] k;    // chỉ số bước (pha ghi) (0 -> 7) / chỉ số đọc (pha đọc) (0 -> 5)
    reg read_mode; // WRITE = 0, READ = 1

    wire [3:0] D = {i_dec_00, i_dec_01, i_dec_10, i_dec_11};

    // ctrl_fsm
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            k <= 3'd0;
            read_mode <= 1'b0;
            o_memory_done <= 1'b0;
        end
        else begin
            o_memory_done <= 1'b0;

            if (!read_mode) begin   // pha GHI
                if (i_valid) begin
                    if (i_sof) begin
                        k <= 3'd1;
                    end
                    else if (k == 3'd7) begin
                        k <= 3'd0;
                        read_mode <= 1'b1;
                        o_memory_done <= 1'b1;
                    end
                    else begin
                        k <= k + 3'd1;
                    end
                end
            end
            else begin
                if (k == 3'd5) begin    // pha Đọc
                    k <= 3'd0;
                    read_mode <= 1'b0;
                end
                else begin
                    k <= k + 3'd1;
                end
            end
        end
    end
    
    wire wr_enable = rstn && i_valid && ~read_mode && ~i_sof;

    // write_ctrl: Ghi dữ liệu vào bộ nhớ
    always @(posedge clk) begin
        if (wr_enable) begin
            case (k)
                3'd2: mem[0] <= D;
                3'd3: mem[1] <= D;
                3'd4: mem[2] <= D;
                3'd5: mem[3] <= D;
                3'd6: mem[4] <= D;
                3'd7: mem[5] <= D;
                default: begin
                    // không ghi vào bộ nhớ
                end
            endcase
        end
    end

    // rd_mux: Đọc dữ liệu từ bộ nhớ
    reg [3:0] rd_data;
    wire rd_en = read_mode && (k <= 3'd5);

    always @(*) begin
        rd_data = 4'b0;

        if (rd_en) begin
            rd_data = mem[5-k];
        end
    end

    assign o_bck_dec_00 = read_mode ? rd_data[3] : 1'b0;
    assign o_bck_dec_01 = read_mode ? rd_data[2] : 1'b0;
    assign o_bck_dec_10 = read_mode ? rd_data[1] : 1'b0;
    assign o_bck_dec_11 = read_mode ? rd_data[0] : 1'b0;


endmodule