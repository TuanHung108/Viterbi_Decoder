module viterbi_top (
    input wire clk,
    input wire rstn,
    
    input wire [15:0] input_data,
    input wire viterbi_enable,

    output wire [7:0] output_data,
    output wire output_done
);

    // EU <-> BMU
    wire [1:0] eu_pair_bmu;

    // EU <-> ACSU
    wire eu_valid_acsu, eu_sof_acsu; 

    // BMU <-> ACSU
    wire [1:0] bmu_bm00_acsu, bmu_bm01_acsu, bmu_bm10_acsu, bmu_bm11_acsu;

    // ACSU <-> SMU
    wire acsu_dec_00_smu, acsu_dec_01_smu, acsu_dec_10_smu, acsu_dec_11_smu; 
    wire acsu_valid_smu, acsu_sof_smu;

    // ACSU <-> TBU
    wire [1:0] acsu_slt_node_tbu;

    // SMU <-> TBU
    wire smu_bck_dec_00_tbu, smu_bck_dec_01_tbu, smu_bck_dec_10_tbu, smu_bck_dec_11_tbu;
    wire smu_memory_done_tbu; 


    extractor_unit eu (
        .clk(clk),
        .rstn(rstn),
        .input_data(input_data),
        .viterbi_enable(viterbi_enable),
        .o_pair(eu_pair_bmu),
        .o_valid(eu_valid_acsu),
        .o_sof(eu_sof_acsu)
    );


    branch_metric_unit bmu (
        .i_pair(eu_pair_bmu),
        .o_bm00(bmu_bm00_acsu),
        .o_bm01(bmu_bm01_acsu),
        .o_bm10(bmu_bm10_acsu),
        .o_bm11(bmu_bm11_acsu)
    );


    add_compare_select_unit acsu (
        .clk(clk),
        .i_valid(eu_valid_acsu),
        .i_sof(eu_sof_acsu),
        .i_bm00(bmu_bm00_acsu),
        .i_bm01(bmu_bm01_acsu),
        .i_bm10(bmu_bm10_acsu),
        .i_bm11(bmu_bm11_acsu),
        .o_dec_00(acsu_dec_00_smu),
        .o_dec_01(acsu_dec_01_smu),
        .o_dec_10(acsu_dec_10_smu),
        .o_dec_11(acsu_dec_11_smu),
        .o_valid(acsu_valid_smu),
        .o_sof(acsu_sof_smu),
        .o_slt_node(acsu_slt_node_tbu)
    );


    survivor_memory_unit smu (
        .clk(clk),
        .rstn(rstn),
        .i_valid(acsu_valid_smu),
        .i_sof(acsu_sof_smu),
        .i_dec_00(acsu_dec_00_smu),
        .i_dec_01(acsu_dec_01_smu),
        .i_dec_10(acsu_dec_10_smu),
        .i_dec_11(acsu_dec_11_smu),
        .o_bck_dec_00(smu_bck_dec_00_tbu),
        .o_bck_dec_01(smu_bck_dec_01_tbu),
        .o_bck_dec_10(smu_bck_dec_10_tbu),
        .o_bck_dec_11(smu_bck_dec_11_tbu),
        .o_memory_done(smu_memory_done_tbu)
    );

    traceback_unit tbu (
        .clk(clk),
        .rstn(rstn),
        .i_memory_done(smu_memory_done_tbu),
        .i_slt_node(acsu_slt_node_tbu),
        .i_bck_dec_00(smu_bck_dec_00_tbu),
        .i_bck_dec_01(smu_bck_dec_01_tbu),
        .i_bck_dec_10(smu_bck_dec_10_tbu),
        .i_bck_dec_11(smu_bck_dec_11_tbu),
        .output_data(output_data),
        .output_done(output_done)
    );


endmodule