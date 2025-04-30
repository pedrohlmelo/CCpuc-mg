#include <stdio.h>
#include <stdlib.h>


char nadadorC(int idade)
{
    char identi;
    if(5<=idade && idade<=7)
    {
        identi = 'F';

    }

    else if(8<=idade && idade<=10)
    {
        identi = 'E';

    }
    else if(11<=idade && idade<=13)
    {
        identi = 'D';

    }
    else if(idade == 14 || idade == 15)
    {
        identi = 'C';
    }
    else if(idade ==16 || idade == 17)
    {
        identi = 'B';
    }
    else if(idade>=18)
    {
        identi = 'A';
    }
    return identi;
}

int main()
{
    int n,id;
    //printf("Digite a quantidade\n");
    scanf("%d",&n);


    for(int u=0; u<n; u++)
    {
    //printf("Digite as idades\n");
        scanf("%d",&id);
        printf("%c\n",nadadorC(id));
    }
    return 0;
}
