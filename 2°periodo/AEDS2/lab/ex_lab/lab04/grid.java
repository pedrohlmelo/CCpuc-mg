import java.util.Scanner;


public class grid{

	public static void ultrapassagens(int[] saida, int []chegada, int n){

            int ultrapassagem = 0;
	    int novo[] = new int[n];
	    for(int i = 0; i < n; i++){
		    for(int j = 0; j < n; j++){
                       if(saida[i] == chegada [j]){
			       novo[i] = j+1;
                       }
          	}
	    }

	for(int i = (n-1); i > 0;i--){
            
               for(int j = 0; j < i; j++){
		       if(novo[j] > novo[j+1]){
                          int aux = novo[j];
                          novo[j] = novo[j+1];
			  novo[j+1] = aux;
			  ultrapassagem++;
		   }
         	}
             }
	System.out.println(ultrapassagem);
     }

	public static void main(String args[]){
		Scanner sc = new Scanner(System.in);
                
		while(sc.hasNext()){

		int N =  sc.nextInt();
		int  saida[] = new int[N];
		int  chegada[] = new int[N];

		for(int i = 0; i < N; i++){
			saida[i] = sc.nextInt();
		}
		for(int u = 0; u < N; u++){
			chegada[u] = sc.nextInt();
		}

		ultrapassagens(saida,chegada,N);
	}
    }
}
