`timescale 1ns / 1ps

module basic_module (
    input [4:0] credit,
    input [1:0] selected_items,
    output valid_selection
    output enough_money,
    output [3:0] change_value
);

    // Internal signals
    reg [7:0] internal_reg;

    // Main logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            internal_reg <= 8'b0;
            data_out <= 8'b0;
        end else begin
            internal_reg <= data_in;
            data_out <= internal_reg;
        end
    end

endmodule