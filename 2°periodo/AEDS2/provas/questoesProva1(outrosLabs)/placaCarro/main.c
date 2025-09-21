#include <stdio.h>
#include <stdlib.h>

void conferePlaca(char placa[]){


	int tam = 0;
	while(placa[tam] != '\0'){
		tam++;
	}

          if(tam == 8){
		   if('A' <= placa[0] <= 'Z' && 'A' <= placa[1] <= 'Z' && 'A' <= placa[2] <= 'Z'){
		  if(placa[3] == '-' && 0 <= placa[4] <= 9 && 0 <= placa[5] <= 9 && 0 <= placa[6] <= 9 && 0 <= placa[7] <= 9){
			 printf("1\n");
		  }
		   }
	  }
	  else if(tam == 7){
		  if('A' <= placa[0] <= 'Z' && 'A' <= placa[1] <= 'Z' && 'A' <= placa[2] <= 'Z'){
			  if( 0 <= placa[3] <= 9 && 'A' <= placa[4] <= 'Z' && 0  <= placa[5] <= 9 && 0 <= placa[6] <= 9){
				  printf("2\n");
			  }
		  }
	  }
	  else printf("0\n");
 
}


int main(){

     char placa[100];

     scanf(" %[^\n]",placa);

      conferePlaca(placa);
	   


	return 0 ;
}
