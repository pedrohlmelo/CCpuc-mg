import java.util.Scanner;
import java.io.*; 

class Game {
    private int id;
    private String name;
    private String releaseDate;
    private int estimatedOwners;
    private float price;
    private String[] supportedLanguages;
    private int supportedLanguages_count;
    private int metacriticScore;
    private float userScore;
    private int achievements;
    private String[] publishers;
    private int publishers_count;
    private String[] developers;
    private int developers_count;
    private String[] categories;
    private int categories_count;
    private String[] genres;
    private int genres_count;
    private String[] tags;
    private int tags_count;

    public Game() {}

    public void setId(int id) { this.id = id; }
    public int getId() { return id; }
    
    public void setName(String name) { this.name = name; }
    public String getName() { return this.name; } 
    
    public void setReleaseDate(String releaseDate) { this.releaseDate = releaseDate; }
    
    public void setEstimatedOwners(int estimatedOwners) { this.estimatedOwners = estimatedOwners; }
    public int getEstimatedOwners() { return estimatedOwners; }
    
    public void setPrice(float price) { this.price = price; }
    
    public void setSupportedLanguages(String[] supportedLanguages, int count) { 
        this.supportedLanguages = supportedLanguages; 
        this.supportedLanguages_count = count;
    }
    public void setMetacriticScore(int metacriticScore){ this.metacriticScore = metacriticScore; }
    public void setUserScore(float userScore){ this.userScore = userScore; }
    public void setAchievements(int achievements){ this.achievements = achievements; }
    public void setPublishers(String[] publishers, int count) { 
        this.publishers = publishers; 
        this.publishers_count = count;
    }
    public void setDevelopers(String[] developers, int count) { 
        this.developers = developers;
        this.developers_count = count;
    }
    public void setCategories(String[] categories, int count) { 
        this.categories = categories; 
        this.categories_count = count;
    }
    public void setGenres(String[] genres, int count) { 
        this.genres = genres;
        this.genres_count = count;
    }
    public void setTags(String[] tags, int count) { 
        this.tags = tags;
        this.tags_count = count;
    }
}

class No2 {
    public Game elemento;
    public No2 esq, dir;

    public No2(Game elemento) {
        this.elemento = elemento;
        this.esq = null;
        this.dir = null;
    }
}

class No1 {
    public int elemento; 
    public No1 esq, dir;
    public No2 raizSec; 

    public No1(int elemento) {
        this.elemento = elemento;
        this.esq = null;
        this.dir = null;
        this.raizSec = null;
    }
}

class ArvoreArvore {
    private No1 raiz;
    public int comparacoes;

    public ArvoreArvore() {
        raiz = null;
        comparacoes = 0;
        int[] chaves = {7, 3, 11, 1, 5, 9, 13, 0, 2, 4, 6, 8, 10, 12, 14};
        for (int chave : chaves) {
            inserirNaPrimeira(chave);
        }
    }

    private void inserirNaPrimeira(int x) {
        raiz = inserirNaPrimeira(x, raiz);
    }

    private No1 inserirNaPrimeira(int x, No1 i) {
        if (i == null) {
            i = new No1(x);
        } else if (x < i.elemento) {
            i.esq = inserirNaPrimeira(x, i.esq);
        } else if (x > i.elemento) {
            i.dir = inserirNaPrimeira(x, i.dir);
        }
        return i;
    }

    public void inserir(Game game) throws Exception {
        int chave1 = game.getEstimatedOwners() % 15;
        No1 noPrimeira = pesquisarNaPrimeira(chave1, raiz);
        
        if (noPrimeira == null) {
            throw new Exception("Erro");
        }
        
        noPrimeira.raizSec = inserirNaSegunda(game, noPrimeira.raizSec);
    }

    private No1 pesquisarNaPrimeira(int x, No1 i) {
        if (i == null) return null;
        if (x == i.elemento) return i;
        else if (x < i.elemento) return pesquisarNaPrimeira(x, i.esq);
        else return pesquisarNaPrimeira(x, i.dir);
    }

    private No2 inserirNaSegunda(Game x, No2 i) throws Exception {
        if (i == null) {
            i = new No2(x);
        } else if (x.getName().compareTo(i.elemento.getName()) < 0) {
            i.esq = inserirNaSegunda(x, i.esq);
        } else if (x.getName().compareTo(i.elemento.getName()) > 0) {
            i.dir = inserirNaSegunda(x, i.dir);
        } 
        return i;
    }


    public void pesquisar(String nome) {
        System.out.print("=> " + nome);
        System.out.print(" => raiz "); 
        
        if (!pesquisarGlobal(raiz, nome)) {
            System.out.println(" NAO");
        }
    }

   
    private boolean pesquisarGlobal(No1 i, String nome) {
        if (i == null) return false;

        if (pesquisarNaSegunda(i.raizSec, nome)) {
            return true; 
        }

        System.out.print(" ESQ "); 
        if (pesquisarGlobal(i.esq, nome)) return true;
        
        System.out.print(" DIR "); 
        if (pesquisarGlobal(i.dir, nome)) return true;
        
        return false;
    }

