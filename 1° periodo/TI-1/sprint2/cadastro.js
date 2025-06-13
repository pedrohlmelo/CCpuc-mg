// Arquivo: cadastro.js (versão modificada)

document.addEventListener('DOMContentLoaded', () => {
    const formCadastro = document.getElementById('formCadastro');
    const mensagemDiv = document.getElementById('mensagem');
    const categoriaExistenteSelect = document.getElementById('categoria_existente');

    // Função para popular categorias existentes (opcional, mas recomendado)
    async function popularCategorias() {
        try {
            // Limpa opções antigas para não duplicar ao reenviar o form
            categoriaExistenteSelect.innerHTML = '<option value="" selected>-- Selecione uma Categoria Existente --</option>';

            const response = await fetch('db.json'); // Busca o db.json para pegar as categorias
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const data = await response.json();
            const categorias = Object.keys(data);
            categorias.forEach(cat => {
                const option = document.createElement('option');
                option.value = cat;
                option.textContent = formatarTextoCategoria(cat);
                categoriaExistenteSelect.appendChild(option);
            });
        } catch (error) {
            console.error('Erro ao carregar categorias:', error);
            mensagemDiv.innerHTML = `<div class="alert alert-warning">Não foi possível carregar as categorias existentes.</div>`;
        }
    }

    function formatarTextoCategoria(texto) {
        return texto.replaceAll('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
    }

    popularCategorias(); // Chama a função para popular

    formCadastro.addEventListener('submit', async (event) => {
        event.preventDefault();
        mensagemDiv.innerHTML = ''; // Limpa mensagens anteriores

        const formData = new FormData(formCadastro);
        // O json-server adiciona o 'id' automaticamente, não precisamos enviá-lo.
        const novaFerramenta = {
            nome: formData.get('nome'),
            descricao: formData.get('descricao'),
            recomendacao: formData.get('recomendacao'),
            link: formData.get('link')
        };

        let categoria = formData.get('nova_categoria').trim();
        if (!categoria) {
            categoria = formData.get('categoria_existente');
        }

        if (!categoria) {
            mensagemDiv.innerHTML = '<div class="alert alert-danger">Por favor, selecione ou insira uma categoria.</div>';
            return;
        }

        // Formata a nova categoria para o padrão snake_case se for nova
        if (formData.get('nova_categoria').trim()) {
            categoria = categoria.toLowerCase().replace(/\s+/g, '_');
        }


        try {
            // ==================================================================
            // ALTERAÇÃO PRINCIPAL AQUI
            // A URL do fetch agora é construída dinamicamente com a categoria.
            // O corpo do JSON agora envia apenas os dados da ferramenta.
            // ==================================================================
            const response = await fetch(`http://localhost:3000/${categoria}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(novaFerramenta), // Enviamos apenas o objeto da ferramenta
            });

            const resultado = await response.json();

            if (response.ok) {
                mensagemDiv.innerHTML = `<div class="alert alert-success">Ferramenta cadastrada com sucesso!</div>`;
                formCadastro.reset(); // Limpa o formulário
                popularCategorias(); // Repopula categorias caso uma nova tenha sido adicionada
            } else {
                mensagemDiv.innerHTML = `<div class="alert alert-danger">${resultado.message || 'Erro ao cadastrar.'}</div>`;
            }
        } catch (error) {
            console.error('Erro ao enviar formulário:', error);
            mensagemDiv.innerHTML = '<div class="alert alert-danger">Erro de conexão ao tentar cadastrar. Verifique se o json-server está rodando.</div>';
        }
    });
});