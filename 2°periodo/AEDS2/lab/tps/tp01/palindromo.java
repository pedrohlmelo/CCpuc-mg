import java.util.Scanner;
public class palindromo{


  public static boolean verificaPalindromo(String letras){

            String a = new StringBuilder(letras).reverse().toString();
	   if(a.equals(letras)) return true;
	   else return false;




	 }
 public static void main(String args[]){
 
    Scanner sc = new Scanner(System.in);
    String texto = sc.nextLine();
    

    while(!texto.equalsIgnoreCase("FIM"))
   {

    if(verificaPalindromo(texto))
    {
	    System.out.println("SIM");
    }
    else{
	    System.out.println("NAO");
    
    }
    texto = sc.nextLine();
   }







 }








}
