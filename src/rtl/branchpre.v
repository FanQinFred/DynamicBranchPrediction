// Stage: IF | ID | EX | MEM |WB
//

module branch_predict (
    input wire clk, rst,

    input wire[31:0] instrD,

    input wire flushD,flushE,flushM,
    input wire stallD,

    input wire pred_takeE,      // 预测的是否跳�???
    input wire actual_takeE,    // 实际是否跳转
    input wire actual_takeD,

    input wire branchD,
    input wire [31:0] pcF,

    output wire pred_takeD,    // D阶段使用
    output wire preErrorE      // E阶段判断预测是否正确
);

    wire pred_takeF;    // 预测是否跳转 

    reg pred_takeD_reg;

    //判断译码阶段是否是分支指�???

    
    //EX阶段判断预测是否正确
    assign preErrorE = (actual_takeE != pred_takeE);

    // 译码阶段输出�???终的预测结果
    assign pred_takeD = branchD & pred_takeD_reg;  

    // 定义参数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b10, Strongly_taken = 2'b11;
    parameter PHT_DEPTH = 20;
    parameter GHR_WIDTH = 20;

    reg [GHR_WIDTH-1:0] GHR;  //全局历史
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    assign PHT_index = GHR ^ pcF[30:11];

    // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段�???
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
    
    assign update_PHT_index = GHR;

    always@(posedge clk) begin
        if(rst) begin
            GHR <= 20'b0;
        end
        else if(branchD & actual_takeD) begin
            GHR <= {GHR[GHR_WIDTH-2:0],1};
        end
        else if(branchD & !actual_takeD) begin
            GHR <= {GHR[GHR_WIDTH-2:0],0};
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
            if(branchD) begin
                case(PHT[update_PHT_index])
                    2'b11:
                        case(actual_takeD)
                            1'b1:PHT[update_PHT_index]<=2'b11;
                            1'b0:PHT[update_PHT_index]<=2'b10;
                            default:;
                        endcase
                    2'b10:
                        case(actual_takeD)
                            1'b1:PHT[update_PHT_index]<=2'b11;
                            1'b0:PHT[update_PHT_index]<=2'b01;
                            default:;
                        endcase
                    2'b01:
                        case(actual_takeD)
                            1'b1:PHT[update_PHT_index]<=2'b10;
                            1'b0:PHT[update_PHT_index]<=2'b00;
                            default:;
                        endcase
                    2'b00:
                        case(actual_takeD)
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