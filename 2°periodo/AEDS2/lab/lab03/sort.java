import java.util.Scanner;

public class sort {

    public static void Sort(int n, int[] numeros, int M) {
        for (int i = 1; i < n; i++) {
            int j = i - 1;
            int temp = numeros[i];

            while (j >= 0 && compare(numeros[j], temp, M) > 0) {
                numeros[j + 1] = numeros[j];
                j--;
            }
            numeros[j + 1] = temp;
        }

        for (int u = 0; u < n; u++) {
            System.out.println(numeros[u]);
        }
    }

    public static int compare(int a, int b, int M) {
        int modA = a % M;
        int modB = b % M;

        if (modA != modB) return modA - modB;

        if (a % 2 != 0 && b % 2 == 0) return -1;
        if (a % 2 == 0 && b % 2 != 0) return 1;

        if (a % 2 != 0) return b - a;
        return a - b;
    }

    public static void main(String args[]) {
        Scanner sc = new Scanner(System.in);

        while (true) {
            int N = sc.nextInt();
            int M = sc.nextInt();

            if (N == 0 && M == 0) {
                System.out.println("0 0");
                break;
            }

            int numeros[] = new int[N];
            for (int i = 0; i < N; i++) {
                numeros[i] = sc.nextInt();
            }

            System.out.println(N + " " + M);
            Sort(N, numeros, M);
        }

        sc.close();
    }
}

