import java.util.*;

public class Main {

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        while (sc.hasNext()) {
            int N = sc.nextInt();
            if (N == 0) {
                System.out.println();
            }
            while (N == 1) {
                sc.nextLine();
                System.out.println();
                String[] Package = new String[1000];
                int u = 0;
                for (int i = 0; i < Package.length; i++) {
                    Package[i] = sc.nextLine();
                    if (Package[i].charAt(0) != 'P') {
                        N = Integer.parseInt(Package[i]);
                        break;
                    }
                    u++;
                }
                int[] IP = new int[u];
                for (int i = 0; i < u; i++) {
                    String nova = "";
                    nova += Package[i].charAt(8);
                    nova += Package[i].charAt(9);
                    nova += Package[i].charAt(10);
                    IP[i] = Integer.parseInt(nova);
                }

                for (int i = u - 1; i > 0; i--) {
                    for (int j = 0; j < i; j++) {
                        if (IP[j] > IP[j + 1]) {
                            String aux = Package[j];
                            Package[j] = Package[j + 1];
                            Package[j + 1] = aux;

                            int auxx = IP[j];
                            IP[j] = IP[j + 1];
                            IP[j + 1] = auxx;
                        }
                    }
                }
                for (int i = 0; i < u; i++) {
                    System.out.println(Package[i]);
                }
                System.out.println();
            }
        }

    }
}
