import java.util.*;
import java.io.*;

class Game{
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
 
 public Game(){}


 public void setId(int id) {
    this.id = id;
}

public void setName(String name) {
    this.name = name;
}

public void setReleaseDate(String releaseDate) {
    this.releaseDate = releaseDate;
}

public void setEstimatedOwners(int estimatedOwners) {
    this.estimatedOwners = estimatedOwners;
}

public void setPrice(float price) {
    this.price = price;
}

public void setSupportedLanguages(String[] supportedLanguages) {
    this.supportedLanguages = supportedLanguages;
}

public void setPublishers(String[] publishers) {
    this.publishers = publishers;
}

public void setDevelopers(String[] developers) {
    this.developers = developers;
}

public void setCategories(String[] categories) {
    this.categories = categories;
}

public void setGenres(String[] genres) {
    this.genres = genres;
}

public void setTags(String[] tags) {
    this.tags = tags;
}

}



public class Main{

    public static void formatar(Game game, String linha){
        int i = 0;
        int contagemVirgulas = 0;
        String auxId = "";
        while(linha.charAt(i) != ','){
            i++;
        }
        contagemVirgulas++;
        for(int u = 0; u < i; u++){
            auxId += linha.charAt(u);
        }
        int id = Integer.parseInt(auxId);
        game.setId(id);
         
        String auxName = "";
        for(int u = i+1; linha.charAt(u) != ','; u++){
               auxName += linha.charAt(u);
        }
        game.setName(auxName);
        contagemVirgulas++;
         String auxreleaseDate = "";
         int contagem = 0;
         for(int u = 0; u < linha.length(); u++){
            if(linha.charAt(u) == ','){
                contagem++;
            }
            if(contagem >= 2 && contagem < 4){
                if(linha.charAt(u) != '"'){
                    auxreleaseDate += linha.charAt(u);
                }
            }
         }
         game.setReleaseDate(auxreleaseDate);
         contagemVirgulas= 4;
         contagem = 0;
         String auxestimatedOwners = "";
         for(int u = 0; u < linha.length(); u++){
            if(linha.charAt(u) == ','){
                contagem ++;
            }
            if(contagem == contagemVirgulas){
                auxestimatedOwners += linha.charAt(u+1);
            }
         }
           int estimatedOwners = Integer.parseInt(auxestimatedOwners);
           game.setEstimatedOwners(estimatedOwners);
           contagemVirgulas++;
           contagem = 0;

           String auxPrice = "";
           for(int u = 0; u < linha.length(); u++){
            if(linha.charAt(u) == ','){
                contagem ++;
            }
            if(contagem == contagemVirgulas){
                auxPrice += linha.charAt(u+1);
            }
         }
         float price = Float.parseFloat(auxPrice);
         game.setPrice(price);

         contagemVirgulas++;
         contagem = 0;
         int contagemAspas = 0;

         String auxsupportedLanguages = "";
         for(int u = 0; u < linha.length(); u++){
            if(contagem < contagemVirgulas){
            if(linha.charAt(u) == ','){
                contagem ++;
            }
        }
        if(contagem == contagemVirgulas && linha.charAt(u) == '"'){
            contagemAspas++;
        }
        if(contagemAspas < 2){
            if(contagem == contagemVirgulas && linha.charAt(u) != '"' && linha.charAt(u) != '\''){
                auxsupportedLanguages += linha.charAt(u);
            }
         }
        }

            
            
        }
        
         
    }

    public static void main(String[] args){
        File arquivo = new File("games.csv");
          Scanner scFile = new Scanner(arquivo);
          Scanner sc = new Scanner(System.in);
          Game[] game =  new Game[2000];
          int i = 0;
          scFile.nextLine();
          
          while(scFile.hasNext()){
            game[i] =  new Game();
            String linha = scFile.nextLine();
            formatar(game[i],linha);
            i++;  
          }
        
    }
}