module add_compare_select_unit (
    input wire clk,

    input wire i_valid,
    input wire i_sof,

    input wire [1:0] i_bm00,
    input wire [1:0] i_bm01,
    input wire [1:0] i_bm10,
    input wire [1:0] i_bm11,

    output wire o_dec_00,
    output wire o_dec_01,
    output wire o_dec_10,
    output wire o_dec_11,

    output wire o_valid,
    output wire o_sof,
    output wire [1:0] o_slt_node
);
    localparam PM_W = 5;

    reg [PM_W-1:0] pm00, pm01, pm10, pm11; // thanh ghi cập nhật Path Metric

    // Init_ctrl: điều khiển khởi tạo khung
    reg i_sof_d;

    wire force_zero = i_sof | i_sof_d;
    wire [PM_W-1:0] a_eff = i_sof ? {PM_W{1'b0}} : pm00; // khởi tạo ở bước 1 (trạng thái xuất phát là 00)


    // Thực hiện các bước trong CSA_a (state 00 và 10) và CSA_b (state 01 và 11)
    // Tính hiệu Path Metric
    wire signed [PM_W:0] delta1 = $signed({1'b0, a_eff}) - $signed({1'b0, pm01});
    wire signed [PM_W:0] delta2 = $signed({1'b0, pm10}) - $signed({1'b0, pm11});

    // Tính hiệu Branch Metric
    wire signed [2:0] t1 = $signed({1'b0, i_bm11}) - $signed({1'b0, i_bm00});
    wire signed [2:0] t2 = $signed({1'b0, i_bm01}) - $signed({1'b0, i_bm10});

    // Mở rộng hiệu Branch Metric để so sánh với hiệu Path Metric
    wire signed [PM_W:0] t1_extend = t1;
    wire signed [PM_W:0] t2_extend = t2;
    
    wire cmp_00 = delta1 > t1_extend;
    wire cmp_10 = delta1 > -t1_extend;
    wire cmp_01 = delta2 > t2_extend;
    wire cmp_11 = delta2 > -t2_extend;

    // Các quyết định nhánh sống sót
    assign o_dec_00 = force_zero ? 1'b0 : cmp_00;
    assign o_dec_10 = force_zero ? 1'b0 : cmp_10;
    assign o_dec_01 = force_zero ? 1'b0 : cmp_01;
    assign o_dec_11 = force_zero ? 1'b0 : cmp_11;

    wire [PM_W-1:0] pm00_next = o_dec_00 ? (pm01 + i_bm11) : (a_eff + i_bm00);
    wire [PM_W-1:0] pm10_next = o_dec_10 ? (pm01 + i_bm00) : (a_eff + i_bm11);
    wire [PM_W-1:0] pm01_next = o_dec_01 ? (pm11 + i_bm01) : (pm10 + i_bm10);
    wire [PM_W-1:0] pm11_next = o_dec_11 ? (pm11 + i_bm10) : (pm10 + i_bm01);

    // Cập nhật Path Metric mỗi chu kỳ clock khi i_valid = 1
    always @(posedge clk) begin
        if (i_valid) begin
            pm00 <= pm00_next;
            pm01 <= pm01_next;
            pm10 <= pm10_next;
            pm11 <= pm11_next;

            i_sof_d <= i_sof;
        end
    end


    // Min Finder: tìm trạng thái có Path Metric nhỏ nhất
    // Tầng so sánh 1
    wire [1:0] winner_00_10 = (pm00 <= pm10) ? 2'b00 : 2'b10;
    wire [1:0] winner_01_11 = (pm01 <= pm11) ? 2'b01 : 2'b11;
    
    // Tầng so sánh 2
    wire [PM_W-1:0] min_pm_00_10 = (pm00 <= pm10) ? pm00 : pm10;
    wire [PM_W-1:0] min_pm_01_11 = (pm01 <= pm11) ? pm01 : pm11;
    assign o_slt_node = (min_pm_00_10 <= min_pm_01_11) ? winner_00_10 : winner_01_11;

    assign o_valid = i_valid;
    assign o_sof = i_sof;

endmodule