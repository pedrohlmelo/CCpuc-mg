import java.util.Scanner;



public class Main{

        public static void jogos(String[] jogo){
		int contador = 0;
		for(int i = 0; i < 6; i++){
			if(jogo[i].charAt(0) == 'V'){
				contador++;
			}
		}

		if(5 <= contador && contador  <= 6){
			System.out.println("1");
		}
		else if(3 <= contador && contador  <=4){
			System.out.println("2");
		}
		else if(1 <= contador && contador <= 2){
			System.out.println("3");
		}
		else System.out.println();
	}


	public static void main(String[] args){		


		Scanner sc = new Scanner(System.in);

		String[] jogo = new String[6];

		for(int i = 0; i < 6; i ++){
			jogo[i] = sc.nextLine();
		}

		jogos(jogo);

		sc.close();
	}
}
