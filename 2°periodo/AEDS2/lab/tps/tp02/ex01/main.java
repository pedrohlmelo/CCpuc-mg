import java.util.Scanner;

public class main {

    
    private static String readExpr(Scanner sc) {
        String s = sc.nextLine();
        if (s.trim().length() == 0) s = sc.nextLine(); 
        return s;
    }

    
    private static String removeSpaces(String s) {
        String r = "";
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c != ' ' && c != '\t' && c != '\r') r += c;
        }
        return r;
    }

    private static String substituiVariaveis(String expr, int[] valores) {
        String r = "";
        for (int i = 0; i < expr.length(); i++) {
            char c = expr.charAt(i);
            if (c >= 'A' && c <= 'Z') {
                int idx = c - 'A';
                if (idx >= 0 && idx < valores.length) r += (char)('0' + valores[idx]);
                else r += c; // se houver variável além do fornecido
            } else {
                r += c;
            }
        }
        return r;
    }

    
    private static boolean temOperador(String e) {
        for (int i = 0; i < e.length(); i++) {
            char c = e.charAt(i);
            if (c == 'a' || c == 'o' || c == 'n') return true;
        }
        return false;
    }

    private static int achaFecha(String s, int posAposAbre) {
        int dep = 1;
        for (int i = posAposAbre; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '(') dep++;
            else if (c == ')') dep--;
            if (dep == 0) return i;
        }
        return -1; // não encontrou
    }

    // separa argumentos de and/or respeitando parênteses
    private static int[] avaliaArgs(String dentro) {
        int cap = Math.max(1, dentro.length()); // buffer simples
        int[] vals = new int[cap];
        int qtd = 0;

        int ini = 0, dep = 0;
        for (int j = 0; j <= dentro.length(); j++) {
            boolean fimArg = (j == dentro.length());
            if (!fimArg) {
                char c = dentro.charAt(j);
                if (c == '(') dep++;
                else if (c == ')') dep--;
                else if (c == ',' && dep == 0) fimArg = true;
            }
            if (fimArg) {
                String arg = dentro.substring(ini, j);
                int v = eval(arg); // argumentos já estão com A/B/C substituídos
                vals[qtd++] = v;
                ini = j + 1;
            }
        }
        int[] res = new int[qtd];
        for (int i = 0; i < qtd; i++) res[i] = vals[i];
        return res;
    }

    private static String reduz(String expr) {
        // NOT
        int i = expr.indexOf("not(");
        if (i != -1) {
            int fim = achaFecha(expr, i + 4);
            if (fim == -1) return expr; // evita estouro
            String dentro = expr.substring(i + 4, fim);
            int val = 1 - eval(dentro);
            return expr.substring(0, i) + val + expr.substring(fim + 1);
        }

        // AND
        i = expr.indexOf("and(");
        if (i != -1) {
            int fim = achaFecha(expr, i + 4);
            if (fim == -1) return expr;
            String dentro = expr.substring(i + 4, fim);
            int[] args = avaliaArgs(dentro);
            int val = 1;
            for (int v : args) if (v == 0) { val = 0; break; }
            return expr.substring(0, i) + val + expr.substring(fim + 1);
        }

        // OR
        i = expr.indexOf("or(");
        if (i != -1) {
            int fim = achaFecha(expr, i + 3);
            if (fim == -1) return expr;
            String dentro = expr.substring(i + 3, fim);
            int[] args = avaliaArgs(dentro);
            int val = 0;
            for (int v : args) if (v == 1) { val = 1; break; }
            return expr.substring(0, i) + val + expr.substring(fim + 1);
        }

        return expr;
    }

    // remove parênteses exteriores quando englobam a expressão inteira
    private static String stripOuterParens(String e) {
        while (e.length() >= 2 && e.charAt(0) == '(') {
            int f = achaFecha(e, 1);
            if (f == e.length() - 1) {
                e = e.substring(1, e.length() - 1);
            } else break;
        }
        return e;
    }

    // expr já com variáveis substituídas e sem espaços
    private static int eval(String expr) {
        expr = removeSpaces(expr);
        expr = stripOuterParens(expr);

        if (expr.length() == 1 && (expr.charAt(0) == '0' || expr.charAt(0) == '1')) {
            return expr.charAt(0) - '0';
        }

        while (temOperador(expr)) {
            String prox = reduz(expr);
            if (prox.equals(expr)) break; // segurança contra loop
            expr = stripOuterParens(removeSpaces(prox));
        }

        // última limpeza de parênteses
        expr = stripOuterParens(expr);
        return (expr.length() == 1) ? (expr.charAt(0) - '0') : 0; // default seguro
    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        while (true) {
            int n = sc.nextInt();
            if (n == 0) break;

            int[] valores = new int[n];
            for (int i = 0; i < n; i++) valores[i] = sc.nextInt();

            String expr = readExpr(sc);
            expr = substituiVariaveis(expr, valores); // troca A,B,C,... por 0/1

            int ans = eval(expr);
            System.out.println(ans);  // 0 ou 1
        }
        sc.close();
    }
}
