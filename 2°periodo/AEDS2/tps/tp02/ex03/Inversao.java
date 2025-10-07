import java.util.Scanner;

public class Inversao{
  

  public static void inverte(String texto){  //Método que inverte a string
      String npalavra = "";
      int u = (texto.length()-1); //Variavel para ir de length para 0
      for(int i=0;i<texto.length();i++){
        char c = texto.charAt(u);
        npalavra += c;
        u--;
        }
        System.out.println(npalavra);

  }
          public static void main(String args[]){
              
              Scanner sc = new Scanner(System.in);

              String palavra = sc.nextLine();

              while(!palavra.equals("FIM")){

                inverte(palavra);
                palavra = sc.nextLine();
              }
              sc.close();
          }





}