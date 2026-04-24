`timescale 1ns / 1ps

module tb_vending_comb;

    reg [4:0] credit;
    reg [1:0] select_item;
    wire valid_selection;
    wire enough_money;
    wire [3:0] change_value;

    integer errors;

    vending_comb dut (
        .credit(credit),
        .select_item(select_item),
        .valid_selection(valid_selection),
        .enough_money(enough_money),
        .change_value(change_value)
    );

    task check_case;
        input [4:0] test_credit;
        input [1:0] test_select_item;
        input expected_valid_selection;
        input expected_enough_money;
        input [3:0] expected_change_value;
        input [8*64:1] test_name;
        begin
            credit = test_credit;
            select_item = test_select_item;
            #1;

            if (valid_selection !== expected_valid_selection) begin
                $display("ERROR: %0s valid_selection expected %0b got %0b",
                         test_name, expected_valid_selection, valid_selection);
                errors = errors + 1;
            end

            if (enough_money !== expected_enough_money) begin
                $display("ERROR: %0s enough_money expected %0b got %0b",
                         test_name, expected_enough_money, enough_money);
                errors = errors + 1;
            end

            if (change_value !== expected_change_value) begin
                $display("ERROR: %0s change_value expected %0d got %0d",
                         test_name, expected_change_value, change_value);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_vending_comb.vcd");
        $dumpvars(0, tb_vending_comb);

        errors = 0;
        credit = 5'd0;
        select_item = 2'b00;

        check_case(5'd9,  2'b01, 1'b1, 1'b0, 4'd0, "item_a_insufficient_credit");
        check_case(5'd10, 2'b01, 1'b1, 1'b1, 4'd0, "item_a_exact_credit");
        check_case(5'd15, 2'b10, 1'b1, 1'b1, 4'd5, "item_b_overpayment");
        check_case(5'd10, 2'b00, 1'b0, 1'b0, 4'd0, "no_selection");
        check_case(5'd15, 2'b11, 1'b0, 1'b0, 4'd0, "invalid_selection");

        if (errors == 0) begin
            $display("PASS: tb_vending_comb completed without errors");
        end else begin
            $display("FAIL: tb_vending_comb detected %0d error(s)", errors);
        end

        $finish;
    end

endmodule
