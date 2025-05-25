const form = document.getElementById('formDica');
const listaDicas = document.getElementById('listaDicas');
const indexEdicao = document.getElementById('indexEdicao');
const alertContainer = document.getElementById('alertContainer');
const formTitulo = document.getElementById('formTitulo');
const btnSalvar = document.getElementById('btnSalvar');

const getDicas = () => JSON.parse(localStorage.getItem('dicasSeguranca')) || [];
const setDicas = (dicas) => localStorage.setItem('dicasSeguranca', JSON.stringify(dicas));

function showAlert(message, type = 'success') {
  alertContainer.innerHTML = `
    <div class="alert alert-${type} alert-dismissible fade show" role="alert">
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Fechar"></button>
    </div>`;
  setTimeout(() => {
    const alertNode = alertContainer.querySelector('.alert');
    if (alertNode) bootstrap.Alert.getOrCreateInstance(alertNode).close();
  }, 4000);
}

function renderDicas() {
  const dicas = getDicas();
  listaDicas.innerHTML = dicas.map((dica, index) => `
    <div class="col-md-6">
      <div class="card p-3 shadow">
        <h5 class="card-title">${dica.titulo}</h5>
        <p class="card-text">${dica.descricao}</p>
        <p class="card-text"><strong>Categoria:</strong> ${dica.categoria}</p>
        <button class="btn btn-sm btn-warning me-2 btn-acao" onclick="editarDica(${index})">Editar</button>
        <button class="btn btn-sm btn-danger btn-acao" onclick="confirmarExclusao(${index})">Deletar</button>
      </div>
    </div>
  `).join('');
}

function editarDica(index) {
  const dica = getDicas()[index];
  form.titulo.value = dica.titulo;
  form.descricao.value = dica.descricao;
  form.categoria.value = dica.categoria;
  indexEdicao.value = index;
  formTitulo.textContent = 'Editar Dica de Segurança';
  btnSalvar.textContent = 'Atualizar Dica';
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function confirmarExclusao(index) {
  if (confirm("Tem certeza que deseja excluir esta dica?")) {
    const dicas = getDicas();
    dicas.splice(index, 1);
    setDicas(dicas);
    renderDicas();
    showAlert("Dica excluída com sucesso!", "warning");
  }
}

form.addEventListener('submit', (e) => {
  e.preventDefault();
  const { titulo, descricao, categoria } = form;
  const dicas = getDicas();
  const index = indexEdicao.value;

  if (index === '') {
    dicas.push({ titulo: titulo.value, descricao: descricao.value, categoria: categoria.value });
    showAlert("Dica cadastrada com sucesso!");
  } else {
    dicas[index] = { titulo: titulo.value, descricao: descricao.value, categoria: categoria.value };
    indexEdicao.value = '';
    showAlert("Dica atualizada com sucesso!", "info");
    formTitulo.textContent = 'Cadastro de Dicas de Segurança';
    btnSalvar.textContent = 'Salvar Dica';
  }

  setDicas(dicas);
  form.reset();
  renderDicas();
});

window.onload = renderDicas;
