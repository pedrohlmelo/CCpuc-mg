.data
vetor:    .word 5,4,3,2,1   # 5 elementos
n:        .word 5

.text
.globl main

# -------------------------
# main
# -------------------------
main:

    # a0 = endereço base do vetor
    la a0, vetor

    # a1 = tamanho do vetor (5)
    lw a1, n

    # chama a função
    jal ra, sum_vec

    # -------------------------
    # Neste ponto:
    # a0 contém a SOMA do vetor ✅
    # -------------------------

    # Encerrar programa
    li a7, 10


# --------------------------------------------------
# sum_vec
# a0 = endereço do vetor
# a1 = tamanho
# retorno: a0 = soma
# --------------------------------------------------

sum_vec:

    add  t0, zero, zero     # t0 = soma = 0
    add  t1, zero, zero     # t1 = i = 0

sum_loop:

    bge  t1, a1, sum_end    # se i >= n, encerra

    slli t2, t1, 2           # t2 = i * 4
    add  t2, a0, t2          # t2 = &v[i]
    lw   t3, 0(t2)           # t3 = v[i]

    add  t0, t0, t3          # soma += v[i]

    addi t1, t1, 1           # i++
    j    sum_loop


sum_end:

    add  a0, t0, zero        # a0 = soma final 
    j fim   # loop infinito

fim:
    j fim   # loop infinito

