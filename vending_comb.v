`timescale 1ns / 1ps

module vending_comb (
    input [4:0] credit,
    input [1:0] select_item,
    output reg valid_selection,
    output reg enough_money,
    output reg [3:0] change_value
);

    always @(*) begin
        // Default values to prevent latch inference
        valid_selection = 1'b0;
        enough_money = 1'b0;
        change_value = 4'd0;

        case (select_item)
            2'b01,
            2'b10: begin // Share the same logic for items 2'b01 and 2'b10
                valid_selection = 1'b1;
                if (credit >= 5'd10) begin
                    enough_money = 1'b1;
                    change_value = credit - 5'd10;
                end
            end
            default: begin // Default case for invalid selections
                valid_selection = 1'b0;
                enough_money = 1'b0;
                change_value = 4'd0;
            end
        endcase
    end

endmodule
