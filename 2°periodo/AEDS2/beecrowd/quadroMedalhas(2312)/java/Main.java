import java.util.Scanner;



public class Main{


	public static void ordena(String[] pais,int[] ouro, int[] prata, int[] bronze, int N){

		for(int i = (N-1); i > 0; i--){
			for(int j = 0; j < i; j++){
				if(ouro[j] > ouro[j+1]){
					String aux = pais[j];
					pais[j] = pais[j+1];
					pais[j+1] = aux;
					
					int aux1 = ouro[j];
					ouro[j] = ouro[j+1];
					ouro[j+1] = aux1;

					int aux2 = prata[j];
					prata[j] = prata[j+1];
					prata[j+1] = aux2;

					int aux3 = bronze[j];
					bronze[j] = bronze[j+1];
					bronze[j+1] = aux3;
				}
				else if(ouro[j] == ouro[j+1] && prata[j] > prata[j+1]){
					String aux = pais[j];
					pais[j] = pais[j+1];
					pais[j+1] = aux;

					int aux1 = prata[j];
					prata[j] = prata[j+1];
					prata[j+1] = aux1;

					int aux2 = bronze[j];
					bronze[j] = bronze[j+1];
					bronze[j+1] = aux2;
				}
				else if(ouro[j] == ouro[j+1] && prata[j] == prata[j+1] && bronze[j] > bronze[j+1]){
					String aux = pais[j];
					pais[j] = pais[j+1];
					pais[j+1] = aux;

					int aux1 = bronze[j];
					bronze[j] = bronze[j+1];
					bronze[j+1] = aux1;
				}
				else if(ouro[j] == ouro[j+1] && prata[j] == prata[j+1] && bronze[j] == bronze[j+1]){
					int contagem = 0;
					while(pais[j].charAt(contagem) == pais[j+1].charAt(contagem)){
						contagem++;
					}
					if(pais[j].charAt(contagem) < pais[j+1].charAt(contagem)){
						String aux = pais[j];
						pais[j] = pais[j+1];
						pais[j+1] = aux;
					}
				}
			}
		}

				for(int i = (N-1); i >=0; i--){
					System.out.println(pais[i] + " " + ouro[i] + " " + prata[i] + " " + bronze[i]);
				}
	}

	public static void main(String[] args){
		Scanner sc = new Scanner(System.in);


		int N = sc.nextInt();
		int[] ouro = new int[N];
		int[] prata = new int[N];
		int[] bronze = new int[N];

		String[] pais = new String[N];

		for(int i = 0; i < N; i++){
			pais[i] = sc.next();
			ouro[i] = sc.nextInt();
			prata[i] = sc.nextInt();
			bronze[i] = sc.nextInt();
		}
		ordena(pais, ouro, prata, bronze, N);

		sc.close();
	}
}
		
	
