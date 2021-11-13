// Stage: IF | ID | EX | MEM |WB
//

module branch_predict_global (
    input wire clk, rst,

    input wire[31:0] instrD,

    input wire flushD,flushE,flushM,
    input wire stallD,

    input wire pred_takeE,      // 妫板嫭绁撮惃鍕Ц閸氾箒鐑﹂敓锟�???
    input wire actual_takeE,    // 鐎圭偤妾弰顖氭儊鐠哄疇娴�
    input wire actual_takeD,

    input wire branchD,
    input wire [31:0] pcF,

    output wire pred_takeD,    // D闂冭埖顔屾担璺ㄦ暏
    output wire preErrorE      // E闂冭埖顔岄崚銈嗘焽妫板嫭绁撮弰顖氭儊濮濓絿鈥�
);

    wire pred_takeF;    // 妫板嫭绁撮弰顖氭儊鐠哄疇娴� 

    reg pred_takeD_reg;

    //閸掋倖鏌囩拠鎴犵垳闂冭埖顔岄弰顖氭儊閺勵垰鍨庨弨顖涘瘹閿燂拷???

    
    //EX闂冭埖顔岄崚銈嗘焽妫板嫭绁撮弰顖氭儊濮濓絿鈥�
    assign preErrorE = (actual_takeE != pred_takeE);

    // 鐠囨垹鐖滈梼鑸殿唽鏉堟挸鍤敓锟�???缂佸牏娈戞０鍕ゴ缂佹挻鐏�
    assign pred_takeD = branchD & pred_takeD_reg;  

    // 鐎规矮绠熼崣鍌涙殶
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b10, Strongly_taken = 2'b11;
    parameter PHT_DEPTH = 20;
    parameter GHR_WIDTH = 20;

    reg [GHR_WIDTH-1:0] GHR;  //閸忋劌鐪崢鍡楀蕉
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    assign PHT_index = GHR ^ pcF[30:11];

    // 閸︺劌褰囬幐鍥▉濞堢敻顣╁ù瀣Ц閸氾缚绱扮捄瀹犳祮閿涘苯鑻熺紒蹇氱箖濞翠焦鎸夌痪澶哥炊闁帞绮扮拠鎴犵垳闂冭埖顔岄敓锟�???
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