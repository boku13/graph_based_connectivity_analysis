// C++ program to implement full adder
#include <bits/stdc++.h>
using namespace std;
// Function to print sum and C-Out
void Full_Adder(int A,int B,int C_In){
    int Sum , C_Out;
    // Calculating value of sum
    Sum = C_In ^ (A ^ B);
   
    //Calculating value of C-Out
    C_Out = (A & B) | (B & C_In) | (A & C_In);
  
   // printing the values
    cout<<"Sum = "<< Sum <<endl;
    cout<<"C-Out = "<< C_Out <<endl;
  }
  