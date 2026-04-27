document.addEventListener('DOMContentLoaded', () => {
    function getCategoriaDaUrl() {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get('categoria');
    }

    function formatarTexto(texto) {
        return texto.replaceAll('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
    }

    const categoria = getCategoriaDaUrl();
    const listaFerramentasElement = document.getElementById('lista-ferramentas');
    const paginaTituloElement = document.getElementById('pagina-titulo');

    if (categoria) {
        const tituloFormatado = formatarTexto(categoria) + ' Recomendados';
        if (paginaTituloElement) {
            paginaTituloElement.textContent = tituloFormatado;
            document.title = tituloFormatado;
        }

        fetch('db.json')
            .then(response => response.json())
            .then(data => {
                console.log(`Dados carregados para a categoria "${categoria}":`, data[categoria]);
                if (data && data[categoria] && listaFerramentasElement) {
                    const ferramentasContainer = document.createElement('div');
                    ferramentasContainer.classList.add('ferramentas-grid');

                    data[categoria].forEach(ferramenta => {
                        const divFerramentaDetalhada = document.createElement('div');
                        divFerramentaDetalhada.classList.add('ferramenta-detalhada');

                        const nomeH2 = document.createElement('h2');
                        nomeH2.textContent = formatarTexto(ferramenta.nome);

                        const descricaoP = document.createElement('p');
                        descricaoP.textContent = ferramenta.descricao;

                        const recomendacaoTituloH3 = document.createElement('h3');
                        recomendacaoTituloH3.textContent = 'Por que recomendamos:';

                        const recomendacaoP = document.createElement('p');
                        recomendacaoP.textContent = ferramenta.recomendacao;

                        const linkA = document.createElement('a');
                        linkA.href = ferramenta.link;
                        linkA.textContent = 'Visitar Site';
                        linkA.target = '_blank';
                        linkA.classList.add('btn', 'btn-primary');

                        divFerramentaDetalhada.appendChild(nomeH2);
                        divFerramentaDetalhada.appendChild(descricaoP);
                        divFerramentaDetalhada.appendChild(recomendacaoTituloH3);
                        divFerramentaDetalhada.appendChild(recomendacaoP);
                        divFerramentaDetalhada.appendChild(linkA);

                        ferramentasContainer.appendChild(divFerramentaDetalhada);
                    });

                    listaFerramentasElement.appendChild(ferramentasContainer);
                } else if (!listaFerramentasElement) {
                    console.error('Elemento com ID "lista-ferramentas" não encontrado no HTML.');
                } else {
                    console.error(`Dados para a categoria "${categoria}" não encontrados no db.json.`);
                }
            })
            .catch(error => {
                console.error('Erro ao carregar o db.json:', error);
            });
    } else {
        console.error('Parâmetro "categoria" não encontrado na URL.');
    }
});
