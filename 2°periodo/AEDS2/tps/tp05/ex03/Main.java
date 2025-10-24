import java.util.Scanner;
import java.io.*; // Inclui File, FileWriter, IOException,PrintWriter

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

    // --- Setters ---
    public void setId(int id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setReleaseDate(String releaseDate) { this.releaseDate = releaseDate; }
    public void setEstimatedOwners(int estimatedOwners) { this.estimatedOwners = estimatedOwners; }
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
    
    // --- Getters ---
    public int getId() { return id; }
    public String getName() { return this.name; } 
    public String getReleaseDate() { return this.releaseDate; }
    public int getEstimatedOwners() { return this.estimatedOwners; }
    public float getPrice() { return this.price; }
    public int getMetacriticScore() { return this.metacriticScore; }
    public float getUserScore() { return this.userScore; }
    public int getAchievements() { return this.achievements; }

    /**
     * Imprime o jogo formatado como na saída da questão.
     */
    public void imprimir() {
        System.out.print("=> " + this.id + " ## " + this.name + " ## " + this.releaseDate + " ## " + this.estimatedOwners + " ## ");
        
        if (this.price == 0.0f) {
            System.out.print("0.0");
        } else {
            if(this.price == (int)this.price) {
                 System.out.print((int)this.price);
            } else {
                 System.out.print(this.price);
            }
        }

        System.out.print(" ## [");
        for (int i = 0; i < this.supportedLanguages_count; i++) {
            System.out.print(this.supportedLanguages[i]);
            if (i < this.supportedLanguages_count - 1) System.out.print(", ");
        }
        System.out.print("] ## " + this.metacriticScore + " ## " + this.userScore + " ## " + this.achievements + " ## [");
        for (int i = 0; i < this.publishers_count; i++) {
            System.out.print(this.publishers[i]);
            if (i < this.publishers_count - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
        for (int i = 0; i < this.developers_count; i++) {
            System.out.print(this.developers[i]);
            if (i < this.developers_count - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
        for (int i = 0; i < this.categories_count; i++) {
            System.out.print(this.categories[i]);
            if (i < this.categories_count - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
        for (int i = 0; i < this.genres_count; i++) {
            System.out.print(this.genres[i]);
            if (i < this.genres_count - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
         for (int i = 0; i < this.tags_count; i++) {
            System.out.print(this.tags[i]);
            if (i < this.tags_count - 1) System.out.print(", ");
        }
        System.out.println("] ##"); 
    }
}

public class Main {
    
    // Contadores globais para o log
    private static long totalComparacoes = 0;
    private static long totalMovimentacoes = 0;

    
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
                if(countTemp == resultado.length){ // Redimensiona o array
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
        
        // Adiciona o último item
        if(countTemp == resultado.length){ 
            String[] temp = new String[resultado.length * 2];
            for(int k=0; k < resultado.length; k++) temp[k] = resultado[k];
            resultado = temp;
        }
        resultado[countTemp++] = itemAtual;
        
        // Corta o array para o tamanho exato
        String[] arrayResultado = new String[countTemp];
        for(int i=0; i < countTemp; i++) arrayResultado[i] = resultado[i];
        
        count[0] = countTemp; // Retorna o tamanho 
        return arrayResultado;
    }

    /**
     * Lê uma linha do CSV e preenche o objeto Game.
     */
    public static void formatar(Game game, String linha) {
        String[] campos = new String[20]; // Array temporário 
        int campoCount = 0;
        String campoAtual = "";
        boolean dentroDeAspas = false;
    
        // Separa os campos da linha (considerando aspas)
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
        
        // Trata a data
        String dataOriginal = campos[2];
        String dataSemVirgula = "";
        for(int i = 0; i < dataOriginal.length(); i++){
            if(dataOriginal.charAt(i) != ',') dataSemVirgula += dataOriginal.charAt(i);
        }
        
        int[] dataPartes_count = new int[1]; 
        String[] dataPartes = separarStringInterna(dataSemVirgula, ' ', dataPartes_count);
        
        String diaStr = "01", mesStr = "Jan", anoStr = "1970";

        if (dataPartes_count[0] >= 3) { 
            mesStr = dataPartes[0];
            diaStr = dataPartes[1];
            anoStr = dataPartes[2];
        } else if (dataPartes_count[0] == 2) { 
            mesStr = dataPartes[0];
            anoStr = dataPartes[1];
            diaStr = "01"; 
        } 
        
        if (diaStr.length() == 1) {
            diaStr = "0" + diaStr;
        }

        String mesNum = "";
        switch (mesStr) {
            case "Jan": mesNum = "01"; break; case "Feb": mesNum = "02"; break;
            case "Mar": mesNum = "03"; break; case "Apr": mesNum = "04"; break;
            case "May": mesNum = "05"; break; case "Jun": mesNum = "06"; break;
            case "Jul": mesNum = "07"; break; case "Aug": mesNum = "08"; break;
            case "Sep": mesNum = "09"; break; case "Oct": mesNum = "10"; break;
            case "Nov": mesNum = "11"; break; case "Dec": mesNum = "12"; break;
            default: mesNum = "00"; break;
        }
        game.setReleaseDate(diaStr + "/" + mesNum + "/" + anoStr);
        
        game.setEstimatedOwners(Integer.parseInt(campos[3]));
        game.setPrice(Float.parseFloat(campos[4]));
        
        // Limpa e separa as linguagens
        String linguagensStr = campos[5];
        String linguagensLimpas = "";
        for(int i = 0; i < linguagensStr.length(); i++){
            char c = linguagensStr.charAt(i);
            if(c != '[' && c != ']' && c != '\'') linguagensLimpas += c;
        }
        int[] lang_count = new int[1];
        game.setSupportedLanguages(separarStringInterna(linguagensLimpas, ',', lang_count), lang_count[0]);
        
        game.setMetacriticScore(Integer.parseInt(campos[6]));
        game.setUserScore(Float.parseFloat(campos[7]));
        game.setAchievements(Integer.parseInt(campos[8]));
        
        int[] pub_count = new int[1];
        game.setPublishers(separarStringInterna(campos[9], ',', pub_count), pub_count[0]);
        
        int[] dev_count = new int[1];
        game.setDevelopers(separarStringInterna(campos[10], ',', dev_count), dev_count[0]);

        int[] cat_count = new int[1];
        game.setCategories(separarStringInterna(campos[11], ',', cat_count), cat_count[0]);

        int[] gen_count = new int[1];
        game.setGenres(separarStringInterna(campos[12], ',', gen_count), gen_count[0]);

        int[] tag_count = new int[1];
        game.setTags(separarStringInterna(campos[13], ',', tag_count), tag_count[0]);
    }

    

    public static void heapsort(Game[] games, int n) {
        
        for (int i = n / 2 - 1; i >= 0; i--) {
            heapify(games, n, i);
        }

        
        for (int i = n - 1; i > 0; i--) {
           
            swap(games, 0, i);
            
            
            heapify(games, i, 0);
        }
    }

    
    private static void heapify(Game[] games, int n, int i) {
        int maior = i;       
        int esq = 2 * i + 1; 
        int dir = 2 * i + 2; 

        
        if (esq < n && isMaior(games[esq], games[maior])) {
            maior = esq;
        }

        
        if (dir < n && isMaior(games[dir], games[maior])) {
            maior = dir;
        }

        
        if (maior != i) {
            swap(games, i, maior); 
            heapify(games, n, maior); 
        }
    }

  
    private static boolean isMaior(Game a, Game b) {
        totalComparacoes++;
        if (a.getEstimatedOwners() != b.getEstimatedOwners()) {
            return a.getEstimatedOwners() > b.getEstimatedOwners();
        } else {
            // Se empatar, usa o AppID
            totalComparacoes++;
            return a.getId() > b.getId();
        }
    }

    
    private static void swap(Game[] games, int i, int j) {
        Game temp = games[i];
        games[i] = games[j];
        games[j] = temp;
        totalMovimentacoes += 3; 
    }
    
    public static void criarLog(String matricula, double tempo, long comparacoes, long movimentacoes) throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter(matricula + "_heapsort.txt"))) {
            String tempoStr = String.valueOf(tempo).replace(',', '.');
            writer.print(matricula + "\t" + comparacoes + "\t" + movimentacoes + "\t" + tempoStr + ".ms" + "\n");
        }
    }

    public static void main(String[] args) throws Exception {

        File arquivo = new File("/tmp/games.csv");
        
        Game[] todosOsGames = new Game[1];
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
        
        // Corta o array para o tamanho exato
        Game[] tempGames = new Game[totalGamesCount];
        for(int i = 0; i < totalGamesCount; i++) tempGames[i] = todosOsGames[i];
        todosOsGames = tempGames; 

        Scanner sc = new Scanner(System.in);
        
        
        int[] id = new int[1];
        int count = 0; 
        String entrada;

        while (sc.hasNext()) {
            entrada = sc.next();
            if (entrada.equals("FIM")) break;
            int valor = Integer.parseInt(entrada);
            if(count == id.length){ 
                int[] tempInt = new int[id.length*2];
                for(int i = 0; i < id.length; i++){ tempInt[i] = id[i]; }
                id = tempInt;
            }
            id[count] = valor;
            count++;
        }

        
        Game[] vetorJogos = new Game[count];
        int jogosEncontrados = 0;
        
        for (int i = 0; i < count; i++) {
            int idBusca = id[i];
            for(int j = 0; j < todosOsGames.length; j++) { 
                if (todosOsGames[j].getId() == idBusca) {
                    vetorJogos[jogosEncontrados] = todosOsGames[j];
                    jogosEncontrados++;
                    break; 
                }
            }
        }
        
        
        totalComparacoes = 0; 
        totalMovimentacoes = 0;
        long startTime = System.nanoTime();
        
        heapsort(vetorJogos, jogosEncontrados);
        
        long endTime = System.nanoTime();
        double tempoExecucao = (endTime - startTime) / 1_000_000.0; 

        // 3. Cria o log
        criarLog("889841", tempoExecucao, totalComparacoes, totalMovimentacoes); 

        
        for (int i = 0; i < jogosEncontrados; i++) {
            vetorJogos[i].imprimir();
        }
        
        sc.close();
    }
}