#include <iostream>

using namespace std;
class Pessoa
{
private:
    string nome;
    int idade;
    float altura;
public:
    Pessoa()
    {
        inicializa(string("nenhum"),1,1);
    }

    void inicializa(string texto,int id, float alt)
    {
        setnome(texto);
        setidade(id);
        setaltura(alt);
    }

    void setnome(string texto)
    {
        if(texto.length()<2)
        {
            cout << "Nome curto demais" << endl;
        }
        else
            nome = texto;
    }

    void setidade(int id)
    {
        if(id < 0)
        {
            cout << "Idade invalida" << endl;
        }
        else
            idade = id;
    }

    void setaltura(float alt)
    {
        if(alt > 0.50 && alt < 3.00)
        {
            altura = alt;

        }
        else cout << "Altura invalida" << endl;

    }

    string getnome()
    {
        return nome;
    }

    int getidade()
    {
        return idade;
    }

    float getaltura()
    {
        return altura;
    }

    void preenche()
    {
        string texto;
        int id1;
        float alt1;
        getline(cin,texto);
        setnome(texto);
        cin >> id1 >> alt1;
        setidade(id1);
        setaltura(alt1);
        cin.ignore();
    }

    void exibe()
    {
        cout << "Dados da pessoa:" << endl;
        cout << "Nome: " << getnome() << endl << "Idade: " << getidade() << " anos" << endl << "Altura: " << getaltura() << " metros" << endl;
    }
};

void PreenchePessoas(Pessoa pessoa[],int tam)
{
    for(int i=0; i<tam; i++)
    {
        pessoa[i].preenche();
    }
}

void ExibePessoas(Pessoa pessoa[],int tam)
{
    for(int i=0; i<tam; i++)
    {
        pessoa[i].exibe();
    }
}

int main()
{
    int N;
    cin >> N;
    Pessoa pessoa[N];
    cin.ignore();
    PreenchePessoas(pessoa,N);
    ExibePessoas(pessoa,N);

    return 0;
}
