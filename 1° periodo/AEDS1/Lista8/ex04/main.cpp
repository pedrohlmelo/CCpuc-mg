#include <iostream>

using namespace std;

class Escritor
{
private:
    string identificador;
public:
    Escritor()
    {
        configurar("nenhum");
    }

    void configurar(string entrada)
    {
        definirIdentificador(entrada);
    }

    void definirIdentificador(string entrada)
    {
        if (entrada.length() > 2) identificador = entrada;
        else cout << "Identificador inv�lido" << endl;
    }

    string obterIdentificador()
    {
        return identificador;
    }

    void mostrar()
    {
        cout << "Escritor: " << obterIdentificador() << endl;
    }
};

class Publicacao
{
private:
    string nomeObra;
    int anoLancamento;
    Escritor* referenciaAutor;
public:
    Publicacao(Escritor* ptrAutor) : referenciaAutor(ptrAutor)
    {
        configurarPublicacao("nenhum", 0);
    }

    void configurarPublicacao(string tituloEntrada, int anoEntrada)
    {
        definirNomeObra(tituloEntrada);
        definirAno(anoEntrada);
    }

    void definirNomeObra(string tituloEntrada)
    {
        if (tituloEntrada.length() > 2) nomeObra = tituloEntrada;
        else cout << "Nome da obra inv�lido" << endl;
    }

    void definirAno(int anoEntrada)
    {
        if (anoEntrada < 2026) anoLancamento = anoEntrada;
        else cout << "Ano de lan�amento inv�lido" << endl;
    }

    string obterNomeObra()
    {
        return nomeObra;
    }

    int obterAno()
    {
        return anoLancamento;
    }

    void mostrarInformacoes()
    {
        cout << "Informa��es da Publica��o: " << endl;
        cout << "T�tulo: " << obterNomeObra() << endl;
        cout << "Ano de Lan�amento: " << obterAno() << endl;
        cout << "Escritor: " << referenciaAutor->obterIdentificador() << endl;
    }
};

int main()
{
    string entradaAutor;
    getline(cin, entradaAutor);
    Escritor escritorPrincipal;
    escritorPrincipal.definirIdentificador(entradaAutor);

    string entradaTitulo;
    int entradaAno;
    getline(cin, entradaTitulo);
    cin >> entradaAno;

    Publicacao obra(&escritorPrincipal);
    obra.definirNomeObra(entradaTitulo);
    obra.definirAno(entradaAno);
    obra.mostrarInformacoes();

    return 0;
}
