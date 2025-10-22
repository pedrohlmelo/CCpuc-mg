import java.util.Scanner;
import java.io.*; 

class Game {
    private int id;
    private String name;
    private String releaseDate;
    private int estimatedOwners;
    private float price;
    private String[] supportedLanguages;
    private int metacriticScore;
    private float userScore;
    private int achievements;
    private String[] publishers;
    private String[] developers;
    private String[] categories;
    private String[] genres;
    private String[] tags;

    public Game() {}

    public void setId(int id) { this.id = id; }
    public void setName(String name) { this.name = name; }
    public void setReleaseDate(String releaseDate) { this.releaseDate = releaseDate; }
    public void setEstimatedOwners(int estimatedOwners) { this.estimatedOwners = estimatedOwners; }
    public void setPrice(float price) { this.price = price; }
    public void setSupportedLanguages(String[] supportedLanguages) { this.supportedLanguages = supportedLanguages; }
    public void setMetacriticScore(int metacriticScore){ this.metacriticScore = metacriticScore; }
    public void setUserScore(float userScore){ this.userScore = userScore; }
    public void setAchievements(int achievements){ this.achievements = achievements; }
    public void setPublishers(String[] publishers) { this.publishers = publishers; }
    public void setDevelopers(String[] developers) { this.developers = developers; }
    public void setCategories(String[] categories) { this.categories = categories; }
    public void setGenres(String[] genres) { this.genres = genres; }
    public void setTags(String[] tags) { this.tags = tags; }
    
    public int getId() { return id; }
    public String getName() { return this.name; } 
}

