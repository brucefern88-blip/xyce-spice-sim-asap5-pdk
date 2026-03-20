// 16-bit counter with enable and load
module counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        load,
    input  wire [15:0] data_in,
    output reg  [15:0] count,
    output wire        overflow
);

    assign overflow = (count == 16'hFFFF) & en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 16'h0000;
        else if (load)
            count <= data_in;
        else if (en)
            count <= count + 16'h0001;
    end

endmodule
