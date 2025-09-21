import java.util.Scanner;

public class Main{

	   
	public static void intensidade(int[] numeros){

		for(int z = 2; z > 0; z--){
			for(int j = 0; j < z; j++){
				if(numeros[j] > numeros[j+1]){
					int aux = numeros[j];
					numeros[j] = numeros[j+1];
					numeros[j+1] = aux;
				}
			}
		}

		int distancia = numeros[2] - numeros[0];

		if(distancia  <= 20){
			System.out.println("A");
		}
		else if(distancia > 20  && distancia  <= 50){
		       System.out.println("M");
		}
                else System.out.println("B");

	}		


	public static void main(String[] args){

		Scanner sc = new Scanner(System.in);

		int N = sc.nextInt();

		int i  =  0;

		while(i < N){
			int[] numeros = new int[3];

			for(int u = 0; u < 3; u++){
				numeros[u] = sc.nextInt();
			}
			intensidade(numeros);
			i++;
		}
		sc.close();
	}
}
