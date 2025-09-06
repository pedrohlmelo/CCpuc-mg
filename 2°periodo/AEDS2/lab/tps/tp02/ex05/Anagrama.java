import java.util.Scanner;

public class Anagrama{

    public static void verificaAnagrama(String texto){
        String texto2 = "";
        String texto1 = "";
        int i = 0;
        char c;

     while (i < texto.length() && texto.charAt(i) != '-') {
        texto1 += texto.charAt(i);
        i++;
     }

    i++;

     while (i < texto.length()) {
        texto2 += texto.charAt(i);
        i++;
     }
     texto1 = texto1.toLowerCase();
     texto2 = texto2.toLowerCase();
    
     if(texto1.length() != texto2.length()){
        System.out.println("N\u00C3O");
     }
     else{
        for(int u=0;u<texto1.length();u++){
            c = texto1.charAt(u);
            int s1 = 0;
            int s2 = 0;
            for(int j=0;j<texto1.length();j++){
                if(c == texto1.charAt(j)){
                    s1++;
                }
            }
            for(int j=0;j<texto2.length();j++){
                if(c == texto2.charAt(j)){
                    s2++;
                }
            }

            if(s1 != s2){
                System.out.println("N\u00C3O");
                return;
            }
            
            
        }
        System.out.println("SIM");
     }

    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        String t1 = sc.nextLine();
        

        while(!t1.equals("FIM")){
             verificaAnagrama(t1);
             t1 = sc.nextLine();

        }
        sc.close();
    }
}