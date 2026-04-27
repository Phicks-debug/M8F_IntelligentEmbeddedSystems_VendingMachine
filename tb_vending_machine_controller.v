`timescale 1ns / 1ps

module tb_vending_machine_controller;

    localparam [1:0] S_IDLE     = 2'b00;
    localparam [1:0] S_WAIT     = 2'b01;
    localparam [1:0] S_DISPENSE = 2'b10;
    localparam [1:0] S_CHANGE   = 2'b11;

    reg clk;
    reg reset;
    reg [3:0] coin_in;
    reg [1:0] select_item;

    wire dispense_itemA;
    wire dispense_itemB;
    wire [3:0] change;

    integer errors;

    vending_machine_controller dut (
        .clk(clk),
        .reset(reset),
        .coin_in(coin_in),
        .select_item(select_item),
        .dispense_itemA(dispense_itemA),
        .dispense_itemB(dispense_itemB),
        .change(change)
    );

    always #5 clk = ~clk;

    task check;
        input          condition;
        input [8*80:1] message;

        begin
            if (!condition) begin
                $display("ERROR: %0s", message);
                errors = errors + 1;
            end
        end
    endtask

    task step_cycle;
        input [3:0] test_coin_in;
        input [1:0] test_select_item;

        begin
            coin_in     = test_coin_in;
            select_item = test_select_item;

            @(posedge clk);
            #1;

            if (dispense_itemA && dispense_itemB) begin
                $display("ERROR: both dispense outputs are high");
                errors = errors + 1;
            end
        end
    endtask

    task apply_reset;
        begin
            reset       = 1'b1;
            coin_in     = 4'd0;
            select_item = 2'b00;

            @(posedge clk);
            #1;

            check(dut.current_state == S_IDLE, "reset did not return state to S_IDLE");
            check(dut.credit_reg == 5'd0, "reset did not clear credit_reg");
            check(dispense_itemA == 1'b0, "reset left dispense_itemA active");
            check(dispense_itemB == 1'b0, "reset left dispense_itemB active");
            check(change == 4'd0, "reset left change output active");

            reset = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("tb_vending_machine_controller.vcd");
        $dumpvars(0, tb_vending_machine_controller);

        clk         = 1'b0;
        reset       = 1'b0;
        coin_in     = 4'd0;
        select_item = 2'b00;
        errors      = 0;

        apply_reset;

        // Exact payment for Item A.
        step_cycle(4'd10, 2'b01);
        check(dut.current_state == S_DISPENSE, "exact Item A payment did not enter S_DISPENSE");
        check(dispense_itemA == 1'b1, "Item A was not dispensed on exact payment");
        check(dispense_itemB == 1'b0, "Item B dispensed during Item A purchase");
        check(change == 4'd0, "change should be zero for exact Item A payment");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_CHANGE, "controller did not enter S_CHANGE after dispensing Item A");
        check(change == 4'd0, "change should remain zero in Item A exact-payment transaction");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_IDLE, "controller did not return to S_IDLE after Item A transaction");
        check(dut.credit_reg == 5'd0, "credit_reg should be zero after Item A transaction");

        apply_reset;

        // Exact payment for Item B.
        step_cycle(4'd10, 2'b10);
        check(dut.current_state == S_DISPENSE, "exact Item B payment did not enter S_DISPENSE");
        check(dispense_itemA == 1'b0, "Item A dispensed during Item B purchase");
        check(dispense_itemB == 1'b1, "Item B was not dispensed on exact payment");
        check(change == 4'd0, "change should be zero for exact Item B payment");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_CHANGE, "controller did not enter S_CHANGE after dispensing Item B");
        check(change == 4'd0, "change should remain zero in Item B exact-payment transaction");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_IDLE, "controller did not return to S_IDLE after Item B transaction");
        check(dut.credit_reg == 5'd0, "credit_reg should be zero after Item B transaction");

        apply_reset;

        // Overpayment returns change after dispensing.
        step_cycle(4'd13, 2'b10);
        check(dut.current_state == S_DISPENSE, "overpayment did not enter S_DISPENSE");
        check(dispense_itemB == 1'b1, "Item B was not dispensed on overpayment");
        check(change == 4'd0, "change should not be returned until S_CHANGE");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_CHANGE, "overpayment did not enter S_CHANGE");
        check(change == 4'd3, "incorrect change returned for overpayment");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_IDLE, "controller did not return to S_IDLE after overpayment transaction");
        check(dut.credit_reg == 5'd0, "credit_reg should be zero after overpayment transaction");

        apply_reset;

        // Insufficient credit followed by more coins.
        step_cycle(4'd6, 2'b01);
        check(dut.current_state == S_WAIT, "insufficient credit should place controller in S_WAIT");
        check(dut.credit_reg == 5'd6, "credit_reg did not store the first partial payment");
        check(dispense_itemA == 1'b0, "Item A dispensed too early");
        check(dispense_itemB == 1'b0, "Item B dispensed during insufficient-credit test");

        step_cycle(4'd0, 2'b01);
        check(dut.current_state == S_WAIT, "controller should keep waiting without additional coins");
        check(dut.credit_reg == 5'd6, "credit_reg changed unexpectedly while waiting");
        check(dispense_itemA == 1'b0, "Item A dispensed without enough credit");

        step_cycle(4'd4, 2'b01);
        check(dut.current_state == S_DISPENSE, "controller did not dispense after enough total credit was inserted");
        check(dispense_itemA == 1'b1, "Item A was not dispensed after enough credit accumulated");
        check(change == 4'd0, "change should be zero for accumulated exact payment");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_CHANGE, "controller did not enter S_CHANGE after accumulated purchase");
        check(change == 4'd0, "change should remain zero after accumulated exact payment");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_IDLE, "controller did not return to S_IDLE after accumulated purchase");
        check(dut.credit_reg == 5'd0, "credit_reg should be zero after accumulated purchase");

        apply_reset;

        // No selection and invalid selection keep stored credit.
        step_cycle(4'd10, 2'b00);
        check(dut.current_state == S_WAIT, "no selection with credit should keep controller waiting");
        check(dut.credit_reg == 5'd10, "credit_reg should store credit when no selection is made");
        check(dispense_itemA == 1'b0, "Item A dispensed with no selection");
        check(dispense_itemB == 1'b0, "Item B dispensed with no selection");

        step_cycle(4'd0, 2'b11);
        check(dut.current_state == S_WAIT, "invalid selection should keep controller waiting");
        check(dut.credit_reg == 5'd10, "credit_reg should be preserved on invalid selection");
        check(dispense_itemA == 1'b0, "Item A dispensed on invalid selection");
        check(dispense_itemB == 1'b0, "Item B dispensed on invalid selection");

        step_cycle(4'd0, 2'b01);
        check(dut.current_state == S_DISPENSE, "valid selection after waiting did not dispense Item A");
        check(dispense_itemA == 1'b1, "Item A was not dispensed after delayed valid selection");
        check(change == 4'd0, "change should be zero after delayed valid selection");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_CHANGE, "controller did not enter S_CHANGE after delayed valid selection");

        step_cycle(4'd0, 2'b00);
        check(dut.current_state == S_IDLE, "controller did not return to S_IDLE after delayed valid selection");
        check(dut.credit_reg == 5'd0, "credit_reg should be zero after delayed valid selection");

        if (errors == 0) begin
            $display("PASS: tb_vending_machine_controller completed without errors");
        end else begin
            $display("FAIL: tb_vending_machine_controller detected %0d error(s)", errors);
        end

        $finish;
    end

endmodule
