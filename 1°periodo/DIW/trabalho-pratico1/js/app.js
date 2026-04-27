const receitas = [
    {
        id: 1,
        titulo: "Pão de Queijo",
        imagem: "imgs/pao-de-queijo-capa.webp",
        descricao: "Rende até 30 unidades - 80 min",
        ingredientes: [
            "400g de mussarela ralada",
            "500g de polvilho azedo",
            "100ml de leite",
            "100ml de água",
            "3/4 xícara de óleo",
            "1 colher de café de sal",
            "2 ovos batidos"
        ],
        preparo: `Em uma tigela, coloque o polvilho azedo, o leite, a água e o óleo. Misture bem até ficar homogêneo.
                    Em seguida, adicione os ovos batidos e o sal, e mexa até formar uma massa. Acrescente a mussarela ralada e misture.
                    Modele os pães e asse a 180°C por 20 minutos ou até dourar.`,
        lancamento: false,
        categoria: "Salgados"
    },
    {
        id: 2,
        titulo: "Canjiquinha",
        imagem: "imgs/canjiquinha-mineira.webp",
        descricao: "Rende até 8 porções - 100 min",
        ingredientes: [
            "1,3 kg de costelinha suína",
            "2 cabeças de alho",
            "Sal, pimenta e limão",
            "Canjiquinha (quirera)",
            "Cebola, tomate, calabresa, bacon",
            "Colorau, louro, extrato de tomate",
            "Água quente e cebolinha"
        ],
        preparo: `Tempere a costelinha com alho, sal, pimenta e limão. Frite com açúcar e banha, junte os temperos e a canjiquinha demolhada.
                    Cozinhe na pressão por 20 minutos, finalize com cebolinha.`,
        lancamento: false,
        categoria: "Salgados"
    },
    {
        id: 3,
        titulo: "Bolo de Banana com Aveia",
        imagem: "imgs/bolo-de-banana-com-aveia-facil-capa.webp",
        descricao: "Rende até 12 fatias - 50 min",
        ingredientes: [
            "5 bananas maduras",
            "4 ovos",
            "1 xícara de açúcar demerara",
            "1/2 xícara de óleo",
            "1 xícara de uvas-passas",
            "1 colher de canela",
            "1 colher de fermento",
            "200g de aveia em flocos"
        ],
        preparo: `Bata no liquidificador as bananas, ovos e óleo. Misture com os ingredientes secos e leve ao forno por 40 minutos a 180ºC.`,
        lancamento: false,
        categoria: "Bolos"
    },
    {
        id: 4,
        titulo: "Doce de Leite Talhado",
        imagem: "imgs/doce-de-leite-talhado-06.jpg",
        descricao: "Rende aproximadamente 750g - 40 min",
        ingredientes: [
            "1 litro de leite integral",
            "1 xícara de açúcar refinado",
            "50 ml de suco de limão",
            "8 a 10 cravos",
            "1 canela em pau"
        ],
        preparo: `Derreta o açúcar com os cravos e a canela. Adicione o leite e o limão e cozinhe sem mexer por cerca de 30 minutos. Retire os cravos e sirva.`,
        lancamento: true,
        categoria: "Doces"
    },
    {
        id: 5,
        titulo: "Patê de ovo fit",
        imagem: "imgs/pate-de-ovo-fit.webp",
        descricao: "Rende aproximadamente 6 a 8 porç. - 15 min",
        ingredientes: [
            "2 ovos grandes",
            "500 ml de água (ou o suficiente para cozinhar)",
            "1 colher de sopa de requeijão light",
            "1/2 colher de chá de sal (ou a gosto)",
            "Cebolinha a gosto"
        ],
        preparo: `Cozinhe os ovos em água fervente por 5-10 minutos, conforme a textura da gema desejada.
                    Descasque os ovos e amasse-os com um garfo.
                    Adicione cebolinha picada, requeijão e sal. Misture até obter uma pasta cremosa.
                    Sirva com torradas ou pães frescos.`,
        lancamento: true,
        categoria: "Salgados"
    }
];


document.addEventListener("DOMContentLoaded", () => {
    const container = document.querySelector("#receitas-container");
    const lancamentosLink = document.querySelector('header ul li:nth-child(4) a');
    const dropdownCategorias = document.getElementById('dropdownCategorias');
    const dropdownMenuCategorias = document.querySelector('.dropdown-menu');
    const barraDePesquisa = document.getElementById('barraDePesquisa');
    const botaoPesquisar = document.getElementById('botaoPesquisar');

    function exibirReceitas(listaDeReceitas) {
        container.innerHTML = '';
        if (listaDeReceitas.length === 0) {
            container.innerHTML = '<p>Nenhuma receita encontrada.</p>';
            return;
        }
        listaDeReceitas.forEach(r => {
            const card = document.createElement("div");
            card.className = "col-md-6 col-lg-4 mb-4";
            card.innerHTML = `
                <div class="card">
                    <img src="${r.imagem}" class="card-img-top" alt="${r.titulo}">
                    <div class="card-body">
                        <h5 class="card-title">${r.titulo}</h5>
                        <p class="card-text">${r.descricao}</p>
                        <a href="detalhe.html?id=${r.id}" class="btn btn-primary">Ver Receita</a>
                    </div>
                </div>
            `;
            container.appendChild(card);
        });
    }

    exibirReceitas(receitas);

    lancamentosLink.addEventListener('click', (event) => {
        event.preventDefault();
        const lancamentos = receitas.filter(receita => receita.lancamento);
        exibirReceitas(lancamentos);
    });

    dropdownMenuCategorias.addEventListener('click', (event) => {
        if (event.target.classList.contains('dropdown-item')) {
            const categoriaSelecionada = event.target.textContent;
            dropdownCategorias.textContent = categoriaSelecionada;
            const receitasFiltradas = receitas.filter(receita => receita.categoria === categoriaSelecionada);
            exibirReceitas(receitasFiltradas);
        }
    });

   
    botaoPesquisar.addEventListener('click', () => {
        const termoPesquisa = barraDePesquisa.value.toLowerCase();
        const resultadosPesquisa = receitas.filter(receita =>
            receita.titulo.toLowerCase().includes(termoPesquisa)
        );
        exibirReceitas(resultadosPesquisa);
    });

    
    barraDePesquisa.addEventListener('keypress', (event) => {
        if (event.key === 'Enter') {
            botaoPesquisar.click();
        }
    });
});


if (window.location.pathname.includes('detalhe.html')) {
    const urlParams = new URLSearchParams(window.location.search);
    const receitaId = parseInt(urlParams.get('id'));
    const receita = receitas.find(r => r.id === receitaId);
    if (receita) {
        document.getElementById("titulo-detalhe").textContent = receita.titulo;
        const informacoes = document.getElementById("informacoes-gerais");
        informacoes.innerHTML = `
            <div class="row">
                <div class="col-md-6">
                    <img src="${receita.imagem}" class="img-fluid mb-3" alt="${receita.titulo}">
                </div>
                <div class="col-md-6">
                    <h5>Ingredientes</h5>
                    <ul>
                        ${receita.ingredientes.map(ingrediente => `<li>${ingrediente}</li>`).join('')}
                    </ul>
                    <h5>Modo de Preparo</h5>
                    <p>${receita.preparo}</p>
                </div>
            </div>
        `;
    } else {
        console.log(`Receita com ID ${receitaId} não encontrada.`);
    }
}
