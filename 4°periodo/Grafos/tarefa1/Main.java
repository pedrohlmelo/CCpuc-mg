import java.util.*;

public class Main {

    public static void main(String[] args){
    Scanner sc = new Scanner(System.in);
    System.out.println("digite o nome do arquivo");
    
    String arquivo = sc.Next();

    System.out.println("Digite o numero do vertice");
    int vertice = sc.NextInt();

    File arq = new File(arquivo);

    Scanner scf = new Scanner(arq);

    int n = scfile.nextInt();
        int m = scfile.nextInt();
 
        List<Integer>[] sucessores = new ArrayList[n + 1];
        List<Integer>[] predecessores = new ArrayList[n + 1];
        for (int i = 0; i <= n; i++) {
            sucessores[i] = new ArrayList<>();
            predecessores[i] = new ArrayList<>();
        }
 

        while (scfile.hasNextInt()) {
            int origem = scfile.nextInt();
            if (!scfile.hasNextInt()) break;
            int destino = scfile.nextInt();
            sucessores[origem].add(destino);
            predecessores[destino].add(origem);
        }
        scfile.close();
 
        if (vertice < 0 || vertice > n) {
            System.out.println("Vertice " + vertice + " nao existe no grafo (faixa valida: 0 a " + n + ").");
            sc.close();
            return;
        }
 
        System.out.println();
        System.out.println("Vertice consultado: " + vertice);
        System.out.println("Grau de saida: " + sucessores[vertice].size());
        System.out.println("Grau de entrada: " + predecessores[vertice].size());
        System.out.println("Sucessores: " + sucessores[vertice]);
        System.out.println("Predecessores: " + predecessores[vertice]);
 
        sc.close();
    
    }
    
}
