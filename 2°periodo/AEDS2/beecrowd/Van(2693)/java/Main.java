import java.util.Scanner;


public class Main{
	 
	public static void ordena(String[] nome, String[] regiao, int[] distancia, int N){

		for(int i = (N-1); i > 0; i--){
			for(int j = 0; j < i; j++){
				if(distancia[j] > distancia[j+1]){
					String aux = nome[j];
				       nome[j] = nome[j+1];
			               nome[j+1] = aux;
			          }
		                 else if(distancia[j] == distancia[j+1] && regiao[j].charAt(0) > regiao[j+1].charAt(0)){
			                String aux = nome[j];
		                        nome[j] = nome[j+1];
		                        nome[j+1] = aux;
		                  }
	                          else if(distancia[j] == distancia[j+1] && regiao[j] == regiao[j+1]){
		                            int contador = 0;
		                        while(nome[j].charAt(contador) == nome[j+1].charAt(contador)){
		                                contador++;
		                          }
	                                  if(nome[j].charAt(contador) > nome[j+1].charAt(contador)){
		                                   String aux = nome[j];
		                                   nome[j] = nome[j+1];
		                                   nome[j+1] = aux;
		                          }
                                  }
                       }
                    }
		       for(int i = 0; i < N; i++){
			       System.out.println(nome[i]);
		       }
               }		

   
	public static void main(String[] args){

		Scanner sc = new Scanner(System.in);

		while(sc.hasNext()){
			int N = sc.nextInt();
			String[] nome = new String[N];
			String[] regiao = new String[N];
			int[] distancia = new int[N];

			for(int i = 0; i < N; i++){
				nome[i] = sc.next();
				regiao[i] = sc.next();
				distancia[i] = sc.nextInt();
			}

			ordena(nome,regiao,distancia,N);
		}
		sc.close();
	}
}
