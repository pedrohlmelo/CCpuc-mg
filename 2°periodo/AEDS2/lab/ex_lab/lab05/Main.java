import java.util.Random;

public class Main {

    
    public static void QuickSortFirstPivot(int[] array, int left, int right) {
        int i = left, j = right;
        int pivot = array[left];

        while (i <= j) {
            while (array[i] < pivot) i++;
            while (array[j] > pivot) j--;
            if (i <= j) {
                int temp = array[i];
                array[i] = array[j];
                array[j] = temp;
                i++;
                j--;
            }
        }
        if (left < j) QuickSortFirstPivot(array, left, j);
        if (i < right) QuickSortFirstPivot(array, i, right);
    }

 
    public static void QuickSortLastPivot(int[] array, int left, int right) {
        int i = left, j = right;
        int pivot = array[right];

        while (i <= j) {
            while (array[i] < pivot) i++;
            while (array[j] > pivot) j--;
            if (i <= j) {
                int temp = array[i];
                array[i] = array[j];
                array[j] = temp;
                i++;
                j--;
            }
        }
        if (left < j) QuickSortLastPivot(array, left, j);
        if (i < right) QuickSortLastPivot(array, i, right);
    }

   
    public static void QuickSortRandomPivot(int[] array, int left, int right) {
        if (left >= right) return;
        int i = left, j = right;
        Random rand = new Random();
        int pivot = array[left + rand.nextInt(right - left + 1)];

        while (i <= j) {
            while (array[i] < pivot) i++;
            while (array[j] > pivot) j--;
            if (i <= j) {
                int temp = array[i];
                array[i] = array[j];
                array[j] = temp;
                i++;
                j--;
            }
        }
        if (left < j) QuickSortRandomPivot(array, left, j);
        if (i < right) QuickSortRandomPivot(array, i, right);
    }

 
    public static int medianaValor(int a, int b, int c) {
        if ((a > b) != (a > c)) return a;
        else if ((b > a) != (b > c)) return b;
        else return c;
    }

    public static void QuickSortMediana(int[] array, int left, int right) {
        int i = left, j = right;
        int meio = (left + right) / 2;
        int pivot = medianaValor(array[left], array[meio], array[right]);

        while (i <= j) {
            while (array[i] < pivot) i++;
            while (array[j] > pivot) j--;
            if (i <= j) {
                int temp = array[i];
                array[i] = array[j];
                array[j] = temp;
                i++;
                j--;
            }
        }
        if (left < j) QuickSortMediana(array, left, j);
        if (i < right) QuickSortMediana(array, i, right);
    }

   
    public static int[] gerarAleatorio(int n) {
        Random rand = new Random();
        int[] array = new int[n];
        for (int i = 0; i < n; i++) array[i] = rand.nextInt(100000);
        return array;
    }

    public static int[] gerarOrdenado(int n) {
        int[] array = new int[n];
        for (int i = 0; i < n; i++) array[i] = i;
        return array;
    }

    public static int[] gerarQuaseOrdenado(int n) {
        int[] array = gerarOrdenado(n);
        Random rand = new Random();
        for (int i = 0; i < n / 20; i++) { // troca 5% dos elementos
            int x = rand.nextInt(n);
            int y = rand.nextInt(n);
            int temp = array[x];
            array[x] = array[y];
            array[y] = temp;
        }
        return array;
    }

    // ---------- Main ----------
    public static void main(String[] args) {
        int[] tamanhos = {100, 1000, 10000};

        for (int n : tamanhos) {
            int[] ordenado = gerarOrdenado(n);
            int[] quase = gerarQuaseOrdenado(n);
            int[] aleatorio = gerarAleatorio(n);

            System.out.println("\n--- Testando com " + n + " elementos ---");

            // Primeiro Pivô
            testar("Primeiro Pivô", ordenado, quase, aleatorio, n, 1);
            // Último Pivô
            testar("Último Pivô", ordenado, quase, aleatorio, n, 2);
            // Aleatório
            testar("Pivô Aleatório", ordenado, quase, aleatorio, n, 3);
            // Mediana
            testar("Mediana de Três", ordenado, quase, aleatorio, n, 4);

            System.out.println("-----------------------------");
        }
    }

    
    public static void testar(String nome, int[] ordenado, int[] quase, int[] aleatorio, int n, int tipo) {
        int[] array;

        array = ordenado.clone();
        long inicio = System.currentTimeMillis();
        if (tipo == 1) QuickSortFirstPivot(array, 0, array.length - 1);
        if (tipo == 2) QuickSortLastPivot(array, 0, array.length - 1);
        if (tipo == 3) QuickSortRandomPivot(array, 0, array.length - 1);
        if (tipo == 4) QuickSortMediana(array, 0, array.length - 1);
        long fim = System.currentTimeMillis();
        System.out.println(nome + " | Ordenado | " + n + " elementos: " + (fim - inicio) + " ms");

        array = quase.clone();
        inicio = System.currentTimeMillis();
        if (tipo == 1) QuickSortFirstPivot(array, 0, array.length - 1);
        if (tipo == 2) QuickSortLastPivot(array, 0, array.length - 1);
        if (tipo == 3) QuickSortRandomPivot(array, 0, array.length - 1);
        if (tipo == 4) QuickSortMediana(array, 0, array.length - 1);
        fim = System.currentTimeMillis();
        System.out.println(nome + " | Quase Ordenado | " + n + " elementos: " + (fim - inicio) + " ms");

        array = aleatorio.clone();
        inicio = System.currentTimeMillis();
        if (tipo == 1) QuickSortFirstPivot(array, 0, array.length - 1);
        if (tipo == 2) QuickSortLastPivot(array, 0, array.length - 1);
        if (tipo == 3) QuickSortRandomPivot(array, 0, array.length - 1);
        if (tipo == 4) QuickSortMediana(array, 0, array.length - 1);
        fim = System.currentTimeMillis();
        System.out.println(nome + " | Aleatório | " + n + " elementos: " + (fim - inicio) + " ms");
    }
}

