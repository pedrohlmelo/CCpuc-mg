document.addEventListener('DOMContentLoaded', () => {
  fetch('db.json')
    .then(response => response.json())
    .then(data => {
      console.log('Dados carregados do db.json:', data);
      const categoria = 'navegadores';
      const listaFerramentasElement = document.getElementById('lista-ferramentas');

      if (data && data[categoria] && listaFerramentasElement) {
        data[categoria].forEach(ferramenta => {
          const divFerramenta = document.createElement('div');
          divFerramenta.classList.add('ferramenta-item'); 

          const nomeH3 = document.createElement('h3');
          nomeH3.textContent = ferramenta.nome;

          const descricaoP = document.createElement('p');
          descricaoP.textContent = ferramenta.descricao;

          const recomendacaoP = document.createElement('p');
          recomendacaoP.textContent = `Recomendação: ${ferramenta.recomendacao}`;

          const linkA = document.createElement('a');
          linkA.href = ferramenta.link;
          linkA.textContent = 'Saiba mais';
          linkA.target = '_blank'; 

          divFerramenta.appendChild(nomeH3);
          divFerramenta.appendChild(descricaoP);
          divFerramenta.appendChild(recomendacaoP);
          divFerramenta.appendChild(linkA);

          listaFerramentasElement.appendChild(divFerramenta);
        });
      } else if (!listaFerramentasElement) {
        console.error('Elemento com ID "lista-ferramentas" não encontrado no HTML.');
      } else {
        console.error(`Dados para a categoria "${categoria}" não encontrados no db.json.`);
      }
    })
    .catch(error => {
      console.error('Erro ao carregar o db.json:', error);
    });
});