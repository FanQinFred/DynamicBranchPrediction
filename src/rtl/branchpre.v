// Stage: IF | ID | EX | MEM |WB
//                    preErrorM
//在F指阶段预测是否跳转；
//D在译码阶段执行预测结果；
//E在执行阶段判断是否预测正确；
//M在提交阶段处理错误预测和更新PHT
//pc用于BHT instruction用于判断是否跳转
module branch_predict (
    input wire clk, rst,

    input wire[31:0] instrD,

    input wire flushD,flushE,flushM,
    input wire stallD,

    //E在执行阶段判断是否预测正确；
    input wire pred_takeE,      // 预测的是否跳转
    input wire actual_takeE,    // 实际是否跳转
    input wire actual_takeM,

    input wire branchM,

    input wire [31:0] pcF,
    input wire [31:0] pcM,

    output wire pred_takeD,    // D阶段使用
    output wire preErrorE      // E阶段判断预测是否正确
);

    wire pred_takeF;    // 预测是否跳转 

    reg pred_takeD_reg;

    //判断译码阶段是否是分支指令?
    assign branchD = (instrD[31:26]==6'b000100);
    
    //EX阶段判断预测是否正确
    assign preErrorE = (actual_takeE != pred_takeE);

    // 译码阶段输出终的预测结果
    assign pred_takeD = branchD & pred_takeD_reg;  

    // 定义参数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b10, Strongly_taken = 2'b11;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];  //前六次branch历史记录
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;

    // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段
    assign pred_takeF = PHT[PHT_index][1];

    always @(posedge clk) begin
        if(rst | flushD |flushE |flushM) begin
            pred_takeD_reg <= 0;
        end
        else if(~stallD) begin
            pred_takeD_reg <= pred_takeF;
        end
    end

    wire [(PHT_DEPTH-1):0] update_PHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign update_BHT_index = pcM[11:2];
    assign update_BHR_value = BHT[update_BHT_index];
    assign update_PHT_index = update_BHR_value;

    always@(posedge clk) begin
        if(rst) begin
            for(j = 0; j < (1<<BHT_DEPTH); j=j+1) begin
                BHT[j] <= 0;
            end
        end
        else if(branchM & actual_takeM) begin
            BHT[update_BHT_index]<={update_BHR_value[4:0],1'b1};
        end
        else if(branchM & !actual_takeM) begin
            BHT[update_BHT_index]<={update_BHR_value[4:0],1'b0};
        end else begin
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            if(branchM) begin
                case(PHT[update_PHT_index])
                    2'b11:
                        case(actual_takeM)
                            1'b1:PHT[update_PHT_index]<=2'b11;
                            1'b0:PHT[update_PHT_index]<=2'b10;
                            default:;
                        endcase
                    2'b10:
                        case(actual_takeM)
                            1'b1:PHT[update_PHT_index]<=2'b11;
                            1'b0:PHT[update_PHT_index]<=2'b01;
                            default:;
                        endcase
                    2'b01:
                        case(actual_takeM)
                            1'b1:PHT[update_PHT_index]<=2'b10;
                            1'b0:PHT[update_PHT_index]<=2'b00;
                            default:;
                        endcase
                    2'b00:
                        case(actual_takeM)
                            1'b1:PHT[update_PHT_index]<=2'b01;
                            1'b0:PHT[update_PHT_index]<=2'b00;
                            default:;
                        endcase
                    default:;
                endcase 
            end
        end
    end
endmodule