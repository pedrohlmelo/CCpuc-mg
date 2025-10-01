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

    public static void set(Game game,String[] atributos){

    }

    public static void main(String[] args){
        File arquivo = new File("games.csv");
          Scanner scFile = new Scanner(arquivo);
          Scanner sc = new Scanner(System.in);
          Game[] game =  new Game[2000];
          int i = 0;
          
          while(scFile.hasNext()){
            game[i] =  new Game();
            String[14] atributos = new String[14];
            set(game[i], atributos);
            i++;  
          }
        
    }
}