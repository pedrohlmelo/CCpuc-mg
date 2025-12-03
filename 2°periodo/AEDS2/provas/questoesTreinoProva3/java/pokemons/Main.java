import java.util.*;

public class Main{

    public static void main(String [] args){

        Scanner sc = new Scanner(System.in);

        int N = sc.nextInt();
        sc.nextLine();
        String[] Pokemons = new String[N];
        int[] Rep = new int[N];

        for(int i = 0; i < N; i++){
            Pokemons[i] = sc.nextLine();
        }
        for(int i = 0; i < N; i++){
            Rep[i] = 0;
        }

        for(int i = N-1; i >= 0; i--){
            for(int j = 0; j < i; j++){
                if(Pokemons[i].equals(Pokemons[j])){
                    Rep[j] = 1;
                }
            }
        }
        int soma = 0;
        for(int i = 0; i < N; i++){
            soma += Rep[i];
        }
        int totalP = N - soma;
        int Faltam = 151 - totalP;
        System.out.println("Falta(m) " + Faltam + " " +"pokemon(s).");
        
    }
}
