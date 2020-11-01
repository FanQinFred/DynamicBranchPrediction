// Stage: IF | ID | EX | MEM |WB
//                    preErrorM

module branch_predict_choose (
    input wire clk, rst,
    input wire [31:0]pcF,pcM,
    input wire global_errorM,
    input wire local_errorM,
    output wire pred_chooseD
);

    parameter strongly_global=2'b11,weakly_global=2'b10,weakly_local=2'b01,strongly_local=2'b00;
    parameter CPHT_DEPTH = 20;
    reg [1:0] CPHT [(1<<CPHT_DEPTH)-1:0];
    
    integer i;
    wire [(CPHT_DEPTH-1):0] CPHT_index;
  
    assign CPHT_index = pcF[19:0];


    assign pred_chooseF = CPHT[CPHT_index][1];

    always @(posedge clk) begin
        if(rst | flushD |flushE |flushM) begin
            pred_chooseD <= 0;
        end
        else if(~stallD) begin
            pred_chooseD <= pred_chooseF;
        end
    end

    wire [CPHT_DEPTH-1:0] update_CPHT_index;


    assign update_CPHT_index = pcM[19:0];

    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<CPHT_DEPTH); i=i+1) begin
                CPHT[i] <= weakly_global;
            end
        end
        else begin
            if(branchM) begin
                case(CPHT[update_CPHT_index])
                    2'b11:
                        case({global_errorM,local_error})
                            2'b00:CPHT[update_CPHT_index]<=2'b11;
                            2'b01:CPHT[update_CPHT_index]<=2'b11;
                            2'b10:CPHT[update_CPHT_index]<=2'b10;
                            2'b11:CPHT[update_CPHT_index]<=2'b11;
                            default:;
                        endcase
                    2'b10:
                        case({global_errorM,local_error})
                            2'b00:CPHT[update_CPHT_index]<=2'b10;
                            2'b01:CPHT[update_CPHT_index]<=2'b11;
                            2'b10:CPHT[update_CPHT_index]<=2'b01;
                            2'b11:CPHT[update_CPHT_index]<=2'b10;
                            default:;
                        endcase
                    2'b01:
                        case({global_errorM,local_error})
                            2'b00:CPHT[update_CPHT_index]<=2'b01;
                            2'b01:CPHT[update_CPHT_index]<=2'b10;
                            2'b10:CPHT[update_CPHT_index]<=2'b00;
                            2'b11:CPHT[update_CPHT_index]<=2'b01;
                            default:;
                        endcase
                    2'b00:
                        case({global_errorM,local_error})
                            2'b00:CPHT[update_CPHT_index]<=2'b00;
                            2'b01:CPHT[update_CPHT_index]<=2'b01;
                            2'b10:CPHT[update_CPHT_index]<=2'b00;
                            2'b11:CPHT[update_CPHT_index]<=2'b00;
                            default:;
                        endcase
                    default:;
                endcase 
            end
        end
    end
endmodule