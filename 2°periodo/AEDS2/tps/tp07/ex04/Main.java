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

class NoAN {
    public Game elemento;
    public NoAN esq, dir;
    public boolean cor; 

    public NoAN(Game elemento) {
        this(elemento, null, null, false);
    }

    public NoAN(Game elemento, NoAN esq, NoAN dir, boolean cor) {
        this.elemento = elemento;
        this.esq = esq;
        this.dir = dir;
        this.cor = cor;
    }
}

class Alvinegra {
    private NoAN raiz;
    public int comparacoes;
    
    private static final boolean PRETO = false;
    private static final boolean VERMELHO = true;

    public Alvinegra() {
        raiz = null;
        comparacoes = 0;
    }

    public void inserir(Game elemento) throws Exception {
        if (raiz == null) {
            raiz = new NoAN(elemento);
            raiz.cor = PRETO;
        } else {
            if (raiz.esq != null && raiz.dir != null && raiz.esq.cor == VERMELHO && raiz.dir.cor == VERMELHO) {
                raiz.cor = VERMELHO;
                raiz.esq.cor = PRETO;
                raiz.dir.cor = PRETO;
                raiz.cor = PRETO; 
            }
            inserir(elemento, null, null, null, raiz);
        }
        raiz.cor = PRETO; 
    }

    private void inserir(Game elemento, NoAN bisavo, NoAN avo, NoAN pai, NoAN i) throws Exception {
        if (i == null) {
            if (elemento.getName().compareTo(pai.elemento.getName()) < 0) {
                pai.esq = new NoAN(elemento, null, null, VERMELHO);
            } else {
                pai.dir = new NoAN(elemento, null, null, VERMELHO);
            }
            balancear(bisavo, avo, pai);
        } else {
            if (i.esq != null && i.dir != null && i.esq.cor == VERMELHO && i.dir.cor == VERMELHO) {
                i.cor = VERMELHO;
                i.esq.cor = PRETO;
                i.dir.cor = PRETO;
                if (i == raiz) i.cor = PRETO;
                balancear(bisavo, avo, pai);
            }

            int cmp = elemento.getName().compareTo(i.elemento.getName());
            if (cmp < 0) {
                inserir(elemento, avo, pai, i, i.esq);
            } else if (cmp > 0) {
                inserir(elemento, avo, pai, i, i.dir);
            }
        }
    }

    private void balancear(NoAN bisavo, NoAN avo, NoAN pai) {
        if (pai.cor == VERMELHO) {
            if (pai.elemento.getName().compareTo(avo.elemento.getName()) > 0) { 
                if (pai.dir != null && pai.dir.cor == VERMELHO) { 
                    if (bisavo == null) raiz = rotacionarEsquerda(avo);
                    else {
                        if (avo.elemento.getName().compareTo(bisavo.elemento.getName()) < 0)
                            bisavo.esq = rotacionarEsquerda(avo);
                        else
                            bisavo.dir = rotacionarEsquerda(avo);
                    }
                    avo.cor = VERMELHO;
                    pai.cor = PRETO;
                } else if (pai.esq != null && pai.esq.cor == VERMELHO) { 
                    if (bisavo == null) raiz = rotacionarDireitaEsquerda(avo);
                    else {
                        if (avo.elemento.getName().compareTo(bisavo.elemento.getName()) < 0)
                            bisavo.esq = rotacionarDireitaEsquerda(avo);
                        else
                            bisavo.dir = rotacionarDireitaEsquerda(avo);
                    }
                    avo.cor = VERMELHO;
                }
            } else { 
                if (pai.esq != null && pai.esq.cor == VERMELHO) { 
                    if (bisavo == null) raiz = rotacionarDireita(avo);
                    else {
                        if (avo.elemento.getName().compareTo(bisavo.elemento.getName()) < 0)
                            bisavo.esq = rotacionarDireita(avo);
                        else
                            bisavo.dir = rotacionarDireita(avo);
                    }
                    avo.cor = VERMELHO;
                    pai.cor = PRETO;
                } else if (pai.dir != null && pai.dir.cor == VERMELHO) { 
                    if (bisavo == null) raiz = rotacionarEsquerdaDireita(avo);
                    else {
                        if (avo.elemento.getName().compareTo(bisavo.elemento.getName()) < 0)
                            bisavo.esq = rotacionarEsquerdaDireita(avo);
                        else
                            bisavo.dir = rotacionarEsquerdaDireita(avo);
                    }
                    avo.cor = VERMELHO;
                }
            }
        }
    }

    private NoAN rotacionarDireita(NoAN no) {
        NoAN noEsq = no.esq;
        NoAN noEsqDir = noEsq.dir;
        noEsq.dir = no;
        no.esq = noEsqDir;
        return noEsq;
    }

    private NoAN rotacionarEsquerda(NoAN no) {
        NoAN noDir = no.dir;
        NoAN noDirEsq = noDir.esq;
        noDir.esq = no;
        no.dir = noDirEsq;
        return noDir;
    }

    private NoAN rotacionarDireitaEsquerda(NoAN no) {
        no.dir = rotacionarDireita(no.dir);
        NoAN temp = rotacionarEsquerda(no);
        temp.cor = PRETO; 
        return temp;
    }

    private NoAN rotacionarEsquerdaDireita(NoAN no) {
        no.esq = rotacionarEsquerda(no.esq);
        NoAN temp = rotacionarDireita(no);
        temp.cor = PRETO; 
        return temp;
    }

    public void pesquisar(String nome) {
        System.out.print(nome + ": =>raiz "); 
        if (pesquisar(raiz, nome)) {
            System.out.println(" SIM");
        } else {
            System.out.println(" NAO");
        }
    }

    private boolean pesquisar(NoAN no, String nome) {
        if (no == null) {
            comparacoes++;
            return false;
        }
        int cmp = nome.compareTo(no.elemento.getName());
        if (cmp == 0) {
            comparacoes++;
            return true;
        } else if (cmp < 0) {
            System.out.print(" esq");
            comparacoes++;
            return pesquisar(no.esq, nome);
        } else {
            System.out.print(" dir");
            comparacoes++;
            return pesquisar(no.dir, nome);
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

        Alvinegra arvore = new Alvinegra();
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
        try (FileWriter writer = new FileWriter("889841_alvinegra.txt")) { 
            long tempoTotal = fimTempo - inicioTempo;
            writer.write("889841" + "\t" + tempoTotal + "ms\t" + arvore.comparacoes);
        } catch (IOException e) {
            System.out.println("Erro ao criar log.");
        }
        sc.close();
    }
}