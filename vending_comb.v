`timescale 1ns / 1ps

module vending_comb (
    input      [4:0] credit,
    input      [1:0] select_item,
    output reg       valid_selection,
    output reg       enough_money,
    output reg [3:0] change_value
);

    localparam [1:0] ITEM_A = 2'b01;
    localparam [1:0] ITEM_B = 2'b10;
    localparam [4:0] ITEM_PRICE = 5'd10;

    always @(*) begin
        valid_selection = 1'b0;
        enough_money    = 1'b0;
        change_value    = 4'd0;

        if ((select_item == ITEM_A) || (select_item == ITEM_B)) begin
            valid_selection = 1'b1;

            if (credit >= ITEM_PRICE) begin
                enough_money = 1'b1;
                change_value = credit - ITEM_PRICE;
            end
        end
    end

endmodule
