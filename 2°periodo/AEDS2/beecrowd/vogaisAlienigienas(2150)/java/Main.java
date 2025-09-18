import java.util.Scanner;



public class Main{




      public static void main(String[] args){

	      Scanner sc = new Scanner(System.in);
              
	      
	      while(sc.hasNext()){
		      int contador = 0;
		     String vogais = sc.nextLine();
		     String frase = sc.nextLine();
                  for(int i = 0; i < vogais.length(); i++){
			  for(int j = 0; j < frase.length(); j++){
				  if(vogais.charAt(i) == frase.charAt(j)){
					  contador++;
				  }
			  }
		  }
                   
                    System.out.println(contador);

      }
}
}
