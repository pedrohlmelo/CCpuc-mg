#include <stdio.h>


typedef struct
{
    int x;
    int y;
} Ponto;

int main()
{
    int n;



    scanf("%d", &n);


    for (int i = 0; i < n; i++)
    {
        Ponto a, b, c;
        int alinhamentos_horizontais = 0;
        int alinhamentos_verticais = 0;



        scanf("%d %d", &a.x, &a.y);

        scanf("%d %d", &b.x, &b.y);

        scanf("%d %d", &c.x, &c.y);


        if (a.y == b.y)
        {
            alinhamentos_horizontais++;
        }
        if (a.x == b.x)
        {
            alinhamentos_verticais++;
        }


        if (a.y == c.y)
        {
            alinhamentos_horizontais++;
        }
        if (a.x == c.x)
        {
            alinhamentos_verticais++;
        }


        if (b.y == c.y)
        {
            alinhamentos_horizontais++;
        }
        if (b.x == c.x)
        {
            alinhamentos_verticais++;
        }



        printf("alinhamentos verticais: %d\n", alinhamentos_verticais);
        printf("alinhamentos horizontais: %d\n", alinhamentos_horizontais);
        printf("\n");
    }

    return 0;
}
