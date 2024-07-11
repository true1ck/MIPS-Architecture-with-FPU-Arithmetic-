module sqrt
(
  input [31:0] A,            // Input floating-point number A
  input cpu_clk, sqrt_clk, fp_clk, int_clk,  // Clock inputs
  output [31:0] Out      // Output square root of A
);

reg start;                   // Start signal
reg [31:0] sqa, a_reg;       // Registers for square of A and A
wire [31:0] ratio, sum, shifted; // Wires for ratio, sum, and shifted value
reg [31:0] prev_sqa;         // Previous value of sqa
parameter STAB_THRESHOLD = 32'h00000001; // Stabilizer threshold

fp_divider fdiv(
  .int_clk(int_clk),
  .fp_clk(fp_clk),
  .A(A),
  .B(sqa),
  .Out(ratio)
);

fp_adder fadd (
  .A(ratio),
  .B(sqa),
  .Out(sum)
);

assign shifted = {sum[31], sum[30:23]-8'b1, sum[22:0]}; // Shift the sum by 1 bit to the right
assign Out = sqa;  // Output the square root

initial begin
    sqa = 32'h3f800000; // Initial guess for square root (32'h3f800000 is 1.0 in IEEE 754 single precision)
    prev_sqa = 0;
end

always @(posedge int_clk) begin
    if (start) begin
        sqa <= 32'h3f800000;  // Reset square root guess
        a_reg <= A;           // Save input value A
        start <= 0;           // Reset start signal
    end
end

always @(posedge sqrt_clk) begin
    if (!start) begin
        sqa <= shifted;      // Update square root guess
        prev_sqa <= sqa;     // Save previous value of sqa
    end
end

always @(posedge cpu_clk) begin
    start <= (start || (prev_sqa - sqa > STAB_THRESHOLD));  // Set start signal or stabilizer check
end

endmodule