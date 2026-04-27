#include <iostream>

using namespace std;

class Plataforma
{
private:
    int nivelAtual = 0, totalNiveis, pessoasNoInterior = 0, limitePessoas;
public:
    Plataforma()
    {
        configurarTudo(0, 0);
    }

    Plataforma(int limite, int niveis)
    {
        configurarTudo(limite, niveis);
    }

    void configurarTudo(int limite, int niveis)
    {
        definirLimitePessoas(limite);
        definirTotalNiveis(niveis);
    }

    void definirLimitePessoas(int valor)
    {
        if (valor > 0) limitePessoas = valor;
        else cout << "Limite inválido" << endl;
    }

    void definirTotalNiveis(int valor)
    {
        if (valor > 0) totalNiveis = valor;
        else cout << "Quantidade de níveis inválida" << endl;
    }

    int obterNivelAtual()
    {
        return nivelAtual;
    }

    int obterTotalNiveis()
    {
        return totalNiveis;
    }

    int obterLimitePessoas()
    {
        return limitePessoas;
    }

    int obterPessoasNoInterior()
    {
        return pessoasNoInterior;
    }

    void adicionarPessoa()
    {
        if (pessoasNoInterior < limitePessoas) pessoasNoInterior++;
        else cout << "Capacidade máxima atingida" << endl;
    }

    void removerPessoa()
    {
        if (pessoasNoInterior > 0) pessoasNoInterior--;
        else cout << "Plataforma vazia" << endl;
    }

    void subirNivel()
    {
        if (nivelAtual < totalNiveis) nivelAtual++;
        else cout << "Já está no nível mais alto" << endl;
    }

    void descerNivel()
    {
        if (nivelAtual > 0) nivelAtual--;
        else cout << "Já está no nível térreo" << endl;
    }

    void mostrarStatus()
    {
        cout << "Nível atual: " << obterNivelAtual() << endl;
        cout << "Pessoas dentro: " << obterPessoasNoInterior() << endl;
    }
};

int main()
{
    int capacidadeMaxima, numeroDeNiveis, comandos;
    cin >> capacidadeMaxima >> numeroDeNiveis;
    Plataforma sistema(capacidadeMaxima, numeroDeNiveis);
    cin >> comandos;

    for (int i = 0; i < comandos; i++)
    {
        string acao;
        cin >> acao;

        if (acao == "entrar")
        {
            sistema.adicionarPessoa();
            sistema.mostrarStatus();
        }
        else if (acao == "sair")
        {
            sistema.removerPessoa();
            sistema.mostrarStatus();
        }
        else if (acao == "subir")
        {
            sistema.subirNivel();
            sistema.mostrarStatus();
        }
        else if (acao == "descer")
        {
            sistema.descerNivel();
            sistema.mostrarStatus();
        }
        else
        {
            cout << "Comando inválido" << endl;
        }
    }

    return 0;
}
