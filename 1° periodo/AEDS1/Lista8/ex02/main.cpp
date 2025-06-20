#include <iostream>

using namespace std;

class Tempo
{
private:
    int hora, minuto, segundo;
public:
    Tempo()
    {
        inicializarTempo(0, 0, 0);
    }

    void definirHora(int h)
    {
        if (h >= 0 && h <= 23) hora = h;
        else cout << "Hora inválida" << endl;
    }

    void definirMinuto(int m)
    {
        if (m >= 0 && m <= 59) minuto = m;
        else cout << "Minuto inválido" << endl;
    }

    void definirSegundo(int s)
    {
        if (s >= 0 && s <= 59) segundo = s;
        else cout << "Segundo inválido" << endl;
    }

    int obterHora()
    {
        return hora;
    }

    int obterMinuto()
    {
        return minuto;
    }

    int obterSegundo()
    {
        return segundo;
    }

    void avancarTempo()
    {
        segundo++;
        if (segundo == 60)
        {
            segundo = 0;
            minuto++;
        }
        if (minuto == 60)
        {
            minuto = 0;
            hora++;
        }
        if (hora == 24)
        {
            hora = 0;
            minuto = 0;
            segundo = 0;
        }
    }

    void lerDados()
    {
        int h, m, s;
        cin >> h >> m >> s;
        definirHora(h);
        definirMinuto(m);
        definirSegundo(s);
    }

    void mostrarTempo()
    {
        cout << "Hora atual: " << obterHora() << ":" << obterMinuto() << ":" << obterSegundo() << endl;
        avancarTempo();
        cout << "Hora após avanço: " << obterHora() << ":" << obterMinuto() << ":" << obterSegundo() << endl << endl;
    }

private:
    void inicializarTempo(int h, int m, int s)
    {
        definirHora(h);
        definirMinuto(m);
        definirSegundo(s);
    }
};

void carregarTempos(Tempo vetor[], int quantidade)
{
    for (int i = 0; i < quantidade; i++)
    {
        vetor[i].lerDados();
    }
}

void imprimirTempos(Tempo vetor[], int quantidade)
{
    for (int i = 0; i < quantidade; i++)
    {
        vetor[i].mostrarTempo();
    }
}

int main()
{
    int total;
    cin >> total;
    if (total >= 1 && total <= 1000)
    {
        Tempo listaTempos[total];
        carregarTempos(listaTempos, total);
        imprimirTempos(listaTempos, total);
    }
    else
    {
        cout << "Quantidade inválida" << endl;
    }
    return 0;
}
