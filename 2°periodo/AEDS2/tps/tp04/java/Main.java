import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.io.File;

class Game {
    //atributos
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

    // sets e get
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


    
      //Pega todos os dados de um jogo e os imprime na tela em uma única linha
     
    public void imprimir() {
        System.out.print("=> " + id + " ## " + name + " ## " + releaseDate + " ## " + estimatedOwners + " ## " + price + " ## [");
        for (int i = 0; i < supportedLanguages.length; i++) {
            System.out.print(supportedLanguages[i]);
            if (i < supportedLanguages.length - 1) System.out.print(", ");
        }
        System.out.print("] ## " + metacriticScore + " ## " + userScore + " ## " + achievements + " ## [");
        for (int i = 0; i < publishers.length; i++) {
            System.out.print(publishers[i]);
            if (i < publishers.length - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
        for (int i = 0; i < developers.length; i++) {
            System.out.print(developers[i]);
            if (i < developers.length - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
        for (int i = 0; i < categories.length; i++) {
            System.out.print(categories[i]);
            if (i < categories.length - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
        for (int i = 0; i < genres.length; i++) {
            System.out.print(genres[i]);
            if (i < genres.length - 1) System.out.print(", ");
        }
        System.out.print("] ## [");
        for (int i = 0; i < tags.length; i++) {
            System.out.print(tags[i]);
            if (i < tags.length - 1) System.out.print(", ");
        }
        // para pular para a próxima linha após imprimir tudo.
        System.out.println("] ##");
    }
}

public class Main {
    /*
      Um método auxiliar para fazer o trabalho do "split".
      Ele pega um texto (ex: "A,B,C") e um separador (ex: ',') e retorna
      um array de strings (ex: ["A", "B", "C"]).
     */
    private static String[] separarStringInterna(String texto, char separador) {
        if (texto == null || texto.isEmpty()) return new String[0];
        List<String> resultado = new ArrayList<>();
        String itemAtual = "";
        for (int i = 0; i < texto.length(); i++) {
            char c = texto.charAt(i);
            if (c == separador) {
                resultado.add(itemAtual);
                itemAtual = "";
                if (i + 1 < texto.length() && texto.charAt(i + 1) == ' ') i++;
            } else {
                itemAtual += c;
            }
        }
        resultado.add(itemAtual);
        String[] arrayResultado = new String[resultado.size()];
        for(int i=0; i < resultado.size(); i++) arrayResultado[i] = resultado.get(i);
        return arrayResultado;
    }

    public static void formatar(Game game, String linha) {
        
        /* percorre a linha do CSV
        caractere por caractere. A variável `dentroDeAspas` garante que ele não
         separe campos por vírgulas que estão dentro de aspas (como em uma data).*/
        List<String> campos = new ArrayList<>();
        String campoAtual = "";
        boolean dentroDeAspas = false;
    
        for (int i = 0; i < linha.length(); i++) {
            char c = linha.charAt(i);
            if (c == '"') {
                dentroDeAspas = !dentroDeAspas;
            } else if (c == ',' && !dentroDeAspas) {
                campos.add(campoAtual);
                campoAtual = "";
            } else {
                campoAtual += c;
            }
        }
        campos.add(campoAtual);
    
        
        game.setId(Integer.parseInt(campos.get(0)));
        game.setName(campos.get(1));
        
        
        String dataOriginal = campos.get(2);
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
        
        
        game.setEstimatedOwners(Integer.parseInt(campos.get(3)));
        game.setPrice(Float.parseFloat(campos.get(4)));
        String linguagensStr = campos.get(5);
        String linguagensLimpas = "";
        for(int i = 0; i < linguagensStr.length(); i++){
            char c = linguagensStr.charAt(i);
            if(c != '[' && c != ']' && c != '\'') linguagensLimpas += c;
        }
        game.setSupportedLanguages(separarStringInterna(linguagensLimpas, ','));
        game.setMetacriticScore(Integer.parseInt(campos.get(6)));
        game.setUserScore(Float.parseFloat(campos.get(7)));
        game.setAchievements(Integer.parseInt(campos.get(8)));
        game.setPublishers(separarStringInterna(campos.get(9), ','));
        game.setDevelopers(separarStringInterna(campos.get(10), ','));
        game.setCategories(separarStringInterna(campos.get(11), ','));
        game.setGenres(separarStringInterna(campos.get(12), ','));
        game.setTags(separarStringInterna(campos.get(13), ','));
    }

    public static void main(String[] args) throws Exception {
        
        // Lê o arquivo "games.csv", chama o 'formatar' para cada linha
        // e guarda todos os objetos 'Game' em uma lista.
        File arquivo = new File("/tmp/games.csv");
        List<Game> gamesList = new ArrayList<>();
        try (Scanner scFile = new Scanner(arquivo)) {
            scFile.nextLine(); // Pula o cabeçalho
            while (scFile.hasNextLine()) {
                String linha = scFile.nextLine();
                if (linha.isEmpty()) continue;
                Game novoGame = new Game();
                formatar(novoGame, linha);
                gamesList.add(novoGame);
            }
        }
    
        
        try (Scanner sc = new Scanner(System.in)) {
            String entrada;
            
            while (sc.hasNext()) {
                entrada = sc.next(); 
    
                // Se o usuário digitar "FIM", o programa para.
                if (entrada.equalsIgnoreCase("FIM")) {
                    break;
                }
    
                // Converte a entrada para número e procura o jogo na lista.
                int idParaBuscar = Integer.parseInt(entrada);
                for (Game game : gamesList) {
                    if (game.getId() == idParaBuscar) {
                        game.imprimir();
                        break; 
                    }
                }
            }
        } 
    } 
}