    #include <stdio.h> 
     
    void max_pooling(int input[4][4], int output[2][2], int pool_size) { 
        int output_row = 0, output_col; 
     
        // Iterate over the input matrix with a step equal to the pool size 
        for (int i = 0; i < 4; i += pool_size) { 
            output_col = 0; // Reset output column for each output row 
     
            for (int j = 0; j < 4; j += pool_size) { 
                int max_value = input[i][j]; 
     
                // Find the maximum value in the pooling window 
                for (int m = 0; m < pool_size; m++) { 
                    for (int n = 0; n < pool_size; n++) { 
                        if (i + m < 4 && j + n < 4) { // Ensure we don't go out of bounds 
                            if (input[i + m][j + n] > max_value) { 
                                max_value = input[i + m][j + n]; 
                            } 
                        } 
                    } 
                } 
                output[output_row][output_col] = max_value; 
                output_col++; 
            } 
            output_row++; 
        } 
    } 
     
    int main() { 
        int input[4][4] = { 
            {1, 2, 3, 4}, 
            {5, 6, 7, 8}, 
            {9, 10, 11, 12}, 
            {13, 14, 15, 16} 
        }; 
         
        int output[2][2]; // Output will be 2x2 for a 4x4 input with pool size of 2 
        int pool_size = 2; 
     
        max_pooling(input, output, pool_size); 
     
        // Print the output 
        printf("Output after max pooling:\n"); 
        for (int i = 0; i < 2; i++) { 
            for (int j = 0; j < 2; j++) { 
                printf("%d ", output[i][j]); 
            } 
            printf("\n"); 
        } 
     
        return 0; 
    } 