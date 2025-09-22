import java.util.Scanner;

public class Main{



	public static void main(String[] args){
		 
		
		Scanner sc = new Scanner(System.in);
		int N = sc.nextInt();
		int K = sc.nextInt();
		

		 if ( 1 <= N && N <= 100 && 1 <= K && K <= 1000 && K >= N){//condicao do K e N
                       if(N ==1){// se o n = 1 ele tara K tempo de fala
			       System.out.println(K);
		       }
		      else if((K-N)/N >= 1){ // se o tempo de cada for >= 1

		     System.out.println((K-N)/N);
		   }

		 }
		     else { //se a formula der - de 1 saida = 1 de qualquer jeito
			   System.out.println("1");
		   }

	        

		
		
		
		sc.close();
	}
}
