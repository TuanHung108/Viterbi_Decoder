module traceback (
    input wire clk,
    input wire rst_n,

    input wire i_memory_done,
    input wire [1:0] i_slt_node,

    input wire i_bck_dec_00,
    input wire i_bck_dec_01,
    input wire i_bck_dec_10,
    input wire i_bck_dec_11,

    output wire [7:0] output_data,
    output reg output_done
);

    reg [8:0] sh;
    reg [1:0] cur;
    reg run;

    // Chọn trạng thái hiện tại để truy vết
    wire [1:0] target = i_memory_done ? i_slt_node : cur;


    // Chọn bit quyết định sống sot của trạng thái hiện tại target
    reg d;
    always @(*) begin
        case (target)
            2'b00: d = i_bck_dec_00;
            2'b01: d = i_bck_dec_01;
            2'b10: d = i_bck_dec_10;
            2'b11: d = i_bck_dec_11;
        endcase
    end


    wire bit_in = target[1]; // bit thông tin khôi phục
    wire [1:0] next_node = {target[0], d}; // trạng thái liền trước

    always @(posedge clk) begin
        if (i_memory_done | run) begin
            cur <= next_node;
        end
    end

    // Control logic 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sh <= 9'b0;
            run <= 1'b0;
            output_done <= 1'b0;
        end
        else begin
            output_done <= 1'b0;

            if (i_memory_done) begin
                sh <= {bit_in, 1'b1, 7'b0};
                run <= 1'b1;
                output_done <= 1'b0;
            end
            else if (run) begin
                sh <= {bit_in, sh[8:1]};

                if (sh[1] == 1'b1) begin
                    run <= 1'b0;
                    output_done <= 1'b1;
                end
                else begin
                    run <= 1'b1;
                end
            end
        end
    end

    assign output_data = sh[8:1];

endmodule