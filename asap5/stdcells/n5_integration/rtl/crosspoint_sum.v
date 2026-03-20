// ============================================================================
// CROSSPOINT SUM MODULE — Parameterized One-Hot Convolution
// ============================================================================
// Implements the crossbar crosspoint operation:
//   output[k] = OR( v[i] AND h[j] ) for all i+j == k
//
// Physical mapping:
//   Each AND = single via at crosspoint grid intersection (wired-AND)
//   Each OR  = shorted output wire collecting via taps (wired-OR)
//
// In standard-cell flow, AND → NAND2+INV, OR → NOR tree
// (* keep_hierarchy *) prevents Yosys from flattening across modules
// ============================================================================

(* keep_hierarchy *)
module crosspoint_sum #(
    parameter M = 3,    // vertical input width (one-hot)
    parameter N = 3     // horizontal input width (one-hot)
) (
    input  wire [M-1:0]     v,  // vertical one-hot input
    input  wire [N-1:0]     h,  // horizontal one-hot input
    output wire [M+N-2:0]   s   // sum one-hot output (0 to M+N-2)
);

    // Generate the crosspoint grid
    genvar k, i;
    generate
        for (k = 0; k < M + N - 1; k = k + 1) begin : sum_bit
            // Collect all AND results for this output bit
            // output[k] = OR of v[i] & h[k-i] for all valid i
            localparam integer NUM_TERMS = (k < M ? k + 1 : M) - (k >= N ? k - N + 1 : 0);

            // Wired-AND: via at each grid intersection where i + j == k
            wire [M-1:0] grid_and;
            for (i = 0; i < M; i = i + 1) begin : grid
                if (i <= k && (k - i) < N) begin : valid
                    assign grid_and[i] = v[i] & h[k-i];  // Wired-AND via
                end else begin : unused
                    assign grid_and[i] = 1'b0;
                end
            end

            // Wired-OR: shorted output wire collecting all via taps
            assign s[k] = |grid_and;
        end
    endgenerate

endmodule
