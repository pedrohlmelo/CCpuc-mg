.data
vetor:    .word 7, 2, 15, 4, 9     # 5 elementos
n:        .word 5

.text
.globl main

main:
    # a0 = endereço do vetor
    la a0, vetor

    # a1 = tamanho do vetor
    lw a1, n

    # chama a função max_vec
    jal ra, max_vec

    # resultado (máximo) agora está em a0
    mv s0, a0          # armazena em registrador seguro

    # finaliza programa corretamente
    li a7, 10
    ecall


# --------------------------------------------------
# FUNÇÃO: max_vec
# a0 = endereço do vetor
# a1 = tamanho
# retorno: a0 = maior valor
# --------------------------------------------------

max_vec:
    lw   t0, 0(a0)             # t0 = max = v[0]
    li   t1, 1                  # i = 1

max_loop:
    bge  t1, a1, max_end        # if i >= n: fim

    slli t2, t1, 2              # offset = i * 4
    add  t2, a0, t2
    lw   t3, 0(t2)              # t3 = v[i]

    ble  t3, t0, max_skip       # se v[i] <= max, pula
    mv   t0, t3                  # max = v[i]

max_skip:
    addi t1, t1, 1              # i++
    j    max_loop

max_end:
    mv   a0, t0                  # return max
    j    fim
fim:
    j fim   # loop infinito

