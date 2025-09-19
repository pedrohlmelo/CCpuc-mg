import java.util.Scanner;


public class Main{

        public static  void ordena(int[] numeros, int N){
           int contagem = 0;

	   for(int z = (N-1); z > 0; z--){
		   for(int j = 0; j < z; j++){
			   if(numeros[j] > numeros[j+1]){
				   int aux = numeros[j];
				   numeros[j] = numeros[j+1];
				   numeros[j+1] = aux;
				   contagem++;
			   }
			   
		   }
	   }
	   System.out.println(contagem);
	}



	public static void main(String[] args){


		Scanner sc = new Scanner(System.in);

		int T = sc.nextInt();
		int N = sc.nextInt();
                int i = 0;

		while(i < T){

			int[] numeros = new int[N];
			for(int u = 0; u < N; u++){
				numeros[u] = sc.nextInt();
			}

			ordena(numeros,N);
			i++;
			N = sc.nextInt();
		}
		sc.close();

	}
}