    private boolean pesquisarNaSegunda(No2 i, String nome) {
        if (i == null) return false;

        
        boolean resp = pesquisarNaSegundaRecursivo(i, nome);
        if (resp) {
            System.out.println(" SIM");
            return true;
        } 
        return false;
    }

    private boolean pesquisarNaSegundaRecursivo(No2 i, String nome) {
        if (i == null) {
            comparacoes++;
            return false;
        }

        String nomeNo = i.elemento.getName();
        
        if (nome.equals(nomeNo)) {
            comparacoes++;
            return true;
        } else if (nome.compareTo(nomeNo) < 0) {
            System.out.print("esq "); 
            comparacoes++;
            return pesquisarNaSegundaRecursivo(i.esq, nome);
        } else {
            System.out.print("dir "); 
            comparacoes++;
            return pesquisarNaSegundaRecursivo(i.dir, nome);
        }
    }
}

public class Main {
    
    private static String[] separarStringInterna(String texto, char separador, int[] count) {
        if (texto == null || texto.isEmpty()) {
            count[0] = 0;
            return new String[0];
        }
        String[] resultado = new String[1]; 
        int countTemp = 0;
        String itemAtual = "";
        for (int i = 0; i < texto.length(); i++) {
            char c = texto.charAt(i);
            if (c == separador) {
                if(countTemp == resultado.length){
                    String[] temp = new String[resultado.length * 2];
                    for(int k=0; k < resultado.length; k++) temp[k] = resultado[k];
                    resultado = temp;
                }
                resultado[countTemp++] = itemAtual;
                itemAtual = "";
                if (i + 1 < texto.length() && texto.charAt(i + 1) == ' ') i++;
            } else {
                itemAtual += c;
            }
        }
        if(countTemp == resultado.length){ 
            String[] temp = new String[resultado.length * 2];
            for(int k=0; k < resultado.length; k++) temp[k] = resultado[k];
            resultado = temp;
        }
        resultado[countTemp++] = itemAtual;
        String[] arrayResultado = new String[countTemp];
        for(int i=0; i < countTemp; i++) arrayResultado[i] = resultado[i];
        count[0] = countTemp; 
        return arrayResultado;
    }

    public static void formatar(Game game, String linha) {
        String[] campos = new String[20]; 
        int campoCount = 0;
        String campoAtual = "";
        boolean dentroDeAspas = false;
        for (int i = 0; i < linha.length(); i++) {
            char c = linha.charAt(i);
            if (c == '"') {
                dentroDeAspas = !dentroDeAspas;
            } else if (c == ',' && !dentroDeAspas) {
                campos[campoCount++] = campoAtual;
                campoAtual = "";
            } else {
                campoAtual += c;
            }
        }
        campos[campoCount++] = campoAtual;
        game.setId(Integer.parseInt(campos[0]));
        game.setName(campos[1]);
        game.setReleaseDate(campos[2]);
        game.setEstimatedOwners(Integer.parseInt(campos[3]));
        game.setPrice(Float.parseFloat(campos[4]));
    }

    public static Game GameporID(int id, Game[] todosOsGames, int totalGamesCount){
        for(int i = 0; i < totalGamesCount; i++){
           if(id == todosOsGames[i].getId()){
               return todosOsGames[i];
           }
        }
        return null;
    }

    public static void main(String[] args) throws Exception {
        long inicioTempo = System.currentTimeMillis();

        File arquivo = new File("/tmp/games.csv"); 
        Game[] todosOsGames = new Game[5000];
        int totalGamesCount = 0; 
        
        try (Scanner scFile = new Scanner(arquivo)) {
            scFile.nextLine(); 
            while (scFile.hasNextLine()) {
                String linha = scFile.nextLine();
                if (linha.isEmpty()) continue;
                Game novoGame = new Game();
                formatar(novoGame, linha);
                
                if(totalGamesCount == todosOsGames.length){ 
                    Game[] temp = new Game[todosOsGames.length * 2];
                    for(int i = 0; i < todosOsGames.length; i++) temp[i] = todosOsGames[i];
                    todosOsGames = temp;
                }
                todosOsGames[totalGamesCount++] = novoGame;
            }
        }

        ArvoreArvore arvore = new ArvoreArvore();
        Scanner sc = new Scanner(System.in);

        String entrada;
        while (true) {
            entrada = sc.nextLine();
            if (entrada.equals("FIM")) break;
            
            int id = Integer.parseInt(entrada);
            Game jogoParaInserir = GameporID(id, todosOsGames, totalGamesCount);
            
            if (jogoParaInserir != null) {
                try {
                    arvore.inserir(jogoParaInserir);
                } catch (Exception e) {
                }
            }
        }

        while (true) {
            entrada = sc.nextLine();
            if (entrada.equals("FIM")) break;
            
            arvore.pesquisar(entrada);
        }

        long fimTempo = System.currentTimeMillis();
        
        try (FileWriter writer = new FileWriter("889841_arvoreArvore.txt")) { 
            long tempoTotal = fimTempo - inicioTempo;
            writer.write("889841" + "\t" + tempoTotal + "ms\t" + arvore.comparacoes);
        } catch (IOException e) {
            System.out.println("Erro ao criar log.");
        }

        sc.close();
    }
}