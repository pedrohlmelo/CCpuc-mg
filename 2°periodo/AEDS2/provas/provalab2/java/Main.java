import java.util.*;

public class Main{
    public static void Conferealunos(int[] numeros, int quantidade){
              int[] trocas = new int[quantidade];
              for(int i = 0; i < quantidade; i++){
                trocas[i] = 0;//guarda cada elemento com um total 0 de trocas(max 1 troca)
              }
              int[] alunos = new int[quantidade];
              for(int i = 0; i < quantidade; i++){
                alunos[i] = numeros[i];//guarda cada aluno com sua nota
              }
              for(int i = quantidade -1; i > 0; i--){//ordenacao maior para menor
                for(int j = 0; j < i; j++){
                    if(numeros[j] < numeros[j+1]){
                        int aux = numeros[j];
                        numeros[j] = numeros[j+1];
                        numeros[j+1] = aux;
                    }
                }
              }
              for(int i = 0; i < quantidade; i++){
                if(alunos[i] != numeros[i]){//se as notas dos alunos que foram guardadas antes foram diferentes e porque ouve uma troca
                    trocas[i] = 1;
                }
              }
              int total = quantidade;
              for(int i = 0; i < quantidade; i++){
                total = total-trocas[i];//total de alunos - total de trocas = quantidade dos que nao trocaram
              }
              System.out.println(total);

    }



    public static void main(String[] args){
        Scanner sc = new Scanner(System.in);
        int casos = sc.nextInt();
        int i = 0;
        int quantidade;
        while(i < casos){
           quantidade = sc.nextInt();
           int[] numeros = new int[quantidade];
           for(int j = 0; j < quantidade; j++){
            numeros[j] = sc.nextInt();
           }
           Conferealunos(numeros,quantidade);
           i++; //i vai ate a quantidade de casos
        }
        sc.close();
    }
}
