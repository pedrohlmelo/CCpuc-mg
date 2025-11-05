import java.util.*; 
class Cartela{
    int[] elementos;
    public Cartela(int[] elementos){
           this.elementos = elementos;
    }
}
public class Main{

    public static void ConfereVencedor(Cartela[] cartelas, int Ncartelas, int qtd,int[] sequencia){
              int[] contagem = new int[Ncartelas];
              for(int i = 0; i < Ncartelas; i++){
                contagem[i] = 0;
              } 
              for(int i = 0; i < sequencia.length; i++){
                  for(int j = 0; j < Ncartelas; j++){
                    for(int z = 0; z < qtd ; z++){
                        if(sequencia[i] == cartelas[j].elementos[z]){
                            contagem[j] ++;
                            if(contagem[j] == qtd){
                                System.out.println(j+1);
                                return;
                            }
                        }
                    }
                  }
              }
    }
    public static void main(String args[]){
        Scanner sc = new Scanner(System.in);
        int Ncartelas = sc.nextInt();
        int qtd = sc.nextInt();
        int maior = sc.nextInt();

        Cartela[] cartelas = new Cartela[Ncartelas];
       int i = 0;
       while(i < Ncartelas){
            int[] numeros = new int[qtd];
           for(int j = 0; j < qtd; j++){
            numeros[j] = sc.nextInt();
           }
           cartelas[i] = new Cartela(numeros);
           i++;
         }
         int sequencia[] = new int[maior];
         for(int j = 0; j < maior; j++){
            sequencia[j] = sc.nextInt();
         }
         ConfereVencedor(cartelas, Ncartelas, qtd, sequencia);
         sc.close();
    }
}