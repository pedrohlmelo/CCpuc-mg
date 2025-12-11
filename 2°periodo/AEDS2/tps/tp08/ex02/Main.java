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
    public void setPrice(float price) { this.price = price; }
    public void setSupportedLanguages(String[] supportedLanguages, int count) { this.supportedLanguages = supportedLanguages; this.supportedLanguages_count = count; }
    public void setMetacriticScore(int metacriticScore){ this.metacriticScore = metacriticScore; }
    public void setUserScore(float userScore){ this.userScore = userScore; }
    public void setAchievements(int achievements){ this.achievements = achievements; }
    public void setPublishers(String[] publishers, int count) { this.publishers = publishers; this.publishers_count = count; }
    public void setDevelopers(String[] developers, int count) { this.developers = developers; this.developers_count = count; }
    public void setCategories(String[] categories, int count) { this.categories = categories; this.categories_count = count; }
    public void setGenres(String[] genres, int count) { this.genres = genres; this.genres_count = count; }
    public void setTags(String[] tags, int count) { this.tags = tags; this.tags_count = count; }
}

class Hash {
    Game[] tabela;
    int m = 21;
    public int comparacoes = 0;

    public Hash() {
        this.tabela = new Game[m];
        for (int i = 0; i < m; i++) {
            tabela[i] = null;
        }
        comparacoes = 0;
    }

    public int h(String elemento) {
        int resp = 0;
        for (int i = 0; i < elemento.length(); i++) {
            resp += (int)elemento.charAt(i);
        }
        return resp % m;
    }

    public int hRehash(String elemento) {
        int resp = 0;
        for (int i = 0; i < elemento.length(); i++) {
            resp += (int)elemento.charAt(i);
        }
        return (resp + 1) % m;
    }

    public void inserir(Game elemento) {
        if (elemento == null) return;
        
        int pos = h(elemento.getName());

        if (tabela[pos] == null) {
            tabela[pos] = elemento;
        } else {
            pos = hRehash(elemento.getName());
            if (tabela[pos] == null) {
                tabela[pos] = elemento;
            }
        }
    }

    public void pesquisar(String nome) {
        System.out.print(nome + ": ");
        
        int pos = h(nome);
        
        if (tabela[pos] != null) {
            comparacoes++;
            if (tabela[pos].getName().equals(nome)) {
                System.out.println(" (Posicao: " + pos + ") SIM");
                return;
            }
        }

        int posRehash = hRehash(nome);
        if (tabela[posRehash] != null) {
            comparacoes++;
            if (tabela[posRehash].getName().equals(nome)) {
                System.out.println(" (Posicao: " + posRehash + ") SIM");
                return;
            }
        }
        
        System.out.println(" (Posicao: " + pos + ") NAO");
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

        Hash tabelaHash = new Hash();
        Scanner sc = new Scanner(System.in);

        String entrada;
        while (true) {
            entrada = sc.nextLine();
            if (entrada.equals("FIM")) break;
            try {
                int id = Integer.parseInt(entrada);
                Game jogoParaInserir = GameporID(id, todosOsGames, totalGamesCount);
                tabelaHash.inserir(jogoParaInserir);
            } catch (NumberFormatException e) {
            }
        }

        while (true) {
            entrada = sc.nextLine();
            if (entrada.equals("FIM")) break;
            tabelaHash.pesquisar(entrada);
        }

        long fimTempo = System.currentTimeMillis();
        
        try (FileWriter writer = new FileWriter("889841_hashRehash.txt")) { 
            long tempoTotal = fimTempo - inicioTempo;
            writer.write("889841" + "\t" + tempoTotal + "ms\t" + tabelaHash.comparacoes);
        } catch (IOException e) {
            System.out.println("Erro ao criar log.");
        }

        sc.close();
    }
}