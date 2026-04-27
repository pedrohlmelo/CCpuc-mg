#include <iostream>

using namespace std;

class Veiculo
{
private:
    int tanqueMaximo = 50, rendimento = 15, combustivelAtual, combustivelRestante, kmPercorridos;
public:
    Veiculo()
    {
        configurarTudo(50, 15, 0, 0);
    }

    void configurarTudo(int cap, int cons, int inicio, int dist)
    {
        definirTanque(cap);
        definirRendimento(cons);
        definirCombustivel(inicio);
        definirDistancia(dist);
    }

    void definirTanque(int cap)
    {
        if (cap == 50) tanqueMaximo = cap;
        else cout << "Tanque inválido" << endl;
    }

    void definirRendimento(int cons)
    {
        if (cons == 15) rendimento = cons;
        else cout << "Rendimento inválido" << endl;
    }

    void definirCombustivel(int inicio)
    {
        if (inicio <= 50) combustivelAtual = inicio;
        else cout << "Capacidade excedida" << endl;
    }

    void definirDistancia(int km)
    {
        if (km <= 750) kmPercorridos = km;
        else cout << "Distância acima do permitido" << endl;
    }

    int obterTanque()
    {
        return tanqueMaximo;
    }

    int obterRendimento()
    {
        return rendimento;
    }

    int obterCombustivel()
    {
        return combustivelAtual;
    }

    int obterDistancia()
    {
        return kmPercorridos;
    }

    void calcularRestante()
    {
        int gasto = kmPercorridos / rendimento;
        combustivelRestante = combustivelAtual - gasto;
    }

    void lerInformacoes()
    {
        int entradaComb, entradaDist;
        cin >> entradaComb >> entradaDist;
        definirCombustivel(entradaComb);
        definirDistancia(entradaDist);
        calcularRestante();
    }

    void mostrarDados()
    {
        cout << "Distância rodada: " << obterDistancia() << endl;
        cout << "Combustível restante: " << combustivelRestante << endl;
    }
};

void preencherVeiculos(Veiculo frota[], int tamanho)
{
    for (int i = 0; i < tamanho; i++)
    {
        frota[i].lerInformacoes();
    }
}

void mostrarVeiculos(Veiculo frota[], int tamanho)
{
    for (int i = 0; i < tamanho; i++)
    {
        cout << "Veículo " << i + 1 << ":" << endl;
        frota[i].mostrarDados();
    }
}

int main()
{
    Veiculo frota[2];
    preencherVeiculos(frota, 2);
    mostrarVeiculos(frota, 2);
    return 0;
}