public class Main {
    
    
    private static int totalComparacoes = 0;

   
    private static String[] separarStringInterna(String texto, char separador) {
        if (texto == null || texto.isEmpty()) return new String[0];
        
        String[] resultado = new String[1]; // Array inicial
        int count = 0;
        String itemAtual = "";
        
        for (int i = 0; i < texto.length(); i++) {
            char c = texto.charAt(i);
            if (c == separador) {
                // Redimensiona o array se necessário
                if(count == resultado.length){ 
                    String[] temp = new String[resultado.length * 2];
                    for(int k=0; k < resultado.length; k++) temp[k] = resultado[k];
                    resultado = temp;
                }
                resultado[count++] = itemAtual;
                itemAtual = "";
                if (i + 1 < texto.length() && texto.charAt(i + 1) == ' ') i++;
            } else {
                itemAtual += c;
            }
        }
        
        // Adiciona o último item
        if(count == resultado.length){ 
            String[] temp = new String[resultado.length * 2];
            for(int k=0; k < resultado.length; k++) temp[k] = resultado[k];
            resultado = temp;
        }
        resultado[count++] = itemAtual;
        
        // Cria o array final com o tamanho exato
        String[] arrayResultado = new String[count];
        for(int i=0; i < count; i++) arrayResultado[i] = resultado[i];
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
        
        String dataOriginal = campos[2];
        String dataSemVirgula = "";
        for(int i = 0; i < dataOriginal.length(); i++){
            if(dataOriginal.charAt(i) != ',') dataSemVirgula += dataOriginal.charAt(i);
        }
        String[] dataPartes = separarStringInterna(dataSemVirgula, ' ');
        
        String diaStr = "01", mesStr = "Jan", anoStr = "1970";

        if (dataPartes.length >= 3) { 
            mesStr = dataPartes[0];
            diaStr = dataPartes[1];
            anoStr = dataPartes[2];
        } else if (dataPartes.length == 2) { 
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
        String linguagensStr = campos[5];
        String linguagensLimpas = "";
        for(int i = 0; i < linguagensStr.length(); i++){
            char c = linguagensStr.charAt(i);
            if(c != '[' && c != ']' && c != '\'') linguagensLimpas += c;
        }
        game.setSupportedLanguages(separarStringInterna(linguagensLimpas, ','));
        game.setMetacriticScore(Integer.parseInt(campos[6]));
        game.setUserScore(Float.parseFloat(campos[7]));
        game.setAchievements(Integer.parseInt(campos[8]));
        game.setPublishers(separarStringInterna(campos[9], ','));
        game.setDevelopers(separarStringInterna(campos[10], ','));
        game.setCategories(separarStringInterna(campos[11], ','));
        game.setGenres(separarStringInterna(campos[12], ','));
        game.setTags(separarStringInterna(campos[13], ','));
    }

    // Compara duas strings (s1 e s2) caractere por caractere
    public static int compararNomes(String s1, String s2) {
        int inicio = 0;
        
        while(inicio < s1.length() && inicio < s2.length()){
            if(s1.charAt(inicio) == s2.charAt(inicio)){
                 inicio++;
            } else {
                return s1.charAt(inicio) - s2.charAt(inicio);
            }
        }

        if(s1.length() == s2.length()){
            return 0; 
        } else if (s1.length() > s2.length()) {
            return 1; 
        } else {
            return -1; 
        }
    }

    // Ordena o vetor de Jogos 
    public static void ordenaGamesPorNome(Game[] games, int n){
        for(int i = n-1; i > 0; i--){
            for(int j = 0; j < i; j++){
                if(compararNomes(games[j].getName(), games[j+1].getName()) > 0){
                    Game aux = games[j];
                    games[j] = games[j+1];
                    games[j+1] = aux;
                }
            }
        }
    }
    
    // Realiza a pesquisa binária e conta UMA comparação por iteração
    public static boolean buscaBinariaPorNome(Game[] games, int n, String nomeBusca) {
        int esquerda = 0;
        int direita = n - 1;

        while (esquerda <= direita) {
            totalComparacoes++; // Contagem da comparação da pesquisa
            int meio = (esquerda + direita) / 2;
            String nomeMeio = games[meio].getName();
            
            int comparacao = compararNomes(nomeMeio, nomeBusca); 
            
            if (comparacao == 0) {
                return true; 
            } else if (comparacao < 0) {
                esquerda = meio + 1; 
            } else {
                direita = meio - 1; 
            }
        }
        return false;
    }

    public static void criarLog(String matricula, double tempo, int comparacoes) throws IOException {
        try (PrintWriter writer = new PrintWriter(new FileWriter("889841_binaria.txt"))) {
            
            String tempoStr = String.valueOf(tempo).replace(',', '.');
            writer.print(matricula + "\t" + tempoStr + "ms" + "\t" + comparacoes + "\n");
        }
    }

    public static void main(String[] args) throws Exception {
        File arquivo = new File("games.csv");
        
        
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
        
        Game[] tempGames = new Game[totalGamesCount];
        for(int i = 0; i < totalGamesCount; i++) tempGames[i] = todosOsGames[i];
        todosOsGames = tempGames; 

        Scanner sc = new Scanner(System.in);
        
        String entrada;
        
        int[] id = new int[1];
        int count = 0; 

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

        String[] names = new String[1];
        int contador = 0; 
        sc.nextLine(); 
        while(sc.hasNextLine()){
            String name = sc.nextLine();
            if(name.equals("FIM")) break;
            if(contador == names.length){
                String[] tempStr = new String[names.length*2];
                for(int i = 0; i < names.length; i++){ tempStr[i] = names[i]; }
                names = tempStr;
            }
            names[contador] = name;
            contador++;
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
        
        ordenaGamesPorNome(vetorJogos, jogosEncontrados);

        totalComparacoes = 0; 
        long startTime = System.nanoTime();
        
        
        
        for (int i = 0; i < contador; i++) {
            String nomeBusca = names[i];
            boolean encontrado = buscaBinariaPorNome(vetorJogos, jogosEncontrados, nomeBusca);
            
            
            System.out.println(encontrado ? " SIM" : " NAO");

        }
        
        
        long endTime = System.nanoTime();
        double tempoExecucao = (endTime - startTime) / 1_000_000.0;

        criarLog("889841", tempoExecucao, totalComparacoes); 
        
        
        sc.close(); 
    }
}