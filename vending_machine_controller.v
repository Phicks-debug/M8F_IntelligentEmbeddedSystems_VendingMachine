`timescale 1ns / 1ps

module vending_machine_controller (
    input clk,
    input reset,
    input [3:0] coin_in,
    input [1:0] select_item,
    output reg dispense_itemA,
    output reg dispense_itemB,
    output reg [3:0] change
);

    localparam [1:0] S_IDLE     = 2'b00;
    localparam [1:0] S_WAIT     = 2'b01;
    localparam [1:0] S_DISPENSE = 2'b10;
    localparam [1:0] S_CHANGE   = 2'b11;

    localparam [1:0] ITEM_NONE = 2'b00;
    localparam [1:0] ITEM_A    = 2'b01;
    localparam [1:0] ITEM_B    = 2'b10;

    reg [1:0] current_state;
    reg [1:0] next_state;

    reg [4:0] credit_reg;
    reg [4:0] next_credit_reg;

    reg [1:0] item_reg;
    reg [1:0] next_item_reg;

    reg [3:0] change_reg;
    reg [3:0] next_change_reg;

    wire [4:0] updated_credit;
    wire valid_selection;
    wire enough_money;
    wire [3:0] change_value;

    assign updated_credit = credit_reg + coin_in;

    vending_comb decision_logic (
        .credit(updated_credit),
        .select_item(select_item),
        .valid_selection(valid_selection),
        .enough_money(enough_money),
        .change_value(change_value)
    );

    // Next-state and register update decisions.
    always @(*) begin
        next_state      = current_state;
        next_credit_reg = credit_reg;
        next_item_reg   = item_reg;
        next_change_reg = change_reg;

        case (current_state)
            S_IDLE,
            S_WAIT: begin
                if (valid_selection && enough_money) begin
                    next_state      = S_DISPENSE;
                    next_credit_reg = 5'd0;
                    next_item_reg   = select_item;
                    next_change_reg = change_value;
                end else begin
                    next_credit_reg = updated_credit;

                    if (updated_credit == 5'd0) begin
                        next_state = S_IDLE;
                    end else begin
                        next_state = S_WAIT;
                    end
                end
            end

            S_DISPENSE: begin
                next_state      = S_CHANGE;
                next_credit_reg = 5'd0;
            end

            S_CHANGE: begin
                next_state      = S_IDLE;
                next_credit_reg = 5'd0;
                next_item_reg   = ITEM_NONE;
                next_change_reg = 4'd0;
            end

            default: begin
                next_state      = S_IDLE;
                next_credit_reg = 5'd0;
                next_item_reg   = ITEM_NONE;
                next_change_reg = 4'd0;
            end
        endcase
    end

    // Registered state is decoded into one-cycle output pulses.
    always @(*) begin
        dispense_itemA = 1'b0;
        dispense_itemB = 1'b0;
        change         = 4'd0;

        if (current_state == S_DISPENSE) begin
            if (item_reg == ITEM_A) begin
                dispense_itemA = 1'b1;
            end else if (item_reg == ITEM_B) begin
                dispense_itemB = 1'b1;
            end
        end else if (current_state == S_CHANGE) begin
            change = change_reg;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            current_state <= S_IDLE;
            credit_reg    <= 5'd0;
            item_reg      <= ITEM_NONE;
            change_reg    <= 4'd0;
        end else begin
            current_state <= next_state;
            credit_reg    <= next_credit_reg;
            item_reg      <= next_item_reg;
            change_reg    <= next_change_reg;
        end
    end

endmodule
