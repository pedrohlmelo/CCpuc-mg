import java.util.Scanner;


public class Main{

	public static void ordena(String[] nome, String[] comportamento,int N){
		int comportaram = 0;
		int ncomportaram = 0;
		for(int i = 0; i < N; i++){
			if(comportamento[i].equals("+")){
				comportaram++;
			}
			else ncomportaram++;
		}

		for(int i = N-1; i > 0; i--){
			for(int j = 0; j < i; j++){
				if(nome[j].charAt(0) > nome[j+1].charAt(0)){
					String aux = nome[j];
					nome[j] = nome[j+1];
					nome[j+1] = aux;
				}
				else if(nome[j].charAt(0) == nome[j+1].charAt(0)){
					int contagem = 0;
					while(nome[j].charAt(contagem) == nome[j+1].charAt(contagem)){
						contagem ++;
					}
					if(nome[j].charAt(contagem) > nome[j+1].charAt(contagem)){
						String auxiliar = nome[j];
						nome[j] = nome[j+1];
						nome[j+1] = auxiliar;
					}
				}
			}
		}
		for(int i = 0; i < N; i++){
			System.out.println(nome[i]);
		}
		System.out.println("Se comportaram : " + comportaram + " " +  "|" + " " +  "Nao se comportaram: " + ncomportaram);
	}


	public static void main(String[] args){
             
		Scanner sc = new Scanner(System.in);

		while(sc.hasNext()){
			int N = sc.nextInt();
			String[] comportamentos = new String[N];
			String[] nomes = new String[N];

			for(int i = 0; i < N; i++){
				comportamentos[i] = sc.next();
				nomes[i] = sc.nextLine();
			}

			ordena(nomes,comportamentos,N);
		}
		sc.close();
	}
}
