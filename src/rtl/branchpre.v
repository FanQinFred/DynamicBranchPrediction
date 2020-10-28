// Stage: IF | ID | EX | MEM |WB
//

module branch_predict (
    input wire clk, rst,
    input wire[31:0] InstrD,
    input wire flushD,
    input wire stallD,
    input wire pred_takeE,
    input wire [31:0] pcF,
    input wire [31:0] pcM,
    input wire branchM,         // M阶段是否是分支指令
    input wire actual_takeM,    // 实际是否跳转

    output wire branchD,        // 译码阶段是否是跳转指令   
    output wire pred_takeD,      // 预测是否跳转  //assign pred_takeD = branchD & pred_takeF_r;  
    output wire preErrorE
);
    wire pred_takeF;
    reg pred_takeF_r;
    assign branchD = InstrD[31:27]==5'b000100;//判断译码阶段是否是分支指令

    assign preErrorE = (branchE == pred_takeE);

    // 译码阶段输出最终的预测结果
    assign pred_takeD = branchD & pred_takeF_r;  

// 定义参数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];  //前六次branch历史记录
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];    //
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------预测逻辑---------------------------------------

    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;

    assign pred_takeF = PHT[PHT_index][1];      // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段。

        // --------------------------pipeline------------------------------
            always @(posedge clk) begin
                if(rst | flushD |flushE |flushM) begin
                    pred_takeF_r <= 0;
                end
                else if(~stallD) begin
                    pred_takeF_r <= pred_takeF;
                end
            end
        // --------------------------pipeline------------------------------

// ---------------------------------------预测逻辑---------------------------------------


// ---------------------------------------BHT初始化以及更新---------------------------------------
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
        else if(branchM) begin
            BHT[update_BHT_index]<={update_BHR_value[4:0],1'b1};  //qf
            // 此处应该添加你的更新逻辑的代码
        end
        else begin
            BHT[update_BHT_index]<={update_BHR_value[4:0],1'b0};  //qf
        end
    end
// ---------------------------------------BHT初始化以及更新---------------------------------------


// ---------------------------------------PHT初始化以及更新---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(PHT[update_PHT_index])
                2'b11:
                    case(branchM)
                        1'b1:PHT[update_PHT_index]<=2'b11;
                        0'b0:PHT[update_PHT_index]<=2'b10;
                        default:
                    endcase
                2'b10:
                    case(branchM)
                        1'b1:PHT[update_PHT_index]<=2'b11;
                        0'b0:PHT[update_PHT_index]<=2'b01;
                        default:
                    endcase
                2'b01:
                    case(branchM)
                        1'b1:PHT[update_PHT_index]<=2'b10;
                        0'b0:PHT[update_PHT_index]<=2'b00;
                        default:
                    endcase
                2'b00:
                    case(branchM)
                        1'b1:PHT[update_PHT_index]<=2'b10;
                        0'b0:PHT[update_PHT_index]<=2'b00;
                        default:
                    endcase
                default:
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------
endmodule