#include <stdio.h>
#include <stdlib.h>

int main()
{
    int c1 = 0, c2 = 0, c3 = 0, c4 = 0, nulo = 0, branco = 0;
    char voto;

    //printf("Digite seus votos \n");

    while(1)
    {
        scanf(" %c", &voto);

        if (voto == '0')
            break;
        else if (voto == '1')
            c1++;
        else if (voto == '2')
            c2++;
        else if (voto == '3')
            c3++;
        else if (voto == '4')
            c4++;
        else if (voto == '5')
            nulo++;
        else if (voto == '6')
            branco++;
    }



    printf("%d\n",c1);
    printf("%d\n",c2);
    printf("%d\n",c3);
    printf("%d\n",c4);
    printf("%d\n",nulo);
    printf("%d\n",branco);

    return 0;
}
